import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/payment_config.dart';
import '../models/promotion_boost.dart';
import '../models/subscription_plan.dart';

class FirestoreTestDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Инициализация всех тестовых данных
  static Future<void> initializeTestData() async {
    try {
      debugPrint('INFO: [firestore_test_data] Начинаем инициализацию тестовых данных');

      await Future.wait([
        _createSubscriptionPlans(),
        _createPromotionPackages(),
        _createTestUsers(),
        _createTestAdvertisements(),
        _createTestTransactions(),
      ]);

      debugPrint('INFO: [firestore_test_data] Тестовые данные успешно созданы');
    } catch (e) {
      debugPrint('ERROR: [firestore_test_data] Ошибка создания тестовых данных: $e');
      rethrow;
    }
  }

  /// Создание планов подписки
  static Future<void> _createSubscriptionPlans() async {
    debugPrint('INFO: [firestore_test_data] Создание планов подписки');

    final batch = _firestore.batch();

    for (final entry in PaymentConfig.subscriptionPlans.entries) {
      final planId = entry.key;
      final planData = entry.value;

      final plan = SubscriptionPlan(
        id: planId,
        name: planData['name'],
        tier: _getTierFromId(planId),
        price: planData['price'].toDouble(),
        durationDays: planData['durationDays'],
        features: List<String>.from(planData['features']),
        isActive: true,
        description: 'План подписки ${planData['name']}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = _firestore.collection('subscription_plans').doc(planId);
      batch.set(docRef, plan.toMap());
    }

    await batch.commit();
    debugPrint('INFO: [firestore_test_data] Планы подписки созданы');
  }

  /// Создание пакетов продвижения
  static Future<void> _createPromotionPackages() async {
    debugPrint('INFO: [firestore_test_data] Создание пакетов продвижения');

    final batch = _firestore.batch();

    for (final entry in PaymentConfig.promotionPackages.entries) {
      final packageId = entry.key;
      final packageData = entry.value;

      final package = PromotionPackage(
        id: packageId,
        name: packageData['name'],
        type: _getPromotionTypeFromString(packageData['type']),
        durationDays: packageData['durationDays'],
        price: packageData['price'].toDouble(),
        priorityLevel: _getPromotionPriorityFromString(packageData['priorityLevel']),
        isActive: true,
        description: 'Пакет продвижения ${packageData['name']}',
        features: List<String>.from(packageData['features']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = _firestore.collection('promotion_packages').doc(packageId);
      batch.set(docRef, package.toMap());
    }

    await batch.commit();
    debugPrint('INFO: [firestore_test_data] Пакеты продвижения созданы');
  }

  /// Создание тестовых пользователей
  static Future<void> _createTestUsers() async {
    debugPrint('INFO: [firestore_test_data] Создание тестовых пользователей');

    final testUsers = [
      {
        'id': 'test_user_1',
        'name': 'Анна Петрова',
        'email': 'anna@example.com',
        'phone': '+7 (999) 123-45-67',
        'city': 'Москва',
        'region': 'Москва',
        'category': 'Фотографы',
        'avatarUrl': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
        'rating': 4.8,
        'reviewsCount': 127,
        'isVerified': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      },
      {
        'id': 'test_user_2',
        'name': 'Михаил Соколов',
        'email': 'mikhail@example.com',
        'phone': '+7 (999) 234-56-78',
        'city': 'Санкт-Петербург',
        'region': 'Санкт-Петербург',
        'category': 'Видеографы',
        'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'rating': 4.9,
        'reviewsCount': 89,
        'isVerified': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 45)),
      },
      {
        'id': 'test_user_3',
        'name': 'Елена Козлова',
        'email': 'elena@example.com',
        'phone': '+7 (999) 345-67-89',
        'city': 'Новосибирск',
        'region': 'Новосибирская область',
        'category': 'Организаторы',
        'avatarUrl': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        'rating': 4.7,
        'reviewsCount': 203,
        'isVerified': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      },
    ];

    final batch = _firestore.batch();

    for (final user in testUsers) {
      final docRef = _firestore.collection('users').doc(user['id']);
      batch.set(docRef, {
        ...user,
        'createdAt': Timestamp.fromDate(user['createdAt'] as DateTime),
      });
    }

    await batch.commit();
    debugPrint('INFO: [firestore_test_data] Тестовые пользователи созданы');
  }

  /// Создание тестовых рекламных объявлений
  static Future<void> _createTestAdvertisements() async {
    debugPrint('INFO: [firestore_test_data] Создание тестовых рекламных объявлений');

    final testAds = [
      {
        'id': 'test_ad_1',
        'userId': 'test_user_1',
        'type': 'banner',
        'placement': 'topBanner',
        'title': 'Профессиональная фотосъемка',
        'description': 'Запечатлите важные моменты с нашими фотографами',
        'imageUrl': 'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=400',
        'targetUrl': 'https://example.com/photography',
        'price': 500.0,
        'startDate': DateTime.now(),
        'endDate': DateTime.now().add(const Duration(days: 7)),
        'status': 'active',
        'region': 'Москва',
        'city': 'Москва',
        'category': 'Фотографы',
        'impressions': 1250,
        'clicks': 45,
        'ctr': 3.6,
        'cpc': 11.11,
        'cpm': 400.0,
      },
      {
        'id': 'test_ad_2',
        'userId': 'test_user_2',
        'type': 'sponsoredPost',
        'placement': 'homeFeed',
        'title': 'Видеосъемка мероприятий',
        'description': 'Качественная видеосъемка ваших событий',
        'imageUrl': 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400',
        'targetUrl': 'https://example.com/videography',
        'price': 1000.0,
        'startDate': DateTime.now(),
        'endDate': DateTime.now().add(const Duration(days: 3)),
        'status': 'active',
        'region': 'Санкт-Петербург',
        'city': 'Санкт-Петербург',
        'category': 'Видеографы',
        'impressions': 890,
        'clicks': 67,
        'ctr': 7.5,
        'cpc': 14.93,
        'cpm': 1123.6,
      },
    ];

    final batch = _firestore.batch();

    for (final ad in testAds) {
      final docRef = _firestore.collection('advertisements').doc(ad['id']);
      batch.set(docRef, {
        ...ad,
        'startDate': Timestamp.fromDate(ad['startDate'] as DateTime),
        'endDate': Timestamp.fromDate(ad['endDate'] as DateTime),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
    debugPrint('INFO: [firestore_test_data] Тестовые рекламные объявления созданы');
  }

  /// Создание тестовых транзакций
  static Future<void> _createTestTransactions() async {
    debugPrint('INFO: [firestore_test_data] Создание тестовых транзакций');

    final testTransactions = [
      {
        'id': 'test_txn_1',
        'userId': 'test_user_1',
        'type': 'subscription',
        'amount': 499.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 5)),
        'description': 'Подписка Премиум (месяц)',
        'subscriptionId': 'test_sub_1',
        'paymentMethod': 'card',
        'paymentProvider': 'stripe',
        'externalTransactionId': 'pi_test_1234567890',
      },
      {
        'id': 'test_txn_2',
        'userId': 'test_user_2',
        'type': 'promotion',
        'amount': 399.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'description': 'Продвижение профиля (неделя)',
        'promotionId': 'test_promo_1',
        'paymentMethod': 'card',
        'paymentProvider': 'yookassa',
        'externalTransactionId': 'test_payment_1234567890',
      },
    ];

    final batch = _firestore.batch();

    for (final txn in testTransactions) {
      final docRef = _firestore.collection('transactions').doc(txn['id']);
      batch.set(docRef, {
        ...txn,
        'timestamp': Timestamp.fromDate(txn['timestamp'] as DateTime),
      });
    }

    await batch.commit();
    debugPrint('INFO: [firestore_test_data] Тестовые транзакции созданы');
  }

  /// Создание тестовых подписок
  static Future<void> createTestSubscriptions() async {
    debugPrint('INFO: [firestore_test_data] Создание тестовых подписок');

    final testSubscriptions = [
      {
        'id': 'test_sub_1',
        'userId': 'test_user_1',
        'planId': 'premium_monthly',
        'startDate': DateTime.now().subtract(const Duration(days: 5)),
        'endDate': DateTime.now().add(const Duration(days: 25)),
        'status': 'active',
        'autoRenew': false,
        'transactionId': 'test_txn_1',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 5)),
      },
    ];

    final batch = _firestore.batch();

    for (final sub in testSubscriptions) {
      final docRef = _firestore.collection('user_subscriptions').doc(sub['id']);
      batch.set(docRef, {
        ...sub,
        'startDate': Timestamp.fromDate(sub['startDate'] as DateTime),
        'endDate': Timestamp.fromDate(sub['endDate'] as DateTime),
        'createdAt': Timestamp.fromDate(sub['createdAt'] as DateTime),
        'updatedAt': Timestamp.fromDate(sub['updatedAt'] as DateTime),
      });
    }

    await batch.commit();
    debugPrint('INFO: [firestore_test_data] Тестовые подписки созданы');
  }

  /// Создание тестовых продвижений
  static Future<void> createTestPromotions() async {
    debugPrint('INFO: [firestore_test_data] Создание тестовых продвижений');

    final testPromotions = [
      {
        'id': 'test_promo_1',
        'userId': 'test_user_2',
        'type': 'profileBoost',
        'startDate': DateTime.now().subtract(const Duration(days: 2)),
        'endDate': DateTime.now().add(const Duration(days: 5)),
        'status': 'active',
        'priorityLevel': 'high',
        'price': 399.0,
        'region': 'Санкт-Петербург',
        'city': 'Санкт-Петербург',
        'category': 'Видеографы',
        'impressions': 450,
        'clicks': 23,
        'ctr': 5.1,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 2)),
      },
    ];

    final batch = _firestore.batch();

    for (final promo in testPromotions) {
      final docRef = _firestore.collection('promotions').doc(promo['id']);
      batch.set(docRef, {
        ...promo,
        'startDate': Timestamp.fromDate(promo['startDate'] as DateTime),
        'endDate': Timestamp.fromDate(promo['endDate'] as DateTime),
        'createdAt': Timestamp.fromDate(promo['createdAt'] as DateTime),
        'updatedAt': Timestamp.fromDate(promo['updatedAt'] as DateTime),
      });
    }

    await batch.commit();
    debugPrint('INFO: [firestore_test_data] Тестовые продвижения созданы');
  }

  /// Очистка всех тестовых данных
  static Future<void> clearTestData() async {
    try {
      debugPrint('INFO: [firestore_test_data] Очистка тестовых данных');

      final collections = [
        'subscription_plans',
        'promotion_packages',
        'user_subscriptions',
        'promotions',
        'advertisements',
        'transactions',
        'users',
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      debugPrint('INFO: [firestore_test_data] Тестовые данные очищены');
    } catch (e) {
      debugPrint('ERROR: [firestore_test_data] Ошибка очистки тестовых данных: $e');
      rethrow;
    }
  }

  // Вспомогательные методы
  static SubscriptionTier _getTierFromId(String planId) {
    if (planId.contains('free')) return SubscriptionTier.free;
    if (planId.contains('premium')) return SubscriptionTier.premium;
    if (planId.contains('pro')) return SubscriptionTier.pro;
    return SubscriptionTier.free;
  }

  static PromotionType _getPromotionTypeFromString(String type) {
    switch (type) {
      case 'profileBoost':
        return PromotionType.profileBoost;
      case 'postBoost':
        return PromotionType.postBoost;
      case 'categoryBoost':
        return PromotionType.categoryBoost;
      case 'searchBoost':
        return PromotionType.searchBoost;
      default:
        return PromotionType.profileBoost;
    }
  }

  static PromotionPriority _getPromotionPriorityFromString(String priority) {
    switch (priority) {
      case 'low':
        return PromotionPriority.low;
      case 'medium':
        return PromotionPriority.medium;
      case 'high':
        return PromotionPriority.high;
      case 'premium':
        return PromotionPriority.premium;
      default:
        return PromotionPriority.medium;
    }
  }
}
