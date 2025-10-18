import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/ab_testing.dart';
import 'package:flutter/foundation.dart';

class ABTestingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РџРѕР»СѓС‡РµРЅРёРµ РІР°СЂРёР°РЅС‚Р° A/B С‚РµСЃС‚Р° РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<String> getVariantForUser(String userId, String testName) async {
    try {
      // РџСЂРѕРІРµСЂСЏРµРј, РµСЃС‚СЊ Р»Рё СѓР¶Рµ РЅР°Р·РЅР°С‡РµРЅРЅС‹Р№ РІР°СЂРёР°РЅС‚ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
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

      // РџРѕР»СѓС‡Р°РµРј Р°РєС‚РёРІРЅС‹Р№ С‚РµСЃС‚
      final DocumentSnapshot testDoc = await _firestore.collection('ab_tests').doc(testName).get();

      if (!testDoc.exists) {
        return 'control'; // Р’РѕР·РІСЂР°С‰Р°РµРј РєРѕРЅС‚СЂРѕР»СЊРЅС‹Р№ РІР°СЂРёР°РЅС‚ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
      }

      final ABTest test = ABTest.fromMap(testDoc.data() as Map<String, dynamic>);

      if (!test.isActive) {
        return 'control';
      }

      // РќР°Р·РЅР°С‡Р°РµРј РІР°СЂРёР°РЅС‚ РЅР° РѕСЃРЅРѕРІРµ Р°Р»РіРѕСЂРёС‚РјР° (РЅР°РїСЂРёРјРµСЂ, С…РµС€ РѕС‚ userId)
      final String variant = _assignVariant(userId, test);

      // РЎРѕС…СЂР°РЅСЏРµРј РЅР°Р·РЅР°С‡РµРЅРёРµ
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

  /// РќР°Р·РЅР°С‡РµРЅРёРµ РІР°СЂРёР°РЅС‚Р° РЅР° РѕСЃРЅРѕРІРµ С…РµС€Р°
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

  /// Р›РѕРіРёСЂРѕРІР°РЅРёРµ СЃРѕР±С‹С‚РёСЏ РґР»СЏ A/B С‚РµСЃС‚Р°
  Future<void> logEvent(
      String userId, String testName, String eventName, Map<String, dynamic>? eventData) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РЅР°Р·РЅР°С‡РµРЅРЅС‹Р№ РІР°СЂРёР°РЅС‚
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

  /// РЎРѕР·РґР°РЅРёРµ A/B С‚РµСЃС‚Р°
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

  /// РђРєС‚РёРІР°С†РёСЏ A/B С‚РµСЃС‚Р°
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

  /// Р”РµР°РєС‚РёРІР°С†РёСЏ A/B С‚РµСЃС‚Р°
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

  /// РџРѕР»СѓС‡РµРЅРёРµ СЂРµР·СѓР»СЊС‚Р°С‚РѕРІ A/B С‚РµСЃС‚Р°
  Future<ABTestResults> getABTestResults(String testId) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ С‚РµСЃС‚Рµ
      final DocumentSnapshot testDoc = await _firestore.collection('ab_tests').doc(testId).get();

      if (!testDoc.exists) {
        throw Exception('AB test not found');
      }

      final ABTest test = ABTest.fromMap(testDoc.data() as Map<String, dynamic>);

      // РџРѕР»СѓС‡Р°РµРј РЅР°Р·РЅР°С‡РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
      final QuerySnapshot assignmentsSnapshot = await _firestore
          .collection('ab_test_assignments')
          .where('testName', isEqualTo: test.name)
          .get();

      // РџРѕР»СѓС‡Р°РµРј СЃРѕР±С‹С‚РёСЏ
      final QuerySnapshot eventsSnapshot = await _firestore
          .collection('ab_test_events')
          .where('testName', isEqualTo: test.name)
          .get();

      // РђРЅР°Р»РёР·РёСЂСѓРµРј РґР°РЅРЅС‹Рµ
      final Map<String, int> variantUsers = {};
      final Map<String, Map<String, int>> variantEvents = {};

      // РџРѕРґСЃС‡РёС‚С‹РІР°РµРј РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ РїРѕ РІР°СЂРёР°РЅС‚Р°Рј
      for (final doc in assignmentsSnapshot.docs) {
        final ABTestAssignment assignment =
            ABTestAssignment.fromMap(doc.data() as Map<String, dynamic>);
        variantUsers[assignment.variant] = (variantUsers[assignment.variant] ?? 0) + 1;
      }

      // РџРѕРґСЃС‡РёС‚С‹РІР°РµРј СЃРѕР±С‹С‚РёСЏ РїРѕ РІР°СЂРёР°РЅС‚Р°Рј
      for (final doc in eventsSnapshot.docs) {
        final ABTestEvent event = ABTestEvent.fromMap(doc.data() as Map<String, dynamic>);
        if (variantEvents[event.variant] == null) {
          variantEvents[event.variant] = {};
        }
        variantEvents[event.variant]![event.eventName] =
            (variantEvents[event.variant]![event.eventName] ?? 0) + 1;
      }

      // РЎРѕР·РґР°РµРј СЂРµР·СѓР»СЊС‚Р°С‚С‹
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

  /// РџРѕР»СѓС‡РµРЅРёРµ РІСЃРµС… Р°РєС‚РёРІРЅС‹С… A/B С‚РµСЃС‚РѕРІ
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

  /// РџСЂРѕРІРµСЂРєР°, СѓС‡Р°СЃС‚РІСѓРµС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РІ С‚РµСЃС‚Рµ
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

  /// РџРѕР»СѓС‡РµРЅРёРµ РІСЃРµС… С‚РµСЃС‚РѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
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

  /// РЎРѕР·РґР°РЅРёРµ РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹С… A/B С‚РµСЃС‚РѕРІ РґР»СЏ РјРѕРЅРµС‚РёР·Р°С†РёРё
  Future<void> createMonetizationABTests() async {
    try {
      // РўРµСЃС‚ С‚Р°СЂРёС„РЅС‹С… РїР»Р°РЅРѕРІ
      await createABTest(
        name: 'subscription_pricing_test',
        description: 'РўРµСЃС‚ СЂР°Р·Р»РёС‡РЅС‹С… С†РµРЅ РЅР° РїРѕРґРїРёСЃРєРё',
        variants: [
          ABTestVariant(
            name: 'control',
            description: 'РўРµРєСѓС‰РёРµ С†РµРЅС‹',
            trafficPercentage: 50,
            config: {
              'premium_price': 499.0,
              'pro_price': 999.0,
            },
          ),
          ABTestVariant(
            name: 'discounted',
            description: 'РЎРєРёРґРєР° 20%',
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

      // РўРµСЃС‚ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёР№
      await createABTest(
        name: 'promotion_placement_test',
        description: 'РўРµСЃС‚ СЂР°Р·РјРµС‰РµРЅРёСЏ РїСЂРѕРјРѕ-РѕР±СЉСЏРІР»РµРЅРёР№',
        variants: [
          ABTestVariant(
            name: 'control',
            description: 'РЎС‚Р°РЅРґР°СЂС‚РЅРѕРµ СЂР°Р·РјРµС‰РµРЅРёРµ',
            trafficPercentage: 50,
            config: {
              'placement': 'top',
              'frequency': 'normal',
            },
          ),
          ABTestVariant(
            name: 'aggressive',
            description: 'РђРіСЂРµСЃСЃРёРІРЅРѕРµ СЂР°Р·РјРµС‰РµРЅРёРµ',
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

      // РўРµСЃС‚ СЂРµС„РµСЂР°Р»СЊРЅРѕР№ РїСЂРѕРіСЂР°РјРјС‹
      await createABTest(
        name: 'referral_rewards_test',
        description: 'РўРµСЃС‚ СЂР°Р·Р»РёС‡РЅС‹С… РЅР°РіСЂР°Рґ Р·Р° СЂРµС„РµСЂР°Р»РѕРІ',
        variants: [
          ABTestVariant(
            name: 'control',
            description: 'РЎС‚Р°РЅРґР°СЂС‚РЅС‹Рµ РЅР°РіСЂР°РґС‹',
            trafficPercentage: 50,
            config: {
              'referrer_bonus': 5,
              'referred_bonus': 3,
            },
          ),
          ABTestVariant(
            name: 'enhanced',
            description: 'РЈРІРµР»РёС‡РµРЅРЅС‹Рµ РЅР°РіСЂР°РґС‹',
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

