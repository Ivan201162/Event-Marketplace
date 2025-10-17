import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ab_testing.dart';

class ABTestingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Получение варианта A/B теста для пользователя
  Future<String> getVariantForUser(String userId, String testName) async {
    try {
      // Проверяем, есть ли уже назначенный вариант для пользователя
      final QuerySnapshot existingVariant = await _firestore
          .collection('ab_test_assignments')
          .where('userId', isEqualTo: userId)
          .where('testName', isEqualTo: testName)
          .limit(1)
          .get();

      if (existingVariant.docs.isNotEmpty) {
        final ABTestAssignment assignment =
            ABTestAssignment.fromMap(existingVariant.docs.first.data() as Map<String, dynamic>);
        return assignment.variant;
      }

      // Получаем активный тест
      final DocumentSnapshot testDoc = await _firestore.collection('ab_tests').doc(testName).get();

      if (!testDoc.exists) {
        return 'control'; // Возвращаем контрольный вариант по умолчанию
      }

      final ABTest test = ABTest.fromMap(testDoc.data() as Map<String, dynamic>);

      if (!test.isActive) {
        return 'control';
      }

      // Назначаем вариант на основе алгоритма (например, хеш от userId)
      final String variant = _assignVariant(userId, test);

      // Сохраняем назначение
      final ABTestAssignment assignment = ABTestAssignment(
        id: _uuid.v4(),
        userId: userId,
        testName: testName,
        variant: variant,
        assignedAt: DateTime.now(),
      );

      await _firestore.collection('ab_test_assignments').doc(assignment.id).set(assignment.toMap());

      debugPrint(
          'INFO: [ABTestingService] Variant $variant assigned to user $userId for test $testName');
      return variant;
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to get variant for user: $e');
      return 'control';
    }
  }

  /// Назначение варианта на основе хеша
  String _assignVariant(String userId, ABTest test) {
    final int hash = userId.hashCode.abs();
    final int bucket = hash % 100; // 0-99

    int cumulativePercentage = 0;
    for (final variant in test.variants) {
      cumulativePercentage += variant.trafficPercentage;
      if (bucket < cumulativePercentage) {
        return variant.name;
      }
    }

    return 'control'; // Fallback
  }

  /// Логирование события для A/B теста
  Future<void> logEvent(
      String userId, String testName, String eventName, Map<String, dynamic>? eventData) async {
    try {
      // Получаем назначенный вариант
      final String variant = await getVariantForUser(userId, testName);

      final ABTestEvent event = ABTestEvent(
        id: _uuid.v4(),
        userId: userId,
        testName: testName,
        variant: variant,
        eventName: eventName,
        eventData: eventData,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('ab_test_events').doc(event.id).set(event.toMap());

      debugPrint(
          'INFO: [ABTestingService] Event logged: $eventName for test $testName, variant $variant');
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to log event: $e');
    }
  }

  /// Создание A/B теста
  Future<String> createABTest({
    required String name,
    required String description,
    required List<ABTestVariant> variants,
    required DateTime startDate,
    required DateTime endDate,
    String? targetAudience,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final ABTest test = ABTest(
        id: _uuid.v4(),
        name: name,
        description: description,
        variants: variants,
        status: ABTestStatus.draft,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetAudience: targetAudience,
        metadata: metadata,
      );

      await _firestore.collection('ab_tests').doc(test.id).set(test.toMap());

      debugPrint('INFO: [ABTestingService] AB test created: ${test.id}');
      return test.id;
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to create AB test: $e');
      rethrow;
    }
  }

  /// Активация A/B теста
  Future<void> activateABTest(String testId) async {
    try {
      await _firestore.collection('ab_tests').doc(testId).update({
        'isActive': true,
        'status': ABTestStatus.active.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [ABTestingService] AB test activated: $testId');
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to activate AB test: $e');
    }
  }

  /// Деактивация A/B теста
  Future<void> deactivateABTest(String testId) async {
    try {
      await _firestore.collection('ab_tests').doc(testId).update({
        'isActive': false,
        'status': ABTestStatus.completed.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [ABTestingService] AB test deactivated: $testId');
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to deactivate AB test: $e');
    }
  }

  /// Получение результатов A/B теста
  Future<ABTestResults> getABTestResults(String testId) async {
    try {
      // Получаем информацию о тесте
      final DocumentSnapshot testDoc = await _firestore.collection('ab_tests').doc(testId).get();

      if (!testDoc.exists) {
        throw Exception('AB test not found');
      }

      final ABTest test = ABTest.fromMap(testDoc.data() as Map<String, dynamic>);

      // Получаем назначения пользователей
      final QuerySnapshot assignmentsSnapshot = await _firestore
          .collection('ab_test_assignments')
          .where('testName', isEqualTo: test.name)
          .get();

      // Получаем события
      final QuerySnapshot eventsSnapshot = await _firestore
          .collection('ab_test_events')
          .where('testName', isEqualTo: test.name)
          .get();

      // Анализируем данные
      final Map<String, int> variantUsers = {};
      final Map<String, Map<String, int>> variantEvents = {};

      // Подсчитываем пользователей по вариантам
      for (final doc in assignmentsSnapshot.docs) {
        final ABTestAssignment assignment =
            ABTestAssignment.fromMap(doc.data() as Map<String, dynamic>);
        variantUsers[assignment.variant] = (variantUsers[assignment.variant] ?? 0) + 1;
      }

      // Подсчитываем события по вариантам
      for (final doc in eventsSnapshot.docs) {
        final ABTestEvent event = ABTestEvent.fromMap(doc.data() as Map<String, dynamic>);
        if (variantEvents[event.variant] == null) {
          variantEvents[event.variant] = {};
        }
        variantEvents[event.variant]![event.eventName] =
            (variantEvents[event.variant]![event.eventName] ?? 0) + 1;
      }

      // Создаем результаты
      final List<VariantResult> variantResults = [];
      for (final variant in test.variants) {
        final int userCount = variantUsers[variant.name] ?? 0;
        final Map<String, int> events = variantEvents[variant.name] ?? {};

        variantResults.add(VariantResult(
          variantName: variant.name,
          userCount: userCount,
          events: events,
          conversionRate: userCount > 0 ? (events['conversion'] ?? 0) / userCount : 0.0,
        ));
      }

      final ABTestResults results = ABTestResults(
        testId: testId,
        testName: test.name,
        totalUsers: assignmentsSnapshot.docs.length,
        variantResults: variantResults,
        startDate: test.startDate,
        endDate: test.endDate,
        isActive: test.isActive,
        createdAt: DateTime.now(),
      );

      return results;
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to get AB test results: $e');
      rethrow;
    }
  }

  /// Получение всех активных A/B тестов
  Future<List<ABTest>> getActiveABTests() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('ab_tests').where('isActive', isEqualTo: true).get();

      return snapshot.docs
          .map((doc) => ABTest.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to get active AB tests: $e');
      return [];
    }
  }

  /// Проверка, участвует ли пользователь в тесте
  Future<bool> isUserInTest(String userId, String testName) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('ab_test_assignments')
          .where('userId', isEqualTo: userId)
          .where('testName', isEqualTo: testName)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to check user test participation: $e');
      return false;
    }
  }

  /// Получение всех тестов пользователя
  Future<List<ABTestAssignment>> getUserTestAssignments(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('ab_test_assignments')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ABTestAssignment.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to get user test assignments: $e');
      return [];
    }
  }

  /// Создание предустановленных A/B тестов для монетизации
  Future<void> createMonetizationABTests() async {
    try {
      // Тест тарифных планов
      await createABTest(
        name: 'subscription_pricing_test',
        description: 'Тест различных цен на подписки',
        variants: [
          ABTestVariant(
            name: 'control',
            description: 'Текущие цены',
            trafficPercentage: 50,
            config: {
              'premium_price': 499.0,
              'pro_price': 999.0,
            },
          ),
          ABTestVariant(
            name: 'discounted',
            description: 'Скидка 20%',
            trafficPercentage: 50,
            config: {
              'premium_price': 399.0,
              'pro_price': 799.0,
            },
          ),
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        targetAudience: 'all_users',
      );

      // Тест промо-кампаний
      await createABTest(
        name: 'promotion_placement_test',
        description: 'Тест размещения промо-объявлений',
        variants: [
          ABTestVariant(
            name: 'control',
            description: 'Стандартное размещение',
            trafficPercentage: 50,
            config: {
              'placement': 'top',
              'frequency': 'normal',
            },
          ),
          ABTestVariant(
            name: 'aggressive',
            description: 'Агрессивное размещение',
            trafficPercentage: 50,
            config: {
              'placement': 'multiple',
              'frequency': 'high',
            },
          ),
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 14)),
        targetAudience: 'premium_users',
      );

      // Тест реферальной программы
      await createABTest(
        name: 'referral_rewards_test',
        description: 'Тест различных наград за рефералов',
        variants: [
          ABTestVariant(
            name: 'control',
            description: 'Стандартные награды',
            trafficPercentage: 50,
            config: {
              'referrer_bonus': 5,
              'referred_bonus': 3,
            },
          ),
          ABTestVariant(
            name: 'enhanced',
            description: 'Увеличенные награды',
            trafficPercentage: 50,
            config: {
              'referrer_bonus': 7,
              'referred_bonus': 5,
            },
          ),
        ],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 21)),
        targetAudience: 'all_users',
      );

      debugPrint('INFO: [ABTestingService] Monetization AB tests created');
    } catch (e) {
      debugPrint('ERROR: [ABTestingService] Failed to create monetization AB tests: $e');
    }
  }
}
