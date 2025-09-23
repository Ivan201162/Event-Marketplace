import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/feature_flags.dart';
import '../models/booking.dart';
import '../models/payment.dart';

/// Сервис для управления платежами
class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Создать платеж
  Future<Payment> createPayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required PaymentType type,
    required double amount,
    required OrganizationType organizationType,
    String? description,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
    double prepaymentAmount = 0.0,
    double taxAmount = 0.0,
    double taxRate = 0.0,
    TaxType? taxType,
  }) async {
    try {
      final payment = Payment(
        id: _generatePaymentId(),
        bookingId: bookingId,
        userId: customerId,
        customerId: customerId,
        specialistId: specialistId,
        type: type,
        status: PaymentStatus.pending,
        amount: amount,
        currency: 'RUB',
        createdAt: DateTime.now(),
        description: description,
        paymentMethod: paymentMethod,
        metadata: metadata,
        organizationType: organizationType,
        prepaymentAmount: prepaymentAmount,
        taxAmount: taxAmount,
        taxRate: taxRate,
        taxType: taxType,
      );

      await _db.collection('payments').doc(payment.id).set(payment.toMap());
      return payment;
    } catch (e) {
      print('Ошибка создания платежа: $e');
      throw Exception('Не удалось создать платеж: $e');
    }
  }

  /// Получить платеж по ID
  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _db.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return Payment.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Ошибка получения платежа: $e');
      return null;
    }
  }

  /// Получить платежи по заявке
  Future<List<Payment>> getPaymentsByBooking(String bookingId) async {
    try {
      final querySnapshot = await _db
          .collection('payments')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Ошибка получения платежей по заявке: $e');
      return [];
    }
  }

  /// Поток платежей по заявке
  Stream<List<Payment>> getPaymentsByBookingStream(String bookingId) => _db
      .collection('payments')
      .where('bookingId', isEqualTo: bookingId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList(),
      );

  /// Получить платежи по клиенту
  Stream<List<Payment>> getPaymentsByCustomerStream(String customerId) => _db
      .collection('payments')
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList(),
      );

  /// Получить платежи по специалисту
  Stream<List<Payment>> getPaymentsBySpecialistStream(String specialistId) =>
      _db
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Payment.fromMap(doc.data()))
                .toList(),
          );

  /// Обновить статус платежа
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionId,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      if (paymentMethod != null) {
        updateData['paymentMethod'] = paymentMethod;
      }

      if (metadata != null) {
        updateData['metadata'] = metadata;
      }

      // Добавляем временные метки в зависимости от статуса
      final now = DateTime.now();
      switch (status) {
        case PaymentStatus.completed:
          updateData['completedAt'] = Timestamp.fromDate(now);
          break;
        case PaymentStatus.failed:
          updateData['failedAt'] = Timestamp.fromDate(now);
          break;
        default:
          break;
      }

      await _db.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      print('Ошибка обновления статуса платежа: $e');
      throw Exception('Не удалось обновить статус платежа: $e');
    }
  }

  /// Создать платежи для заявки с расширенной логикой
  Future<List<Payment>> createPaymentsForBooking({
    required Booking booking,
    required OrganizationType organizationType,
  }) async {
    if (!FeatureFlags.paymentsEnabled) {
      return _createMockPayments(booking, organizationType);
    }

    try {
      final config = PaymentConfiguration.getDefault(organizationType);
      final payments = <Payment>[];

      // Для государственных учреждений - только постоплата
      if (organizationType == OrganizationType.government) {
        final fullPayment = await createPayment(
          bookingId: booking.id,
          customerId: booking.userId,
          specialistId: booking.specialistId ?? '',
          type: PaymentType.fullPayment,
          amount: booking.totalPrice,
          organizationType: organizationType,
          description: 'Полная постоплата (государственное учреждение)',
          metadata: {
            'paymentType': 'postpayment',
            'totalAmount': booking.totalPrice,
            'isGovernment': true,
          },
        );
        payments.add(fullPayment);
        return payments;
      }

      // Для коммерческих организаций - аванс + постоплата
      if (config.requiresAdvance) {
        final advanceAmount = config.calculateAdvanceAmount(booking.totalPrice);
        if (advanceAmount > 0) {
          final advancePayment = await createPayment(
            bookingId: booking.id,
            customerId: booking.userId,
            specialistId: booking.specialistId ?? '',
            type: PaymentType.advance,
            amount: advanceAmount,
            organizationType: organizationType,
            description:
                'Авансовый платеж (${config.advancePercentage.toInt()}%)',
            metadata: {
              'advancePercentage': config.advancePercentage,
              'totalAmount': booking.totalPrice,
              'paymentType': 'prepayment',
            },
          );
          payments.add(advancePayment);
        }
      }

      // Создаем финальный платеж
      final advanceAmount = config.calculateAdvanceAmount(booking.totalPrice);
      final finalAmount =
          config.calculateFinalAmount(booking.totalPrice, advanceAmount);

      if (finalAmount > 0) {
        final finalPayment = await createPayment(
          bookingId: booking.id,
          customerId: booking.userId,
          specialistId: booking.specialistId ?? '',
          type: PaymentType.finalPayment,
          amount: finalAmount,
          organizationType: organizationType,
          description: 'Финальный платеж после выполнения услуг',
          metadata: {
            'advanceAmount': advanceAmount,
            'totalAmount': booking.totalPrice,
            'paymentType': 'postpayment',
          },
        );
        payments.add(finalPayment);
      }

      return payments;
    } catch (e) {
      debugPrint('Ошибка создания платежей для заявки: $e');
      throw Exception('Не удалось создать платежи: $e');
    }
  }

  /// Обработать платеж (имитация)
  Future<void> processPayment(String paymentId, String paymentMethod) async {
    try {
      // Обновляем статус на "обрабатывается"
      await updatePaymentStatus(
        paymentId,
        PaymentStatus.processing,
        paymentMethod: paymentMethod,
      );

      // Имитируем обработку платежа
      await Future.delayed(const Duration(seconds: 2));

      // В реальном приложении здесь была бы интеграция с платежной системой
      // Для демонстрации случайным образом определяем успех/неудачу
      final isSuccess = DateTime.now().millisecond % 2 == 0;

      if (isSuccess) {
        await updatePaymentStatus(
          paymentId,
          PaymentStatus.completed,
          transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        await updatePaymentStatus(
          paymentId,
          PaymentStatus.failed,
          metadata: {'error': 'Недостаточно средств'},
        );
      }
    } catch (e) {
      print('Ошибка обработки платежа: $e');
      await updatePaymentStatus(
        paymentId,
        PaymentStatus.failed,
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Отменить платеж
  Future<void> cancelPayment(String paymentId) async {
    try {
      await updatePaymentStatus(paymentId, PaymentStatus.cancelled);
    } catch (e) {
      print('Ошибка отмены платежа: $e');
      throw Exception('Не удалось отменить платеж: $e');
    }
  }

  /// Создать возврат
  Future<Payment> createRefund({
    required String originalPaymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final originalPayment = await getPayment(originalPaymentId);
      if (originalPayment == null) {
        throw Exception('Оригинальный платеж не найден');
      }

      final refund = await createPayment(
        bookingId: originalPayment.bookingId,
        customerId: originalPayment.customerId,
        specialistId: originalPayment.specialistId,
        type: PaymentType.refund,
        amount: amount,
        organizationType: originalPayment.organizationType,
        description: 'Возврат: $reason',
        metadata: {
          'originalPaymentId': originalPaymentId,
          'refundReason': reason,
        },
      );

      return refund;
    } catch (e) {
      print('Ошибка создания возврата: $e');
      throw Exception('Не удалось создать возврат: $e');
    }
  }

  /// Получить статистику платежей
  Future<PaymentStatistics> getPaymentStatistics(
    String userId, {
    bool isSpecialist = false,
  }) async {
    try {
      final query = isSpecialist
          ? _db.collection('payments').where('specialistId', isEqualTo: userId)
          : _db.collection('payments').where('customerId', isEqualTo: userId);

      final snapshot = await query.get();
      final payments = snapshot.docs.map(Payment.fromDocument).toList();

      double totalAmount = 0;
      double completedAmount = 0;
      double pendingAmount = 0;
      var completedCount = 0;
      var pendingCount = 0;
      var failedCount = 0;

      for (final payment in payments) {
        totalAmount += payment.amount;

        switch (payment.status) {
          case PaymentStatus.completed:
            completedAmount += payment.amount;
            completedCount++;
            break;
          case PaymentStatus.pending:
          case PaymentStatus.processing:
            pendingAmount += payment.amount;
            pendingCount++;
            break;
          case PaymentStatus.failed:
            failedCount++;
            break;
          default:
            break;
        }
      }

      return PaymentStatistics(
        totalAmount: totalAmount,
        completedAmount: completedAmount,
        pendingAmount: pendingAmount,
        completedCount: completedCount,
        pendingCount: pendingCount,
        failedCount: failedCount,
        totalCount: payments.length,
      );
    } catch (e) {
      print('Ошибка получения статистики платежей: $e');
      return PaymentStatistics.empty();
    }
  }

  /// Получить платежную схему для организации
  PaymentScheme getPaymentScheme(OrganizationType organizationType) {
    switch (organizationType) {
      case OrganizationType.individual:
        return const PaymentScheme(
          advancePercentage: 30,
          requiresAdvance: true,
          allowsPostpayment: true,
          maxAdvanceAmount: 50000,
          description: 'Физическое лицо: 30% аванс, 70% постоплата',
        );
      case OrganizationType.commercial:
        return const PaymentScheme(
          advancePercentage: 30,
          requiresAdvance: true,
          allowsPostpayment: true,
          maxAdvanceAmount: 200000,
          description: 'Коммерческая организация: 30% аванс, 70% постоплата',
        );
      case OrganizationType.government:
        return const PaymentScheme(
          advancePercentage: 0,
          requiresAdvance: false,
          allowsPostpayment: true,
          maxAdvanceAmount: 0,
          description: 'Государственное учреждение: 100% постоплата',
        );
      case OrganizationType.nonprofit:
        return const PaymentScheme(
          advancePercentage: 20,
          requiresAdvance: true,
          allowsPostpayment: true,
          maxAdvanceAmount: 100000,
          description: 'Некоммерческая организация: 20% аванс, 80% постоплата',
        );
    }
  }

  /// Рассчитать платежи по схеме
  PaymentCalculation calculatePayments({
    required double totalAmount,
    required OrganizationType organizationType,
  }) {
    final scheme = getPaymentScheme(organizationType);

    var advanceAmount = 0;
    var finalAmount = totalAmount;

    if (scheme.requiresAdvance) {
      advanceAmount = totalAmount * scheme.advancePercentage / 100;
      finalAmount = totalAmount - advanceAmount;

      // Ограничиваем максимальный аванс
      if (scheme.maxAdvanceAmount > 0 &&
          advanceAmount > scheme.maxAdvanceAmount) {
        advanceAmount = scheme.maxAdvanceAmount;
        finalAmount = totalAmount - advanceAmount;
      }
    }

    return PaymentCalculation(
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      finalAmount: finalAmount,
      advancePercentage: scheme.advancePercentage,
      scheme: scheme,
    );
  }

  /// Проверить возможность постоплаты
  bool canUsePostpayment(OrganizationType organizationType, double amount) {
    final scheme = getPaymentScheme(organizationType);
    return scheme.allowsPostpayment;
  }

  /// Получить рекомендуемую схему оплаты
  String getRecommendedPaymentScheme(OrganizationType organizationType) {
    final scheme = getPaymentScheme(organizationType);
    return scheme.description;
  }

  /// Создать mock платежи для демонстрации
  List<Payment> _createMockPayments(
    Booking booking,
    OrganizationType organizationType,
  ) {
    final calculation = calculatePayments(
      totalAmount: booking.totalPrice,
      organizationType: organizationType,
    );

    final payments = <Payment>[];

    if (calculation.advanceAmount > 0) {
      payments.add(
        Payment(
          id: 'mock_advance_${DateTime.now().millisecondsSinceEpoch}',
          bookingId: booking.id,
          customerId: booking.userId,
          specialistId: booking.specialistId ?? '',
          type: PaymentType.advance,
          status: PaymentStatus.pending,
          amount: calculation.advanceAmount,
          currency: 'RUB',
          createdAt: DateTime.now(),
          description:
              'Авансовый платеж (${calculation.advancePercentage.toInt()}%)',
          organizationType: organizationType,
          metadata: {
            'isMock': true,
            'advancePercentage': calculation.advancePercentage,
            'totalAmount': calculation.totalAmount,
          },
          updatedAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 7)),
          isPrepayment: true,
          isFinalPayment: false,
        ),
      );
    }

    if (calculation.finalAmount > 0) {
      payments.add(
        Payment(
          id: 'mock_final_${DateTime.now().millisecondsSinceEpoch}',
          bookingId: booking.id,
          customerId: booking.userId,
          specialistId: booking.specialistId ?? '',
          type: PaymentType.finalPayment,
          status: PaymentStatus.pending,
          amount: calculation.finalAmount,
          currency: 'RUB',
          createdAt: DateTime.now(),
          description: 'Финальный платеж после выполнения услуг',
          organizationType: organizationType,
          metadata: {
            'isMock': true,
            'advanceAmount': calculation.advanceAmount,
            'totalAmount': calculation.totalAmount,
          },
          updatedAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 30)),
          isPrepayment: false,
          isFinalPayment: true,
        ),
      );
    }

    return payments;
  }

  /// Рассчитать налоги для платежа
  Future<Map<String, double>> calculateTaxes({
    required double amount,
    required OrganizationType organizationType,
    required TaxType taxType,
    bool isFromLegalEntity = false,
  }) async {
    final taxAmount = TaxCalculator.calculateTax(
      amount,
      taxType,
      isFromLegalEntity: isFromLegalEntity,
    );
    final taxRate = TaxCalculator.getTaxRate(
      taxType,
      isFromLegalEntity: isFromLegalEntity,
    );

    return {
      'taxAmount': taxAmount,
      'taxRate': taxRate,
      'netAmount': amount - taxAmount,
    };
  }

  /// Создать платеж с автоматическим расчётом налогов
  Future<Payment> createPaymentWithTaxes({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required PaymentType type,
    required double amount,
    required OrganizationType organizationType,
    required TaxType taxType,
    String? description,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
    bool isFromLegalEntity = false,
  }) async {
    // Рассчитываем налоги
    final taxCalculation = await calculateTaxes(
      amount: amount,
      organizationType: organizationType,
      taxType: taxType,
      isFromLegalEntity: isFromLegalEntity,
    );

    // Рассчитываем аванс
    final config = PaymentConfiguration.getDefault(organizationType);
    final prepaymentAmount = config.calculateAdvanceAmount(amount);

    return createPayment(
      bookingId: bookingId,
      customerId: customerId,
      specialistId: specialistId,
      type: type,
      amount: amount,
      organizationType: organizationType,
      description: description,
      paymentMethod: paymentMethod,
      metadata: metadata,
      prepaymentAmount: prepaymentAmount,
      taxAmount: taxCalculation['taxAmount']!,
      taxRate: taxCalculation['taxRate']!,
      taxType: taxType,
    );
  }

  /// Генерировать ID платежа
  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'PAY_${timestamp}_$random';
  }
}

/// Статистика платежей
class PaymentStatistics {
  const PaymentStatistics({
    required this.totalAmount,
    required this.completedAmount,
    required this.pendingAmount,
    required this.completedCount,
    required this.pendingCount,
    required this.failedCount,
    required this.totalCount,
  });

  factory PaymentStatistics.empty() => const PaymentStatistics(
        totalAmount: 0,
        completedAmount: 0,
        pendingAmount: 0,
        completedCount: 0,
        pendingCount: 0,
        failedCount: 0,
        totalCount: 0,
      );
  final double totalAmount;
  final double completedAmount;
  final double pendingAmount;
  final int completedCount;
  final int pendingCount;
  final int failedCount;
  final int totalCount;

  /// Процент завершенных платежей
  double get completionRate {
    if (totalCount == 0) return 0;
    return (completedCount / totalCount) * 100;
  }

  /// Процент завершенной суммы
  double get amountCompletionRate {
    if (totalAmount == 0) return 0;
    return (completedAmount / totalAmount) * 100;
  }
}

/// Платежная схема
class PaymentScheme {
  const PaymentScheme({
    required this.advancePercentage,
    required this.requiresAdvance,
    required this.allowsPostpayment,
    required this.maxAdvanceAmount,
    required this.description,
  });
  final double advancePercentage;
  final bool requiresAdvance;
  final bool allowsPostpayment;
  final double maxAdvanceAmount;
  final String description;
}

/// Расчет платежей
class PaymentCalculation {
  const PaymentCalculation({
    required this.totalAmount,
    required this.advanceAmount,
    required this.finalAmount,
    required this.advancePercentage,
    required this.scheme,
  });
  final double totalAmount;
  final double advanceAmount;
  final double finalAmount;
  final double advancePercentage;
  final PaymentScheme scheme;

  /// Получить описание расчета
  String get description {
    if (advanceAmount == 0) {
      return 'Полная постоплата: ${totalAmount.toStringAsFixed(0)} ${'RUB'}';
    } else {
      return 'Аванс: ${advanceAmount.toStringAsFixed(0)} ${'RUB'} (${advancePercentage.toInt()}%), '
          'Остаток: ${finalAmount.toStringAsFixed(0)} ${'RUB'}';
    }
  }

  /// Проверить, является ли схема постоплатой
  bool get isPostpayment => advanceAmount == 0;

  /// Проверить, является ли схема авансовой
  bool get isPrepayment => advanceAmount > 0;
}
