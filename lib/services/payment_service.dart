import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';
import '../models/booking.dart';

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
  }) async {
    try {
      final payment = Payment(
        id: _generatePaymentId(),
        bookingId: bookingId,
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
        return Payment.fromDocument(doc);
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
          .map((doc) => Payment.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Ошибка получения платежей по заявке: $e');
      return [];
    }
  }

  /// Поток платежей по заявке
  Stream<List<Payment>> getPaymentsByBookingStream(String bookingId) {
    return _db
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payment.fromDocument(doc))
            .toList());
  }

  /// Получить платежи по клиенту
  Stream<List<Payment>> getPaymentsByCustomerStream(String customerId) {
    return _db
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payment.fromDocument(doc))
            .toList());
  }

  /// Получить платежи по специалисту
  Stream<List<Payment>> getPaymentsBySpecialistStream(String specialistId) {
    return _db
        .collection('payments')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payment.fromDocument(doc))
            .toList());
  }

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

  /// Создать платежи для заявки
  Future<List<Payment>> createPaymentsForBooking({
    required Booking booking,
    required OrganizationType organizationType,
  }) async {
    try {
      final config = PaymentConfiguration.getDefault(organizationType);
      final payments = <Payment>[];

      // Создаем авансовый платеж, если требуется
      if (config.requiresAdvance) {
        final advanceAmount = config.calculateAdvanceAmount(booking.totalPrice);
        if (advanceAmount > 0) {
          final advancePayment = await createPayment(
            bookingId: booking.id,
            customerId: booking.customerId,
            specialistId: booking.specialistId,
            type: PaymentType.advance,
            amount: advanceAmount,
            organizationType: organizationType,
            description: 'Авансовый платеж (${config.advancePercentage.toInt()}%)',
            metadata: {
              'advancePercentage': config.advancePercentage,
              'totalAmount': booking.totalPrice,
            },
          );
          payments.add(advancePayment);
        }
      }

      // Создаем финальный платеж
      final advanceAmount = config.calculateAdvanceAmount(booking.totalPrice);
      final finalAmount = config.calculateFinalAmount(booking.totalPrice, advanceAmount);
      
      if (finalAmount > 0) {
        final finalPayment = await createPayment(
          bookingId: booking.id,
          customerId: booking.customerId,
          specialistId: booking.specialistId,
          type: PaymentType.final_payment,
          amount: finalAmount,
          organizationType: organizationType,
          description: 'Финальный платеж',
          metadata: {
            'advanceAmount': advanceAmount,
            'totalAmount': booking.totalPrice,
          },
        );
        payments.add(finalPayment);
      }

      return payments;
    } catch (e) {
      print('Ошибка создания платежей для заявки: $e');
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
  Future<PaymentStatistics> getPaymentStatistics(String userId, {bool isSpecialist = false}) async {
    try {
      final query = isSpecialist
          ? _db.collection('payments').where('specialistId', isEqualTo: userId)
          : _db.collection('payments').where('customerId', isEqualTo: userId);

      final snapshot = await query.get();
      final payments = snapshot.docs.map((doc) => Payment.fromDocument(doc)).toList();

      double totalAmount = 0;
      double completedAmount = 0;
      double pendingAmount = 0;
      int completedCount = 0;
      int pendingCount = 0;
      int failedCount = 0;

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

  /// Генерировать ID платежа
  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'PAY_${timestamp}_$random';
  }
}

/// Статистика платежей
class PaymentStatistics {
  final double totalAmount;
  final double completedAmount;
  final double pendingAmount;
  final int completedCount;
  final int pendingCount;
  final int failedCount;
  final int totalCount;

  const PaymentStatistics({
    required this.totalAmount,
    required this.completedAmount,
    required this.pendingAmount,
    required this.completedCount,
    required this.pendingCount,
    required this.failedCount,
    required this.totalCount,
  });

  factory PaymentStatistics.empty() {
    return const PaymentStatistics(
      totalAmount: 0,
      completedAmount: 0,
      pendingAmount: 0,
      completedCount: 0,
      pendingCount: 0,
      failedCount: 0,
      totalCount: 0,
    );
  }

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
