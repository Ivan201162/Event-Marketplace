import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist.dart';
import '../models/notification.dart';

/// Сервис для напоминаний об обновлении цен
class PriceReminderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Отправить напоминание специалисту об обновлении цен
  Future<void> sendPriceUpdateReminder(String specialistId) async {
    try {
      final specialist = await _getSpecialist(specialistId);
      if (specialist == null) return;

      // Проверяем, когда последний раз обновлялись цены
      final lastPriceUpdate = specialist.lastPriceUpdate;
      final now = DateTime.now();
      
      if (lastPriceUpdate != null) {
        final daysSinceUpdate = now.difference(lastPriceUpdate).inDays;
        
        // Отправляем напоминание, если цены не обновлялись более 30 дней
        if (daysSinceUpdate < 30) {
          debugPrint('Цены обновлялись недавно, напоминание не отправляется');
          return;
        }
      }

      // Создаем уведомление
      final notification = Notification(
        id: _generateNotificationId(),
        userId: specialistId,
        type: NotificationType.priceReminder,
        title: 'Обновите ваши цены',
        message: 'Рекомендуем обновить цены на ваши услуги для привлечения большего количества клиентов',
        data: {
          'specialistId': specialistId,
          'action': 'update_prices',
          'lastUpdate': lastPriceUpdate?.toIso8601String(),
        },
        createdAt: now,
        isRead: false,
      );

      // Сохраняем уведомление в базе данных
      await _db.collection('notifications').doc(notification.id).set(notification.toMap());

      // Отправляем push-уведомление
      await _sendPushNotification(specialistId, notification);

      // Обновляем время последнего напоминания
      await _updateLastReminderTime(specialistId);

      debugPrint('Напоминание об обновлении цен отправлено специалисту: $specialistId');
    } catch (e) {
      debugPrint('Ошибка отправки напоминания об обновлении цен: $e');
    }
  }

  /// Отправить массовые напоминания всем специалистам
  Future<void> sendBulkPriceUpdateReminders() async {
    try {
      // Получаем всех специалистов, которые не обновляли цены более 30 дней
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final specialistsQuery = await _db
          .collection('specialists')
          .where('lastPriceUpdate', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .limit(100) // Ограничиваем количество для избежания таймаутов
          .get();

      final specialists = specialistsQuery.docs
          .map((doc) => Specialist.fromDocument(doc))
          .toList();

      debugPrint('Найдено ${specialists.length} специалистов для отправки напоминаний');

      // Отправляем напоминания пакетами по 10
      for (int i = 0; i < specialists.length; i += 10) {
        final batch = specialists.skip(i).take(10);
        
        await Future.wait(
          batch.map((specialist) => sendPriceUpdateReminder(specialist.id)),
        );

        // Небольшая пауза между пакетами
        await Future.delayed(const Duration(seconds: 1));
      }

      debugPrint('Массовые напоминания об обновлении цен отправлены');
    } catch (e) {
      debugPrint('Ошибка отправки массовых напоминаний: $e');
    }
  }

  /// Получить специалистов, которым нужно отправить напоминания
  Future<List<Specialist>> getSpecialistsNeedingPriceReminders() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final query = await _db
          .collection('specialists')
          .where('lastPriceUpdate', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => Specialist.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения специалистов для напоминаний: $e');
      return [];
    }
  }

  /// Отметить, что специалист обновил цены
  Future<void> markPricesUpdated(String specialistId) async {
    try {
      await _db.collection('specialists').doc(specialistId).update({
        'lastPriceUpdate': Timestamp.fromDate(DateTime.now()),
        'lastReminderSent': null, // Сбрасываем время последнего напоминания
      });

      debugPrint('Цены специалиста отмечены как обновленные: $specialistId');
    } catch (e) {
      debugPrint('Ошибка отметки обновления цен: $e');
    }
  }

  /// Получить статистику напоминаний
  Future<Map<String, dynamic>> getReminderStats() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Специалисты, которым нужно отправить напоминания
      final needRemindersQuery = await _db
          .collection('specialists')
          .where('lastPriceUpdate', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .where('isActive', isEqualTo: true)
          .get();

      // Специалисты, которые обновили цены за последние 7 дней
      final recentUpdatesQuery = await _db
          .collection('specialists')
          .where('lastPriceUpdate', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // Напоминания, отправленные за последние 7 дней
      final recentRemindersQuery = await _db
          .collection('notifications')
          .where('type', isEqualTo: NotificationType.priceReminder.name)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      return {
        'specialistsNeedingReminders': needRemindersQuery.docs.length,
        'recentPriceUpdates': recentUpdatesQuery.docs.length,
        'remindersSentThisWeek': recentRemindersQuery.docs.length,
        'lastBulkReminderSent': await _getLastBulkReminderTime(),
      };
    } catch (e) {
      debugPrint('Ошибка получения статистики напоминаний: $e');
      return {};
    }
  }

  /// Настроить автоматические напоминания
  Future<void> setupAutomaticReminders() async {
    try {
      // Создаем Cloud Function для автоматических напоминаний
      final callable = _functions.httpsCallable('setupPriceReminders');
      
      await callable.call({
        'enabled': true,
        'intervalDays': 30,
        'maxRemindersPerDay': 50,
      });

      debugPrint('Автоматические напоминания настроены');
    } catch (e) {
      debugPrint('Ошибка настройки автоматических напоминаний: $e');
    }
  }

  /// Отключить автоматические напоминания
  Future<void> disableAutomaticReminders() async {
    try {
      final callable = _functions.httpsCallable('setupPriceReminders');
      
      await callable.call({
        'enabled': false,
      });

      debugPrint('Автоматические напоминания отключены');
    } catch (e) {
      debugPrint('Ошибка отключения автоматических напоминаний: $e');
    }
  }

  /// Получить специалиста
  Future<Specialist?> _getSpecialist(String specialistId) async {
    try {
      final doc = await _db.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения специалиста: $e');
      return null;
    }
  }

  /// Отправить push-уведомление
  Future<void> _sendPushNotification(String specialistId, Notification notification) async {
    try {
      // Получаем FCM токен специалиста
      final specialistDoc = await _db.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return;

      final fcmToken = specialistDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) return;

      // Отправляем уведомление через Cloud Functions
      final callable = _functions.httpsCallable('sendPushNotification');
      
      await callable.call({
        'token': fcmToken,
        'title': notification.title,
        'body': notification.message,
        'data': notification.data,
      });

      debugPrint('Push-уведомление отправлено: $specialistId');
    } catch (e) {
      debugPrint('Ошибка отправки push-уведомления: $e');
    }
  }

  /// Обновить время последнего напоминания
  Future<void> _updateLastReminderTime(String specialistId) async {
    try {
      await _db.collection('specialists').doc(specialistId).update({
        'lastReminderSent': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка обновления времени напоминания: $e');
    }
  }

  /// Получить время последнего массового напоминания
  Future<DateTime?> _getLastBulkReminderTime() async {
    try {
      final doc = await _db.collection('system_settings').doc('price_reminders').get();
      if (doc.exists) {
        final data = doc.data()!;
        final timestamp = data['lastBulkReminderSent'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения времени последнего массового напоминания: $e');
      return null;
    }
  }

  /// Сгенерировать ID уведомления
  String _generateNotificationId() {
    return 'price_reminder_${DateTime.now().millisecondsSinceEpoch}';
  }
}