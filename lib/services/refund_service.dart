import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/payment.dart';
import 'payment_service.dart';

/// Сервис для обработки возвратов
class RefundService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  /// Создать возврат при отмене бронирования
  Future<RefundResult> createRefundForCancellation({
    required String bookingId,
    required String reason,
    required RefundPolicy policy,
    String? cancelledBy, // ID пользователя, который отменил
  }) async {
    try {
      final booking = await _getBooking(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      final payments = await _paymentService.getPaymentsByBooking(bookingId);
      final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).toList();
      
      if (completedPayments.isEmpty) {
        return RefundResult(
          success: true,
          message: 'Нет завершенных платежей для возврата',
          refundedAmount: 0,
          refundType: RefundType.none,
        );
      }

      // Рассчитываем сумму возврата согласно политике
      final refundCalculation = _calculateRefundAmount(
        completedPayments,
        booking,
        policy,
        reason,
      );

      if (refundCalculation.amount <= 0) {
        return RefundResult(
          success: true,
          message: 'Возврат не требуется согласно политике',
          refundedAmount: 0,
          refundType: RefundType.none,
        );
      }

      // Создаем возвраты для каждого платежа
      final refundedPayments = <Payment>[];
      double totalRefunded = 0;

      for (final payment in completedPayments) {
        final refundAmount = _calculatePaymentRefund(
          payment,
          refundCalculation.amount,
          refundCalculation.totalPaid,
        );

        if (refundAmount > 0) {
          final refund = await _createRefundPayment(
            originalPayment: payment,
            amount: refundAmount,
            reason: reason,
            policy: policy,
            cancelledBy: cancelledBy,
          );

          // Обрабатываем возврат через Stripe
          final refundResult = await _processStripeRefund(
            originalTransactionId: payment.transactionId!,
            amount: refundAmount,
            reason: reason,
          );

          if (refundResult.success) {
            await _paymentService.updatePaymentStatus(
              refund.id,
              PaymentStatus.completed,
              transactionId: refundResult.transactionId,
              completedAt: DateTime.now(),
            );

            totalRefunded += refundAmount;
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
      }

      // Обновляем статус бронирования
      await _updateBookingStatus(bookingId, BookingStatus.cancelled, reason);

      // Создаем уведомления
      await _createRefundNotifications(
        booking,
        refundedPayments,
        totalRefunded,
        reason,
      );

      return RefundResult(
        success: true,
        message: 'Возврат успешно обработан',
        refundedAmount: totalRefunded,
        refundedPayments: refundedPayments,
        refundType: refundCalculation.type,
        refundPolicy: policy,
      );
    } catch (e) {
      debugPrint('Ошибка создания возврата: $e');
      return RefundResult(
        success: false,
        errorMessage: e.toString(),
        refundedAmount: 0,
        refundType: RefundType.none,
      );
    }
  }

  /// Создать частичный возврат
  Future<RefundResult> createPartialRefund({
    required String paymentId,
    required double amount,
    required String reason,
    String? requestedBy,
  }) async {
    try {
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      if (payment.status != PaymentStatus.completed) {
        throw Exception('Платеж не завершен');
      }

      if (amount > payment.amount) {
        throw Exception('Сумма возврата не может превышать сумму платежа');
      }

      // Создаем возврат
      final refund = await _createRefundPayment(
        originalPayment: payment,
        amount: amount,
        reason: reason,
        policy: RefundPolicy.partial,
        cancelledBy: requestedBy,
      );

      // Обрабатываем возврат через Stripe
      final refundResult = await _processStripeRefund(
        originalTransactionId: payment.transactionId!,
        amount: amount,
        reason: reason,
      );

      if (refundResult.success) {
        await _paymentService.updatePaymentStatus(
          refund.id,
          PaymentStatus.completed,
          transactionId: refundResult.transactionId,
          completedAt: DateTime.now(),
        );

        return RefundResult(
          success: true,
          message: 'Частичный возврат успешно обработан',
          refundedAmount: amount,
          refundedPayments: [refund],
          refundType: RefundType.partial,
        );
      } else {
        await _paymentService.updatePaymentStatus(
          refund.id,
          PaymentStatus.failed,
          failedAt: DateTime.now(),
          metadata: {'error': refundResult.errorMessage},
        );

        return RefundResult(
          success: false,
          errorMessage: refundResult.errorMessage,
          refundedAmount: 0,
          refundType: RefundType.partial,
        );
      }
    } catch (e) {
      debugPrint('Ошибка создания частичного возврата: $e');
      return RefundResult(
        success: false,
        errorMessage: e.toString(),
        refundedAmount: 0,
        refundType: RefundType.partial,
      );
    }
  }

  /// Получить историю возвратов для пользователя
  Future<List<RefundHistoryItem>> getRefundHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final query = await _db
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: PaymentType.refund.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final payment = Payment.fromDocument(doc);
        return RefundHistoryItem(
          id: payment.id,
          amount: payment.amount,
          reason: payment.metadata?['refundReason'] as String? ?? 'Не указано',
          status: payment.status,
          createdAt: payment.createdAt,
          completedAt: payment.completedAt,
          originalPaymentId: payment.metadata?['originalPaymentId'] as String?,
          bookingId: payment.bookingId,
        );
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения истории возвратов: $e');
      return [];
    }
  }

  /// Рассчитать сумму возврата согласно политике
  RefundCalculation _calculateRefundAmount(
    List<Payment> completedPayments,
    Booking booking,
    RefundPolicy policy,
    String reason,
  ) {
    final totalPaid = completedPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final eventDate = booking.eventDate;
    final now = DateTime.now();
    final timeUntilEvent = eventDate.difference(now);

    // Определяем тип возврата и сумму
    RefundType refundType;
    double refundAmount;

    switch (policy) {
      case RefundPolicy.full:
        refundType = RefundType.full;
        refundAmount = totalPaid;
        break;
      
      case RefundPolicy.timeBased:
        if (timeUntilEvent.inDays >= 7) {
          refundType = RefundType.full;
          refundAmount = totalPaid;
        } else if (timeUntilEvent.inDays >= 3) {
          refundType = RefundType.partial;
          refundAmount = totalPaid * 0.5; // 50% возврата
        } else if (timeUntilEvent.inDays >= 1) {
          refundType = RefundType.partial;
          refundAmount = totalPaid * 0.25; // 25% возврата
        } else {
          refundType = RefundType.none;
          refundAmount = 0;
        }
        break;
      
      case RefundPolicy.partial:
        refundType = RefundType.partial;
        refundAmount = totalPaid * 0.5; // 50% возврата
        break;
      
      case RefundPolicy.none:
        refundType = RefundType.none;
        refundAmount = 0;
        break;
      
      case RefundPolicy.advanceOnly:
        // Возвращаем только аванс
        final advancePayment = completedPayments.firstWhere(
          (p) => p.type == PaymentType.advance,
          orElse: () => completedPayments.first,
        );
        refundType = RefundType.partial;
        refundAmount = advancePayment.amount;
        break;
    }

    return RefundCalculation(
      amount: refundAmount,
      totalPaid: totalPaid,
      type: refundType,
      policy: policy,
      timeUntilEvent: timeUntilEvent,
    );
  }

  /// Рассчитать возврат для конкретного платежа
  double _calculatePaymentRefund(
    Payment payment,
    double totalRefundAmount,
    double totalPaidAmount,
  ) {
    if (totalRefundAmount <= 0 || totalPaidAmount <= 0) return 0;
    
    // Пропорциональный возврат
    final paymentRatio = payment.amount / totalPaidAmount;
    return totalRefundAmount * paymentRatio;
  }

  /// Создать платеж возврата
  Future<Payment> _createRefundPayment({
    required Payment originalPayment,
    required double amount,
    required String reason,
    required RefundPolicy policy,
    String? cancelledBy,
  }) async {
    return await _paymentService.createPayment(
      bookingId: originalPayment.bookingId,
      customerId: originalPayment.customerId,
      specialistId: originalPayment.specialistId,
      type: PaymentType.refund,
      amount: amount,
      organizationType: originalPayment.organizationType,
      description: 'Возврат: $reason',
      metadata: {
        'originalPaymentId': originalPayment.id,
        'refundReason': reason,
        'refundPolicy': policy.name,
        'originalAmount': originalPayment.amount,
        'refundAmount': amount,
        'cancelledBy': cancelledBy,
        'refundType': 'cancellation',
      },
    );
  }

  /// Обработать возврат через Stripe
  Future<StripeRefundResult> _processStripeRefund({
    required String originalTransactionId,
    required double amount,
    required String reason,
  }) async {
    // В реальном приложении здесь была бы интеграция с Stripe API
    await Future.delayed(const Duration(seconds: 1));

    // Имитируем успешную обработку возврата
    return StripeRefundResult(
      success: true,
      transactionId: 'refund_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Возврат успешно обработан',
    );
  }

  /// Получить бронирование
  Future<Booking?> _getBooking(String bookingId) async {
    try {
      final doc = await _db.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения бронирования: $e');
      return null;
    }
  }

  /// Обновить статус бронирования
  Future<void> _updateBookingStatus(String bookingId, BookingStatus status, String reason) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status.name,
      'cancellationReason': reason,
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Создать уведомления о возврате
  Future<void> _createRefundNotifications(
    Booking booking,
    List<Payment> refundedPayments,
    double totalRefunded,
    String reason,
  ) async {
    final notifications = [
      {
        'userId': booking.userId,
        'type': 'refund_processed',
        'title': 'Возврат обработан',
        'message': 'Возврат на сумму $totalRefunded ₽ успешно обработан',
        'data': {
          'bookingId': booking.id,
          'refundAmount': totalRefunded,
          'reason': reason,
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
      {
        'userId': booking.specialistId,
        'type': 'booking_cancelled',
        'title': 'Бронирование отменено',
        'message': 'Бронирование "${booking.eventTitle}" было отменено',
        'data': {
          'bookingId': booking.id,
          'reason': reason,
          'refundAmount': totalRefunded,
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
      },
    ];

    for (final notification in notifications) {
      await _db.collection('notifications').add(notification);
    }
  }
}

/// Политики возврата
enum RefundPolicy {
  full,        // Полный возврат
  timeBased,   // Возврат в зависимости от времени до события
  partial,     // Частичный возврат (50%)
  advanceOnly, // Возврат только аванса
  none,        // Без возврата
}

/// Типы возврата
enum RefundType {
  full,    // Полный возврат
  partial, // Частичный возврат
  none,    // Без возврата
}

/// Результат возврата
class RefundResult {
  const RefundResult({
    required this.success,
    this.message,
    this.errorMessage,
    required this.refundedAmount,
    this.refundedPayments,
    required this.refundType,
    this.refundPolicy,
  });

  final bool success;
  final String? message;
  final String? errorMessage;
  final double refundedAmount;
  final List<Payment>? refundedPayments;
  final RefundType refundType;
  final RefundPolicy? refundPolicy;
}

/// Расчет возврата
class RefundCalculation {
  const RefundCalculation({
    required this.amount,
    required this.totalPaid,
    required this.type,
    required this.policy,
    required this.timeUntilEvent,
  });

  final double amount;
  final double totalPaid;
  final RefundType type;
  final RefundPolicy policy;
  final Duration timeUntilEvent;
}

/// Элемент истории возвратов
class RefundHistoryItem {
  const RefundHistoryItem({
    required this.id,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.originalPaymentId,
    this.bookingId,
  });

  final String id;
  final double amount;
  final String reason;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? originalPaymentId;
  final String? bookingId;
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
