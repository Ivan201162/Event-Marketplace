import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/payment.dart';
import '../models/specialist.dart';
import 'payment_service.dart';

/// Сервис для управления двухэтапными платежами
class TwoStagePaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  /// Создать двухэтапный платеж для бронирования
  Future<TwoStagePaymentResult> createTwoStagePayment({
    required Booking booking,
    required OrganizationType organizationType,
    double? customAdvancePercentage,
    double? discountAmount,
    String? discountReason,
  }) async {
    try {
      final config = PaymentConfiguration.getDefault(organizationType);
      
      // Рассчитываем суммы с учетом скидки
      final totalAmount = booking.totalPrice;
      final finalAmount = discountAmount != null 
          ? totalAmount - discountAmount 
          : totalAmount;
      
      // Рассчитываем аванс
      final advancePercentage = customAdvancePercentage ?? config.advancePercentage;
      final advanceAmount = config.requiresAdvance 
          ? finalAmount * (advancePercentage / 100)
          : 0.0;
      
      final remainingAmount = finalAmount - advanceAmount;

      // Создаем авансовый платеж
      Payment? advancePayment;
      if (advanceAmount > 0) {
        advancePayment = await _paymentService.createPayment(
          bookingId: booking.id,
          customerId: booking.userId,
          specialistId: booking.specialistId ?? '',
          type: PaymentType.advance,
          amount: advanceAmount,
          organizationType: organizationType,
          description: 'Авансовый платеж (${advancePercentage.toInt()}%)',
          metadata: {
            'advancePercentage': advancePercentage,
            'totalAmount': totalAmount,
            'finalAmount': finalAmount,
            'discountAmount': discountAmount ?? 0,
            'discountReason': discountReason,
            'paymentType': 'prepayment',
            'isTwoStage': true,
          },
        );
      }

      // Создаем финальный платеж
      Payment? finalPayment;
      if (remainingAmount > 0) {
        finalPayment = await _paymentService.createPayment(
          bookingId: booking.id,
          customerId: booking.userId,
          specialistId: booking.specialistId ?? '',
          type: PaymentType.finalPayment,
          amount: remainingAmount,
          organizationType: organizationType,
          description: 'Финальный платеж после завершения мероприятия',
          metadata: {
            'advanceAmount': advanceAmount,
            'totalAmount': totalAmount,
            'finalAmount': finalAmount,
            'discountAmount': discountAmount ?? 0,
            'discountReason': discountReason,
            'paymentType': 'postpayment',
            'isTwoStage': true,
          },
        );
      }

      // Обновляем бронирование с информацией о платежах
      await _updateBookingWithPaymentInfo(
        booking.id,
        advanceAmount,
        remainingAmount,
        discountAmount,
        discountReason,
      );

      return TwoStagePaymentResult(
        advancePayment: advancePayment,
        finalPayment: finalPayment,
        totalAmount: totalAmount,
        finalAmount: finalAmount,
        advanceAmount: advanceAmount,
        remainingAmount: remainingAmount,
        discountAmount: discountAmount ?? 0,
        advancePercentage: advancePercentage,
      );
    } catch (e) {
      debugPrint('Ошибка создания двухэтапного платежа: $e');
      throw Exception('Не удалось создать двухэтапный платеж: $e');
    }
  }

  /// Обработать авансовый платеж
  Future<PaymentResult> processAdvancePayment({
    required String paymentId,
    required String paymentMethod,
    String? cardToken,
  }) async {
    try {
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      if (payment.type != PaymentType.advance) {
        throw Exception('Это не авансовый платеж');
      }

      // Обновляем статус на "обрабатывается"
      await _paymentService.updatePaymentStatus(
        paymentId,
        PaymentStatus.processing,
        paymentMethod: paymentMethod,
      );

      // Имитируем обработку платежа через Stripe
      final result = await _processStripePayment(
        amount: payment.amount,
        currency: payment.currency,
        paymentMethod: paymentMethod,
        cardToken: cardToken,
        description: payment.description ?? 'Авансовый платеж',
      );

      if (result.success) {
        // Обновляем статус платежа
        await _paymentService.updatePaymentStatus(
          paymentId,
          PaymentStatus.completed,
          transactionId: result.transactionId,
          completedAt: DateTime.now(),
        );

        // Обновляем статус бронирования
        await _updateBookingStatus(payment.bookingId, BookingStatus.confirmed);

        // Создаем уведомления
        await _createPaymentNotifications(payment, 'advance_completed');

        return PaymentResult(
          success: true,
          transactionId: result.transactionId,
          message: 'Авансовый платеж успешно обработан',
        );
      } else {
        await _paymentService.updatePaymentStatus(
          paymentId,
          PaymentStatus.failed,
          failedAt: DateTime.now(),
          metadata: {'error': result.errorMessage},
        );

        return PaymentResult(
          success: false,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      debugPrint('Ошибка обработки авансового платежа: $e');
      await _paymentService.updatePaymentStatus(
        paymentId,
        PaymentStatus.failed,
        failedAt: DateTime.now(),
        metadata: {'error': e.toString()},
      );
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Обработать финальный платеж
  Future<PaymentResult> processFinalPayment({
    required String paymentId,
    required String paymentMethod,
    String? cardToken,
  }) async {
    try {
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      if (payment.type != PaymentType.finalPayment) {
        throw Exception('Это не финальный платеж');
      }

      // Проверяем, что аванс был оплачен
      final advancePayment = await _getAdvancePayment(payment.bookingId);
      if (advancePayment == null || advancePayment.status != PaymentStatus.completed) {
        throw Exception('Авансовый платеж не был оплачен');
      }

      // Обновляем статус на "обрабатывается"
      await _paymentService.updatePaymentStatus(
        paymentId,
        PaymentStatus.processing,
        paymentMethod: paymentMethod,
      );

      // Имитируем обработку платежа через Stripe
      final result = await _processStripePayment(
        amount: payment.amount,
        currency: payment.currency,
        paymentMethod: paymentMethod,
        cardToken: cardToken,
        description: payment.description ?? 'Финальный платеж',
      );

      if (result.success) {
        // Обновляем статус платежа
        await _paymentService.updatePaymentStatus(
          paymentId,
          PaymentStatus.completed,
          transactionId: result.transactionId,
          completedAt: DateTime.now(),
        );

        // Обновляем статус бронирования
        await _updateBookingStatus(payment.bookingId, BookingStatus.completed);

        // Создаем уведомления
        await _createPaymentNotifications(payment, 'final_completed');

        return PaymentResult(
          success: true,
          transactionId: result.transactionId,
          message: 'Финальный платеж успешно обработан',
        );
      } else {
        await _paymentService.updatePaymentStatus(
          paymentId,
          PaymentStatus.failed,
          failedAt: DateTime.now(),
          metadata: {'error': result.errorMessage},
        );

        return PaymentResult(
          success: false,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      debugPrint('Ошибка обработки финального платежа: $e');
      await _paymentService.updatePaymentStatus(
        paymentId,
        PaymentStatus.failed,
        failedAt: DateTime.now(),
        metadata: {'error': e.toString()},
      );
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Получить информацию о двухэтапном платеже
  Future<TwoStagePaymentInfo?> getTwoStagePaymentInfo(String bookingId) async {
    try {
      final payments = await _paymentService.getPaymentsByBooking(bookingId);
      
      final advancePayment = payments.firstWhere(
        (p) => p.type == PaymentType.advance,
        orElse: () => throw Exception('Авансовый платеж не найден'),
      );
      
      final finalPayment = payments.firstWhere(
        (p) => p.type == PaymentType.finalPayment,
        orElse: () => throw Exception('Финальный платеж не найден'),
      );

      return TwoStagePaymentInfo(
        bookingId: bookingId,
        advancePayment: advancePayment,
        finalPayment: finalPayment,
        totalAmount: advancePayment.amount + finalPayment.amount,
        advanceAmount: advancePayment.amount,
        remainingAmount: finalPayment.amount,
        advancePercentage: (advancePayment.amount / (advancePayment.amount + finalPayment.amount)) * 100,
        isAdvancePaid: advancePayment.status == PaymentStatus.completed,
        isFinalPaid: finalPayment.status == PaymentStatus.completed,
        discountAmount: advancePayment.metadata?['discountAmount'] as double? ?? 0,
        discountReason: advancePayment.metadata?['discountReason'] as String?,
      );
    } catch (e) {
      debugPrint('Ошибка получения информации о двухэтапном платеже: $e');
      return null;
    }
  }

  /// Создать возврат для отмененного бронирования
  Future<RefundResult> createRefund({
    required String bookingId,
    required String reason,
    double? refundAmount,
    bool refundAdvanceOnly = false,
  }) async {
    try {
      final payments = await _paymentService.getPaymentsByBooking(bookingId);
      final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).toList();
      
      if (completedPayments.isEmpty) {
        return RefundResult(
          success: true,
          message: 'Нет завершенных платежей для возврата',
          refundedAmount: 0,
        );
      }

      double totalRefundAmount = 0;
      final refundedPayments = <Payment>[];

      for (final payment in completedPayments) {
        if (refundAdvanceOnly && payment.type != PaymentType.advance) {
          continue;
        }

        final amountToRefund = refundAmount ?? payment.amount;
        
        // Создаем возврат
        final refund = await _paymentService.createPayment(
          bookingId: bookingId,
          customerId: payment.customerId,
          specialistId: payment.specialistId,
          type: PaymentType.refund,
          amount: amountToRefund,
          organizationType: payment.organizationType,
          description: 'Возврат: $reason',
          metadata: {
            'originalPaymentId': payment.id,
            'refundReason': reason,
            'originalAmount': payment.amount,
            'refundAmount': amountToRefund,
          },
        );

        // Обрабатываем возврат через Stripe
        final refundResult = await _processStripeRefund(
          originalTransactionId: payment.transactionId!,
          amount: amountToRefund,
          reason: reason,
        );

        if (refundResult.success) {
          await _paymentService.updatePaymentStatus(
            refund.id,
            PaymentStatus.completed,
            transactionId: refundResult.transactionId,
            completedAt: DateTime.now(),
          );

          totalRefundAmount += amountToRefund;
          refundedPayments.add(refund);
        } else {
          await _paymentService.updatePaymentStatus(
            refund.id,
            PaymentStatus.failed,
            failedAt: DateTime.now(),
            metadata: {'error': refundResult.errorMessage},
          );
        }
      }

      // Обновляем статус бронирования
      await _updateBookingStatus(bookingId, BookingStatus.cancelled);

      return RefundResult(
        success: true,
        message: 'Возврат успешно обработан',
        refundedAmount: totalRefundAmount,
        refundedPayments: refundedPayments,
      );
    } catch (e) {
      debugPrint('Ошибка создания возврата: $e');
      return RefundResult(
        success: false,
        errorMessage: e.toString(),
        refundedAmount: 0,
      );
    }
  }

  /// Имитация обработки платежа через Stripe
  Future<StripePaymentResult> _processStripePayment({
    required double amount,
    required String currency,
    required String paymentMethod,
    String? cardToken,
    required String description,
  }) async {
    // В реальном приложении здесь была бы интеграция с Stripe API
    await Future.delayed(const Duration(seconds: 2));

    // Имитируем успешную обработку в 90% случаев
    final isSuccess = DateTime.now().millisecond % 10 != 0;

    if (isSuccess) {
      return StripePaymentResult(
        success: true,
        transactionId: 'stripe_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Платеж успешно обработан',
      );
    } else {
      return StripePaymentResult(
        success: false,
        errorMessage: 'Недостаточно средств на карте',
      );
    }
  }

  /// Имитация обработки возврата через Stripe
  Future<StripeRefundResult> _processStripeRefund({
    required String originalTransactionId,
    required double amount,
    required String reason,
  }) async {
    // В реальном приложении здесь была бы интеграция с Stripe API
    await Future.delayed(const Duration(seconds: 1));

    return StripeRefundResult(
      success: true,
      transactionId: 'refund_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Возврат успешно обработан',
    );
  }

  /// Обновить бронирование с информацией о платежах
  Future<void> _updateBookingWithPaymentInfo(
    String bookingId,
    double advanceAmount,
    double remainingAmount,
    double? discountAmount,
    String? discountReason,
  ) async {
    await _db.collection('bookings').doc(bookingId).update({
      'prepayment': advanceAmount,
      'remainingAmount': remainingAmount,
      'discountAmount': discountAmount ?? 0,
      'discountReason': discountReason,
      'isTwoStagePayment': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Обновить статус бронирования
  Future<void> _updateBookingStatus(String bookingId, BookingStatus status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Получить авансовый платеж для бронирования
  Future<Payment?> _getAdvancePayment(String bookingId) async {
    final payments = await _paymentService.getPaymentsByBooking(bookingId);
    try {
      return payments.firstWhere((p) => p.type == PaymentType.advance);
    } catch (e) {
      return null;
    }
  }

  /// Создать уведомления о платеже
  Future<void> _createPaymentNotifications(Payment payment, String type) async {
    // Создаем уведомления для заказчика и специалиста
    final notifications = [
      {
        'userId': payment.customerId,
        'type': 'payment_$type',
        'title': type == 'advance_completed' ? 'Аванс оплачен' : 'Финальный платеж оплачен',
        'message': 'Платеж на сумму ${payment.amount} ₽ успешно обработан',
        'data': {'paymentId': payment.id, 'bookingId': payment.bookingId},
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
      {
        'userId': payment.specialistId,
        'type': 'payment_$type',
        'title': type == 'advance_completed' ? 'Получен аванс' : 'Получен финальный платеж',
        'message': 'Платеж на сумму ${payment.amount} ₽ успешно обработан',
        'data': {'paymentId': payment.id, 'bookingId': payment.bookingId},
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
    ];

    for (final notification in notifications) {
      await _db.collection('notifications').add(notification);
    }
  }
}

/// Результат создания двухэтапного платежа
class TwoStagePaymentResult {
  const TwoStagePaymentResult({
    required this.advancePayment,
    required this.finalPayment,
    required this.totalAmount,
    required this.finalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    required this.discountAmount,
    required this.advancePercentage,
  });

  final Payment? advancePayment;
  final Payment? finalPayment;
  final double totalAmount;
  final double finalAmount;
  final double advanceAmount;
  final double remainingAmount;
  final double discountAmount;
  final double advancePercentage;
}

/// Информация о двухэтапном платеже
class TwoStagePaymentInfo {
  const TwoStagePaymentInfo({
    required this.bookingId,
    required this.advancePayment,
    required this.finalPayment,
    required this.totalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    required this.advancePercentage,
    required this.isAdvancePaid,
    required this.isFinalPaid,
    required this.discountAmount,
    this.discountReason,
  });

  final String bookingId;
  final Payment advancePayment;
  final Payment finalPayment;
  final double totalAmount;
  final double advanceAmount;
  final double remainingAmount;
  final double advancePercentage;
  final bool isAdvancePaid;
  final bool isFinalPaid;
  final double discountAmount;
  final String? discountReason;
}

/// Результат обработки платежа
class PaymentResult {
  const PaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.errorMessage,
  });

  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorMessage;
}

/// Результат возврата
class RefundResult {
  const RefundResult({
    required this.success,
    this.message,
    this.errorMessage,
    required this.refundedAmount,
    this.refundedPayments,
  });

  final bool success;
  final String? message;
  final String? errorMessage;
  final double refundedAmount;
  final List<Payment>? refundedPayments;
}

/// Результат платежа через Stripe
class StripePaymentResult {
  const StripePaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.errorMessage,
  });

  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorMessage;
}

/// Результат возврата через Stripe
class StripeRefundResult {
  const StripeRefundResult({
    required this.success,
    this.transactionId,
    this.message,
    this.errorMessage,
  });

  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorMessage;
}
