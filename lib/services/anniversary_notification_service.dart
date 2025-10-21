import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/customer_portfolio.dart';
import 'customer_portfolio_service.dart';

/// Сервис для отправки напоминаний о годовщинах
class AnniversaryNotificationService {
  factory AnniversaryNotificationService() => _instance;
  AnniversaryNotificationService._internal();
  static final AnniversaryNotificationService _instance =
      AnniversaryNotificationService._internal();

  final CustomerPortfolioService _portfolioService = CustomerPortfolioService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _dailyCheckTimer;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    // Инициализация timezone
    tz.initializeTimeZones();

    // Настройка уведомлений
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Запуск ежедневной проверки
    _startDailyCheck();
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // TODO(developer): Переход к экрану портфолио или специалистов
    // Логирование:'Уведомление нажато: ${response.payload}');
  }

  /// Запуск ежедневной проверки годовщин
  void _startDailyCheck() {
    // Проверяем каждый день в 9:00
    _scheduleDailyCheck();

    // Также проверяем сразу при запуске
    _checkAnniversaries();
  }

  /// Планирование ежедневной проверки
  void _scheduleDailyCheck() {
    final now = DateTime.now();
    final nextCheck = DateTime(now.year, now.month, now.day, 9);

    if (nextCheck.isBefore(now)) {
      nextCheck.add(const Duration(days: 1));
    }

    final duration = nextCheck.difference(now);

    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = Timer(duration, () {
      _checkAnniversaries();
      _scheduleDailyCheck(); // Планируем следующую проверку
    });
  }

  /// Проверка годовщин и отправка уведомлений
  Future<void> _checkAnniversaries() async {
    try {
      // Получаем заказчиков с годовщинами сегодня
      final customersWithAnniversaries = await _portfolioService
          .getCustomersWithAnniversariesToday();

      for (final customer in customersWithAnniversaries) {
        await _sendAnniversaryNotification(customer);
      }

      // Получаем заказчиков с годовщинами в ближайшие 7 дней
      final customersWithUpcomingAnniversaries = await _portfolioService
          .getCustomersWithUpcomingAnniversaries(7);

      for (final customer in customersWithUpcomingAnniversaries) {
        await _sendUpcomingAnniversaryNotification(customer);
      }
    } on Exception {
      // Логирование:'Ошибка проверки годовщин: $e');
    }
  }

  /// Отправка уведомления о годовщине сегодня
  Future<void> _sendAnniversaryNotification(CustomerPortfolio customer) async {
    if (!customer.anniversaryRemindersEnabled) return;

    final notificationId = customer.id.hashCode;
    const channelId = 'anniversary_notifications';
    const channelName = 'Напоминания о годовщинах';
    const channelDescription = 'Уведомления о годовщинах и важных датах';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    const title = '🎉 Поздравляем с годовщиной!';
    final body = customer.weddingDate != null
        ? 'Сегодня ${customer.yearsMarried} лет со дня свадьбы! Время заказать новое мероприятие?'
        : 'Сегодня важная дата! Время заказать новое мероприятие?';

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
      payload: 'anniversary_${customer.id}',
    );
  }

  /// Отправка уведомления о приближающейся годовщине
  Future<void> _sendUpcomingAnniversaryNotification(CustomerPortfolio customer) async {
    if (!customer.anniversaryRemindersEnabled) return;

    final upcomingAnniversaries = customer.upcomingAnniversaries;
    if (upcomingAnniversaries.isEmpty) return;

    final nextAnniversary = upcomingAnniversaries.first;
    final daysUntil = nextAnniversary.difference(DateTime.now()).inDays;

    // Отправляем уведомление за 3 дня до годовщины
    if (daysUntil == 3) {
      final notificationId = customer.id.hashCode + 1000; // Другой ID для предупреждения
      const channelId = 'upcoming_anniversary_notifications';
      const channelName = 'Предстоящие годовщины';
      const channelDescription = 'Уведомления о приближающихся годовщинах';

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.medium,
        priority: Priority.medium,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      const title = '📅 Скоро годовщина!';
      final body = 'Через $daysUntil дней годовщина! Не забудьте заказать мероприятие.';

      await _notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: 'upcoming_anniversary_${customer.id}',
      );
    }
  }

  /// Планирование уведомления о годовщине
  Future<void> scheduleAnniversaryNotification(
    CustomerPortfolio customer,
    DateTime anniversary,
  ) async {
    if (!customer.anniversaryRemindersEnabled) return;

    final now = DateTime.now();
    final thisYear = DateTime(now.year, anniversary.month, anniversary.day, 9);
    final nextYear = DateTime(now.year + 1, anniversary.month, anniversary.day, 9);

    DateTime scheduledDate;
    if (thisYear.isAfter(now)) {
      scheduledDate = thisYear;
    } else {
      scheduledDate = nextYear;
    }

    final notificationId = customer.id.hashCode + anniversary.hashCode;
    const channelId = 'scheduled_anniversary_notifications';
    const channelName = 'Запланированные годовщины';
    const channelDescription = 'Уведомления о запланированных годовщинах';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    const title = '🎉 Годовщина!';
    const body = 'Сегодня годовщина! Время заказать новое мероприятие?';

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: 'scheduled_anniversary_${customer.id}',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Отмена уведомления о годовщине
  Future<void> cancelAnniversaryNotification(String customerId, DateTime anniversary) async {
    final notificationId = customerId.hashCode + anniversary.hashCode;
    await _notifications.cancel(notificationId);
  }

  /// Отмена всех уведомлений для заказчика
  Future<void> cancelAllNotificationsForCustomer(String customerId) async {
    // Отменяем основные уведомления
    await _notifications.cancel(customerId.hashCode);
    await _notifications.cancel(customerId.hashCode + 1000);

    // Отменяем запланированные уведомления (примерно)
    for (var i = 0; i < 100; i++) {
      await _notifications.cancel(customerId.hashCode + i);
    }
  }

  /// Отправка тестового уведомления
  Future<void> sendTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Тестовые уведомления',
      channelDescription: 'Тестовые уведомления для проверки',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      999,
      'Тестовое уведомление',
      'Портфолио заказчика работает!',
      details,
    );
  }

  /// Проверка разрешений на уведомления
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    const granted = true;

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (!granted) return false;
    }

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      if (!granted) return false;
    }

    return granted;
  }

  /// Остановка сервиса
  void dispose() {
    _dailyCheckTimer?.cancel();
  }
}
