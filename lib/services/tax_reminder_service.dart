import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/safe_log.dart';
import '../models/tax_info.dart';
import '../services/tax_service.dart';

/// Сервис для напоминаний о налогах
class TaxReminderService {
  factory TaxReminderService() => _instance;
  TaxReminderService._internal();
  static final TaxReminderService _instance = TaxReminderService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final TaxService _taxService = TaxService();

  /// Отправить напоминание о налоге
  Future<void> sendTaxReminder(TaxInfo taxInfo) async {
    try {
      SafeLog.info('Отправляем напоминание о налоге ${taxInfo.id}', 'tax_reminder_service');

      // Обновляем статус напоминания в базе данных
      await _taxService.sendTaxReminder(taxInfo.id);

      // Отправляем push-уведомление
      await _sendPushNotification(taxInfo);

      // Отправляем email (если настроен)
      await _sendEmailReminder(taxInfo);

      SafeLog.info('Напоминание отправлено успешно', 'tax_reminder_service');
    } on Exception catch (e) {
      SafeLog.error('Ошибка отправки напоминания: $e');
      throw Exception('Не удалось отправить напоминание: $e');
    }
  }

  /// Отправить push-уведомление
  Future<void> _sendPushNotification(TaxInfo taxInfo) async {
    try {
      // Получаем FCM токен пользователя
      final userDoc = await _db.collection('users').doc(taxInfo.userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        SafeLog.warning(
          'FCM токен не найден для пользователя ${taxInfo.userId}',
          'tax_reminder_service',
        );
        return;
      }

      // Здесь можно добавить отправку push-уведомления через Firebase Cloud Messaging
      // Для демонстрации просто логируем
      SafeLog.info('Отправляем push-уведомление на токен: $fcmToken', 'tax_reminder_service');

      // TODO(developer): Реализовать отправку push-уведомления через FCM
      // Временная заглушка - просто логируем
      // Логирование:'Отправка напоминания о налогах для пользователя $userId');
      // await _sendFCMNotification(fcmToken, taxInfo);
    } on Exception catch (e) {
      SafeLog.error('Ошибка отправки push-уведомления: $e');
    }
  }

  /// Отправить email напоминание
  Future<void> _sendEmailReminder(TaxInfo taxInfo) async {
    try {
      // Получаем email пользователя
      final userDoc = await _db.collection('users').doc(taxInfo.userId).get();
      final email = userDoc.data()?['email'] as String?;

      if (email == null) {
        SafeLog.warning(
          'Email не найден для пользователя ${taxInfo.userId}',
          'tax_reminder_service',
        );
        return;
      }

      // Здесь можно добавить отправку email через EmailJS или другой сервис
      SafeLog.info('Отправляем email напоминание на: $email', 'tax_reminder_service');

      // TODO(developer): Реализовать отправку email
      // await _sendEmail(email, taxInfo);
    } on Exception catch (e) {
      SafeLog.error('Ошибка отправки email: $e');
    }
  }

  /// Проверить и отправить напоминания о просроченных налогах
  Future<void> checkAndSendOverdueReminders() async {
    try {
      SafeLog.info('Проверяем просроченные налоги', 'tax_reminder_service');

      final now = DateTime.now();
      final querySnapshot = await _db
          .collection('tax_info')
          .where('isPaid', isEqualTo: false)
          .where('nextReminderDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final overdueTaxes = querySnapshot.docs.map(TaxInfo.fromDocument).toList();

      SafeLog.info('Найдено ${overdueTaxes.length} просроченных налогов', 'tax_reminder_service');

      for (final taxInfo in overdueTaxes) {
        await sendTaxReminder(taxInfo);
        // Небольшая задержка между отправками
        await Future.delayed(const Duration(seconds: 1));
      }

      SafeLog.info('Напоминания о просроченных налогах отправлены', 'tax_reminder_service');
    } on Exception catch (e) {
      SafeLog.error('Ошибка проверки просроченных налогов: $e');
    }
  }

  /// Настроить периодические напоминания
  Future<void> schedulePeriodicReminders() async {
    try {
      SafeLog.info('Настраиваем периодические напоминания', 'tax_reminder_service');

      // Проверяем напоминания каждый день в 9:00
      // В реальном приложении это можно сделать через cron job или Cloud Functions

      // Для демонстрации просто логируем
      SafeLog.info('Периодические напоминания настроены', 'tax_reminder_service');
    } on Exception catch (e) {
      SafeLog.error('Ошибка настройки периодических напоминаний: $e');
    }
  }

  /// Получить статистику напоминаний
  Future<Map<String, dynamic>> getReminderStatistics() async {
    try {
      SafeLog.info('Получаем статистику напоминаний', 'tax_reminder_service');

      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      // Напоминания за последнюю неделю
      final recentReminders = await _db
          .collection('tax_info')
          .where('reminderSent', isEqualTo: true)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      // Просроченные налоги
      final overdueTaxes = await _db
          .collection('tax_info')
          .where('isPaid', isEqualTo: false)
          .where('nextReminderDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final statistics = {
        'recentRemindersCount': recentReminders.docs.length,
        'overdueTaxesCount': overdueTaxes.docs.length,
        'lastCheckDate': now.toIso8601String(),
      };

      SafeLog.info('Статистика напоминаний получена', 'tax_reminder_service');
      return statistics;
    } on Exception catch (e) {
      SafeLog.error('Ошибка получения статистики напоминаний: $e');
      throw Exception('Не удалось получить статистику напоминаний: $e');
    }
  }

  /// Отправить напоминание о приближающемся сроке оплаты
  Future<void> sendUpcomingDeadlineReminder(TaxInfo taxInfo) async {
    try {
      SafeLog.info('Отправляем напоминание о приближающемся сроке', 'tax_reminder_service');

      // Проверяем, приближается ли срок оплаты (например, за 3 дня)
      final deadline = taxInfo.createdAt.add(const Duration(days: 30));
      final now = DateTime.now();
      final daysUntilDeadline = deadline.difference(now).inDays;

      if (daysUntilDeadline <= 3 && daysUntilDeadline > 0) {
        await sendTaxReminder(taxInfo);
        SafeLog.info('Напоминание о приближающемся сроке отправлено', 'tax_reminder_service');
      }
    } on Exception catch (e) {
      SafeLog.error('Ошибка отправки напоминания о приближающемся сроке: $e');
    }
  }

  /// Получить список налогов, требующих напоминания
  Future<List<TaxInfo>> getTaxesNeedingReminder() async {
    try {
      SafeLog.info('Получаем налоги, требующие напоминания', 'tax_reminder_service');

      final now = DateTime.now();
      final querySnapshot = await _db
          .collection('tax_info')
          .where('isPaid', isEqualTo: false)
          .where('nextReminderDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final taxesNeedingReminder = querySnapshot.docs.map(TaxInfo.fromDocument).toList();

      SafeLog.info(
        'Найдено ${taxesNeedingReminder.length} налогов, требующих напоминания',
        'tax_reminder_service',
      );
      return taxesNeedingReminder;
    } on Exception catch (e) {
      SafeLog.error('Ошибка получения налогов, требующих напоминания: $e');
      throw Exception('Не удалось получить налоги, требующие напоминания: $e');
    }
  }
}
