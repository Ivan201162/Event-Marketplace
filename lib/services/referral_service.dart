import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/referral_system.dart';
import 'package:flutter/foundation.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РЎРѕР·РґР°РЅРёРµ СЂРµС„РµСЂР°Р»СЊРЅРѕРіРѕ РєРѕРґР° РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<ReferralCode> createReferralCode(String userId) async {
    try {
      // РџСЂРѕРІРµСЂСЏРµРј, РµСЃС‚СЊ Р»Рё СѓР¶Рµ Р°РєС‚РёРІРЅС‹Р№ РєРѕРґ
      final existingCode = await _firestore
          .collection('referral_codes')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingCode.docs.isNotEmpty) {
        return ReferralCode.fromMap(existingCode.docs.first.data());
      }

      // РЎРѕР·РґР°РµРј РЅРѕРІС‹Р№ РєРѕРґ
      final String code = _generateReferralCode();
      final String id = _uuid.v4();

      final ReferralCode referralCode = ReferralCode(
        id: id,
        userId: userId,
        code: code,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 365)), // Р“РѕРґ РґРµР№СЃС‚РІРёСЏ
      );

      await _firestore.collection('referral_codes').doc(id).set(referralCode.toMap());

      debugPrint('INFO: [ReferralService] Created referral code: $code for user: $userId');
      return referralCode;
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to create referral code: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЂРµС„РµСЂР°Р»СЊРЅРѕРіРѕ РєРѕРґР° РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<ReferralCode?> getUserReferralCode(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('referral_codes')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ReferralCode.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to get user referral code: $e');
      return null;
    }
  }

  /// РџСЂРѕРІРµСЂРєР° Рё РёСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ СЂРµС„РµСЂР°Р»СЊРЅРѕРіРѕ РєРѕРґР°
  Future<Referral?> useReferralCode(String code, String referredUserId) async {
    try {
      // РќР°С…РѕРґРёРј РєРѕРґ
      final QuerySnapshot codeSnapshot = await _firestore
          .collection('referral_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (codeSnapshot.docs.isEmpty) {
        throw Exception('Р РµС„РµСЂР°Р»СЊРЅС‹Р№ РєРѕРґ РЅРµ РЅР°Р№РґРµРЅ РёР»Рё РЅРµР°РєС‚РёРІРµРЅ');
      }

      final ReferralCode referralCode =
          ReferralCode.fromMap(codeSnapshot.docs.first.data() as Map<String, dynamic>);

      if (!referralCode.canBeUsed) {
        throw Exception('Р РµС„РµСЂР°Р»СЊРЅС‹Р№ РєРѕРґ РёСЃС‚РµРє РёР»Рё РґРѕСЃС‚РёРі Р»РёРјРёС‚Р° РёСЃРїРѕР»СЊР·РѕРІР°РЅРёР№');
      }

      // РџСЂРѕРІРµСЂСЏРµРј, РЅРµ РёСЃРїРѕР»СЊР·РѕРІР°Р» Р»Рё СѓР¶Рµ СЌС‚РѕС‚ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РєРѕРґ
      final existingReferral = await _firestore
          .collection('referrals')
          .where('referredId', isEqualTo: referredUserId)
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        throw Exception('Р’С‹ СѓР¶Рµ РёСЃРїРѕР»СЊР·РѕРІР°Р»Рё СЂРµС„РµСЂР°Р»СЊРЅС‹Р№ РєРѕРґ');
      }

      // РЎРѕР·РґР°РµРј СЂРµС„РµСЂР°Р»СЊРЅСѓСЋ Р·Р°РїРёСЃСЊ
      final String referralId = _uuid.v4();
      final Referral referral = Referral(
        id: referralId,
        referrerId: referralCode.userId,
        referredId: referredUserId,
        referralCode: code.toUpperCase(),
        status: ReferralStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('referrals').doc(referralId).set(referral.toMap());

      // РЈРІРµР»РёС‡РёРІР°РµРј СЃС‡РµС‚С‡РёРє РёСЃРїРѕР»СЊР·РѕРІР°РЅРёР№ РєРѕРґР°
      await _firestore.collection('referral_codes').doc(referralCode.id).update({
        'usageCount': FieldValue.increment(1),
      });

      debugPrint('INFO: [ReferralService] Referral created: $referralId');
      return referral;
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to use referral code: $e');
      rethrow;
    }
  }

  /// Р—Р°РІРµСЂС€РµРЅРёРµ СЂРµС„РµСЂР°Р»Р° (РєРѕРіРґР° РЅРѕРІС‹Р№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ СЃРѕРІРµСЂС€Р°РµС‚ РїРµСЂРІРѕРµ РґРµР№СЃС‚РІРёРµ)
  Future<void> completeReferral(String referralId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('referrals').doc(referralId).get();

      if (!doc.exists) {
        throw Exception('Р РµС„РµСЂР°Р» РЅРµ РЅР°Р№РґРµРЅ');
      }

      final Referral referral = Referral.fromMap(doc.data() as Map<String, dynamic>);

      if (referral.isCompleted) {
        return; // РЈР¶Рµ Р·Р°РІРµСЂС€РµРЅ
      }

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚СѓСЃ СЂРµС„РµСЂР°Р»Р°
      await _firestore.collection('referrals').doc(referralId).update({
        'status': ReferralStatus.completed.toString().split('.').last,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // РќР°С‡РёСЃР»СЏРµРј Р±РѕРЅСѓСЃС‹
      await _applyReferralBonuses(referral);

      debugPrint('INFO: [ReferralService] Referral completed: $referralId');
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to complete referral: $e');
      rethrow;
    }
  }

  /// РџСЂРёРјРµРЅРµРЅРёРµ Р±РѕРЅСѓСЃРѕРІ Р·Р° СЂРµС„РµСЂР°Р»
  Future<void> _applyReferralBonuses(Referral referral) async {
    try {
      // Р‘РѕРЅСѓСЃ РґР»СЏ РїСЂРёРіР»Р°СЃРёРІС€РµРіРѕ
      final ReferralReward referrerReward = ReferralReward(
        id: _uuid.v4(),
        userId: referral.referrerId,
        referralId: referral.id,
        type: ReferralBonusType.freePromotion,
        value: 1.0, // 1 Р±РµСЃРїР»Р°С‚РЅРѕРµ РїСЂРѕРґРІРёР¶РµРЅРёРµ
        description: 'Р‘РѕРЅСѓСЃ Р·Р° РїСЂРёРіР»Р°С€РµРЅРёРµ РґСЂСѓРіР°',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // Р‘РѕРЅСѓСЃ РґР»СЏ РїСЂРёРіР»Р°С€РµРЅРЅРѕРіРѕ
      final ReferralReward referredReward = ReferralReward(
        id: _uuid.v4(),
        userId: referral.referredId,
        referralId: referral.id,
        type: ReferralBonusType.premiumTrial,
        value: 7.0, // 7 РґРЅРµР№ РїСЂРµРјРёСѓРј
        description: 'РџСЂРёРІРµС‚СЃС‚РІРµРЅРЅС‹Р№ Р±РѕРЅСѓСЃ Р·Р° СЂРµРіРёСЃС‚СЂР°С†РёСЋ РїРѕ РїСЂРёРіР»Р°С€РµРЅРёСЋ',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // РЎРѕС…СЂР°РЅСЏРµРј Р±РѕРЅСѓСЃС‹
      await _firestore
          .collection('referral_rewards')
          .doc(referrerReward.id)
          .set(referrerReward.toMap());

      await _firestore
          .collection('referral_rewards')
          .doc(referredReward.id)
          .set(referredReward.toMap());

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      await _updateReferralStats(referral.referrerId);
      await _updateReferralStats(referral.referredId);

      debugPrint('INFO: [ReferralService] Bonuses applied for referral: ${referral.id}');
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to apply referral bonuses: $e');
      rethrow;
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё СЂРµС„РµСЂР°Р»РѕРІ
  Future<void> _updateReferralStats(String userId) async {
    try {
      // РџРѕРґСЃС‡РёС‚С‹РІР°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      final QuerySnapshot referralsSnapshot =
          await _firestore.collection('referrals').where('referrerId', isEqualTo: userId).get();

      final QuerySnapshot rewardsSnapshot =
          await _firestore.collection('referral_rewards').where('userId', isEqualTo: userId).get();

      final int totalReferrals = referralsSnapshot.docs.length;
      final int completedReferrals = referralsSnapshot.docs
          .where((doc) => Referral.fromMap(doc.data() as Map<String, dynamic>).isCompleted)
          .length;
      final int pendingReferrals = totalReferrals - completedReferrals;

      double totalBonusesEarned = 0.0;
      int activeRewards = 0;
      int usedRewards = 0;

      for (final doc in rewardsSnapshot.docs) {
        final ReferralReward reward = ReferralReward.fromMap(doc.data() as Map<String, dynamic>);
        totalBonusesEarned += reward.value;
        if (reward.isUsed) {
          usedRewards++;
        } else if (reward.canBeUsed) {
          activeRewards++;
        }
      }

      final ReferralStats stats = ReferralStats(
        userId: userId,
        totalReferrals: totalReferrals,
        completedReferrals: completedReferrals,
        pendingReferrals: pendingReferrals,
        totalBonusesEarned: totalBonusesEarned,
        activeRewards: activeRewards,
        usedRewards: usedRewards,
        lastReferralAt: referralsSnapshot.docs.isNotEmpty
            ? Referral.fromMap(referralsSnapshot.docs.last.data() as Map<String, dynamic>).createdAt
            : null,
      );

      await _firestore.collection('referral_stats').doc(userId).set(stats.toMap());

      debugPrint('INFO: [ReferralService] Stats updated for user: $userId');
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to update referral stats: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё СЂРµС„РµСЂР°Р»РѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<ReferralStats?> getUserReferralStats(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('referral_stats').doc(userId).get();

      if (doc.exists) {
        return ReferralStats.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to get user referral stats: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ Р°РєС‚РёРІРЅС‹С… РЅР°РіСЂР°Рґ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<ReferralReward>> getUserActiveRewards(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('referral_rewards')
          .where('userId', isEqualTo: userId)
          .where('isUsed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReferralReward.fromMap(doc.data() as Map<String, dynamic>))
          .where((reward) => reward.canBeUsed)
          .toList();
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to get user active rewards: $e');
      return [];
    }
  }

  /// РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ РЅР°РіСЂР°РґС‹
  Future<void> useReward(String rewardId) async {
    try {
      await _firestore.collection('referral_rewards').doc(rewardId).update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [ReferralService] Reward used: $rewardId');
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to use reward: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЂРµС„РµСЂР°Р»РѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<Referral>> getUserReferrals(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Referral.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to get user referrals: $e');
      return [];
    }
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ СѓРЅРёРєР°Р»СЊРЅРѕРіРѕ СЂРµС„РµСЂР°Р»СЊРЅРѕРіРѕ РєРѕРґР°
  String _generateReferralCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    String code;
    bool isUnique = false;

    do {
      code = '';
      for (int i = 0; i < 8; i++) {
        code += chars[random.nextInt(chars.length)];
      }

      // РџСЂРѕРІРµСЂСЏРµРј СѓРЅРёРєР°Р»СЊРЅРѕСЃС‚СЊ (СѓРїСЂРѕС‰РµРЅРЅР°СЏ РїСЂРѕРІРµСЂРєР°)
      isUnique = true; // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РЅСѓР¶РЅРѕ РїСЂРѕРІРµСЂРёС‚СЊ РІ Р‘Р”
    } while (!isUnique);

    return code;
  }

  /// РЎРѕР·РґР°РЅРёРµ СЂРµС„РµСЂР°Р»СЊРЅРѕР№ СЃСЃС‹Р»РєРё
  String createReferralLink(String code) {
    return 'https://eventmarketplace.app/invite/$code';
  }

  /// РџСЂРѕРІРµСЂРєР° РґРѕСЃС‚РёР¶РµРЅРёСЏ СѓСЂРѕРІРЅРµР№ СЂРµС„РµСЂР°Р»СЊРЅРѕР№ РїСЂРѕРіСЂР°РјРјС‹
  Future<List<String>> checkReferralLevels(String userId) async {
    try {
      final ReferralStats? stats = await getUserReferralStats(userId);
      if (stats == null) return [];

      final List<String> achievements = [];

      if (stats.completedReferrals >= 5) {
        achievements.add('level_5_referrals');
      }
      if (stats.completedReferrals >= 10) {
        achievements.add('level_10_referrals');
      }
      if (stats.completedReferrals >= 25) {
        achievements.add('level_25_referrals');
      }
      if (stats.completedReferrals >= 50) {
        achievements.add('level_50_referrals');
      }

      return achievements;
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to check referral levels: $e');
      return [];
    }
  }
}

