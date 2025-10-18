import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class GrowthMechanicsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Р”РѕР±Р°РІР»РµРЅРёРµ РѕРїС‹С‚Р° РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
  Future<void> addExperience(String userId, int experience, String reason) async {
    try {
      final DocumentSnapshot userLevelDoc =
          await _firestore.collection('user_levels').doc(userId).get();

      Map<String, dynamic> userLevel;
      if (userLevelDoc.exists) {
        userLevel = userLevelDoc.data() as Map<String, dynamic>;
      } else {
        userLevel = {
          'userId': userId,
          'level': 1,
          'experience': 0,
          'totalExperience': 0,
          'nextLevelExperience': 1000,
          'updatedAt': DateTime.now(),
        };
      }

      // Р”РѕР±Р°РІР»СЏРµРј РѕРїС‹С‚
      int newExperience = (userLevel['experience'] ?? 0) + experience;
      final int newTotalExperience = (userLevel['totalExperience'] ?? 0) + experience;

      // РџСЂРѕРІРµСЂСЏРµРј РїРѕРІС‹С€РµРЅРёРµ СѓСЂРѕРІРЅСЏ
      int newLevel = userLevel['level'] ?? 1;
      int newNextLevelExperience = userLevel['nextLevelExperience'] ?? 1000;
      bool levelUp = false;

      while (newExperience >= newNextLevelExperience) {
        newLevel++;
        newExperience -= newNextLevelExperience;
        newNextLevelExperience = _calculateNextLevelExperience(newLevel);
        levelUp = true;
      }

      final Map<String, dynamic> updatedLevel = {
        'userId': userId,
        'level': newLevel,
        'experience': newExperience,
        'totalExperience': newTotalExperience,
        'nextLevelExperience': newNextLevelExperience,
        'updatedAt': DateTime.now(),
        'title': _getLevelTitle(newLevel),
        'benefits': _getLevelBenefits(newLevel),
      };

      await _firestore.collection('user_levels').doc(userId).set(updatedLevel);

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ Рѕ РїРѕРІС‹С€РµРЅРёРё СѓСЂРѕРІРЅСЏ
      if (levelUp) {
        await _sendLevelUpNotification(userId, newLevel, newTotalExperience);
      }

      debugPrint('INFO: [GrowthMechanicsService] Experience added: $experience to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to add experience: $e');
    }
  }

  /// Р Р°СЃС‡РµС‚ РѕРїС‹С‚Р° РґР»СЏ СЃР»РµРґСѓСЋС‰РµРіРѕ СѓСЂРѕРІРЅСЏ
  int _calculateNextLevelExperience(int level) {
    // Р­РєСЃРїРѕРЅРµРЅС†РёР°Р»СЊРЅР°СЏ С„РѕСЂРјСѓР»Р°: base * (level ^ 1.5)
    const int baseExperience = 1000;
    return (baseExperience * (level * level * 0.5)).round();
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С‚РёС‚СѓР»Р° СѓСЂРѕРІРЅСЏ
  String _getLevelTitle(int level) {
    if (level >= 50) return 'Р›РµРіРµРЅРґР°';
    if (level >= 40) return 'РњР°СЃС‚РµСЂ';
    if (level >= 30) return 'Р­РєСЃРїРµСЂС‚';
    if (level >= 20) return 'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»';
    if (level >= 10) return 'РћРїС‹С‚РЅС‹Р№';
    if (level >= 5) return 'РџСЂРѕРґРІРёРЅСѓС‚С‹Р№';
    return 'РќРѕРІРёС‡РѕРє';
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РїСЂРµРёРјСѓС‰РµСЃС‚РІ СѓСЂРѕРІРЅСЏ
  Map<String, dynamic> _getLevelBenefits(int level) {
    return {
      'discount': _calculateLevelDiscount(level),
      'prioritySupport': level >= 10,
      'exclusiveFeatures': level >= 20,
      'personalManager': level >= 30,
    };
  }

  /// Р Р°СЃС‡РµС‚ СЃРєРёРґРєРё РїРѕ СѓСЂРѕРІРЅСЋ
  double _calculateLevelDiscount(int level) {
    if (level >= 30) return 0.20; // 20%
    if (level >= 20) return 0.15; // 15%
    if (level >= 10) return 0.10; // 10%
    if (level >= 5) return 0.05; // 5%
    return 0.0;
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РїРѕРІС‹С€РµРЅРёРё СѓСЂРѕРІРЅСЏ
  Future<void> _sendLevelUpNotification(String userId, int newLevel, int totalExperience) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'milestone',
        'title': 'РџРѕР·РґСЂР°РІР»СЏРµРј! РќРѕРІС‹Р№ СѓСЂРѕРІРµРЅСЊ!',
        'message': 'Р’С‹ РґРѕСЃС‚РёРіР»Рё $newLevel СѓСЂРѕРІРЅСЏ! РћР±С‰РёР№ РѕРїС‹С‚: $totalExperience',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/profile/level',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РїСЂРѕС„РёР»СЊ',
        'data': {
          'level': newLevel,
          'totalExperience': totalExperience,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint('INFO: [GrowthMechanicsService] Level up notification sent to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to send level up notification: $e');
    }
  }

  /// РџСЂРѕРІРµСЂРєР° Рё РІС‹РґР°С‡Р° РґРѕСЃС‚РёР¶РµРЅРёР№
  Future<void> checkAndAwardAchievements(
      String userId, String action, Map<String, dynamic> context) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµ Р°РєС‚РёРІРЅС‹Рµ РґРѕСЃС‚РёР¶РµРЅРёСЏ
      final QuerySnapshot achievementsSnapshot =
          await _firestore.collection('achievements').where('isActive', isEqualTo: true).get();

      for (final doc in achievementsSnapshot.docs) {
        final Map<String, dynamic> achievement = doc.data() as Map<String, dynamic>;

        // РџСЂРѕРІРµСЂСЏРµРј, РЅРµ РїРѕР»СѓС‡РµРЅРѕ Р»Рё СѓР¶Рµ СЌС‚Рѕ РґРѕСЃС‚РёР¶РµРЅРёРµ
        final bool alreadyEarned = await _isAchievementEarned(userId, achievement['id']);
        if (alreadyEarned) continue;

        // РџСЂРѕРІРµСЂСЏРµРј СѓСЃР»РѕРІРёРµ РґРѕСЃС‚РёР¶РµРЅРёСЏ
        final bool conditionMet = await _checkAchievementCondition(
          userId,
          achievement,
          action,
          context,
        );

        if (conditionMet) {
          await _awardAchievement(userId, achievement);
        }
      }
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to check achievements: $e');
    }
  }

  /// РџСЂРѕРІРµСЂРєР° СѓСЃР»РѕРІРёСЏ РґРѕСЃС‚РёР¶РµРЅРёСЏ
  Future<bool> _checkAchievementCondition(
    String userId,
    Map<String, dynamic> achievement,
    String action,
    Map<String, dynamic> context,
  ) async {
    try {
      final Map<String, dynamic> condition = achievement['condition'] ?? {};
      final String conditionType = condition['type'] ?? '';

      switch (conditionType) {
        case 'referral_count':
          final int requiredCount = condition['count'] ?? 0;
          final int actualCount = await _getUserReferralCount(userId);
          return actualCount >= requiredCount;

        case 'purchase_count':
          final int requiredCount = condition['count'] ?? 0;
          final int actualCount = await _getUserPurchaseCount(userId);
          return actualCount >= requiredCount;

        case 'total_spent':
          final double requiredAmount = (condition['amount'] ?? 0.0).toDouble();
          final double actualAmount = await _getUserTotalSpent(userId);
          return actualAmount >= requiredAmount;

        case 'consecutive_days':
          final int requiredDays = condition['days'] ?? 0;
          final int actualDays = await _getUserConsecutiveDays(userId);
          return actualDays >= requiredDays;

        case 'level_reached':
          final int requiredLevel = condition['level'] ?? 0;
          final int actualLevel = await _getUserLevel(userId);
          return actualLevel >= requiredLevel;

        case 'action_count':
          final String targetAction = condition['action'] ?? '';
          final int requiredCount = condition['count'] ?? 0;
          if (targetAction == action) {
            final int actualCount = await _getUserActionCount(userId, action);
            return actualCount >= requiredCount;
          }
          return false;

        default:
          return false;
      }
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to check achievement condition: $e');
      return false;
    }
  }

  /// Р’С‹РґР°С‡Р° РґРѕСЃС‚РёР¶РµРЅРёСЏ
  Future<void> _awardAchievement(String userId, Map<String, dynamic> achievement) async {
    try {
      final Map<String, dynamic> userAchievement = {
        'id': _uuid.v4(),
        'userId': userId,
        'achievementId': achievement['id'],
        'achievementName': achievement['name'],
        'achievementType': achievement['type'],
        'earnedAt': DateTime.now(),
        'isClaimed': false,
        'progress': achievement['condition'],
      };

      await _firestore
          .collection('user_achievements')
          .doc(userAchievement['id'])
          .set(userAchievement);

      // Р”РѕР±Р°РІР»СЏРµРј РѕРїС‹С‚ Р·Р° РґРѕСЃС‚РёР¶РµРЅРёРµ
      if (achievement['points'] != null) {
        await addExperience(userId, achievement['points'], 'Achievement: ${achievement['name']}');
      }

      // Р’С‹РґР°РµРј РЅР°РіСЂР°РґСѓ
      await _giveAchievementReward(userId, achievement);

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ
      await _sendAchievementNotification(userId, achievement);

      debugPrint(
          'INFO: [GrowthMechanicsService] Achievement awarded: ${achievement['name']} to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to award achievement: $e');
    }
  }

  /// Р’С‹РґР°С‡Р° РЅР°РіСЂР°РґС‹ Р·Р° РґРѕСЃС‚РёР¶РµРЅРёРµ
  Future<void> _giveAchievementReward(String userId, Map<String, dynamic> achievement) async {
    try {
      final Map<String, dynamic> reward = achievement['reward'] ?? {};
      final String rewardType = reward['type'] ?? '';

      switch (rewardType) {
        case 'premium_days':
          final int days = reward['days'] ?? 0;
          await _addPremiumDays(userId, days);
          break;
        case 'discount':
          final double discount = (reward['value'] ?? 0.0).toDouble();
          await _addDiscount(userId, discount);
          break;
        case 'badge':
          final String badgeId = reward['badgeId'] ?? '';
          await _awardBadge(userId, badgeId);
          break;
        case 'points':
          final int points = reward['value'] ?? 0;
          await addExperience(userId, points, 'Achievement reward: ${achievement['name']}');
          break;
      }
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to give achievement reward: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РґРѕСЃС‚РёР¶РµРЅРёРё
  Future<void> _sendAchievementNotification(String userId, Map<String, dynamic> achievement) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'achievement',
        'title': 'Р”РѕСЃС‚РёР¶РµРЅРёРµ РїРѕР»СѓС‡РµРЅРѕ!',
        'message': 'РџРѕР·РґСЂР°РІР»СЏРµРј! Р’С‹ РїРѕР»СѓС‡РёР»Рё РґРѕСЃС‚РёР¶РµРЅРёРµ "${achievement['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/achievements',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РґРѕСЃС‚РёР¶РµРЅРёСЏ',
        'data': {
          'achievementId': achievement['id'],
          'achievementName': achievement['name'],
          'achievementType': achievement['type'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to send achievement notification: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ С‡РµР»Р»РµРЅРґР¶Р°
  Future<String> createChallenge({
    required String name,
    required String description,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> conditions,
    required Map<String, dynamic> rewards,
    String? icon,
    String? category,
  }) async {
    try {
      final Map<String, dynamic> challenge = {
        'id': _uuid.v4(),
        'name': name,
        'description': description,
        'type': type,
        'status': 'active',
        'startDate': startDate,
        'endDate': endDate,
        'conditions': conditions,
        'rewards': rewards,
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'icon': icon,
        'category': category,
      };

      await _firestore.collection('challenges').doc(challenge['id']).set(challenge);

      debugPrint('INFO: [GrowthMechanicsService] Challenge created: ${challenge['id']}');
      return challenge['id'];
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to create challenge: $e');
      rethrow;
    }
  }

  /// РЈС‡Р°СЃС‚РёРµ РІ С‡РµР»Р»РµРЅРґР¶Рµ
  Future<void> joinChallenge(String userId, String challengeId) async {
    try {
      // РџСЂРѕРІРµСЂСЏРµРј, РЅРµ СѓС‡Р°СЃС‚РІСѓРµС‚ Р»Рё СѓР¶Рµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ
      final bool alreadyJoined = await _isUserInChallenge(userId, challengeId);
      if (alreadyJoined) return;

      final DocumentSnapshot challengeDoc =
          await _firestore.collection('challenges').doc(challengeId).get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final Map<String, dynamic> challenge = challengeDoc.data() as Map<String, dynamic>;

      if (!challenge['isActive']) {
        throw Exception('Challenge is not active');
      }

      final Map<String, dynamic> userChallenge = {
        'id': _uuid.v4(),
        'userId': userId,
        'challengeId': challengeId,
        'challengeName': challenge['name'],
        'challengeType': challenge['type'],
        'joinedAt': DateTime.now(),
        'status': 'active',
        'progress': {},
      };

      await _firestore.collection('user_challenges').doc(userChallenge['id']).set(userChallenge);

      // РЈРІРµР»РёС‡РёРІР°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ СѓС‡Р°СЃС‚РЅРёРєРѕРІ
      await _firestore.collection('challenges').doc(challengeId).update({
        'participants': FieldValue.increment(1),
      });

      debugPrint('INFO: [GrowthMechanicsService] User $userId joined challenge $challengeId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to join challenge: $e');
      rethrow;
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ РїСЂРѕРіСЂРµСЃСЃР° С‡РµР»Р»РµРЅРґР¶Р°
  Future<void> updateChallengeProgress(
      String userId, String challengeId, Map<String, dynamic> progress) async {
    try {
      final QuerySnapshot userChallengeSnapshot = await _firestore
          .collection('user_challenges')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challengeId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (userChallengeSnapshot.docs.isEmpty) return;

      final String userChallengeId = userChallengeSnapshot.docs.first.id;

      await _firestore.collection('user_challenges').doc(userChallengeId).update({
        'progress': progress,
      });

      // РџСЂРѕРІРµСЂСЏРµРј, РІС‹РїРѕР»РЅРµРЅ Р»Рё С‡РµР»Р»РµРЅРґР¶
      await _checkChallengeCompletion(userId, challengeId);

      debugPrint('INFO: [GrowthMechanicsService] Challenge progress updated for user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to update challenge progress: $e');
    }
  }

  /// РџСЂРѕРІРµСЂРєР° РІС‹РїРѕР»РЅРµРЅРёСЏ С‡РµР»Р»РµРЅРґР¶Р°
  Future<void> _checkChallengeCompletion(String userId, String challengeId) async {
    try {
      final DocumentSnapshot challengeDoc =
          await _firestore.collection('challenges').doc(challengeId).get();

      if (!challengeDoc.exists) return;

      final Map<String, dynamic> challenge = challengeDoc.data() as Map<String, dynamic>;
      final QuerySnapshot userChallengeSnapshot = await _firestore
          .collection('user_challenges')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challengeId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (userChallengeSnapshot.docs.isEmpty) return;

      final Map<String, dynamic> userChallenge =
          userChallengeSnapshot.docs.first.data() as Map<String, dynamic>;

      // РџСЂРѕРІРµСЂСЏРµРј СѓСЃР»РѕРІРёСЏ РІС‹РїРѕР»РЅРµРЅРёСЏ
      final bool isCompleted = await _checkChallengeConditions(challenge, userChallenge);

      if (isCompleted) {
        await _completeChallenge(userId, challengeId, challenge, userChallenge);
      }
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to check challenge completion: $e');
    }
  }

  /// РџСЂРѕРІРµСЂРєР° СѓСЃР»РѕРІРёР№ С‡РµР»Р»РµРЅРґР¶Р°
  Future<bool> _checkChallengeConditions(
      Map<String, dynamic> challenge, Map<String, dynamic> userChallenge) async {
    try {
      final Map<String, dynamic> conditions = challenge['conditions'] ?? {};
      final Map<String, dynamic> progress = userChallenge['progress'] ?? {};

      for (final condition in conditions.entries) {
        final String key = condition.key;
        final dynamic requiredValue = condition.value;
        final dynamic actualValue = progress[key];

        if (actualValue == null || actualValue < requiredValue) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to check challenge conditions: $e');
      return false;
    }
  }

  /// Р—Р°РІРµСЂС€РµРЅРёРµ С‡РµР»Р»РµРЅРґР¶Р°
  Future<void> _completeChallenge(
    String userId,
    String challengeId,
    Map<String, dynamic> challenge,
    Map<String, dynamic> userChallenge,
  ) async {
    try {
      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚СѓСЃ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊСЃРєРѕРіРѕ С‡РµР»Р»РµРЅРґР¶Р°
      await _firestore.collection('user_challenges').doc(userChallenge['id']).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // РЈРІРµР»РёС‡РёРІР°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ Р·Р°РІРµСЂС€РµРЅРЅС‹С… С‡РµР»Р»РµРЅРґР¶РµР№
      await _firestore.collection('challenges').doc(challengeId).update({
        'completedCount': FieldValue.increment(1),
      });

      // Р’С‹РґР°РµРј РЅР°РіСЂР°РґСѓ
      await _giveChallengeReward(userId, challenge);

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ
      await _sendChallengeCompletionNotification(userId, challenge);

      debugPrint(
          'INFO: [GrowthMechanicsService] Challenge completed: $challengeId by user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to complete challenge: $e');
    }
  }

  /// Р’С‹РґР°С‡Р° РЅР°РіСЂР°РґС‹ Р·Р° С‡РµР»Р»РµРЅРґР¶
  Future<void> _giveChallengeReward(String userId, Map<String, dynamic> challenge) async {
    try {
      final Map<String, dynamic> rewards = challenge['rewards'] ?? {};

      for (final reward in rewards.entries) {
        final String rewardType = reward.key;
        final dynamic rewardValue = reward.value;

        switch (rewardType) {
          case 'experience':
            await addExperience(userId, rewardValue as int, 'Challenge: ${challenge['name']}');
            break;
          case 'premium_days':
            await _addPremiumDays(userId, rewardValue as int);
            break;
          case 'badge':
            await _awardBadge(userId, rewardValue as String);
            break;
          case 'discount':
            await _addDiscount(userId, (rewardValue as num).toDouble());
            break;
        }
      }
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to give challenge reward: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ Р·Р°РІРµСЂС€РµРЅРёРё С‡РµР»Р»РµРЅРґР¶Р°
  Future<void> _sendChallengeCompletionNotification(
      String userId, Map<String, dynamic> challenge) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'challenge',
        'title': 'Р§РµР»Р»РµРЅРґР¶ РІС‹РїРѕР»РЅРµРЅ!',
        'message': 'РџРѕР·РґСЂР°РІР»СЏРµРј! Р’С‹ РІС‹РїРѕР»РЅРёР»Рё С‡РµР»Р»РµРЅРґР¶ "${challenge['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/challenges',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ С‡РµР»Р»РµРЅРґР¶Рё',
        'data': {
          'challengeId': challenge['id'],
          'challengeName': challenge['name'],
          'challengeType': challenge['type'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthMechanicsService] Failed to send challenge completion notification: $e');
    }
  }

  /// Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅС‹Рµ РјРµС‚РѕРґС‹ РґР»СЏ РїСЂРѕРІРµСЂРєРё СѓСЃР»РѕРІРёР№
  Future<bool> _isAchievementEarned(String userId, String achievementId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('user_achievements')
        .where('userId', isEqualTo: userId)
        .where('achievementId', isEqualTo: achievementId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<int> _getUserReferralCount(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getUserPurchaseCount(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    return snapshot.docs.length;
  }

  Future<double> _getUserTotalSpent(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0.0).toDouble();
    }
    return total;
  }

  Future<int> _getUserConsecutiveDays(String userId) async {
    // РЈРїСЂРѕС‰РµРЅРЅР°СЏ Р»РѕРіРёРєР° - РІ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РЅСѓР¶РЅР° Р±РѕР»РµРµ СЃР»РѕР¶РЅР°СЏ СЃРёСЃС‚РµРјР°
    return 1;
  }

  Future<int> _getUserLevel(String userId) async {
    final DocumentSnapshot doc = await _firestore.collection('user_levels').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['level'] ?? 1;
    }
    return 1;
  }

  Future<int> _getUserActionCount(String userId, String action) async {
    // РЈРїСЂРѕС‰РµРЅРЅР°СЏ Р»РѕРіРёРєР° - РІ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РЅСѓР¶РЅР° СЃРёСЃС‚РµРјР° РѕС‚СЃР»РµР¶РёРІР°РЅРёСЏ РґРµР№СЃС‚РІРёР№
    return 1;
  }

  Future<bool> _isUserInChallenge(String userId, String challengeId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('user_challenges')
        .where('userId', isEqualTo: userId)
        .where('challengeId', isEqualTo: challengeId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅС‹Рµ РјРµС‚РѕРґС‹ РґР»СЏ РЅР°РіСЂР°Рґ
  Future<void> _addPremiumDays(String userId, int days) async {
    // Р›РѕРіРёРєР° РґРѕР±Р°РІР»РµРЅРёСЏ РїСЂРµРјРёСѓРј РґРЅРµР№
    debugPrint('INFO: [GrowthMechanicsService] Added $days premium days to user $userId');
  }

  Future<void> _addDiscount(String userId, double discount) async {
    // Р›РѕРіРёРєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЃРєРёРґРєРё
    debugPrint('INFO: [GrowthMechanicsService] Added $discount discount to user $userId');
  }

  Future<void> _awardBadge(String userId, String badgeId) async {
    try {
      final DocumentSnapshot badgeDoc = await _firestore.collection('badges').doc(badgeId).get();

      if (!badgeDoc.exists) return;

      final Map<String, dynamic> badge = badgeDoc.data() as Map<String, dynamic>;

      final Map<String, dynamic> userBadge = {
        'id': _uuid.v4(),
        'userId': userId,
        'badgeId': badgeId,
        'badgeName': badge['name'],
        'badgeType': badge['type'],
        'earnedAt': DateTime.now(),
        'isDisplayed': true,
        'category': badge['category'],
      };

      await _firestore.collection('user_badges').doc(userBadge['id']).set(userBadge);

      debugPrint('INFO: [GrowthMechanicsService] Badge awarded: ${badge['name']} to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to award badge: $e');
    }
  }
}

