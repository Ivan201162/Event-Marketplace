import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/event_idea.dart';

/// Сервис для уведомлений о новых идеях
class IdeasNotificationService {
  static final IdeasNotificationService _instance = IdeasNotificationService._internal();
  factory IdeasNotificationService() => _instance;
  IdeasNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Инициализация локальных уведомлений
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Запрос разрешений
      await _requestPermissions();

      // Настройка обработчиков сообщений
      _setupMessageHandlers();

      _isInitialized = true;
      debugPrint('IdeasNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing IdeasNotificationService: $e');
    }
  }

  /// Запрос разрешений на уведомления
  Future<void> _requestPermissions() async {
    // Firebase Messaging разрешения
    final messagingSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Firebase Messaging permission status: ${messagingSettings.authorizationStatus}');

    // Локальные уведомления разрешения
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Обработка сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Обработка уведомлений при запуске приложения
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  /// Обработка сообщений в foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    if (message.data['type'] == 'new_idea') {
      await _showLocalNotification(
        title: message.notification?.title ?? 'Новая идея!',
        body: message.notification?.body ?? 'Посмотрите новую идею для мероприятия',
        payload: message.data['idea_id'],
      );
    }
  }

  /// Обработка нажатий на уведомления
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    
    final ideaId = message.data['idea_id'];
    if (ideaId != null) {
      // TODO: Навигация к идее
      debugPrint('Navigate to idea: $ideaId');
    }
  }

  /// Обработка нажатий на локальные уведомления
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      // TODO: Навигация к идее
      debugPrint('Navigate to idea: ${response.payload}');
    }
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ideas_channel',
      'Идеи мероприятий',
      channelDescription: 'Уведомления о новых идеях для мероприятий',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Подписаться на уведомления о новых идеях
  Future<void> subscribeToNewIdeas() async {
    try {
      await _firebaseMessaging.subscribeToTopic('new_ideas');
      debugPrint('Subscribed to new_ideas topic');
    } catch (e) {
      debugPrint('Error subscribing to new_ideas: $e');
    }
  }

  /// Отписаться от уведомлений о новых идеях
  Future<void> unsubscribeFromNewIdeas() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('new_ideas');
      debugPrint('Unsubscribed from new_ideas topic');
    } catch (e) {
      debugPrint('Error unsubscribing from new_ideas: $e');
    }
  }

  /// Подписаться на уведомления о популярных идеях
  Future<void> subscribeToPopularIdeas() async {
    try {
      await _firebaseMessaging.subscribeToTopic('popular_ideas');
      debugPrint('Subscribed to popular_ideas topic');
    } catch (e) {
      debugPrint('Error subscribing to popular_ideas: $e');
    }
  }

  /// Отписаться от уведомлений о популярных идеях
  Future<void> unsubscribeFromPopularIdeas() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('popular_ideas');
      debugPrint('Unsubscribed from popular_ideas topic');
    } catch (e) {
      debugPrint('Error unsubscribing from popular_ideas: $e');
    }
  }

  /// Подписаться на уведомления по типу мероприятия
  Future<void> subscribeToEventType(EventIdeaType type) async {
    try {
      await _firebaseMessaging.subscribeToTopic('event_type_${type.name}');
      debugPrint('Subscribed to event_type_${type.name} topic');
    } catch (e) {
      debugPrint('Error subscribing to event_type_${type.name}: $e');
    }
  }

  /// Отписаться от уведомлений по типу мероприятия
  Future<void> unsubscribeFromEventType(EventIdeaType type) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('event_type_${type.name}');
      debugPrint('Unsubscribed from event_type_${type.name} topic');
    } catch (e) {
      debugPrint('Error unsubscribing from event_type_${type.name}: $e');
    }
  }

  /// Получить FCM токен
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Показать уведомление о новой идее
  Future<void> showNewIdeaNotification(EventIdea idea) async {
    await _showLocalNotification(
      title: 'Новая идея: ${idea.title}',
      body: idea.description.length > 100 
          ? '${idea.description.substring(0, 100)}...'
          : idea.description,
      payload: idea.id,
    );
  }

  /// Показать уведомление о популярной идее
  Future<void> showPopularIdeaNotification(EventIdea idea) async {
    await _showLocalNotification(
      title: 'Популярная идея!',
      body: '${idea.title} набирает популярность (${idea.likesCount} лайков)',
      payload: idea.id,
    );
  }

  /// Показать уведомление о рекомендуемой идее
  Future<void> showFeaturedIdeaNotification(EventIdea idea) async {
    await _showLocalNotification(
      title: 'Рекомендуем посмотреть',
      body: '${idea.title} - идея, которая может вам понравиться',
      payload: idea.id,
    );
  }

  /// Настроить уведомления по расписанию
  Future<void> scheduleDailyIdeasNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_ideas_channel',
      'Ежедневные идеи',
      channelDescription: 'Ежедневные уведомления с идеями для мероприятий',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Уведомление каждый день в 10:00
    await _localNotifications.zonedSchedule(
      0,
      'Новые идеи ждут вас!',
      'Посмотрите свежие идеи для вашего мероприятия',
      _nextInstanceOfTime(10, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Получить следующий экземпляр времени
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Отменить все запланированные уведомления
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Получить статус разрешений
  Future<NotificationSettings> getPermissionStatus() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Проверить, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    final settings = await getPermissionStatus();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
