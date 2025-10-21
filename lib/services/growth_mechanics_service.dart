import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class GrowthMechanicsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Добавление опыта пользователю
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

      // Добавляем опыт
      int newExperience = (userLevel['experience'] ?? 0) + experience;
      final int newTotalExperience = (userLevel['totalExperience'] ?? 0) + experience;

      // Проверяем повышение уровня
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

      // Отправляем уведомление о повышении уровня
      if (levelUp) {
        await _sendLevelUpNotification(userId, newLevel, newTotalExperience);
      }

      debugPrint('INFO: [GrowthMechanicsService] Experience added: $experience to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to add experience: $e');
    }
  }

  /// Расчет опыта для следующего уровня
  int _calculateNextLevelExperience(int level) {
    // Экспоненциальная формула: base * (level ^ 1.5)
    const int baseExperience = 1000;
    return (baseExperience * (level * level * 0.5)).round();
  }

  /// Получение титула уровня
  String _getLevelTitle(int level) {
    if (level >= 50) return 'Легенда';
    if (level >= 40) return 'Мастер';
    if (level >= 30) return 'Эксперт';
    if (level >= 20) return 'Профессионал';
    if (level >= 10) return 'Опытный';
    if (level >= 5) return 'Продвинутый';
    return 'Новичок';
  }

  /// Получение преимуществ уровня
  Map<String, dynamic> _getLevelBenefits(int level) {
    return {
      'discount': _calculateLevelDiscount(level),
      'prioritySupport': level >= 10,
      'exclusiveFeatures': level >= 20,
      'personalManager': level >= 30,
    };
  }

  /// Расчет скидки по уровню
  double _calculateLevelDiscount(int level) {
    if (level >= 30) return 0.20; // 20%
    if (level >= 20) return 0.15; // 15%
    if (level >= 10) return 0.10; // 10%
    if (level >= 5) return 0.05; // 5%
    return 0.0;
  }

  /// Отправка уведомления о повышении уровня
  Future<void> _sendLevelUpNotification(String userId, int newLevel, int totalExperience) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'milestone',
        'title': 'Поздравляем! Новый уровень!',
        'message': 'Вы достигли $newLevel уровня! Общий опыт: $totalExperience',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/profile/level',
        'actionText': 'Посмотреть профиль',
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

  /// Проверка и выдача достижений
  Future<void> checkAndAwardAchievements(
      String userId, String action, Map<String, dynamic> context) async {
    try {
      // Получаем все активные достижения
      final QuerySnapshot achievementsSnapshot =
          await _firestore.collection('achievements').where('isActive', isEqualTo: true).get();

      for (final doc in achievementsSnapshot.docs) {
        final Map<String, dynamic> achievement = doc.data() as Map<String, dynamic>;

        // Проверяем, не получено ли уже это достижение
        final bool alreadyEarned = await _isAchievementEarned(userId, achievement['id']);
        if (alreadyEarned) continue;

        // Проверяем условие достижения
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

  /// Проверка условия достижения
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

  /// Выдача достижения
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

      // Добавляем опыт за достижение
      if (achievement['points'] != null) {
        await addExperience(userId, achievement['points'], 'Achievement: ${achievement['name']}');
      }

      // Выдаем награду
      await _giveAchievementReward(userId, achievement);

      // Отправляем уведомление
      await _sendAchievementNotification(userId, achievement);

      debugPrint(
          'INFO: [GrowthMechanicsService] Achievement awarded: ${achievement['name']} to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to award achievement: $e');
    }
  }

  /// Выдача награды за достижение
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

  /// Отправка уведомления о достижении
  Future<void> _sendAchievementNotification(String userId, Map<String, dynamic> achievement) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'achievement',
        'title': 'Достижение получено!',
        'message': 'Поздравляем! Вы получили достижение "${achievement['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/achievements',
        'actionText': 'Посмотреть достижения',
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

  /// Создание челленджа
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

  /// Участие в челлендже
  Future<void> joinChallenge(String userId, String challengeId) async {
    try {
      // Проверяем, не участвует ли уже пользователь
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

      // Увеличиваем количество участников
      await _firestore.collection('challenges').doc(challengeId).update({
        'participants': FieldValue.increment(1),
      });

      debugPrint('INFO: [GrowthMechanicsService] User $userId joined challenge $challengeId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to join challenge: $e');
      rethrow;
    }
  }

  /// Обновление прогресса челленджа
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

      // Проверяем, выполнен ли челлендж
      await _checkChallengeCompletion(userId, challengeId);

      debugPrint('INFO: [GrowthMechanicsService] Challenge progress updated for user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to update challenge progress: $e');
    }
  }

  /// Проверка выполнения челленджа
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

      // Проверяем условия выполнения
      final bool isCompleted = await _checkChallengeConditions(challenge, userChallenge);

      if (isCompleted) {
        await _completeChallenge(userId, challengeId, challenge, userChallenge);
      }
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to check challenge completion: $e');
    }
  }

  /// Проверка условий челленджа
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

  /// Завершение челленджа
  Future<void> _completeChallenge(
    String userId,
    String challengeId,
    Map<String, dynamic> challenge,
    Map<String, dynamic> userChallenge,
  ) async {
    try {
      // Обновляем статус пользовательского челленджа
      await _firestore.collection('user_challenges').doc(userChallenge['id']).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Увеличиваем количество завершенных челленджей
      await _firestore.collection('challenges').doc(challengeId).update({
        'completedCount': FieldValue.increment(1),
      });

      // Выдаем награду
      await _giveChallengeReward(userId, challenge);

      // Отправляем уведомление
      await _sendChallengeCompletionNotification(userId, challenge);

      debugPrint(
          'INFO: [GrowthMechanicsService] Challenge completed: $challengeId by user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthMechanicsService] Failed to complete challenge: $e');
    }
  }

  /// Выдача награды за челлендж
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

  /// Отправка уведомления о завершении челленджа
  Future<void> _sendChallengeCompletionNotification(
      String userId, Map<String, dynamic> challenge) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'challenge',
        'title': 'Челлендж выполнен!',
        'message': 'Поздравляем! Вы выполнили челлендж "${challenge['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/challenges',
        'actionText': 'Посмотреть челленджи',
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

  /// Вспомогательные методы для проверки условий
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
    // Упрощенная логика - в реальном приложении нужна более сложная система
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
    // Упрощенная логика - в реальном приложении нужна система отслеживания действий
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

  /// Вспомогательные методы для наград
  Future<void> _addPremiumDays(String userId, int days) async {
    // Логика добавления премиум дней
    debugPrint('INFO: [GrowthMechanicsService] Added $days premium days to user $userId');
  }

  Future<void> _addDiscount(String userId, double discount) async {
    // Логика добавления скидки
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
