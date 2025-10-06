import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment.dart';

/// Сервис для управления платежами
class PaymentService {
  PaymentService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Создать платеж
  Future<Payment> createPayment({
    required String bookingId,
    required String userId,
    required String specialistId,
    required PaymentType type,
    required double amount,
    required String currency,
    required PaymentMethod method,
    required String description,
    String? transactionId,
    String? paymentProvider,
    double? fee,
    double? tax,
    Map<String, dynamic>? metadata,
    DateTime? dueDate,
  }) async {
    try {
      final payment = Payment(
        id: '', // Будет установлен Firestore
        bookingId: bookingId,
        userId: userId,
        specialistId: specialistId,
        type: type,
        amount: amount,
        currency: currency,
        status: PaymentStatus.pending,
        method: method,
        description: description,
        transactionId: transactionId,
        paymentProvider: paymentProvider,
        fee: fee,
        tax: tax,
        totalAmount: _calculateTotalAmount(amount, fee, tax),
        metadata: metadata,
        createdAt: DateTime.now(),
        dueDate: dueDate,
      );

      final docRef =
          await _firestore.collection('payments').add(payment.toMap());

      return payment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания платежа: $e');
    }
  }

  /// Создать предоплату (30% от стоимости)
  Future<Payment> createDepositPayment({
    required String bookingId,
    required String userId,
    required String specialistId,
    required double totalAmount,
    required String currency,
    required PaymentMethod method,
    String? paymentProvider,
    DateTime? dueDate,
  }) async {
    const depositPercentage = 0.30; // 30%
    final depositAmount = totalAmount * depositPercentage;

    return createPayment(
      bookingId: bookingId,
      userId: userId,
      specialistId: specialistId,
      type: PaymentType.deposit,
      amount: depositAmount,
      currency: currency,
      method: method,
      description: 'Предоплата 30% за бронирование',
      paymentProvider: paymentProvider,
      dueDate: dueDate,
    );
  }

  /// Создать окончательный платеж (остаток 70%)
  Future<Payment> createFinalPayment({
    required String bookingId,
    required String userId,
    required String specialistId,
    required double totalAmount,
    required String currency,
    required PaymentMethod method,
    String? paymentProvider,
    DateTime? dueDate,
  }) async {
    // Проверяем, что предоплата уже была внесена
    final existingPayments = await getPaymentsByBooking(bookingId);
    final hasCompletedDeposit = existingPayments.any(
      (payment) =>
          payment.type == PaymentType.deposit &&
          payment.status == PaymentStatus.completed,
    );

    if (!hasCompletedDeposit) {
      throw Exception(
        'Нельзя создать окончательный платеж без завершенной предоплаты',
      );
    }

    // Проверяем, что окончательный платеж еще не создан
    final hasExistingFinalPayment = existingPayments.any(
      (payment) => payment.type == PaymentType.finalPayment,
    );

    if (hasExistingFinalPayment) {
      throw Exception(
        'Окончательный платеж уже создан для данного бронирования',
      );
    }

    const depositPercentage = 0.30; // 30%
    final finalAmount = totalAmount * (1 - depositPercentage);

    return createPayment(
      bookingId: bookingId,
      userId: userId,
      specialistId: specialistId,
      type: PaymentType.finalPayment,
      amount: finalAmount,
      currency: currency,
      method: method,
      description: 'Окончательный платеж за услуги (70%)',
      paymentProvider: paymentProvider,
      dueDate: dueDate,
    );
  }

  /// Обновить статус платежа
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionId,
    String? providerTransactionId,
    String? refundReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      final now = DateTime.now();

      switch (status) {
        case PaymentStatus.processing:
          updateData['processedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.completed:
          updateData['completedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.failed:
          updateData['failedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.cancelled:
          updateData['cancelledAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.refunded:
          updateData['refundedAt'] = Timestamp.fromDate(now);
          if (refundReason != null) {
            updateData['refundReason'] = refundReason;
          }
          break;
        case PaymentStatus.pending:
          // Ничего не добавляем
          break;
      }

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      if (providerTransactionId != null) {
        updateData['providerTransactionId'] = providerTransactionId;
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      throw Exception('Ошибка обновления статуса платежа: $e');
    }
  }

  /// Получить платеж по ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();

      if (!doc.exists) return null;

      return Payment.fromDocument(doc);
    } catch (e) {
      throw Exception('Ошибка получения платежа: $e');
    }
  }

  /// Получить платежи по бронированию
  Future<List<Payment>> getPaymentsByBooking(String bookingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения платежей по бронированию: $e');
    }
  }

  /// Получить платежи пользователя
  Future<List<Payment>> getUserPayments(
    String userId, {
    PaymentStatus? status,
    PaymentType? type,
    int? limit,
  }) async {
    try {
      Query query =
          _firestore.collection('payments').where('userId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения платежей пользователя: $e');
    }
  }

  /// Получить платежи специалиста
  Future<List<Payment>> getSpecialistPayments(
    String specialistId, {
    PaymentStatus? status,
    PaymentType? type,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения платежей специалиста: $e');
    }
  }

  /// Получить просроченные платежи
  Future<List<Payment>> getOverduePayments() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('payments')
          .where(
            'status',
            whereIn: [
              PaymentStatus.pending.name,
              PaymentStatus.processing.name,
            ],
          )
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();

      return querySnapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения просроченных платежей: $e');
    }
  }

  /// Создать заморозку средств
  Future<Payment> createHoldPayment({
    required String bookingId,
    required String userId,
    required String specialistId,
    required double amount,
    required String currency,
    required PaymentMethod method,
    String? paymentProvider,
    DateTime? dueDate,
  }) async {
    try {
      final holdPayment = Payment(
        id: '', // Будет установлен Firestore
        bookingId: bookingId,
        userId: userId,
        specialistId: specialistId,
        type: PaymentType.hold,
        amount: amount,
        currency: currency,
        status: PaymentStatus.pending,
        method: method,
        description: 'Заморозка средств для бронирования',
        paymentProvider: paymentProvider,
        totalAmount: _calculateTotalAmount(amount, null, null),
        metadata: {
          'holdType': 'booking_reservation',
          'holdReason': 'Reservation hold for booking $bookingId',
        },
        createdAt: DateTime.now(),
        dueDate: dueDate,
      );

      final docRef =
          await _firestore.collection('payments').add(holdPayment.toMap());

      return holdPayment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания заморозки средств: $e');
    }
  }

  /// Освободить замороженные средства
  Future<void> releaseHoldPayment(String holdPaymentId) async {
    try {
      await updatePaymentStatus(holdPaymentId, PaymentStatus.cancelled);
    } catch (e) {
      throw Exception('Ошибка освобождения замороженных средств: $e');
    }
  }

  /// Конвертировать заморозку в предоплату
  Future<Payment> convertHoldToDeposit(String holdPaymentId) async {
    try {
      final holdPayment = await getPaymentById(holdPaymentId);
      if (holdPayment == null) {
        throw Exception('Заморозка не найдена');
      }

      if (holdPayment.type != PaymentType.hold) {
        throw Exception('Платеж не является заморозкой');
      }

      // Обновляем тип на предоплату
      final updatedPayment = holdPayment.copyWith(
        type: PaymentType.deposit,
        description: 'Предоплата 30% за бронирование',
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
      );

      await _firestore
          .collection('payments')
          .doc(holdPaymentId)
          .update(updatedPayment.toMap());

      return updatedPayment;
    } catch (e) {
      throw Exception('Ошибка конвертации заморозки в предоплату: $e');
    }
  }

  /// Автоматически создать окончательный платеж при завершении мероприятия
  Future<Payment?> autoCreateFinalPaymentOnEventCompletion(
    String bookingId,
  ) async {
    try {
      final payments = await getPaymentsByBooking(bookingId);

      // Проверяем, что есть завершенная предоплата
      final completedDeposit = payments.firstWhere(
        (payment) =>
            payment.type == PaymentType.deposit &&
            payment.status == PaymentStatus.completed,
        orElse: () => throw Exception('Завершенная предоплата не найдена'),
      );

      // Проверяем, что окончательный платеж еще не создан
      final hasExistingFinalPayment = payments.any(
        (payment) => payment.type == PaymentType.finalPayment,
      );

      if (hasExistingFinalPayment) {
        return null; // Окончательный платеж уже существует
      }

      // Вычисляем общую сумму из предоплаты (30% от общей суммы)
      final totalAmount = completedDeposit.amount / 0.30;

      // Создаем окончательный платеж
      return await createFinalPayment(
        bookingId: bookingId,
        userId: completedDeposit.userId,
        specialistId: completedDeposit.specialistId,
        totalAmount: totalAmount,
        currency: completedDeposit.currency,
        method: completedDeposit.method,
        paymentProvider: completedDeposit.paymentProvider,
        dueDate:
            DateTime.now().add(const Duration(days: 7)), // 7 дней на оплату
      );
    } catch (e) {
      print('Ошибка автоматического создания окончательного платежа: $e');
      return null;
    }
  }

  /// Создать возврат
  Future<Payment> createRefund({
    required String originalPaymentId,
    required String bookingId,
    required String userId,
    required String specialistId,
    required double amount,
    required String currency,
    required String reason,
    String? paymentProvider,
  }) async {
    try {
      // Проверяем оригинальный платеж
      final originalPayment = await getPaymentById(originalPaymentId);
      if (originalPayment == null) {
        throw Exception('Оригинальный платеж не найден');
      }

      if (originalPayment.status != PaymentStatus.completed) {
        throw Exception('Можно вернуть только завершенные платежи');
      }

      // Проверяем, что возврат не превышает сумму оригинального платежа
      if (amount > originalPayment.amount) {
        throw Exception(
          'Сумма возврата не может превышать сумму оригинального платежа',
        );
      }

      final refund = Payment(
        id: '', // Будет установлен Firestore
        bookingId: bookingId,
        userId: userId,
        specialistId: specialistId,
        type: PaymentType.refund,
        amount: amount,
        currency: currency,
        status: PaymentStatus.pending,
        method: originalPayment.method, // Используем тот же метод
        description: 'Возврат: $reason',
        paymentProvider: paymentProvider ?? originalPayment.paymentProvider,
        metadata: {
          'originalPaymentId': originalPaymentId,
          'refundReason': reason,
          'originalAmount': originalPayment.amount,
          'refundPercentage':
              (amount / originalPayment.amount * 100).toStringAsFixed(2),
        },
        createdAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('payments').add(refund.toMap());

      return refund.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания возврата: $e');
    }
  }

  /// Автоматически создать возврат аванса при отмене бронирования
  Future<Payment?> autoCreateRefundOnCancellation(
    String bookingId,
    String reason,
  ) async {
    try {
      final payments = await getPaymentsByBooking(bookingId);

      // Ищем завершенные платежи для возврата
      final completedPayments = payments
          .where(
            (payment) =>
                payment.status == PaymentStatus.completed &&
                (payment.type == PaymentType.deposit ||
                    payment.type == PaymentType.finalPayment),
          )
          .toList();

      if (completedPayments.isEmpty) {
        return null; // Нет завершенных платежей для возврата
      }

      // Создаем возврат для каждого завершенного платежа
      Payment? firstRefund;
      for (final payment in completedPayments) {
        final refund = await createRefund(
          originalPaymentId: payment.id,
          bookingId: bookingId,
          userId: payment.userId,
          specialistId: payment.specialistId,
          amount: payment.amount,
          currency: payment.currency,
          reason: reason,
          paymentProvider: payment.paymentProvider,
        );

        firstRefund ??= refund;
      }

      return firstRefund;
    } catch (e) {
      print('Ошибка автоматического создания возврата: $e');
      return null;
    }
  }

  /// Получить финансовую статистику пользователя
  Future<Map<String, dynamic>> getUserFinancialStats(String userId) async {
    try {
      final payments = await getUserPayments(userId);

      double totalIncome = 0;
      double totalExpenses = 0;
      var completedPayments = 0;
      var pendingPayments = 0;
      var failedPayments = 0;
      var refundedPayments = 0;
      var holdPayments = 0;

      for (final payment in payments) {
        switch (payment.status) {
          case PaymentStatus.completed:
            completedPayments++;
            if (payment.type == PaymentType.deposit ||
                payment.type == PaymentType.finalPayment) {
              totalIncome += payment.amount;
            } else if (payment.type == PaymentType.refund) {
              totalExpenses += payment.amount;
            }
            // Заморозки не учитываем в доходах/расходах
            break;
          case PaymentStatus.pending:
          case PaymentStatus.processing:
            pendingPayments++;
            if (payment.type == PaymentType.hold) {
              holdPayments++;
            }
            break;
          case PaymentStatus.failed:
            failedPayments++;
            break;
          case PaymentStatus.cancelled:
            // Не учитываем отмененные платежи (включая освобожденные заморозки)
            break;
          case PaymentStatus.refunded:
            refundedPayments++;
            totalExpenses += payment.amount;
            break;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netIncome': totalIncome - totalExpenses,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'refundedPayments': refundedPayments,
        'holdPayments': holdPayments,
        'totalPayments': payments.length,
      };
    } catch (e) {
      throw Exception('Ошибка получения финансовой статистики: $e');
    }
  }

  /// Получить финансовую статистику специалиста
  Future<Map<String, dynamic>> getSpecialistFinancialStats(
    String specialistId,
  ) async {
    try {
      final payments = await getSpecialistPayments(specialistId);

      double totalIncome = 0;
      double totalExpenses = 0;
      var completedPayments = 0;
      var pendingPayments = 0;
      var failedPayments = 0;
      var refundedPayments = 0;
      var holdPayments = 0;

      for (final payment in payments) {
        switch (payment.status) {
          case PaymentStatus.completed:
            completedPayments++;
            if (payment.type == PaymentType.deposit ||
                payment.type == PaymentType.finalPayment) {
              totalIncome += payment.amount;
            } else if (payment.type == PaymentType.refund) {
              totalExpenses += payment.amount;
            }
            // Заморозки не учитываем в доходах/расходах
            break;
          case PaymentStatus.pending:
          case PaymentStatus.processing:
            pendingPayments++;
            if (payment.type == PaymentType.hold) {
              holdPayments++;
            }
            break;
          case PaymentStatus.failed:
            failedPayments++;
            break;
          case PaymentStatus.cancelled:
            // Не учитываем отмененные платежи (включая освобожденные заморозки)
            break;
          case PaymentStatus.refunded:
            refundedPayments++;
            totalExpenses += payment.amount;
            break;
        }
      }

      return {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netIncome': totalIncome - totalExpenses,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'refundedPayments': refundedPayments,
        'holdPayments': holdPayments,
        'totalPayments': payments.length,
      };
    } catch (e) {
      throw Exception('Ошибка получения финансовой статистики специалиста: $e');
    }
  }

  /// Создать финансовый отчет
  Future<FinancialReport> generateFinancialReport({
    required String userId,
    required String period, // например, "2024-01"
    bool isSpecialist = false,
  }) async {
    try {
      final payments = isSpecialist
          ? await getSpecialistPayments(userId)
          : await getUserPayments(userId);

      // Фильтруем платежи по периоду
      final periodDate = DateTime.parse('$period-01');
      final nextMonth = DateTime(periodDate.year, periodDate.month + 1);

      final periodPayments = payments
          .where(
            (payment) =>
                payment.createdAt.isAfter(periodDate) &&
                payment.createdAt.isBefore(nextMonth),
          )
          .toList();

      double totalIncome = 0;
      double totalExpenses = 0;
      var completedPayments = 0;
      var pendingPayments = 0;
      var failedPayments = 0;
      var refundedPayments = 0;

      for (final payment in periodPayments) {
        switch (payment.status) {
          case PaymentStatus.completed:
            completedPayments++;
            if (payment.type == PaymentType.deposit ||
                payment.type == PaymentType.finalPayment) {
              totalIncome += payment.amount;
            } else if (payment.type == PaymentType.refund) {
              totalExpenses += payment.amount;
            }
            break;
          case PaymentStatus.pending:
          case PaymentStatus.processing:
            pendingPayments++;
            break;
          case PaymentStatus.failed:
            failedPayments++;
            break;
          case PaymentStatus.cancelled:
            // Не учитываем отмененные платежи
            break;
          case PaymentStatus.refunded:
            refundedPayments++;
            totalExpenses += payment.amount;
            break;
        }
      }

      final report = FinancialReport(
        userId: userId,
        period: period,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netIncome: totalIncome - totalExpenses,
        paymentCount: periodPayments.length,
        completedPayments: completedPayments,
        pendingPayments: pendingPayments,
        failedPayments: failedPayments,
        refundedPayments: refundedPayments,
        currency: 'RUB',
        generatedAt: DateTime.now(),
        breakdown: {
          'byType': _getBreakdownByType(periodPayments),
          'byMethod': _getBreakdownByMethod(periodPayments),
          'byStatus': _getBreakdownByStatus(periodPayments),
        },
      );

      // Сохраняем отчет в Firestore
      await _firestore.collection('financial_reports').add(report.toMap());

      return report;
    } catch (e) {
      throw Exception('Ошибка создания финансового отчета: $e');
    }
  }

  /// Рассчитать итоговую сумму
  double _calculateTotalAmount(double amount, double? fee, double? tax) {
    var total = amount;
    if (fee != null) total += fee;
    if (tax != null) total += tax;
    return total;
  }

  /// Получить разбивку по типам
  Map<String, dynamic> _getBreakdownByType(List<Payment> payments) {
    final breakdown = <String, double>{};

    for (final payment in payments) {
      final typeName = payment.type.name;
      breakdown[typeName] = (breakdown[typeName] ?? 0) + payment.amount;
    }

    return breakdown;
  }

  /// Получить разбивку по методам
  Map<String, dynamic> _getBreakdownByMethod(List<Payment> payments) {
    final breakdown = <String, int>{};

    for (final payment in payments) {
      final methodName = payment.method.name;
      breakdown[methodName] = (breakdown[methodName] ?? 0) + 1;
    }

    return breakdown;
  }

  /// Получить разбивку по статусам
  Map<String, dynamic> _getBreakdownByStatus(List<Payment> payments) {
    final breakdown = <String, int>{};

    for (final payment in payments) {
      final statusName = payment.status.name;
      breakdown[statusName] = (breakdown[statusName] ?? 0) + 1;
    }

    return breakdown;
  }

  /// Удалить платеж (только для тестирования)
  Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления платежа: $e');
    }
  }

  /// Получить все платежи (для администрирования)
  Future<List<Payment>> getAllPayments({int? limit}) async {
    try {
      Query query = _firestore
          .collection('payments')
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map(Payment.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения всех платежей: $e');
    }
  }
}
