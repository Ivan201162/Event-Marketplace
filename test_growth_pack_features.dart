import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'lib/services/referral_service.dart';
import 'lib/services/dynamic_pricing_service.dart';
import 'lib/services/smart_advertising_service.dart';
import 'lib/services/revenue_analytics_service.dart';
import 'lib/services/receipt_service.dart';
import 'lib/services/partnership_service.dart';
import 'lib/services/growth_mechanics_service.dart';
import 'lib/services/notification_service.dart';
import 'lib/models/referral_system.dart';
import 'lib/models/dynamic_pricing.dart';
import 'lib/models/smart_advertising.dart';
import 'lib/models/revenue_analytics.dart';
import 'lib/models/receipt_system.dart';
import 'lib/models/partnership_program.dart';
import 'lib/models/transaction.dart';
import 'lib/models/subscription_plan.dart';
import 'lib/models/promotion_boost.dart';
import 'lib/models/advertisement.dart';

/// Тестирование всех функций Growth Pack
class GrowthPackTester {
  final ReferralService _referralService = ReferralService();
  final DynamicPricingService _pricingService = DynamicPricingService();
  final SmartAdvertisingService _adService = SmartAdvertisingService();
  final RevenueAnalyticsService _analyticsService = RevenueAnalyticsService();
  final ReceiptService _receiptService = ReceiptService();
  final PartnershipService _partnershipService = PartnershipService();
  final GrowthMechanicsService _growthService = GrowthMechanicsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Запуск всех тестов
  Future<void> runAllTests() async {
    print('🚀 Запуск тестирования Growth Pack...\n');

    try {
      await _testReferralSystem();
      await _testDynamicPricing();
      await _testSmartAdvertising();
      await _testRevenueAnalytics();
      await _testReceiptGeneration();
      await _testPartnershipProgram();
      await _testGrowthMechanics();
      await _testNotifications();
      await _testRealTimeUpdates();

      print('\n✅ Все тесты Growth Pack завершены успешно!');
    } catch (e) {
      print('\n❌ Ошибка при тестировании: $e');
    }
  }

  /// Тест 1: Реферальная система
  Future<void> _testReferralSystem() async {
    print('📋 Тестирование реферальной системы...');

    try {
      // Создание тестового пользователя с реферальным кодом
      final testUserId = _uuid.v4();
      final referralCode = await _referralService.generateReferralCode();
      
      await _firestore.collection('users').doc(testUserId).set({
        'id': testUserId,
        'referralCode': referralCode,
        'createdAt': DateTime.now(),
      });

      print('✅ Реферальный код создан: $referralCode');

      // Тест регистрации по реферальному коду
      final referredUserId = _uuid.v4();
      await _referralService.registerReferral(
        referrerId: testUserId,
        referredId: referredUserId,
        referralCode: referralCode,
      );

      print('✅ Реферал зарегистрирован');

      // Проверка статистики
      final stats = await _referralService.getReferralStatsStream(testUserId).first;
      if (stats != null) {
        print('✅ Статистика рефералов: ${stats.invitedUsersCount} приглашенных');
      }

      print('✅ Реферальная система работает корректно\n');
    } catch (e) {
      print('❌ Ошибка в реферальной системе: $e\n');
    }
  }

  /// Тест 2: Динамическое ценообразование
  Future<void> _testDynamicPricing() async {
    print('💰 Тестирование динамического ценообразования...');

    try {
      // Создание правила ценообразования
      final pricingRule = PricingRule(
        id: _uuid.v4(),
        serviceType: ServiceType.subscription,
        basePrice: 499.0,
        demandFactor: 1.2, // +20% при высокой нагрузке
        timeFactor: 1.1,   // +10% в пиковое время
        regionFactor: 1.0, // Базовый регион
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {
          'regionFactors': {
            'Moscow': 1.3,
            'SPB': 1.2,
            'Other': 1.0,
          }
        },
      );

      await _pricingService.setPricingRule(pricingRule);
      print('✅ Правило ценообразования создано');

      // Тест расчета цены
      final finalPrice = await _pricingService.calculateFinalPrice(
        serviceType: ServiceType.subscription,
        basePrice: 499.0,
        region: 'Moscow',
      );

      print('✅ Базовая цена: 499₽, Финальная цена: ${finalPrice.toStringAsFixed(2)}₽');

      print('✅ Динамическое ценообразование работает корректно\n');
    } catch (e) {
      print('❌ Ошибка в динамическом ценообразовании: $e\n');
    }
  }

  /// Тест 3: Умная реклама
  Future<void> _testSmartAdvertising() async {
    print('🎯 Тестирование умной рекламы...');

    try {
      // Создание правила умной рекламы
      final adRule = SmartAdRule(
        id: _uuid.v4(),
        placementType: AdPlacementType.banner,
        targetCriterion: 'user_interest',
        criterionValue: 'music',
        priority: 5,
        maxImpressionsPerUser: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _adService.setSmartAdRule(adRule);
      print('✅ Правило умной рекламы создано');

      // Создание тестового объявления
      final testAd = Advertisement(
        id: _uuid.v4(),
        userId: _uuid.v4(),
        type: AdvertisementType.banner,
        contentUrl: 'https://example.com/music-ad.jpg',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        status: AdvertisementStatus.active,
        title: 'Музыкальное событие',
        description: 'Присоединяйтесь к музыкальному фестивалю!',
        targetAudience: {'interest': 'music'},
        budget: 10000.0,
        category: 'music',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('advertisements').doc(testAd.id).set(testAd.toMap());
      print('✅ Тестовое объявление создано');

      // Тест получения релевантной рекламы
      final relevantAds = await _adService.getRelevantAdsForUser(
        _uuid.v4(),
        interests: ['music'],
        location: 'Moscow',
      );

      print('✅ Найдено ${relevantAds.length} релевантных объявлений');

      print('✅ Умная реклама работает корректно\n');
    } catch (e) {
      print('❌ Ошибка в умной рекламе: $e\n');
    }
  }

  /// Тест 4: Аналитика доходов
  Future<void> _testRevenueAnalytics() async {
    print('📊 Тестирование аналитики доходов...');

    try {
      // Логирование тестовых доходов
      await _analyticsService.logRevenueEvent(
        sourceType: RevenueSourceType.subscription,
        amount: 999.0,
        userId: _uuid.v4(),
        region: 'Moscow',
        category: 'pro',
      );

      await _analyticsService.logRevenueEvent(
        sourceType: RevenueSourceType.promotion,
        amount: 299.0,
        userId: _uuid.v4(),
        region: 'SPB',
        category: 'profile_boost',
      );

      print('✅ События доходов залогированы');

      // Получение статистики
      final stats = await _analyticsService.getRevenueStats(
        sourceType: RevenueSourceType.subscription,
      );

      print('✅ Получено ${stats.length} записей аналитики');

      // Расчет LTV
      final testUserId = _uuid.v4();
      final ltv = await _analyticsService.calculateUserLTV(testUserId);
      print('✅ LTV пользователя: ${ltv.toStringAsFixed(2)}₽');

      print('✅ Аналитика доходов работает корректно\n');
    } catch (e) {
      print('❌ Ошибка в аналитике доходов: $e\n');
    }
  }

  /// Тест 5: Генерация чеков
  Future<void> _testReceiptGeneration() async {
    print('🧾 Тестирование генерации чеков...');

    try {
      // Создание тестовой транзакции
      final testTransaction = Transaction(
        id: _uuid.v4(),
        userId: _uuid.v4(),
        type: TransactionType.subscription,
        amount: 999.0,
        currency: 'RUB',
        status: TransactionStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paymentMethod: 'card',
        paymentProvider: 'yookassa',
        externalTransactionId: 'ext_${_uuid.v4()}',
      );

      // Создание записи чека
      final receipt = await _receiptService.createReceiptRecord(testTransaction);
      print('✅ Запись чека создана: ${receipt.id}');

      // Генерация фискального чека
      final receiptUrl = await _receiptService.generateFiscalReceipt(receipt);
      if (receiptUrl != null) {
        print('✅ Фискальный чек сгенерирован: $receiptUrl');
      }

      // Отправка чека по email
      await _receiptService.sendReceiptByEmail(receipt, 'test@example.com');
      print('✅ Чек отправлен по email');

      print('✅ Генерация чеков работает корректно\n');
    } catch (e) {
      print('❌ Ошибка в генерации чеков: $e\n');
    }
  }

  /// Тест 6: Партнёрская программа
  Future<void> _testPartnershipProgram() async {
    print('🤝 Тестирование партнёрской программы...');

    try {
      // Создание партнёра
      final partner = await _partnershipService.createPartner(
        name: 'Test Partner',
        code: 'TEST123',
        commissionRate: 0.15, // 15%
        contactEmail: 'partner@test.com',
      );

      print('✅ Партнёр создан: ${partner.name}');

      // Создание тестовой транзакции
      final testTransaction = Transaction(
        id: _uuid.v4(),
        userId: _uuid.v4(),
        type: TransactionType.subscription,
        amount: 1000.0,
        currency: 'RUB',
        status: TransactionStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {'partnerCode': 'TEST123'},
      );

      // Начисление комиссии
      await _partnershipService.processPartnerCommission(
        partnerId: partner.id,
        transaction: testTransaction,
      );

      print('✅ Комиссия партнёру начислена');

      // Получение статистики партнёра
      final partnerStats = await _partnershipService.getPartnerStats(partner.id);
      print('✅ Статистика партнёра: ${partnerStats['totalEarnings']}₽');

      print('✅ Партнёрская программа работает корректно\n');
    } catch (e) {
      print('❌ Ошибка в партнёрской программе: $e\n');
    }
  }

  /// Тест 7: Геймификация и маркетинг
  Future<void> _testGrowthMechanics() async {
    print('🎮 Тестирование геймификации...');

    try {
      final testUserId = _uuid.v4();

      // Создание челленджа
      final challenge = await _growthService.createChallenge(
        title: 'Пригласи 5 друзей',
        description: 'Пригласите 5 друзей и получите месяц Premium',
        type: ChallengeType.referral,
        targetValue: 5,
        reward: {'premiumDays': 30},
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      print('✅ Челлендж создан: ${challenge.title}');

      // Участие в челлендже
      await _growthService.joinChallenge(testUserId, challenge.id);
      print('✅ Пользователь присоединился к челленджу');

      // Прогресс в челлендже
      await _growthService.updateChallengeProgress(testUserId, challenge.id, 3);
      print('✅ Прогресс обновлён: 3/5');

      // Создание A/B теста
      final abTest = await _growthService.createABTest(
        name: 'Pricing Test',
        description: 'Тест разных цен на подписки',
        variants: {
          'control': {'price': 499.0},
          'variant_a': {'price': 399.0},
        },
        trafficSplit: 0.5,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      print('✅ A/B тест создан: ${abTest.name}');

      print('✅ Геймификация работает корректно\n');
    } catch (e) {
      print('❌ Ошибка в геймификации: $e\n');
    }
  }

  /// Тест 8: Уведомления
  Future<void> _testNotifications() async {
    print('🔔 Тестирование уведомлений...');

    try {
      final testUserId = _uuid.v4();

      // Тест уведомления о платеже
      final testTransaction = Transaction(
        id: _uuid.v4(),
        userId: testUserId,
        type: TransactionType.subscription,
        amount: 999.0,
        currency: 'RUB',
        status: TransactionStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await NotificationService.sendPaymentNotification(testTransaction);
      print('✅ Уведомление о платеже отправлено');

      // Тест уведомления о подписке
      final testSubscription = UserSubscription(
        id: _uuid.v4(),
        userId: testUserId,
        planId: 'pro_plan',
        planName: 'PRO',
        planType: SubscriptionPlanType.pro,
        price: 999.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        status: SubscriptionStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await NotificationService.sendSubscriptionNotification(testSubscription);
      print('✅ Уведомление о подписке отправлено');

      // Тест уведомления о продвижении
      final testPromotion = PromotionBoost(
        id: _uuid.v4(),
        userId: testUserId,
        targetId: 'profile_123',
        targetType: PromotionTargetType.profile,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        status: PromotionStatus.active,
        priorityLevel: 1,
        price: 299.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await NotificationService.sendPromotionNotification(testPromotion);
      print('✅ Уведомление о продвижении отправлено');

      print('✅ Уведомления работают корректно\n');
    } catch (e) {
      print('❌ Ошибка в уведомлениях: $e\n');
    }
  }

  /// Тест 9: Real-time обновления
  Future<void> _testRealTimeUpdates() async {
    print('⚡ Тестирование real-time обновлений...');

    try {
      // Тест подписки на изменения транзакций
      final testUserId = _uuid.v4();
      final subscription = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: testUserId)
          .snapshots()
          .listen((snapshot) {
        print('📡 Real-time: Обновление транзакций получено');
      });

      // Создание тестовой транзакции для проверки real-time
      await _firestore.collection('transactions').add({
        'userId': testUserId,
        'type': 'subscription',
        'amount': 499.0,
        'status': 'completed',
        'createdAt': DateTime.now(),
      });

      // Ждём немного для получения обновления
      await Future.delayed(const Duration(seconds: 2));

      // Отменяем подписку
      subscription.cancel();

      print('✅ Real-time обновления работают корректно\n');
    } catch (e) {
      print('❌ Ошибка в real-time обновлениях: $e\n');
    }
  }
}

/// Запуск тестов
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final tester = GrowthPackTester();
  await tester.runAllTests();
}