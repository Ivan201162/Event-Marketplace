import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/referral_system.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Создание реферального кода для пользователя
  Future<ReferralCode> createReferralCode(String userId) async {
    try {
      // Проверяем, есть ли уже активный код
      final existingCode = await _firestore
          .collection('referral_codes')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingCode.docs.isNotEmpty) {
        return ReferralCode.fromMap(existingCode.docs.first.data());
      }

      // Создаем новый код
      final String code = _generateReferralCode();
      final String id = _uuid.v4();

      final ReferralCode referralCode = ReferralCode(
        id: id,
        userId: userId,
        code: code,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 365)), // Год действия
      );

      await _firestore.collection('referral_codes').doc(id).set(referralCode.toMap());

      debugPrint('INFO: [ReferralService] Created referral code: $code for user: $userId');
      return referralCode;
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to create referral code: $e');
      rethrow;
    }
  }

  /// Получение реферального кода пользователя
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

  /// Проверка и использование реферального кода
  Future<Referral?> useReferralCode(String code, String referredUserId) async {
    try {
      // Находим код
      final QuerySnapshot codeSnapshot = await _firestore
          .collection('referral_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (codeSnapshot.docs.isEmpty) {
        throw Exception('Реферальный код не найден или неактивен');
      }

      final ReferralCode referralCode =
          ReferralCode.fromMap(codeSnapshot.docs.first.data() as Map<String, dynamic>);

      if (!referralCode.canBeUsed) {
        throw Exception('Реферальный код истек или достиг лимита использований');
      }

      // Проверяем, не использовал ли уже этот пользователь код
      final existingReferral = await _firestore
          .collection('referrals')
          .where('referredId', isEqualTo: referredUserId)
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        throw Exception('Вы уже использовали реферальный код');
      }

      // Создаем реферальную запись
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

      // Увеличиваем счетчик использований кода
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

  /// Завершение реферала (когда новый пользователь совершает первое действие)
  Future<void> completeReferral(String referralId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('referrals').doc(referralId).get();

      if (!doc.exists) {
        throw Exception('Реферал не найден');
      }

      final Referral referral = Referral.fromMap(doc.data() as Map<String, dynamic>);

      if (referral.isCompleted) {
        return; // Уже завершен
      }

      // Обновляем статус реферала
      await _firestore.collection('referrals').doc(referralId).update({
        'status': ReferralStatus.completed.toString().split('.').last,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Начисляем бонусы
      await _applyReferralBonuses(referral);

      debugPrint('INFO: [ReferralService] Referral completed: $referralId');
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to complete referral: $e');
      rethrow;
    }
  }

  /// Применение бонусов за реферал
  Future<void> _applyReferralBonuses(Referral referral) async {
    try {
      // Бонус для пригласившего
      final ReferralReward referrerReward = ReferralReward(
        id: _uuid.v4(),
        userId: referral.referrerId,
        referralId: referral.id,
        type: ReferralBonusType.freePromotion,
        value: 1.0, // 1 бесплатное продвижение
        description: 'Бонус за приглашение друга',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // Бонус для приглашенного
      final ReferralReward referredReward = ReferralReward(
        id: _uuid.v4(),
        userId: referral.referredId,
        referralId: referral.id,
        type: ReferralBonusType.premiumTrial,
        value: 7.0, // 7 дней премиум
        description: 'Приветственный бонус за регистрацию по приглашению',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // Сохраняем бонусы
      await _firestore
          .collection('referral_rewards')
          .doc(referrerReward.id)
          .set(referrerReward.toMap());

      await _firestore
          .collection('referral_rewards')
          .doc(referredReward.id)
          .set(referredReward.toMap());

      // Обновляем статистику
      await _updateReferralStats(referral.referrerId);
      await _updateReferralStats(referral.referredId);

      debugPrint('INFO: [ReferralService] Bonuses applied for referral: ${referral.id}');
    } catch (e) {
      debugPrint('ERROR: [ReferralService] Failed to apply referral bonuses: $e');
      rethrow;
    }
  }

  /// Обновление статистики рефералов
  Future<void> _updateReferralStats(String userId) async {
    try {
      // Подсчитываем статистику
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

  /// Получение статистики рефералов пользователя
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

  /// Получение активных наград пользователя
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

  /// Использование награды
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

  /// Получение рефералов пользователя
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

  /// Генерация уникального реферального кода
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

      // Проверяем уникальность (упрощенная проверка)
      isUnique = true; // В реальном приложении нужно проверить в БД
    } while (!isUnique);

    return code;
  }

  /// Создание реферальной ссылки
  String createReferralLink(String code) {
    return 'https://eventmarketplace.app/invite/$code';
  }

  /// Проверка достижения уровней реферальной программы
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
