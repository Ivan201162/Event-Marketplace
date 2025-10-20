import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../models/payment.dart';
import '../models/transaction.dart';

/// Service for managing payments
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create payment intent for Stripe
  Future<PaymentIntent?> createPaymentIntent({
    required int amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // In real app, this would call your backend API
      // For now, we'll create a mock payment intent
      final paymentIntent = await Stripe.instance.createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
        metadata: metadata ?? {},
      );

      debugPrint('Payment intent created: ${paymentIntent.id}');
      return paymentIntent;
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }

  /// Process payment
  Future<Payment?> processPayment({
    required String userId,
    required String paymentIntentId,
    required PaymentType type,
    required PaymentMethod method,
    required int amount,
    required String description,
    String? specialistId,
    String? bookingId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create payment record
      final payment = Payment(
        id: '', // Will be set by Firestore
        userId: userId,
        specialistId: specialistId,
        bookingId: bookingId,
        type: type,
        method: method,
        status: PaymentStatus.processing,
        amount: amount,
        commission: _calculateCommission(amount, type),
        currency: 'RUB',
        description: description,
        metadata: metadata,
        stripePaymentIntentId: paymentIntentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final docRef = await _firestore.collection('payments').add(payment.toFirestore());

      final paymentId = docRef.id;
      debugPrint('Payment created with ID: $paymentId');

      // Confirm payment with Stripe
      try {
        await Stripe.instance.confirmPayment(
          paymentIntentId,
          const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(),
            ),
          ),
        );

        // Update payment status to completed
        await _updatePaymentStatus(
          paymentId,
          PaymentStatus.completed,
          completedAt: DateTime.now(),
        );

        // Create transaction record
        await _createTransaction(
          userId: userId,
          specialistId: specialistId,
          paymentId: paymentId,
          bookingId: bookingId,
          type: TransactionType.expense,
          amount: amount,
          description: description,
        );

        // If this is a booking payment, create income transaction for specialist
        if (specialistId != null && type == PaymentType.booking) {
          final netAmount = amount - payment.commission;
          await _createTransaction(
            userId: specialistId,
            paymentId: paymentId,
            bookingId: bookingId,
            type: TransactionType.income,
            amount: netAmount,
            description: 'Доход от бронирования',
          );
        }

        return payment.copyWith(
          id: paymentId,
          status: PaymentStatus.completed,
          completedAt: DateTime.now(),
        );
      } catch (e) {
        // Update payment status to failed
        await _updatePaymentStatus(
          paymentId,
          PaymentStatus.failed,
          failureReason: e.toString(),
          failedAt: DateTime.now(),
        );

        debugPrint('Payment failed: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return null;
    }
  }

  /// Get user payments
  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user payments: $e');
      return [];
    }
  }

  /// Get specialist payments
  Future<List<Payment>> getSpecialistPayments(String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting specialist payments: $e');
      return [];
    }
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();

      if (doc.exists) {
        return Payment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting payment by ID: $e');
      return null;
    }
  }

  /// Refund payment
  Future<bool> refundPayment(String paymentId, {int? amount}) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null || !payment.canBeRefunded) {
        return false;
      }

      final refundAmount = amount ?? payment.amount;

      // In real app, this would call Stripe refund API
      // For now, we'll just update the status
      await _updatePaymentStatus(
        paymentId,
        PaymentStatus.refunded,
        updatedAt: DateTime.now(),
      );

      // Create refund transaction
      await _createTransaction(
        userId: payment.userId,
        paymentId: paymentId,
        bookingId: payment.bookingId,
        type: TransactionType.refund,
        amount: refundAmount,
        description: 'Возврат средств',
      );

      debugPrint('Payment refunded: $paymentId');
      return true;
    } catch (e) {
      debugPrint('Error refunding payment: $e');
      return false;
    }
  }

  /// Get user transactions
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user transactions: $e');
      return [];
    }
  }

  /// Get user balance
  Future<int> getUserBalance(String userId) async {
    try {
      final transactions = await getUserTransactions(userId);

      int balance = 0;
      for (final transaction in transactions) {
        if (transaction.isIncome) {
          balance += transaction.amount;
        } else {
          balance -= transaction.amount;
        }
      }

      return balance;
    } catch (e) {
      debugPrint('Error getting user balance: $e');
      return 0;
    }
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStats(String userId) async {
    try {
      final payments = await getUserPayments(userId);
      final transactions = await getUserTransactions(userId);

      final totalPayments = payments.length;
      final successfulPayments = payments.where((p) => p.isSuccessful).length;
      final totalAmount = payments.where((p) => p.isSuccessful).fold(0, (sum, p) => sum + p.amount);
      final totalCommission =
          payments.where((p) => p.isSuccessful).fold(0, (sum, p) => sum + p.commission);

      final incomeTransactions = transactions.where((t) => t.isIncome).toList();
      final expenseTransactions = transactions.where((t) => t.isExpense).toList();

      final totalIncome = incomeTransactions.fold(0, (sum, t) => sum + t.amount);
      final totalExpense = expenseTransactions.fold(0, (sum, t) => sum + t.amount);

      return {
        'totalPayments': totalPayments,
        'successfulPayments': successfulPayments,
        'totalAmount': totalAmount,
        'totalCommission': totalCommission,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      debugPrint('Error getting payment stats: $e');
      return {};
    }
  }

  /// Update payment status
  Future<bool> _updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? failureReason,
    DateTime? completedAt,
    DateTime? failedAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': Timestamp.now(),
      };

      if (failureReason != null) {
        updateData['failureReason'] = failureReason;
      }
      if (completedAt != null) {
        updateData['completedAt'] = Timestamp.fromDate(completedAt);
      }
      if (failedAt != null) {
        updateData['failedAt'] = Timestamp.fromDate(failedAt);
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);

      return true;
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      return false;
    }
  }

  /// Create transaction record
  Future<void> _createTransaction({
    required String userId,
    String? specialistId,
    String? paymentId,
    String? bookingId,
    required TransactionType type,
    required int amount,
    required String description,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transaction = Transaction(
        id: '', // Will be set by Firestore
        userId: userId,
        specialistId: specialistId,
        paymentId: paymentId,
        bookingId: bookingId,
        type: type,
        amount: amount,
        currency: 'RUB',
        description: description,
        category: category,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('transactions').add(transaction.toFirestore());

      debugPrint('Transaction created for user: $userId');
    } catch (e) {
      debugPrint('Error creating transaction: $e');
    }
  }

  /// Calculate commission
  int _calculateCommission(int amount, PaymentType type) {
    switch (type) {
      case PaymentType.booking:
        // 10% commission for bookings
        return (amount * 0.1).round();
      case PaymentType.commission:
        return 0; // No commission on commission payments
      case PaymentType.refund:
        return 0; // No commission on refunds
      case PaymentType.payout:
        return 0; // No commission on payouts
      case PaymentType.subscription:
        // 5% commission for subscriptions
        return (amount * 0.05).round();
      case PaymentType.premium:
        // 15% commission for premium features
        return (amount * 0.15).round();
    }
  }

  /// Get payments stream for user
  Stream<List<Payment>> getUserPaymentsStream(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  /// Get transactions stream for user
  Stream<List<Transaction>> getUserTransactionsStream(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
  }
}
