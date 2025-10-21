import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_models.dart';
import 'payment_service.dart';
import 'sbp_payment_service.dart';
import 'tinkoff_payment_service.dart';
import 'yookassa_payment_service.dart';

class RefundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  final SBPPaymentService _sbpService = SBPPaymentService();
  final YooKassaPaymentService _yooKassaService = YooKassaPaymentService();
  final TinkoffPaymentService _tinkoffService = TinkoffPaymentService();
  final Uuid _uuid = const Uuid();

  /// Creates a refund request
  Future<Refund> createRefund({
    required String paymentId,
    required double amount,
    required String reason,
    required String requestedBy, // User ID who requested the refund
    RefundType type = RefundType.full,
    String? description,
  }) async {
    try {
      // Get the original payment
      final payment = await _paymentService.getPayment(paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      // Validate refund amount
      if (amount > payment.amount) {
        throw Exception('Сумма возврата не может превышать сумму платежа');
      }

      // Check if payment is eligible for refund
      if (!_isPaymentEligibleForRefund(payment)) {
        throw Exception('Платеж не может быть возвращен');
      }

      final refundId = _uuid.v4();
      final refund = Refund(
        id: refundId,
        paymentId: paymentId,
        amount: amount,
        reason: reason,
        type: type,
        status: RefundStatus.pending,
        requestedBy: requestedBy,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save refund to Firestore
      await _firestore.collection('refunds').doc(refundId).set(refund.toMap());

      // Update payment status
      await _paymentService.updatePaymentStatus(paymentId, PaymentStatus.refunded);

      debugPrint('Refund created: $refundId');
      return refund;
    } catch (e) {
      debugPrint('Error creating refund: $e');
      throw Exception('Ошибка создания возврата: $e');
    }
  }

  /// Processes a refund through the appropriate payment gateway
  Future<void> processRefund(String refundId) async {
    try {
      final refundDoc = await _firestore.collection('refunds').doc(refundId).get();
      if (!refundDoc.exists) {
        throw Exception('Возврат не найден');
      }

      final refund = Refund.fromMap(refundDoc.data()!);
      final payment = await _paymentService.getPayment(refund.paymentId);
      if (payment == null) {
        throw Exception('Платеж не найден');
      }

      // Update refund status to processing
      await _updateRefundStatus(refundId, RefundStatus.processing);

      // Process refund based on payment method
      var success = false;
      String? gatewayRefundId;

      switch (payment.method) {
        case PaymentMethod.sbp:
          // SBP refunds are typically handled by the bank
          success = await _processSBPRefund(refund, payment);
          break;
        case PaymentMethod.yookassa:
          gatewayRefundId = await _processYooKassaRefund(refund, payment);
          success = gatewayRefundId != null;
          break;
        case PaymentMethod.tinkoff:
          success = await _processTinkoffRefund(refund, payment);
          break;
        case PaymentMethod.card:
          // Card refunds are handled by the payment gateway
          success = await _processCardRefund(refund, payment);
          break;
        case PaymentMethod.cash:
          // Cash refunds are handled manually
          success = await _processCashRefund(refund, payment);
          break;
        case PaymentMethod.bankTransfer:
          // Bank transfer refunds are handled manually
          success = await _processBankTransferRefund(refund, payment);
          break;
      }

      if (success) {
        await _updateRefundStatus(
          refundId,
          RefundStatus.completed,
          gatewayRefundId: gatewayRefundId,
        );
        debugPrint('Refund processed successfully: $refundId');
      } else {
        await _updateRefundStatus(
          refundId,
          RefundStatus.failed,
          failureReason: 'Ошибка обработки возврата',
        );
        throw Exception('Ошибка обработки возврата');
      }
    } catch (e) {
      debugPrint('Error processing refund: $e');
      await _updateRefundStatus(refundId, RefundStatus.failed, failureReason: e.toString());
      throw Exception('Ошибка обработки возврата: $e');
    }
  }

  /// Cancels a refund request
  Future<void> cancelRefund(String refundId, String reason) async {
    try {
      await _updateRefundStatus(refundId, RefundStatus.cancelled, failureReason: reason);
      debugPrint('Refund cancelled: $refundId');
    } catch (e) {
      debugPrint('Error cancelling refund: $e');
      throw Exception('Ошибка отмены возврата: $e');
    }
  }

  /// Gets refund by ID
  Future<Refund?> getRefund(String refundId) async {
    try {
      final doc = await _firestore.collection('refunds').doc(refundId).get();
      if (!doc.exists) return null;
      return Refund.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting refund: $e');
      return null;
    }
  }

  /// Gets refunds for a payment
  Future<List<Refund>> getPaymentRefunds(String paymentId) async {
    try {
      final snapshot = await _firestore
          .collection('refunds')
          .where('paymentId', isEqualTo: paymentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Refund.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting payment refunds: $e');
      return [];
    }
  }

  /// Gets refunds for a user
  Future<List<Refund>> getUserRefunds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('refunds')
          .where('requestedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Refund.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting user refunds: $e');
      return [];
    }
  }

  /// Updates refund status
  Future<void> _updateRefundStatus(
    String refundId,
    RefundStatus status, {
    String? gatewayRefundId,
    String? failureReason,
  }) async {
    final updateData = {
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (gatewayRefundId != null) {
      updateData['gatewayRefundId'] = gatewayRefundId;
    }

    if (failureReason != null) {
      updateData['failureReason'] = failureReason;
    }

    if (status == RefundStatus.completed) {
      updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
    }

    await _firestore.collection('refunds').doc(refundId).update(updateData);
  }

  /// Checks if payment is eligible for refund
  bool _isPaymentEligibleForRefund(Payment payment) {
    // Only completed payments can be refunded
    if (payment.status != PaymentStatus.completed) {
      return false;
    }

    // Check if payment is within refund window (typically 30 days)
    final daysSincePayment = DateTime.now().difference(payment.completedAt!).inDays;
    if (daysSincePayment > 30) {
      return false;
    }

    return true;
  }

  /// Processes SBP refund
  Future<bool> _processSBPRefund(Refund refund, Payment payment) async {
    try {
      // SBP refunds are typically handled by the bank
      // This would involve contacting the bank's API
      // For now, we'll simulate success
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('SBP refund error: $e');
      return false;
    }
  }

  /// Processes YooKassa refund
  Future<String?> _processYooKassaRefund(Refund refund, Payment payment) async {
    try {
      if (payment.gatewayPaymentId == null) {
        throw Exception('Gateway payment ID not found');
      }

      final refundResponse = await _yooKassaService.createRefund(
        yooKassaPaymentId: payment.gatewayPaymentId!,
        amount: refund.amount,
        reason: refund.reason,
      );

      return refundResponse.id;
    } catch (e) {
      debugPrint('YooKassa refund error: $e');
      return null;
    }
  }

  /// Processes Tinkoff refund
  Future<bool> _processTinkoffRefund(Refund refund, Payment payment) async {
    try {
      if (payment.gatewayPaymentId == null) {
        throw Exception('Gateway payment ID not found');
      }

      await _tinkoffService.createRefund(
        paymentId: payment.gatewayPaymentId!,
        amount: refund.amount,
        reason: refund.reason,
      );

      return true;
    } catch (e) {
      debugPrint('Tinkoff refund error: $e');
      return false;
    }
  }

  /// Processes card refund
  Future<bool> _processCardRefund(Refund refund, Payment payment) async {
    try {
      // Card refunds are handled by the payment gateway
      // This would involve calling the appropriate gateway API
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('Card refund error: $e');
      return false;
    }
  }

  /// Processes cash refund
  Future<bool> _processCashRefund(Refund refund, Payment payment) async {
    try {
      // Cash refunds are handled manually
      // This would typically involve notifying the specialist
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Cash refund error: $e');
      return false;
    }
  }

  /// Processes bank transfer refund
  Future<bool> _processBankTransferRefund(Refund refund, Payment payment) async {
    try {
      // Bank transfer refunds are handled manually
      // This would typically involve notifying the specialist
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Bank transfer refund error: $e');
      return false;
    }
  }
}

/// Refund model
class Refund {
  Refund({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.reason,
    required this.type,
    required this.status,
    required this.requestedBy,
    this.description,
    this.gatewayRefundId,
    this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory Refund.fromMap(Map<String, dynamic> map) => Refund(
    id: map['id'] as String,
    paymentId: map['paymentId'] as String,
    amount: (map['amount'] as num).toDouble(),
    reason: map['reason'] as String,
    type: RefundType.values.firstWhere(
      (e) => e.toString().split('.').last == map['type'] as String,
    ),
    status: RefundStatus.values.firstWhere(
      (e) => e.toString().split('.').last == map['status'] as String,
    ),
    requestedBy: map['requestedBy'] as String,
    description: map['description'] as String?,
    gatewayRefundId: map['gatewayRefundId'] as String?,
    failureReason: map['failureReason'] as String?,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
  );
  final String id;
  final String paymentId;
  final double amount;
  final String reason;
  final RefundType type;
  final RefundStatus status;
  final String requestedBy;
  final String? description;
  final String? gatewayRefundId;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'paymentId': paymentId,
    'amount': amount,
    'reason': reason,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'requestedBy': requestedBy,
    'description': description,
    'gatewayRefundId': gatewayRefundId,
    'failureReason': failureReason,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };
}

/// Refund types
enum RefundType {
  full, // Полный возврат
  partial, // Частичный возврат
}

/// Refund statuses
enum RefundStatus {
  pending, // Ожидает обработки
  processing, // Обрабатывается
  completed, // Завершен
  failed, // Неудачный
  cancelled, // Отменен
}
