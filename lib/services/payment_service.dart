import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/payment_config.dart';
import '../models/premium_profile.dart';
import '../models/promoted_post.dart';
import '../models/subscription.dart';
import '../models/transaction.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Initialize Stripe
  Future<void> initializeStripe() async {
    Stripe.publishableKey = PaymentConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  // Process payment for premium profile promotion
  Future<bool> processPremiumPromotion({
    required String userId,
    required String plan,
    required double amount,
  }) async {
    try {
      // Create payment intent
      final paymentIntent = await _createPaymentIntent(amount);

      // Confirm payment
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: const PaymentMethodData(
          billingDetails: BillingDetails(),
        ),
      );

      if (result.status == PaymentIntentStatus.Succeeded) {
        // Create transaction record
        await _createTransaction(
          userId: userId,
          type: TransactionType.promotion,
          amount: amount,
          description: 'Продвижение профиля - $plan',
        );

        // Create premium profile
        await _createPremiumProfile(userId: userId, plan: plan);

        // Log analytics event
        await _analytics.logEvent(
          name: 'purchase_premium',
          parameters: {
            'user_id': userId,
            'plan': plan,
            'amount': amount,
          },
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }

  // Process subscription payment
  Future<bool> processSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required double amount,
  }) async {
    try {
      final paymentIntent = await _createPaymentIntent(amount);

      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: const PaymentMethodData(
          billingDetails: BillingDetails(),
        ),
      );

      if (result.status == PaymentIntentStatus.Succeeded) {
        // Create transaction record
        await _createTransaction(
          userId: userId,
          type: TransactionType.subscription,
          amount: amount,
          description: 'Подписка ${plan.toString().split('.').last}',
        );

        // Create subscription
        await _createSubscription(userId: userId, plan: plan, amount: amount);

        // Log analytics event
        await _analytics.logEvent(
          name: 'buy_subscription',
          parameters: {
            'user_id': userId,
            'plan': plan.toString().split('.').last,
            'amount': amount,
          },
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Subscription payment error: $e');
      return false;
    }
  }

  // Process donation
  Future<bool> processDonation({
    required String userId,
    required String targetUserId,
    required double amount,
  }) async {
    try {
      final paymentIntent = await _createPaymentIntent(amount);

      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: const PaymentMethodData(
          billingDetails: BillingDetails(),
        ),
      );

      if (result.status == PaymentIntentStatus.Succeeded) {
        // Create transaction record
        await _createTransaction(
          userId: userId,
          type: TransactionType.donation,
          amount: amount,
          description: 'Донат специалисту',
          targetUserId: targetUserId,
        );

        // Log analytics event
        await _analytics.logEvent(
          name: 'send_donation',
          parameters: {
            'user_id': userId,
            'target_user_id': targetUserId,
            'amount': amount,
          },
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Donation payment error: $e');
      return false;
    }
  }

  // Process post boosting
  Future<bool> processPostBoost({
    required String userId,
    required String postId,
    required double amount,
    required int days,
  }) async {
    try {
      final paymentIntent = await _createPaymentIntent(amount);

      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: const PaymentMethodData(
          billingDetails: BillingDetails(),
        ),
      );

      if (result.status == PaymentIntentStatus.Succeeded) {
        // Create transaction record
        await _createTransaction(
          userId: userId,
          type: TransactionType.boostPost,
          amount: amount,
          description: 'Продвижение поста на $days дней',
          postId: postId,
        );

        // Create promoted post
        await _createPromotedPost(
          userId: userId,
          postId: postId,
          days: days,
          budget: amount,
        );

        // Log analytics event
        await _analytics.logEvent(
          name: 'boost_post',
          parameters: {
            'user_id': userId,
            'post_id': postId,
            'amount': amount,
            'days': days,
          },
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Post boost payment error: $e');
      return false;
    }
  }

  // Get user transactions
  Future<List<Transaction>> getUserTransactions(String userId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
  }

  // Get user subscription
  Future<Subscription?> getUserSubscription(String userId) async {
    final snapshot = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Subscription.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  // Get user premium profile
  Future<PremiumProfile?> getUserPremiumProfile(String userId) async {
    final snapshot = await _firestore
        .collection('premiumProfiles')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return PremiumProfile.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  // Private helper methods
  Future<Map<String, dynamic>> _createPaymentIntent(double amount) async {
    // In a real app, this would call your backend API
    // For now, we'll simulate a successful payment intent
    return {
      'client_secret': 'pi_test_1234567890_secret_abcdefghijklmnop',
      'id': 'pi_test_1234567890',
    };
  }

  Future<void> _createTransaction({
    required String userId,
    required TransactionType type,
    required double amount,
    required String description,
    String? targetUserId,
    String? postId,
  }) async {
    final transaction = Transaction(
      id: _firestore.collection('transactions').doc().id,
      userId: userId,
      type: type,
      amount: amount,
      currency: PaymentConfig.defaultCurrency,
      status: TransactionStatus.success,
      timestamp: DateTime.now(),
      description: description,
      targetUserId: targetUserId,
      postId: postId,
    );

    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Future<void> _createPremiumProfile({
    required String userId,
    required String plan,
  }) async {
    final days = _getDaysFromPlan(plan);
    final premiumProfile = PremiumProfile(
      userId: userId,
      activeUntil: DateTime.now().add(Duration(days: days)),
      type: PremiumType.highlight,
      region: 'Москва', // Default region
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('premiumProfiles')
        .doc(userId)
        .set(premiumProfile.toMap());
  }

  Future<void> _createSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required double amount,
  }) async {
    final subscription = Subscription(
      userId: userId,
      plan: plan,
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      autoRenew: true,
      monthlyPrice: amount,
    );

    await _firestore
        .collection('subscriptions')
        .doc(userId)
        .set(subscription.toMap());
  }

  Future<void> _createPromotedPost({
    required String userId,
    required String postId,
    required int days,
    required double budget,
  }) async {
    final promotedPost = PromotedPost(
      postId: postId,
      userId: userId,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: days)),
      priority: 1,
      budget: budget,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('promotedPosts')
        .doc(postId)
        .set(promotedPost.toMap());
  }

  int _getDaysFromPlan(String plan) {
    switch (plan) {
      case '7_days':
        return 7;
      case '14_days':
        return 14;
      case '30_days':
        return 30;
      default:
        return 7;
    }
  }
}
