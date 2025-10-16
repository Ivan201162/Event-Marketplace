import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class GrowthNotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Отправка уведомления о реферале
  Future<void> sendReferralNotification(
      String userId, Map<String, dynamic> referral) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'referral',
        'title': 'Новый реферал!',
        'message': 'Поздравляем! Кто-то зарегистрировался по вашей ссылке',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/referral-program',
        'actionText': 'Посмотреть программу',
        'data': {
          'referralId': referral['id'],
          'referralCode': referral['referralCode'],
          'bonusType': referral['bonusType'],
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Referral notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send referral notification: $e');
    }
  }

  /// Отправка уведомления о бонусе реферала
  Future<void> sendReferralBonusNotification(
      String userId, String bonusType, Map<String, dynamic> bonusData) async {
    try {
      String title = 'Бонус получен!';
      String message = '';

      switch (bonusType) {
        case 'freePromotion':
          message = 'Вы получили бесплатное продвижение профиля!';
          break;
        case 'discount':
          final double discount = (bonusData['discount'] ?? 0.0).toDouble();
          message = 'Вы получили скидку ${(discount * 100).toInt()}%!';
          break;
        case 'premiumTrial':
          final int days = bonusData['days'] ?? 0;
          message = 'Вы получили $days дней Premium бесплатно!';
          break;
        case 'proTrial':
          message = 'Вы получили месяц PRO бесплатно!';
          break;
        case 'cashback':
          final double amount = (bonusData['amount'] ?? 0.0).toDouble();
          message = 'Вы получили кэшбэк $amount рублей!';
          break;
        default:
          message = 'Вы получили бонус!';
      }

      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'referral',
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/referral-program',
        'actionText': 'Посмотреть программу',
        'data': {
          'bonusType': bonusType,
          'bonusData': bonusData,
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Referral bonus notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send referral bonus notification: $e');
    }
  }

  /// Отправка уведомления об изменении цены
  Future<void> sendPriceChangeNotification(
      String userId,
      Map<String, dynamic> pricingRule,
      double oldPrice,
      double newPrice) async {
    try {
      final double changePercent = ((newPrice - oldPrice) / oldPrice * 100);
      final String changeText =
          changePercent > 0 ? 'увеличилась' : 'уменьшилась';
      final String changeValue = changePercent.abs().toStringAsFixed(1);

      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'pricing',
        'title': 'Изменение цены',
        'message':
            'Цена на ${pricingRule['serviceType']} $changeText на $changeValue%',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'Посмотреть тарифы',
        'data': {
          'serviceType': pricingRule['serviceType'],
          'oldPrice': oldPrice,
          'newPrice': newPrice,
          'changePercent': changePercent,
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Price change notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send price change notification: $e');
    }
  }

  /// Отправка уведомления о партнерской комиссии
  Future<void> sendPartnerCommissionNotification(
      String userId, Map<String, dynamic> partnerTransaction) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'partnership',
        'title': 'Партнерская комиссия',
        'message':
            'Вы получили комиссию ${partnerTransaction['commissionAmount']} руб.',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/partnership',
        'actionText': 'Посмотреть партнерку',
        'data': {
          'partnerTransactionId': partnerTransaction['id'],
          'commissionAmount': partnerTransaction['commissionAmount'],
          'transactionId': partnerTransaction['transactionId'],
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Partner commission notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send partner commission notification: $e');
    }
  }

  /// Отправка уведомления о новом рекламном предложении
  Future<void> sendNewAdOfferNotification(
      String userId, Map<String, dynamic> adOffer) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'advertisement',
        'title': 'Новое рекламное предложение',
        'message': 'Специальное предложение для вашей категории!',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization/advertisements',
        'actionText': 'Посмотреть предложения',
        'data': {
          'adOffer': adOffer,
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] New ad offer notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send new ad offer notification: $e');
    }
  }

  /// Отправка уведомления о промо-кампании
  Future<void> sendPromotionNotification(
      String userId, Map<String, dynamic> promotion) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'promotion',
        'title': 'Специальное предложение!',
        'message': promotion['description'],
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'Воспользоваться',
        'data': {
          'promotionId': promotion['id'],
          'promotionName': promotion['name'],
          'trigger': promotion['trigger'],
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Promotion notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send promotion notification: $e');
    }
  }

  /// Отправка уведомления о чеке
  Future<void> sendReceiptNotification(
      String userId, Map<String, dynamic> receipt) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'receipt',
        'title': 'Чек готов!',
        'message':
            'Ваш чек на сумму ${receipt['amount']} ${receipt['currency']} готов к скачиванию',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/receipts/${receipt['id']}',
        'actionText': 'Скачать чек',
        'data': {
          'receiptId': receipt['id'],
          'amount': receipt['amount'],
          'currency': receipt['currency'],
          'receiptUrl': receipt['receiptUrl'],
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Receipt notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send receipt notification: $e');
    }
  }

  /// Отправка уведомления о новом челлендже
  Future<void> sendNewChallengeNotification(
      String userId, Map<String, dynamic> challenge) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'challenge',
        'title': 'Новый челлендж!',
        'message': challenge['description'],
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/challenges/${challenge['id']}',
        'actionText': 'Принять участие',
        'data': {
          'challengeId': challenge['id'],
          'challengeName': challenge['name'],
          'challengeType': challenge['type'],
          'endDate': challenge['endDate'],
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] New challenge notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send new challenge notification: $e');
    }
  }

  /// Отправка уведомления о прогрессе челленджа
  Future<void> sendChallengeProgressNotification(String userId,
      Map<String, dynamic> challenge, Map<String, dynamic> progress) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'challenge',
        'title': 'Прогресс в челлендже',
        'message':
            'Отличная работа! Вы приближаетесь к завершению "${challenge['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/challenges/${challenge['id']}',
        'actionText': 'Посмотреть прогресс',
        'data': {
          'challengeId': challenge['id'],
          'challengeName': challenge['name'],
          'progress': progress,
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Challenge progress notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send challenge progress notification: $e');
    }
  }

  /// Отправка уведомления о новом достижении
  Future<void> sendNewAchievementNotification(
      String userId, Map<String, dynamic> achievement) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'achievement',
        'title': 'Новое достижение!',
        'message':
            'Поздравляем! Вы получили достижение "${achievement['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/achievements',
        'actionText': 'Посмотреть достижения',
        'data': {
          'achievementId': achievement['id'],
          'achievementName': achievement['name'],
          'achievementType': achievement['type'],
          'points': achievement['points'],
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] New achievement notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send new achievement notification: $e');
    }
  }

  /// Отправка уведомления о новом значке
  Future<void> sendNewBadgeNotification(
      String userId, Map<String, dynamic> badge) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'badge',
        'title': 'Новый значок!',
        'message': 'Поздравляем! Вы получили значок "${badge['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/profile/badges',
        'actionText': 'Посмотреть значки',
        'data': {
          'badgeId': badge['id'],
          'badgeName': badge['name'],
          'badgeType': badge['type'],
          'badgeCategory': badge['category'],
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] New badge notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send new badge notification: $e');
    }
  }

  /// Отправка уведомления о A/B тесте
  Future<void> sendABTestNotification(String userId, String testName,
      String variant, Map<String, dynamic> testData) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'abTest',
        'title': 'Участие в тесте',
        'message': 'Вы участвуете в тесте "$testName" (вариант: $variant)',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/ab-tests',
        'actionText': 'Посмотреть тесты',
        'data': {
          'testName': testName,
          'variant': variant,
          'testData': testData,
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] AB test notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send AB test notification: $e');
    }
  }

  /// Отправка уведомления о сезонной акции
  Future<void> sendSeasonalPromotionNotification(
      String userId, String season, Map<String, dynamic> promotionData) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'seasonal',
        'title': 'Сезонная акция!',
        'message': 'Специальные предложения для $season сезона!',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'Посмотреть акции',
        'data': {
          'season': season,
          'promotionData': promotionData,
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Seasonal promotion notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send seasonal promotion notification: $e');
    }
  }

  /// Отправка уведомления о праздничной акции
  Future<void> sendHolidayPromotionNotification(
      String userId, String holiday, Map<String, dynamic> promotionData) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'holiday',
        'title': 'Праздничная акция!',
        'message': 'Специальные предложения к $holiday!',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'Посмотреть акции',
        'data': {
          'holiday': holiday,
          'promotionData': promotionData,
        },
      };

      await _firestore
          .collection('growth_notifications')
          .doc(notification['id'])
          .set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Holiday promotion notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send holiday promotion notification: $e');
    }
  }

  /// Получение уведомлений пользователя
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('growth_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Отметка уведомления как прочитанного
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('growth_notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'INFO: [GrowthNotificationsService] Notification $notificationId marked as read');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to mark notification as read: $e');
    }
  }

  /// Отметка всех уведомлений как прочитанных
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final QuerySnapshot unreadNotifications = await _firestore
          .collection('growth_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final WriteBatch batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint(
          'INFO: [GrowthNotificationsService] All notifications marked as read for user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to mark all notifications as read: $e');
    }
  }

  /// Удаление уведомления
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('growth_notifications')
          .doc(notificationId)
          .delete();
      debugPrint(
          'INFO: [GrowthNotificationsService] Notification $notificationId deleted');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to delete notification: $e');
    }
  }

  /// Получение количества непрочитанных уведомлений
  Stream<int> getUnreadNotificationsCountStream(String userId) {
    return _firestore
        .collection('growth_notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
