import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/analytics_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Сервис для еженедельных отчётов и уведомлений
class WeeklyReportsService {
  factory WeeklyReportsService() => _instance;
  WeeklyReportsService._internal();
  static final WeeklyReportsService _instance =
      WeeklyReportsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      // Инициализация локальных уведомлений
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notifications.initialize(initSettings);

      // Запрос разрешений на уведомления
      await _messaging.requestPermission();

      // Логирование:'WeeklyReportsService инициализирован успешно');
    } on Exception {
      // Логирование:'Ошибка инициализации WeeklyReportsService: $e');
    }
  }

  /// Отправка еженедельного отчёта специалисту
  Future<void> sendSpecialistWeeklyReport(String specialistId) async {
    try {
      final stats = await _analyticsService.getUserStats(specialistId);
      if (stats == null) return;

      final views = (stats['views'] as int?) ?? 0;
      final requests = (stats['requests'] as int?) ?? 0;
      final messages = (stats['messages'] as int?) ?? 0;
      final likes = (stats['likes'] as int?) ?? 0;

      // Создаём отчёт
      final report = {
        'userId': specialistId,
        'type': 'specialist_weekly',
        'views': views,
        'requests': requests,
        'messages': messages,
        'likes': likes,
        'weekStart': DateTime.now().subtract(const Duration(days: 7)),
        'weekEnd': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Сохраняем отчёт в Firestore
      await _firestore.collection('weekly_reports').add(report);

      // Отправляем уведомление
      await _sendSpecialistNotification(specialistId, views, requests);

      // Логирование:'Еженедельный отчёт отправлен специалисту $specialistId');
    } on Exception {
      // Логирование:'Ошибка отправки отчёта специалисту: $e');
    }
  }

  /// Отправка еженедельного отчёта заказчику
  Future<void> sendCustomerWeeklyReport(String customerId) async {
    try {
      // Получаем статистику заказчика
      final requestsQuery = await _firestore
          .collection('analytics_events')
          .where('user_id', isEqualTo: customerId)
          .where('event_name', isEqualTo: 'create_request')
          .where('timestamp',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 7)),)
          .get();

      final totalRequests = requestsQuery.docs.length;

      // Получаем информацию о просмотрах заявок
      final viewedRequests = await _getViewedRequestsCount(customerId);

      // Создаём отчёт
      final report = {
        'userId': customerId,
        'type': 'customer_weekly',
        'totalRequests': totalRequests,
        'viewedRequests': viewedRequests,
        'weekStart': DateTime.now().subtract(const Duration(days: 7)),
        'weekEnd': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Сохраняем отчёт в Firestore
      await _firestore.collection('weekly_reports').add(report);

      // Отправляем уведомление
      await _sendCustomerNotification(
          customerId, totalRequests, viewedRequests,);

      // Логирование:'Еженедельный отчёт отправлен заказчику $customerId');
    } on Exception {
      // Логирование:'Ошибка отправки отчёта заказчику: $e');
    }
  }

  /// Отправка уведомления специалисту
  Future<void> _sendSpecialistNotification(
      String specialistId, int views, int requests,) async {
    try {
      const title = '📊 Ваша недельная статистика';
      final body =
          'Ваш профиль просмотрели $views раз, получено $requests заявок';

      // Локальное уведомление
      await _notifications.show(
        specialistId.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_reports',
            'Еженедельные отчёты',
            channelDescription: 'Уведомления о еженедельной статистике',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );

      // Push-уведомление через FCM
      await _sendPushNotification(specialistId, title, body);
    } on Exception {
      // Логирование:'Ошибка отправки уведомления специалисту: $e');
    }
  }

  /// Отправка уведомления заказчику
  Future<void> _sendCustomerNotification(
    String customerId,
    int totalRequests,
    int viewedRequests,
  ) async {
    try {
      const title = '📈 Ваша активность за неделю';
      final body =
          'Создано $totalRequests заявок, просмотрено $viewedRequests специалистами';

      // Локальное уведомление
      await _notifications.show(
        customerId.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_reports',
            'Еженедельные отчёты',
            channelDescription: 'Уведомления о еженедельной статистике',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );

      // Push-уведомление через FCM
      await _sendPushNotification(customerId, title, body);
    } on Exception {
      // Логирование:'Ошибка отправки уведомления заказчику: $e');
    }
  }

  /// Отправка push-уведомления через FCM
  Future<void> _sendPushNotification(
      String userId, String title, String body,) async {
    try {
      // Получаем FCM токен пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) return;

      // Отправляем уведомление через Cloud Functions
      await _firestore.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'type': 'weekly_report',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Exception {
      // Логирование:'Ошибка отправки push-уведомления: $e');
    }
  }

  /// Получение количества просмотренных заявок
  Future<int> _getViewedRequestsCount(String customerId) async {
    try {
      final requestsQuery = await _firestore
          .collection('requests')
          .where('customerId', isEqualTo: customerId)
          .where('createdAt',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 7)),)
          .get();

      var viewedCount = 0;
      for (final doc in requestsQuery.docs) {
        final data = doc.data();
        final views = data['views'] as int? ?? 0;
        viewedCount += views;
      }

      return viewedCount;
    } on Exception {
      // Логирование:'Ошибка получения количества просмотренных заявок: $e');
      return 0;
    }
  }

  /// Отправка отчётов всем активным пользователям
  Future<void> sendWeeklyReportsToAllUsers() async {
    try {
      // Логирование:'Начинаем отправку еженедельных отчётов...');

      // Получаем всех активных пользователей
      final usersQuery = await _firestore
          .collection('users')
          .where('lastActiveAt',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 30)),)
          .get();

      var specialistCount = 0;
      var customerCount = 0;

      for (final doc in usersQuery.docs) {
        final userData = doc.data();
        final userId = doc.id;
        final userRole = userData['role'] as String?;

        try {
          if (userRole == 'specialist') {
            await sendSpecialistWeeklyReport(userId);
            specialistCount++;
          } else if (userRole == 'customer') {
            await sendCustomerWeeklyReport(userId);
            customerCount++;
          }

          // Небольшая задержка между отправками
          await Future.delayed(const Duration(milliseconds: 100));
        } on Exception {
          // Логирование:'Ошибка отправки отчёта пользователю $userId: $e');
        }
      }

      // Логирование:'Еженедельные отчёты отправлены: $specialistCount специалистам, $customerCount заказчикам');
    } on Exception {
      // Логирование:'Ошибка массовой отправки отчётов: $e');
    }
  }

  /// Получение истории отчётов пользователя
  Future<List<Map<String, dynamic>>> getUserReportsHistory(
      String userId,) async {
    try {
      final reportsQuery = await _firestore
          .collection('weekly_reports')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return reportsQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } on Exception {
      // Логирование:'Ошибка получения истории отчётов: $e');
      return [];
    }
  }

  /// Создание мини-отчёта за 7 дней для отображения в приложении
  Future<Map<String, dynamic>?> getMiniReport(String userId) async {
    try {
      final stats = await _analyticsService.getUserStats(userId);
      if (stats == null) return null;

      final views = (stats['views'] as int?) ?? 0;
      final requests = (stats['requests'] as int?) ?? 0;
      final messages = (stats['messages'] as int?) ?? 0;
      final likes = (stats['likes'] as int?) ?? 0;

      return {
        'views': views,
        'requests': requests,
        'messages': messages,
        'likes': likes,
        'period': '7 дней',
        'generatedAt': DateTime.now(),
      };
    } on Exception {
      // Логирование:'Ошибка создания мини-отчёта: $e');
      return null;
    }
  }

  /// Планировщик еженедельных отчётов (для использования в Cloud Functions)
  Future<void> scheduleWeeklyReports() async {
    try {
      // Проверяем, не отправлялись ли отчёты на этой неделе
      final lastReportQuery = await _firestore
          .collection('system_settings')
          .doc('weekly_reports')
          .get();

      final lastReportDate = lastReportQuery.data()?['lastSent'] as Timestamp?;
      final now = DateTime.now();

      if (lastReportDate != null) {
        final daysSinceLastReport =
            now.difference(lastReportDate.toDate()).inDays;
        if (daysSinceLastReport < 7) {
          // Логирование:'Отчёты уже отправлялись на этой неделе');
          return;
        }
      }

      // Отправляем отчёты
      await sendWeeklyReportsToAllUsers();

      // Обновляем дату последней отправки
      await _firestore.collection('system_settings').doc('weekly_reports').set({
        'lastSent': FieldValue.serverTimestamp(),
        'lastSentDate': now.toIso8601String(),
      });

      // Логирование:'Еженедельные отчёты запланированы и отправлены');
    } on Exception {
      // Логирование:'Ошибка планирования еженедельных отчётов: $e');
    }
  }
}
