import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для монетизации
class MonetizationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создание подписки
  Future<bool> createSubscription({
    required String planId,
    required String planName,
    required double price,
    required String billingCycle, // 'monthly', 'yearly'
    required int duration, // в днях
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final subscriptionData = {
        'planId': planId,
        'planName': planName,
        'price': price,
        'billingCycle': billingCycle,
        'duration': duration,
        'userId': user.uid,
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'endDate':
            Timestamp.fromDate(DateTime.now().add(Duration(days: duration))),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('subscriptions').add(subscriptionData);
      return true;
    } catch (e) {
      print('Ошибка создания подписки: $e');
      return false;
    }
  }

  /// Получение активных подписок пользователя
  Future<List<Map<String, dynamic>>> getUserSubscriptions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения подписок: $e');
      return [];
    }
  }

  /// Отмена подписки
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final subscriptionDoc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();
      if (!subscriptionDoc.exists) return false;

      final subscriptionData = subscriptionDoc.data()!;
      if (subscriptionData['userId'] != user.uid) return false;

      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Ошибка отмены подписки: $e');
      return false;
    }
  }

  /// Создание платного продвижения
  Future<bool> createPromotion({
    required String specialistId,
    required String promotionType, // 'top_placement', 'featured', 'boost'
    required double price,
    required int duration, // в днях
    required String description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final promotionData = {
        'specialistId': specialistId,
        'promotionType': promotionType,
        'price': price,
        'duration': duration,
        'description': description,
        'userId': user.uid,
        'status': 'active',
        'startDate': FieldValue.serverTimestamp(),
        'endDate':
            Timestamp.fromDate(DateTime.now().add(Duration(days: duration))),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('promotions').add(promotionData);
      return true;
    } catch (e) {
      print('Ошибка создания продвижения: $e');
      return false;
    }
  }

  /// Получение активных продвижений специалиста
  Future<List<Map<String, dynamic>>> getSpecialistPromotions(
      String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('promotions')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения продвижений: $e');
      return [];
    }
  }

  /// Создание плана подписки
  Future<bool> createSubscriptionPlan({
    required String planName,
    required String description,
    required double monthlyPrice,
    required double yearlyPrice,
    required List<String> features,
    required int maxEvents,
    required int maxParticipants,
    required bool hasAnalytics,
    required bool hasPrioritySupport,
  }) async {
    try {
      final planData = {
        'planName': planName,
        'description': description,
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
        'features': features,
        'maxEvents': maxEvents,
        'maxParticipants': maxParticipants,
        'hasAnalytics': hasAnalytics,
        'hasPrioritySupport': hasPrioritySupport,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('subscription_plans').add(planData);
      return true;
    } catch (e) {
      print('Ошибка создания плана подписки: $e');
      return false;
    }
  }

  /// Получение доступных планов подписки
  Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    try {
      final querySnapshot = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('monthlyPrice')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения планов: $e');
      return [];
    }
  }

  /// Создание транзакции
  Future<bool> createTransaction({
    required String type, // 'subscription', 'promotion', 'payment'
    required double amount,
    required String currency,
    required String description,
    String? subscriptionId,
    String? promotionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final transactionData = {
        'type': type,
        'amount': amount,
        'currency': currency,
        'description': description,
        'subscriptionId': subscriptionId,
        'promotionId': promotionId,
        'metadata': metadata ?? {},
        'userId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('transactions').add(transactionData);
      return true;
    } catch (e) {
      print('Ошибка создания транзакции: $e');
      return false;
    }
  }

  /// Получение истории транзакций
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения истории транзакций: $e');
      return [];
    }
  }

  /// Получение статистики доходов
  Future<Map<String, dynamic>> getRevenueStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed');

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();

      double totalRevenue = 0;
      Map<String, double> revenueByType = {};
      Map<String, int> transactionCounts = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = data['amount'] as double;
        final type = data['type'] as String;

        totalRevenue += amount;
        revenueByType[type] = (revenueByType[type] ?? 0) + amount;
        transactionCounts[type] = (transactionCounts[type] ?? 0) + 1;
      }

      return {
        'totalRevenue': totalRevenue,
        'revenueByType': revenueByType,
        'transactionCounts': transactionCounts,
        'totalTransactions': querySnapshot.docs.length,
      };
    } catch (e) {
      print('Ошибка получения статистики доходов: $e');
      return {};
    }
  }

  /// Создание купона
  Future<bool> createCoupon({
    required String code,
    required String description,
    required double discount, // в процентах или фиксированная сумма
    required String discountType, // 'percentage', 'fixed'
    required DateTime expiryDate,
    required int usageLimit,
    List<String>? applicablePlans,
  }) async {
    try {
      final couponData = {
        'code': code,
        'description': description,
        'discount': discount,
        'discountType': discountType,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'usageLimit': usageLimit,
        'usageCount': 0,
        'applicablePlans': applicablePlans ?? [],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('coupons').add(couponData);
      return true;
    } catch (e) {
      print('Ошибка создания купона: $e');
      return false;
    }
  }

  /// Применение купона
  Future<Map<String, dynamic>> applyCoupon({
    required String couponCode,
    required double originalPrice,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: couponCode)
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Купон не найден',
        };
      }

      final couponDoc = querySnapshot.docs.first;
      final couponData = couponDoc.data();

      // Проверка срока действия
      final expiryDate = (couponData['expiryDate'] as Timestamp).toDate();
      if (expiryDate.isBefore(DateTime.now())) {
        return {
          'success': false,
          'message': 'Купон истек',
        };
      }

      // Проверка лимита использования
      final usageCount = couponData['usageCount'] as int;
      final usageLimit = couponData['usageLimit'] as int;
      if (usageCount >= usageLimit) {
        return {
          'success': false,
          'message': 'Купон исчерпан',
        };
      }

      // Применение скидки
      final discount = couponData['discount'] as double;
      final discountType = couponData['discountType'] as String;
      double finalPrice = originalPrice;

      if (discountType == 'percentage') {
        finalPrice = originalPrice * (1 - discount / 100);
      } else if (discountType == 'fixed') {
        finalPrice = originalPrice - discount;
      }

      if (finalPrice < 0) finalPrice = 0;

      // Обновление счетчика использования
      await _firestore.collection('coupons').doc(couponDoc.id).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'discount': originalPrice - finalPrice,
        'finalPrice': finalPrice,
        'couponId': couponDoc.id,
      };
    } catch (e) {
      print('Ошибка применения купона: $e');
      return {
        'success': false,
        'message': 'Ошибка применения купона',
      };
    }
  }

  /// Получение аналитики для специалиста
  Future<Map<String, dynamic>> getSpecialistAnalytics({
    required String specialistId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Получение статистики просмотров
      final viewsQuery = _firestore
          .collection('profile_views')
          .where('specialistId', isEqualTo: specialistId);

      if (startDate != null) {
        viewsQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        viewsQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final viewsSnapshot = await viewsQuery.get();

      // Получение статистики заявок
      final requestsQuery = _firestore
          .collection('requests')
          .where('specialistId', isEqualTo: specialistId);

      if (startDate != null) {
        requestsQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        requestsQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final requestsSnapshot = await requestsQuery.get();

      // Получение статистики отзывов
      final reviewsQuery = _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId);

      if (startDate != null) {
        reviewsQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        reviewsQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final reviewsSnapshot = await reviewsQuery.get();

      // Расчет среднего рейтинга
      double totalRating = 0;
      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data();
        totalRating += data['rating'] as double;
      }

      final averageRating = reviewsSnapshot.docs.isNotEmpty
          ? totalRating / reviewsSnapshot.docs.length
          : 0.0;

      return {
        'totalViews': viewsSnapshot.docs.length,
        'totalRequests': requestsSnapshot.docs.length,
        'totalReviews': reviewsSnapshot.docs.length,
        'averageRating': averageRating,
        'conversionRate': viewsSnapshot.docs.isNotEmpty
            ? requestsSnapshot.docs.length / viewsSnapshot.docs.length
            : 0.0,
      };
    } catch (e) {
      print('Ошибка получения аналитики: $e');
      return {};
    }
  }
}
