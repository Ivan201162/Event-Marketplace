import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/referral.dart';

/// Сервис для работы с партнёрской программой
class ReferralService {
  static const String _referralsCollection = 'referrals';
  static const String _partnerProgramCollection = 'partnerProgram';
  static const String _bonusesCollection = 'bonuses';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать партнёрскую программу для пользователя
  Future<String?> createPartnerProgram(String userId) async {
    try {
      final referralCode = _generateReferralCode(userId);

      final partnerProgram = PartnerProgram(
        userId: userId,
        referralCode: referralCode,
        totalReferrals: 0,
        completedReferrals: 0,
        totalBonus: 0,
        status: PartnerStatus.bronze,
        joinedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
      );

      await _firestore
          .collection(_partnerProgramCollection)
          .doc(userId)
          .set(partnerProgram.toFirestore());

      return referralCode;
    } on Exception catch (e) {
      debugPrint('Ошибка создания партнёрской программы: $e');
      return null;
    }
  }

  /// Получить партнёрскую программу пользователя
  Future<PartnerProgram?> getPartnerProgram(String userId) async {
    try {
      final doc = await _firestore
          .collection(_partnerProgramCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return PartnerProgram.fromFirestore(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения партнёрской программы: $e');
      return null;
    }
  }

  /// Получить рефералов пользователя
  Future<List<Referral>> getUserReferrals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_referralsCollection)
          .where('inviterId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map(Referral.fromFirestore).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения рефералов: $e');
      return [];
    }
  }

  /// Обработать приглашение по реферальному коду
  Future<bool> processReferral(
    String referralCode,
    String invitedUserId,
  ) async {
    try {
      // Найти пользователя по реферальному коду
      final partnerQuery = await _firestore
          .collection(_partnerProgramCollection)
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (partnerQuery.docs.isEmpty) {
        debugPrint('Реферальный код не найден: $referralCode');
        return false;
      }

      final inviterId = partnerQuery.docs.first.id;

      // Проверить, не приглашал ли уже этого пользователя
      final existingReferral = await _firestore
          .collection(_referralsCollection)
          .where('inviterId', isEqualTo: inviterId)
          .where('invitedUserId', isEqualTo: invitedUserId)
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        debugPrint('Пользователь уже приглашен этим рефералом');
        return false;
      }

      // Создать запись о реферале
      final referral = Referral(
        id: '${inviterId}_$invitedUserId',
        inviterId: inviterId,
        invitedUserId: invitedUserId,
        timestamp: DateTime.now(),
        bonus: 100, // Базовый бонус за приглашение
      );

      await _firestore
          .collection(_referralsCollection)
          .doc(referral.id)
          .set(referral.toFirestore());

      // Обновить статистику партнёрской программы
      await _updatePartnerProgramStats(inviterId);

      // Создать бонус для пригласившего
      await _createBonus(
        inviterId,
        100,
        BonusType.referral,
        'За приглашение пользователя',
      );

      // Создать бонус для приглашенного
      await _createBonus(
        invitedUserId,
        50,
        BonusType.registration,
        'За регистрацию по приглашению',
      );

      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка обработки реферала: $e');
      return false;
    }
  }

  /// Отметить реферала как завершенного
  Future<bool> completeReferral(String referralId) async {
    try {
      final referralDoc = await _firestore
          .collection(_referralsCollection)
          .doc(referralId)
          .get();

      if (!referralDoc.exists) {
        return false;
      }

      final referral = Referral.fromFirestore(referralDoc);

      if (referral.isCompleted) {
        return true; // Уже завершен
      }

      // Обновить статус реферала
      await _firestore.collection(_referralsCollection).doc(referralId).update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
      });

      // Обновить статистику партнёрской программы
      await _updatePartnerProgramStats(referral.inviterId);

      // Создать дополнительный бонус за завершение
      await _createBonus(
        referral.inviterId,
        200,
        BonusType.milestone,
        'За завершение реферала',
      );

      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка завершения реферала: $e');
      return false;
    }
  }

  /// Обновить статистику партнёрской программы
  Future<void> _updatePartnerProgramStats(String userId) async {
    try {
      final referrals = await getUserReferrals(userId);
      final completedReferrals = referrals.where((r) => r.isCompleted).length;
      final totalBonus = referrals.fold(0, (sum, r) => sum + r.bonus);

      // Определить новый статус
      var newStatus = PartnerStatus.bronze;
      if (completedReferrals >= 20) {
        newStatus = PartnerStatus.platinum;
      } else if (completedReferrals >= 10) {
        newStatus = PartnerStatus.gold;
      } else if (completedReferrals >= 5) {
        newStatus = PartnerStatus.silver;
      }

      await _firestore
          .collection(_partnerProgramCollection)
          .doc(userId)
          .update({
        'totalReferrals': referrals.length,
        'completedReferrals': completedReferrals,
        'totalBonus': totalBonus,
        'status': newStatus.value,
        'lastActivityAt': Timestamp.now(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статистики партнёрской программы: $e');
    }
  }

  /// Создать бонус
  Future<void> _createBonus(
    String userId,
    int amount,
    BonusType type,
    String description,
  ) async {
    try {
      final bonus = Bonus(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        amount: amount,
        type: type.value,
        description: description,
        earnedAt: DateTime.now(),
      );

      await _firestore
          .collection(_bonusesCollection)
          .doc(bonus.id)
          .set(bonus.toFirestore());
    } on Exception catch (e) {
      debugPrint('Ошибка создания бонуса: $e');
    }
  }

  /// Получить бонусы пользователя
  Future<List<Bonus>> getUserBonuses(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bonusesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('earnedAt', descending: true)
          .get();

      return querySnapshot.docs.map(Bonus.fromFirestore).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения бонусов: $e');
      return [];
    }
  }

  /// Получить общий баланс бонусов
  Future<int> getUserBonusBalance(String userId) async {
    try {
      final bonuses = await getUserBonuses(userId);
      final earned = bonuses.fold(0, (sum, bonus) => sum + bonus.amount);
      final used = bonuses
          .where((bonus) => bonus.isUsed)
          .fold(0, (sum, bonus) => sum + bonus.amount);

      return earned - used;
    } on Exception catch (e) {
      debugPrint('Ошибка получения баланса бонусов: $e');
      return 0;
    }
  }

  /// Использовать бонус
  Future<bool> useBonus(String bonusId, String usedFor) async {
    try {
      final bonusDoc =
          await _firestore.collection(_bonusesCollection).doc(bonusId).get();

      if (!bonusDoc.exists) {
        return false;
      }

      final bonus = Bonus.fromFirestore(bonusDoc);

      if (bonus.isUsed) {
        return false; // Уже использован
      }

      await _firestore.collection(_bonusesCollection).doc(bonusId).update({
        'isUsed': true,
        'usedAt': Timestamp.now(),
        'usedFor': usedFor,
      });

      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка использования бонуса: $e');
      return false;
    }
  }

  /// Генерация реферального кода
  String _generateReferralCode(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userHash = userId.hashCode.abs();
    return 'REF${userHash.toString().substring(0, 6).toUpperCase()}';
  }

  /// Сохранить реферальный код локально
  Future<void> saveReferralCodeLocally(String referralCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('referral_code', referralCode);
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения реферального кода: $e');
    }
  }

  /// Получить реферальный код из локального хранилища
  Future<String?> getReferralCodeLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('referral_code');
    } on Exception catch (e) {
      debugPrint('Ошибка получения реферального кода: $e');
      return null;
    }
  }

  /// Получить статистику партнёрской программы
  Future<Map<String, dynamic>> getPartnerProgramStats(String userId) async {
    try {
      final partnerProgram = await getPartnerProgram(userId);
      final referrals = await getUserReferrals(userId);
      final bonuses = await getUserBonuses(userId);
      final balance = await getUserBonusBalance(userId);

      return {
        'partnerProgram': partnerProgram,
        'totalReferrals': referrals.length,
        'completedReferrals': referrals.where((r) => r.isCompleted).length,
        'totalBonuses': bonuses.length,
        'bonusBalance': balance,
        'totalEarned': bonuses.fold(0, (sum, bonus) => sum + bonus.amount),
        'totalUsed': bonuses
            .where((bonus) => bonus.isUsed)
            .fold(0, (sum, bonus) => sum + bonus.amount),
      };
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Очистить старые неактивные рефералы
  Future<int> cleanupOldReferrals() async {
    try {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      final querySnapshot = await _firestore
          .collection(_referralsCollection)
          .where('timestamp', isLessThan: Timestamp.fromDate(monthAgo))
          .where('isCompleted', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Удалено ${querySnapshot.docs.length} старых рефералов');
      }

      return querySnapshot.docs.length;
    } on Exception catch (e) {
      debugPrint('Ошибка очистки старых рефералов: $e');
      return 0;
    }
  }
}
