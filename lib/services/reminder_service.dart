import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';
import '../models/booking.dart';

/// Сервис для управления напоминаниями
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FCMService _fcmService = FCMService();
  final String _reminderTimeKey = 'reminder_time';
  final String _remindersEnabledKey = 'reminder_notifications_enabled';

  /// Создать напоминание для заявки
  Future<void> createBookingReminder(Booking booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled = prefs.getBool(_remindersEnabledKey) ?? true;

      if (!remindersEnabled) return;

      final reminderTime = prefs.getInt(_reminderTimeKey) ?? 30; // минуты
      final reminderDate =
          booking.eventDate.subtract(Duration(minutes: reminderTime));

      // Проверяем, что напоминание в будущем
      if (reminderDate.isAfter(DateTime.now())) {
        await _fcmService.scheduleLocalNotification(
          id: booking.hashCode,
          title: 'Напоминание о мероприятии',
          body: 'Ваше мероприятие начнется через $reminderTime минут',
          scheduledDate: reminderDate,
          payload: 'booking_reminder_${booking.id}',
        );

        print(
            'Напоминание создано для заявки ${booking.id} на ${reminderDate}');
      }
    } catch (e) {
      print('Ошибка создания напоминания: $e');
    }
  }

  /// Обновить напоминание для заявки
  Future<void> updateBookingReminder(Booking booking) async {
    try {
      // Удаляем старое напоминание
      await cancelBookingReminder(booking);

      // Создаем новое
      await createBookingReminder(booking);
    } catch (e) {
      print('Ошибка обновления напоминания: $e');
    }
  }

  /// Отменить напоминание для заявки
  Future<void> cancelBookingReminder(Booking booking) async {
    try {
      await _fcmService.cancelScheduledNotification(booking.hashCode);
      print('Напоминание отменено для заявки ${booking.id}');
    } catch (e) {
      print('Ошибка отмены напоминания: $e');
    }
  }

  /// Создать напоминание о платеже
  Future<void> createPaymentReminder({
    required String paymentId,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled = prefs.getBool(_remindersEnabledKey) ?? true;

      if (!remindersEnabled) return;

      // Напоминание за день до срока платежа
      final reminderDate = dueDate.subtract(const Duration(days: 1));

      if (reminderDate.isAfter(DateTime.now())) {
        await _fcmService.scheduleLocalNotification(
          id: paymentId.hashCode,
          title: title,
          body: body,
          scheduledDate: reminderDate,
          payload: 'payment_reminder_$paymentId',
        );

        print(
            'Напоминание о платеже создано для $paymentId на ${reminderDate}');
      }
    } catch (e) {
      print('Ошибка создания напоминания о платеже: $e');
    }
  }

  /// Создать напоминание о встрече
  Future<void> createMeetingReminder({
    required String meetingId,
    required String specialistName,
    required DateTime meetingDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled = prefs.getBool(_remindersEnabledKey) ?? true;

      if (!remindersEnabled) return;

      final reminderTime = prefs.getInt(_reminderTimeKey) ?? 30; // минуты
      final reminderDate =
          meetingDate.subtract(Duration(minutes: reminderTime));

      if (reminderDate.isAfter(DateTime.now())) {
        await _fcmService.scheduleLocalNotification(
          id: meetingId.hashCode,
          title: 'Встреча с $specialistName',
          body: 'Встреча начнется через $reminderTime минут',
          scheduledDate: reminderDate,
          payload: 'meeting_reminder_$meetingId',
        );

        print(
            'Напоминание о встрече создано для $meetingId на ${reminderDate}');
      }
    } catch (e) {
      print('Ошибка создания напоминания о встрече: $e');
    }
  }

  /// Создать ежедневное напоминание
  Future<void> createDailyReminder({
    required String reminderId,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled = prefs.getBool(_remindersEnabledKey) ?? true;

      if (!remindersEnabled) return;

      // Создаем напоминание на сегодня
      final now = DateTime.now();
      var reminderDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Если время уже прошло сегодня, планируем на завтра
      if (reminderDate.isBefore(now)) {
        reminderDate = reminderDate.add(const Duration(days: 1));
      }

      await _fcmService.scheduleLocalNotification(
        id: reminderId.hashCode,
        title: title,
        body: body,
        scheduledDate: reminderDate,
        payload: 'daily_reminder_$reminderId',
      );

      print(
          'Ежедневное напоминание создано для $reminderId на ${reminderDate}');
    } catch (e) {
      print('Ошибка создания ежедневного напоминания: $e');
    }
  }

  /// Получить время напоминания
  Future<int> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderTimeKey) ?? 30;
  }

  /// Установить время напоминания
  Future<void> setReminderTime(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderTimeKey, minutes);
  }

  /// Проверить, включены ли напоминания
  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? true;
  }

  /// Включить/выключить напоминания
  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, enabled);

    if (!enabled) {
      // Отменяем все запланированные напоминания
      await _fcmService.cancelAllScheduledNotifications();
    }
  }

  /// Создать напоминания для всех активных заявок
  Future<void> createRemindersForActiveBookings(List<Booking> bookings) async {
    try {
      final now = DateTime.now();
      final activeBookings = bookings
          .where((booking) =>
              booking.status == 'confirmed' && booking.eventDate.isAfter(now))
          .toList();

      for (final booking in activeBookings) {
        await createBookingReminder(booking);
      }

      print('Создано напоминаний для ${activeBookings.length} активных заявок');
    } catch (e) {
      print('Ошибка создания напоминаний для активных заявок: $e');
    }
  }

  /// Очистить все напоминания
  Future<void> clearAllReminders() async {
    try {
      await _fcmService.cancelAllScheduledNotifications();
      print('Все напоминания очищены');
    } catch (e) {
      print('Ошибка очистки напоминаний: $e');
    }
  }

  /// Создать тестовое напоминание
  Future<void> createTestReminder() async {
    try {
      final testDate = DateTime.now().add(const Duration(seconds: 10));

      await _fcmService.scheduleLocalNotification(
        id: 999999,
        title: 'Тестовое напоминание',
        body: 'Это тестовое напоминание для проверки настроек',
        scheduledDate: testDate,
        payload: 'test_reminder',
      );

      print('Тестовое напоминание создано на ${testDate}');
    } catch (e) {
      print('Ошибка создания тестового напоминания: $e');
    }
  }
}
