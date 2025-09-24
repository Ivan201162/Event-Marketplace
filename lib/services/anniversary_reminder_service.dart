import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_profile.dart';
import '../models/notification.dart';

/// Сервис для напоминаний о годовщинах и важных датах
class AnniversaryReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Проверить напоминания о важных датах
  Future<void> checkAnniversaryReminders() async {
    try {
      // Получаем всех заказчиков с включенными напоминаниями
      final customersQuery = await _firestore
          .collection('customer_profiles')
          .where('anniversaryRemindersEnabled', isEqualTo: true)
          .get();

      for (final doc in customersQuery.docs) {
        final profile = CustomerProfile.fromDocument(doc);
        await _checkCustomerAnniversaryReminders(profile);
      }
    } catch (e) {
      debugPrint('Error checking anniversary reminders: $e');
    }
  }

  /// Проверить напоминания для конкретного заказчика
  Future<void> _checkCustomerAnniversaryReminders(CustomerProfile profile) async {
    try {
      final now = DateTime.now();
      
      for (final importantDate in profile.importantDates) {
        if (!importantDate.isActive) continue;
        
        final daysUntil = importantDate.daysUntil(now);
        
        // Проверяем, нужно ли отправить напоминание
        if (daysUntil >= 0 && importantDate.reminderDays.contains(daysUntil)) {
          await _sendAnniversaryReminder(profile, importantDate, daysUntil);
        }
      }
    } catch (e) {
      debugPrint('Error checking customer anniversary reminders: $e');
    }
  }

  /// Отправить напоминание о годовщине
  Future<void> _sendAnniversaryReminder(
    CustomerProfile profile,
    ImportantDate importantDate,
    int daysUntil,
  ) async {
    try {
      // Проверяем, не отправляли ли уже напоминание
      final reminderQuery = await _firestore
          .collection('anniversary_reminders')
          .where('customerId', isEqualTo: profile.userId)
          .where('importantDateId', isEqualTo: importantDate.id)
          .where('daysUntil', isEqualTo: daysUntil)
          .where('sentAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
          .get();

      if (reminderQuery.docs.isNotEmpty) {
        return; // Уже отправляли напоминание
      }

      String title;
      String body;

      if (daysUntil == 0) {
        title = 'Сегодня важная дата!';
        body = 'Сегодня ${importantDate.title}! Не забудьте поздравить близких.';
      } else if (daysUntil == 1) {
        title = 'Завтра важная дата';
        body = 'Завтра ${importantDate.title}. Подготовьтесь к празднованию!';
      } else if (daysUntil == 7) {
        title = 'Через неделю важная дата';
        body = 'Через неделю ${importantDate.title}. Время планировать!';
      } else if (daysUntil == 30) {
        title = 'Через месяц важная дата';
        body = 'Через месяц ${importantDate.title}. Начните подготовку!';
      } else {
        title = 'Напоминание о важной дате';
        body = 'Через $daysUntil дней ${importantDate.title}.';
      }

      // Отправляем push-уведомление
      await _sendPushNotification(profile.userId, title, body);

      // Создаем уведомление в приложении
      await _createInAppNotification(
        profile.userId,
        title,
        body,
        NotificationType.anniversary,
        {
          'importantDateId': importantDate.id,
          'daysUntil': daysUntil,
        },
      );

      // Сохраняем запись о напоминании
      await _saveReminderRecord(profile.userId, importantDate.id, daysUntil);
    } catch (e) {
      debugPrint('Error sending anniversary reminder: $e');
    }
  }

  /// Отправить напоминание о годовщине свадьбы
  Future<void> sendWeddingAnniversaryReminder(CustomerProfile profile) async {
    try {
      if (profile.weddingDate == null || !profile.anniversaryRemindersEnabled) {
        return;
      }

      final now = DateTime.now();
      final weddingDate = profile.weddingDate!;
      
      // Проверяем, является ли сегодня годовщиной свадьбы
      if (now.month == weddingDate.month && now.day == weddingDate.day) {
        final yearsOfMarriage = profile.yearsOfMarriage ?? 0;
        
        String title;
        String body;
        
        if (yearsOfMarriage == 0) {
          title = 'С годовщиной свадьбы!';
          body = 'Поздравляем с первой годовщиной свадьбы! 🎉';
        } else if (yearsOfMarriage == 1) {
          title = 'С годовщиной свадьбы!';
          body = 'Поздравляем с первой годовщиной свадьбы! 🎉';
        } else {
          title = 'С годовщиной свадьбы!';
          body = 'Поздравляем с ${yearsOfMarriage}-й годовщиной свадьбы! 🎉';
        }

        // Отправляем push-уведомление
        await _sendPushNotification(profile.userId, title, body);

        // Создаем уведомление в приложении
        await _createInAppNotification(
          profile.userId,
          title,
          body,
          NotificationType.anniversary,
          {
            'type': 'wedding_anniversary',
            'yearsOfMarriage': yearsOfMarriage,
          },
        );
      }
    } catch (e) {
      debugPrint('Error sending wedding anniversary reminder: $e');
    }
  }

  /// Отправить напоминание о дне рождения
  Future<void> sendBirthdayReminder(CustomerProfile profile) async {
    try {
      if (profile.dateOfBirth == null) return;

      final now = DateTime.now();
      final birthDate = profile.dateOfBirth!;
      
      // Проверяем, является ли сегодня днем рождения
      if (now.month == birthDate.month && now.day == birthDate.day) {
        final age = profile.age ?? 0;
        
        String title;
        String body;
        
        if (age == 0) {
          title = 'С днем рождения!';
          body = 'Поздравляем с днем рождения! 🎂';
        } else {
          title = 'С днем рождения!';
          body = 'Поздравляем с $age-летием! 🎂';
        }

        // Отправляем push-уведомление
        await _sendPushNotification(profile.userId, title, body);

        // Создаем уведомление в приложении
        await _createInAppNotification(
          profile.userId,
          title,
          body,
          NotificationType.anniversary,
          {
            'type': 'birthday',
            'age': age,
          },
        );
      }
    } catch (e) {
      debugPrint('Error sending birthday reminder: $e');
    }
  }

  /// Отправить напоминание о предстоящем событии
  Future<void> sendUpcomingEventReminder(CustomerProfile profile, ImportantDate importantDate) async {
    try {
      final now = DateTime.now();
      final daysUntil = importantDate.daysUntil(now);
      
      if (daysUntil < 0) return;

      String title;
      String body;

      if (daysUntil == 0) {
        title = 'Сегодня ${importantDate.title}!';
        body = 'Не забудьте о важном событии сегодня.';
      } else if (daysUntil == 1) {
        title = 'Завтра ${importantDate.title}';
        body = 'Подготовьтесь к завтрашнему событию.';
      } else if (daysUntil <= 7) {
        title = 'Через $daysUntil дней ${importantDate.title}';
        body = 'Время готовиться к важному событию.';
      } else {
        return; // Не отправляем напоминания за более чем неделю
      }

      // Отправляем push-уведомление
      await _sendPushNotification(profile.userId, title, body);

      // Создаем уведомление в приложении
      await _createInAppNotification(
        profile.userId,
        title,
        body,
        NotificationType.anniversary,
        {
          'importantDateId': importantDate.id,
          'daysUntil': daysUntil,
        },
      );
    } catch (e) {
      debugPrint('Error sending upcoming event reminder: $e');
    }
  }

  /// Отправить push-уведомление
  Future<void> _sendPushNotification(String userId, String title, String body) async {
    try {
      // Получаем FCM токен пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) return;

      // Отправляем уведомление через Cloud Functions
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'anniversary',
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'sent': false,
      });
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  /// Создать уведомление в приложении
  Future<void> _createInAppNotification(
    String userId,
    String title,
    String body,
    NotificationType type,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('user_notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'data': data,
      });
    } catch (e) {
      debugPrint('Error creating in-app notification: $e');
    }
  }

  /// Сохранить запись о напоминании
  Future<void> _saveReminderRecord(String customerId, String importantDateId, int daysUntil) async {
    try {
      await _firestore.collection('anniversary_reminders').add({
        'customerId': customerId,
        'importantDateId': importantDateId,
        'daysUntil': daysUntil,
        'sentAt': Timestamp.fromDate(DateTime.now()),
        'status': 'sent',
      });
    } catch (e) {
      debugPrint('Error saving reminder record: $e');
    }
  }

  /// Получить историю напоминаний
  Future<List<Map<String, dynamic>>> getReminderHistory(String customerId) async {
    try {
      final remindersQuery = await _firestore
          .collection('anniversary_reminders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();

      return remindersQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'importantDateId': data['importantDateId'],
          'daysUntil': data['daysUntil'],
          'sentAt': (data['sentAt'] as Timestamp).toDate(),
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting reminder history: $e');
      return [];
    }
  }

  /// Настроить напоминания для заказчика
  Future<void> setupAnniversaryReminders(String customerId, {
    bool enabled = true,
    List<int> reminderDays = const [1, 7, 30],
  }) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'anniversaryRemindersEnabled': enabled,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем настройки напоминаний для всех важных дат
      if (enabled) {
        final profile = CustomerProfile.fromDocument(profileDoc);
        for (final importantDate in profile.importantDates) {
          await _firestore.collection('customer_profiles').doc(profileDoc.id).update({
            'importantDates': profile.importantDates.map((date) {
              if (date.id == importantDate.id) {
                return date.copyWith(
                  reminderDays: reminderDays,
                ).toMap();
              }
              return date.toMap();
            }).toList(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error setting up anniversary reminders: $e');
      throw Exception('Ошибка настройки напоминаний о годовщинах: $e');
    }
  }

  /// Отключить напоминания для заказчика
  Future<void> disableAnniversaryReminders(String customerId) async {
    try {
      await setupAnniversaryReminders(customerId, enabled: false);
    } catch (e) {
      debugPrint('Error disabling anniversary reminders: $e');
      throw Exception('Ошибка отключения напоминаний о годовщинах: $e');
    }
  }

  /// Получить настройки напоминаний
  Future<Map<String, dynamic>?> getReminderSettings(String customerId) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) return null;

      final profile = CustomerProfile.fromDocument(profileQuery.docs.first);
      
      return {
        'enabled': profile.anniversaryRemindersEnabled,
        'importantDatesCount': profile.importantDates.length,
        'upcomingDatesCount': profile.upcomingImportantDates.length,
      };
    } catch (e) {
      debugPrint('Error getting reminder settings: $e');
      return null;
    }
  }

  /// Получить статистику напоминаний
  Future<Map<String, dynamic>> getReminderStats(String customerId) async {
    try {
      final remindersQuery = await _firestore
          .collection('anniversary_reminders')
          .where('customerId', isEqualTo: customerId)
          .get();

      final totalReminders = remindersQuery.docs.length;
      final todayReminders = remindersQuery.docs.where((doc) {
        final sentAt = (doc.data()['sentAt'] as Timestamp).toDate();
        final now = DateTime.now();
        return sentAt.year == now.year && sentAt.month == now.month && sentAt.day == now.day;
      }).length;

      return {
        'totalReminders': totalReminders,
        'todayReminders': todayReminders,
        'lastReminder': remindersQuery.docs.isNotEmpty 
            ? (remindersQuery.docs.first.data()['sentAt'] as Timestamp).toDate()
            : null,
      };
    } catch (e) {
      debugPrint('Error getting reminder stats: $e');
      return {};
    }
  }

  /// Запустить периодическую проверку напоминаний
  Future<void> startPeriodicReminderCheck() async {
    try {
      // Запускаем проверку каждые 24 часа
      await _firestore.collection('system_jobs').doc('anniversary_reminder_check').set({
        'lastRun': Timestamp.fromDate(DateTime.now()),
        'nextRun': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        'status': 'active',
        'type': 'anniversary_reminder_check',
      });
    } catch (e) {
      debugPrint('Error starting periodic reminder check: $e');
    }
  }
}
