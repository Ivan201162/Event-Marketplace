import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/specialist.dart';
import '../models/app_user.dart';

/// Сервис для работы с Firebase Cloud Messaging
class FCMService {
  factory FCMService() => _instance;
  FCMService._internal();
  static final FCMService _instance = FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  /// Инициализация FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Инициализация локальных уведомлений
      await _initializeLocalNotifications();

      // Запрос разрешений
      await _requestPermissions();

      // Получение FCM токена
      await _getFCMToken();

      // Настройка обработчиков сообщений
      _setupMessageHandlers();

      _isInitialized = true;
      print('FCM Service initialized successfully');
    } catch (e) {
      print('Error initializing FCM Service: $e');
    }
  }

  /// Инициализация локальных уведомлений
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Создание канала для Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Запрос разрешений
  Future<void> _requestPermissions() async {
    // Запрос разрешений для FCM
    final settings = await _firebaseMessaging.requestPermission();

    print('User granted permission: ${settings.authorizationStatus}');

    // Запрос разрешений для локальных уведомлений
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Получение FCM токена
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      // Сохранение токена в SharedPreferences
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Обработка сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка сообщений при нажатии на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Обработка сообщений при запуске приложения из уведомления
    _handleInitialMessage();
  }

  /// Обработка сообщений в foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Показать локальное уведомление
    await _showLocalNotification(message);
  }

  /// Обработка сообщений при нажатии на уведомление
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');
    _handleNotificationTap(message);
  }

  /// Обработка сообщений при запуске приложения из уведомления
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App launched from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    // final android = message.notification?.android;

    if (notification != null) {
      // await _localNotifications.show(
      //   message.hashCode,
      //   notification.title,
      //   notification.body,
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'high_importance_channel',
      //       'High Importance Notifications',
      //       channelDescription:
      //           'This channel is used for important notifications.',
      //       importance: Importance.high,
      //       priority: Priority.high,
      //       icon: '@mipmap/ic_launcher',
      //     ),
      //     iOS: const DarwinNotificationDetails(
      //       presentAlert: true,
      //       presentBadge: true,
      //       presentSound: true,
      //     ),
      //   ),
      //   payload: message.data.toString(),
      // );
    }
  }

  /// Обработка нажатия на уведомление
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    // Обработка различных типов уведомлений
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'booking_confirmed':
          _navigateToBooking(data['bookingId'] as String?);
          break;
        case 'booking_rejected':
          _navigateToBooking(data['bookingId'] as String?);
          break;
        case 'payment_completed':
          _navigateToPayment(data['paymentId'] as String?);
          break;
        case 'chat_message':
          _navigateToChat(data['chatId'] as String?);
          break;
        default:
          _navigateToHome();
      }
    } else {
      _navigateToHome();
    }
  }

  /// Обработка нажатия на локальное уведомление
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Здесь можно добавить логику обработки нажатия на локальное уведомление
  }

  /// Навигация к заявке
  void _navigateToBooking(String? bookingId) {
    if (bookingId != null) {
      // TODO: Реализовать навигацию к заявке
      print('Navigate to booking: $bookingId');
    }
  }

  /// Навигация к платежу
  void _navigateToPayment(String? paymentId) {
    if (paymentId != null) {
      // TODO: Реализовать навигацию к платежу
      print('Navigate to payment: $paymentId');
    }
  }

  /// Навигация к чату
  void _navigateToChat(String? chatId) {
    if (chatId != null) {
      // TODO: Реализовать навигацию к чату
      print('Navigate to chat: $chatId');
    }
  }

  /// Навигация на главную
  void _navigateToHome() {
    // TODO: Реализовать навигацию на главную
    print('Navigate to home');
  }

  /// Получить FCM токен
  String? get fcmToken => _fcmToken;

  /// Обновить FCM токен
  Future<String?> refreshToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      print('Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Подписаться на топик
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Отписаться от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Показать локальное уведомление
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    // await _localNotifications.show(
    //   id,
    //   title,
    //   body,
    //   NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'high_importance_channel',
    //       'High Importance Notifications',
    //       channelDescription:
    //           'This channel is used for important notifications.',
    //       importance: Importance.high,
    //       priority: Priority.high,
    //       icon: '@mipmap/ic_launcher',
    //     ),
    //     iOS: const DarwinNotificationDetails(
    //       presentAlert: true,
    //       presentBadge: true,
    //       presentSound: true,
    //     ),
    //   ),
    //   payload: payload ?? data?.toString(),
    // );
  }

  /// Планировать локальное уведомление
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_marketplace',
          'Event Marketplace Notifications',
          channelDescription: 'Уведомления о событиях',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Отменить запланированное уведомление
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Отменить все запланированные уведомления
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Получить настройки уведомлений
  Future<NotificationSettings> getNotificationSettings() async =>
      _firebaseMessaging.getNotificationSettings();

  /// Проверить, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Открыть настройки уведомлений
  Future<void> openNotificationSettings() async {
    // await _localNotifications
    //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    //     ?.openNotificationSettings();
    print('Notification settings opened');
  }

  /// Сохранить FCM токен пользователя в Firestore
  Future<void> saveUserFCMToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
      print('FCM token saved for user: $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Отправить уведомление о бронировании
  Future<void> sendBookingNotification({
    required String userId,
    required String title,
    required String body,
    required String bookingId,
    required String
        type, // 'booking_created', 'booking_confirmed', 'booking_rejected', 'booking_cancelled'
  }) async {
    try {
      // В реальном приложении здесь был бы HTTP запрос к FCM API
      // Для демонстрации показываем локальное уведомление
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        data: {
          'type': type,
          'bookingId': bookingId,
          'userId': userId,
        },
      );
    } catch (e) {
      print('Error sending booking notification: $e');
    }
  }

  /// Подписаться на уведомления о бронированиях
  Future<void> subscribeToBookingNotifications(String userId) async {
    try {
      await subscribeToTopic('bookings_$userId');
      await subscribeToTopic('bookings_all');
    } catch (e) {
      print('Error subscribing to booking notifications: $e');
    }
  }

  /// Отписаться от уведомлений о бронированиях
  Future<void> unsubscribeFromBookingNotifications(String userId) async {
    try {
      await unsubscribeFromTopic('bookings_$userId');
      await unsubscribeFromTopic('bookings_all');
    } catch (e) {
      print('Error unsubscribing from booking notifications: $e');
    }
  }

  /// Отправить локальное уведомление
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_marketplace',
            'Event Marketplace Notifications',
            channelDescription: 'Уведомления о событиях',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      print('Error sending local notification: $e');
    }
  }

  // ========== УМНЫЕ УВЕДОМЛЕНИЯ И РЕКОМЕНДАЦИИ ==========

  /// Отправить напоминание специалисту об обновлении цен
  Future<void> sendPriceUpdateReminder(String specialistId) async {
    try {
      final specialistDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(specialistId)
          .get();
      
      if (!specialistDoc.exists) return;
      
      final specialist = specialistDoc.data()!;
      final lastPriceUpdate = specialist['lastPriceUpdate'] as Timestamp?;
      final now = DateTime.now();
      
      // Проверяем, прошло ли 7 дней с последнего обновления цен
      if (lastPriceUpdate != null) {
        final daysSinceUpdate = now.difference(lastPriceUpdate.toDate()).inDays;
        if (daysSinceUpdate < 7) return;
      }
      
      await sendLocalNotification(
        title: 'Обновите ваши цены',
        body: 'Прошло ${lastPriceUpdate != null ? now.difference(lastPriceUpdate.toDate()).inDays : 7}+ дней с последнего обновления цен. Обновите их для привлечения новых клиентов!',
        payload: 'price_update_reminder',
      );
      
      // Обновляем время последнего напоминания
      await FirebaseFirestore.instance
          .collection('specialists')
          .doc(specialistId)
          .update({'lastPriceReminder': Timestamp.now()});
          
    } catch (e) {
      print('Error sending price update reminder: $e');
    }
  }

  /// Отправить напоминание заказчику об оплате
  Future<void> sendPaymentReminder(String customerId, String bookingId) async {
    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      
      if (!bookingDoc.exists) return;
      
      final booking = bookingDoc.data()!;
      final eventDate = (booking['eventDate'] as Timestamp).toDate();
      final now = DateTime.now();
      
      // Напоминаем за 3 дня до события
      if (eventDate.difference(now).inDays == 3) {
        // await _localNotifications.show(
        //   title: 'Напоминание об оплате',
        //   body: 'До вашего события осталось 3 дня. Не забудьте произвести оплату!',
        //   payload: 'payment_reminder_$bookingId',
        // );
      }
      
    } catch (e) {
      print('Error sending payment reminder: $e');
    }
  }

  /// Отправить cross-sell рекомендацию
  Future<void> sendCrossSellRecommendation(String customerId, List<String> selectedCategories) async {
    try {
      // Определяем недостающие категории для полного пакета
      final allCategories = ['ведущий', 'диджей', 'фотограф', 'видеограф', 'декоратор', 'контент-мейкер'];
      final missingCategories = allCategories.where((cat) => !selectedCategories.contains(cat)).toList();
      
      if (missingCategories.isEmpty) return;
      
      String recommendation = '';
      if (missingCategories.contains('фотограф')) {
        recommendation = 'Добавьте фотографа к вашему мероприятию! Запечатлейте лучшие моменты на память.';
      } else if (missingCategories.contains('видеограф')) {
        recommendation = 'Добавьте видеографа для создания фильма о вашем мероприятии!';
      } else if (missingCategories.contains('декоратор')) {
        recommendation = 'Добавьте декоратора для создания неповторимой атмосферы!';
      }
      
      if (recommendation.isNotEmpty) {
        // await _localNotifications.show(
        //   title: 'Дополните ваш пакет услуг',
        //   body: recommendation,
        //   payload: 'cross_sell_recommendation',
        // );
      }
      
    } catch (e) {
      print('Error sending cross-sell recommendation: $e');
    }
  }

  /// Отправить рекомендацию по увеличению бюджета
  Future<void> sendBudgetRecommendation(String customerId, double currentBudget, List<String> selectedCategories) async {
    try {
      // Если бюджет меньше 50000 и выбрано мало категорий
      if (currentBudget < 50000 && selectedCategories.length < 3) {
        final additionalCost = 15000; // Примерная стоимость фотографа
        // await _localNotifications.show(
        //   title: 'Увеличьте бюджет для лучшего результата',
        //   body: 'Добавьте ${additionalCost.toStringAsFixed(0)} ₽ к бюджету, чтобы включить фотографа и создать незабываемые воспоминания!',
        //   payload: 'budget_recommendation',
        // );
      }
      
    } catch (e) {
      print('Error sending budget recommendation: $e');
    }
  }

  /// Отправить уведомление о новой публикации от избранного специалиста
  Future<void> sendFavoriteSpecialistUpdate(String customerId, String specialistId, String specialistName) async {
    try {
      // await _localNotifications.show(
      //   title: 'Новая публикация от $specialistName',
      //   body: 'Ваш избранный специалист опубликовал новый контент. Посмотрите!',
      //   payload: 'favorite_specialist_update_$specialistId',
      // );
      
    } catch (e) {
      print('Error sending favorite specialist update: $e');
    }
  }

  /// Проверить рабочее время специалиста перед отправкой уведомления
  Future<bool> isSpecialistWorkingHours(String specialistId) async {
    try {
      final specialistDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(specialistId)
          .get();
      
      if (!specialistDoc.exists) return true; // Если нет настроек, отправляем всегда
      
      final specialist = specialistDoc.data()!;
      final workingHours = specialist['workingHours'] as Map<String, dynamic>?;
      
      if (workingHours == null) return true;
      
      final startHour = workingHours['startHour'] as int? ?? 9;
      final endHour = workingHours['endHour'] as int? ?? 18;
      final currentHour = DateTime.now().hour;
      
      return currentHour >= startHour && currentHour <= endHour;
      
    } catch (e) {
      print('Error checking specialist working hours: $e');
      return true; // В случае ошибки отправляем уведомление
    }
  }

  /// Отправить уведомление с учетом рабочего времени специалиста
  Future<void> sendNotificationRespectingWorkingHours({
    required String specialistId,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final isWorkingHours = await isSpecialistWorkingHours(specialistId);
      
      if (isWorkingHours) {
      await sendLocalNotification(
        title: title,
        body: body,
        payload: payload,
      );
      } else {
        // Планируем уведомление на утро
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final scheduledTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
        
        await scheduleNotification(
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          payload: payload,
        );
      }
      
    } catch (e) {
      print('Error sending notification respecting working hours: $e');
    }
  }

  /// Запланировать уведомление на определенное время
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_notifications',
            'Запланированные уведомления',
            channelDescription: 'Уведомления, запланированные на определенное время',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
}
