import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_models.dart';
import 'russian_bank_service.dart';
import 'tax_calculation_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RussianBankService _bankService = RussianBankService();
  final TaxCalculationService _taxService = TaxCalculationService();
  final Uuid _uuid = const Uuid();

  /// Create a new payment
  Future<String> createPayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    required TaxStatus taxStatus,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final paymentId = _uuid.v4();
      final now = DateTime.now();

      // Calculate tax
      final taxCalculation = await _taxService.calculateTax(
        paymentId: paymentId,
        grossAmount: amount,
        taxStatus: taxStatus,
      );

      final payment = Payment(
        id: paymentId,
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: amount,
        taxAmount: taxCalculation.taxAmount,
        netAmount: taxCalculation.netAmount,
        type: type,
        method: method,
        status: PaymentStatus.pending,
        taxStatus: taxStatus,
        metadata: {
          'description': description ?? 'Оплата за услуги',
          'taxCalculationId': taxCalculation.id,
          ...metadata ?? {},
        },
        createdAt: now,
        updatedAt: now,
      );

      // Save payment to Firestore
      await _firestore
          .collection('payments')
          .doc(paymentId)
          .set(payment.toMap());

      // Save tax calculation
      await _firestore
          .collection('taxCalculations')
          .doc(taxCalculation.id)
          .set(taxCalculation.toMap());

      debugPrint('Payment created: $paymentId');
      return paymentId;
    } catch (e) {
      debugPrint('Error creating payment: $e');
      throw Exception('Ошибка создания платежа: $e');
    }
  }

  /// Process payment with external payment system
  Future<Payment> processPayment({
    required String paymentId,
    required String returnUrl,
  }) async {
    try {
      final paymentDoc =
          await _firestore.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) {
        throw Exception('Payment not found');
      }

      final payment = Payment.fromDocument(paymentDoc);

      // Create payment in external system
      String? externalPaymentId;
      String? paymentUrl;
      String? qrCode;

      switch (payment.method) {
        case PaymentMethod.sbp:
          final sbpResponse = await _bankService.createSbpPayment(
            paymentId: paymentId,
            amount: payment.amount,
            description: payment.metadata['description'] ?? 'Оплата за услуги',
            returnUrl: returnUrl,
          );
          externalPaymentId = sbpResponse.id;
          paymentUrl = sbpResponse.confirmationUrl;
          qrCode = sbpResponse.qrCode;
          break;

        case PaymentMethod.yookassa:
          final yookassaResponse = await _bankService.createYooKassaPayment(
            paymentId: paymentId,
            amount: payment.amount,
            description: payment.metadata['description'] ?? 'Оплата за услуги',
            returnUrl: returnUrl,
            method: payment.method,
          );
          externalPaymentId = yookassaResponse.id;
          paymentUrl = yookassaResponse.confirmationUrl;
          qrCode = yookassaResponse.qrCode;
          break;

        case PaymentMethod.tinkoff:
          final tinkoffResponse = await _bankService.createTinkoffPayment(
            paymentId: paymentId,
            amount: payment.amount,
            description: payment.metadata['description'] ?? 'Оплата за услуги',
            returnUrl: returnUrl,
          );
          externalPaymentId = tinkoffResponse.paymentId;
          paymentUrl = tinkoffResponse.paymentUrl;
          qrCode = tinkoffResponse.qrCode;
          break;

        default:
          throw Exception('Unsupported payment method: ${payment.method}');
      }

      // Update payment with external system data
      final updatedPayment = payment.copyWith(
        externalPaymentId: externalPaymentId,
        paymentUrl: paymentUrl,
        qrCode: qrCode,
        status: PaymentStatus.processing,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updatedPayment.toMap());

      debugPrint('Payment processed: $paymentId');
      return updatedPayment;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      throw Exception('Ошибка обработки платежа: $e');
    }
  }

  /// Check payment status
  Future<Payment> checkPaymentStatus(String paymentId) async {
    try {
      final paymentDoc =
          await _firestore.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) {
        throw Exception('Payment not found');
      }

      final payment = Payment.fromDocument(paymentDoc);

      if (payment.externalPaymentId == null) {
        return payment;
      }

      // Check status in external system
      PaymentStatus newStatus = payment.status;
      bool isCompleted = false;

      switch (payment.method) {
        case PaymentMethod.sbp:
          final sbpStatus = await _bankService
              .getSbpPaymentStatus(payment.externalPaymentId!);
          isCompleted = sbpStatus.paid;
          newStatus =
              isCompleted ? PaymentStatus.completed : PaymentStatus.processing;
          break;

        case PaymentMethod.yookassa:
          final yookassaStatus = await _bankService
              .getYooKassaPaymentStatus(payment.externalPaymentId!);
          isCompleted = yookassaStatus.paid;
          newStatus =
              isCompleted ? PaymentStatus.completed : PaymentStatus.processing;
          break;

        case PaymentMethod.tinkoff:
          final tinkoffStatus = await _bankService
              .getTinkoffPaymentStatus(payment.externalPaymentId!);
          isCompleted = tinkoffStatus.success;
          newStatus =
              isCompleted ? PaymentStatus.completed : PaymentStatus.processing;
          break;

        default:
          break;
      }

      // Update payment status if changed
      if (newStatus != payment.status) {
        final updatedPayment = payment.copyWith(
          status: newStatus,
          completedAt: isCompleted ? DateTime.now() : null,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('payments')
            .doc(paymentId)
            .update(updatedPayment.toMap());

        // If payment is completed, trigger booking confirmation
        if (isCompleted) {
          await _onPaymentCompleted(paymentId);
        }

        return updatedPayment;
      }

      return payment;
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      throw Exception('Ошибка проверки статуса платежа: $e');
    }
  }

  /// Process refund
  Future<String> processRefund({
    required String paymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final paymentDoc =
          await _firestore.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) {
        throw Exception('Payment not found');
      }

      final payment = Payment.fromDocument(paymentDoc);

      if (payment.externalPaymentId == null) {
        throw Exception('Cannot refund payment without external ID');
      }

      // Process refund in external system
      final refundResponse = await _bankService.processRefund(
        externalPaymentId: payment.externalPaymentId!,
        amount: amount,
        method: payment.method,
        reason: reason,
      );

      // Create refund request record
      final refundRequest = RefundRequest(
        id: _uuid.v4(),
        paymentId: paymentId,
        reason: reason,
        amount: amount,
        status: RefundStatus.processed,
        externalRefundId: refundResponse.id,
        requestedAt: DateTime.now(),
        processedAt: DateTime.now(),
      );

      await _firestore
          .collection('refundRequests')
          .doc(refundRequest.id)
          .set(refundRequest.toMap());

      // Update payment status
      final updatedPayment = payment.copyWith(
        status: PaymentStatus.refunded,
        refundedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .update(updatedPayment.toMap());

      debugPrint('Refund processed: ${refundRequest.id}');
      return refundRequest.id;
    } catch (e) {
      debugPrint('Error processing refund: $e');
      throw Exception('Ошибка обработки возврата: $e');
    }
  }

  /// Get payment by ID
  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (!doc.exists) return null;
      return Payment.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting payment: $e');
      return null;
    }
  }

  /// Get payments for booking
  Stream<List<Payment>> getBookingPayments(String bookingId) {
    return _firestore
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromDocument(doc)).toList();
    });
  }

  /// Get payments for customer
  Stream<List<Payment>> getCustomerPayments(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromDocument(doc)).toList();
    });
  }

  /// Get payments for specialist
  Stream<List<Payment>> getSpecialistPayments(String specialistId) {
    return _firestore
        .collection('payments')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromDocument(doc)).toList();
    });
  }

  /// Get available payment methods
  List<PaymentMethodInfo> getAvailablePaymentMethods() {
    return _bankService.getAvailablePaymentMethods();
  }

  /// Create prepayment (30% of total amount)
  Future<String> createPrepayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double totalAmount,
    required PaymentMethod method,
    required TaxStatus taxStatus,
  }) async {
    try {
      final prepaymentAmount = totalAmount * 0.3; // 30% prepayment

      return await createPayment(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: prepaymentAmount,
        type: PaymentType.prepayment,
        method: method,
        taxStatus: taxStatus,
        description: 'Предоплата 30% за услуги',
      );
    } catch (e) {
      debugPrint('Error creating prepayment: $e');
      throw Exception('Ошибка создания предоплаты: $e');
    }
  }

  /// Create postpayment (remaining 70% of total amount)
  Future<String> createPostpayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double totalAmount,
    required PaymentMethod method,
    required TaxStatus taxStatus,
  }) async {
    try {
      final postpaymentAmount = totalAmount * 0.7; // 70% postpayment

      return await createPayment(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: postpaymentAmount,
        type: PaymentType.postpayment,
        method: method,
        taxStatus: taxStatus,
        description: 'Остаток 70% за услуги',
      );
    } catch (e) {
      debugPrint('Error creating postpayment: $e');
      throw Exception('Ошибка создания постоплаты: $e');
    }
  }

  /// Create full payment (100% of total amount)
  Future<String> createFullPayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double totalAmount,
    required PaymentMethod method,
    required TaxStatus taxStatus,
  }) async {
    try {
      return await createPayment(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        amount: totalAmount,
        type: PaymentType.full,
        method: method,
        taxStatus: taxStatus,
        description: 'Полная оплата за услуги',
      );
    } catch (e) {
      debugPrint('Error creating full payment: $e');
      throw Exception('Ошибка создания полной оплаты: $e');
    }
  }

  /// Handle payment completion
  Future<void> _onPaymentCompleted(String paymentId) async {
    try {
      final payment = await getPayment(paymentId);
      if (payment == null) return;

      // Update booking status based on payment type
      if (payment.type == PaymentType.prepayment) {
        // Mark booking as confirmed
        await _firestore.collection('bookings').doc(payment.bookingId).update({
          'status': 'confirmed',
          'prepaymentCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (payment.type == PaymentType.postpayment ||
          payment.type == PaymentType.full) {
        // Mark booking as completed
        await _firestore.collection('bookings').doc(payment.bookingId).update({
          'status': 'completed',
          'paymentCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Payment completion handled: $paymentId');
    } catch (e) {
      debugPrint('Error handling payment completion: $e');
    }
  }

  /// Get payment statistics
  Future<PaymentStatistics> getPaymentStatistics({
    String? customerId,
    String? specialistId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('payments');

      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      if (specialistId != null) {
        query = query.where('specialistId', isEqualTo: specialistId);
      }
      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final payments =
          snapshot.docs.map((doc) => Payment.fromDocument(doc)).toList();

      final totalAmount =
          payments.fold(0.0, (sum, payment) => sum + payment.amount);
      final totalTaxAmount =
          payments.fold(0.0, (sum, payment) => sum + payment.taxAmount);
      final totalNetAmount =
          payments.fold(0.0, (sum, payment) => sum + payment.netAmount);
      final completedPayments = payments.where((p) => p.isCompleted).length;
      final failedPayments = payments.where((p) => p.isFailed).length;

      return PaymentStatistics(
        totalPayments: payments.length,
        completedPayments: completedPayments,
        failedPayments: failedPayments,
        totalAmount: totalAmount,
        totalTaxAmount: totalTaxAmount,
        totalNetAmount: totalNetAmount,
        averageAmount:
            payments.isNotEmpty ? totalAmount / payments.length : 0.0,
      );
    } catch (e) {
      debugPrint('Error getting payment statistics: $e');
      throw Exception('Ошибка получения статистики платежей: $e');
    }
  }
}

class PaymentStatistics {
  final int totalPayments;
  final int completedPayments;
  final int failedPayments;
  final double totalAmount;
  final double totalTaxAmount;
  final double totalNetAmount;
  final double averageAmount;

  PaymentStatistics({
    required this.totalPayments,
    required this.completedPayments,
    required this.failedPayments,
    required this.totalAmount,
    required this.totalTaxAmount,
    required this.totalNetAmount,
    required this.averageAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPayments': totalPayments,
      'completedPayments': completedPayments,
      'failedPayments': failedPayments,
      'totalAmount': totalAmount,
      'totalTaxAmount': totalTaxAmount,
      'totalNetAmount': totalNetAmount,
      'averageAmount': averageAmount,
    };
  }

  factory PaymentStatistics.fromMap(Map<String, dynamic> map) {
    return PaymentStatistics(
      totalPayments: map['totalPayments'] as int,
      completedPayments: map['completedPayments'] as int,
      failedPayments: map['failedPayments'] as int,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      totalTaxAmount: (map['totalTaxAmount'] as num).toDouble(),
      totalNetAmount: (map['totalNetAmount'] as num).toDouble(),
      averageAmount: (map['averageAmount'] as num).toDouble(),
    );
  }
}
