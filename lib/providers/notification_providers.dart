import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../models/notification.dart' as app_notification;

/// Провайдер для сервиса уведомлений
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Провайдер для списка уведомлений пользователя
final userNotificationsProvider = StreamProvider<List<app_notification.Notification>>((ref) {
  // Здесь будет логика получения уведомлений из Firestore
  // Пока возвращаем пустой список
  return Stream.value([]);
});

/// Провайдер для количества непрочитанных уведомлений
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(userNotificationsProvider).when(
    data: (notifications) => Stream.value(
      notifications.where((n) => !n.isRead).length,
    ),
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

/// Провайдер для FCM токена
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getFCMToken();
});

/// Провайдер для управления настройками уведомлений
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

/// Настройки уведомлений
class NotificationSettings {
  final bool reviewNotifications;
  final bool bookingNotifications;
  final bool paymentNotifications;
  final bool reminderNotifications;
  final bool marketingNotifications;
  final int reminderHoursBefore;

  const NotificationSettings({
    this.reviewNotifications = true,
    this.bookingNotifications = true,
    this.paymentNotifications = true,
    this.reminderNotifications = true,
    this.marketingNotifications = false,
    this.reminderHoursBefore = 24,
  });

  NotificationSettings copyWith({
    bool? reviewNotifications,
    bool? bookingNotifications,
    bool? paymentNotifications,
    bool? reminderNotifications,
    bool? marketingNotifications,
    int? reminderHoursBefore,
  }) {
    return NotificationSettings(
      reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      bookingNotifications: bookingNotifications ?? this.bookingNotifications,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      reminderNotifications: reminderNotifications ?? this.reminderNotifications,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
      reminderHoursBefore: reminderHoursBefore ?? this.reminderHoursBefore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewNotifications': reviewNotifications,
      'bookingNotifications': bookingNotifications,
      'paymentNotifications': paymentNotifications,
      'reminderNotifications': reminderNotifications,
      'marketingNotifications': marketingNotifications,
      'reminderHoursBefore': reminderHoursBefore,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      reviewNotifications: map['reviewNotifications'] ?? true,
      bookingNotifications: map['bookingNotifications'] ?? true,
      paymentNotifications: map['paymentNotifications'] ?? true,
      reminderNotifications: map['reminderNotifications'] ?? true,
      marketingNotifications: map['marketingNotifications'] ?? false,
      reminderHoursBefore: map['reminderHoursBefore'] ?? 24,
    );
  }
}

/// Нотификатор для настроек уведомлений
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  /// Загружает настройки из SharedPreferences
  Future<void> _loadSettings() async {
    // Здесь будет логика загрузки из SharedPreferences
    // Пока используем значения по умолчанию
  }

  /// Сохраняет настройки в SharedPreferences
  Future<void> _saveSettings() async {
    // Здесь будет логика сохранения в SharedPreferences
  }

  /// Обновляет настройку уведомлений об отзывах
  Future<void> updateReviewNotifications(bool enabled) async {
    state = state.copyWith(reviewNotifications: enabled);
    await _saveSettings();
  }

  /// Обновляет настройку уведомлений о бронированиях
  Future<void> updateBookingNotifications(bool enabled) async {
    state = state.copyWith(bookingNotifications: enabled);
    await _saveSettings();
  }

  /// Обновляет настройку уведомлений об оплатах
  Future<void> updatePaymentNotifications(bool enabled) async {
    state = state.copyWith(paymentNotifications: enabled);
    await _saveSettings();
  }

  /// Обновляет настройку напоминаний
  Future<void> updateReminderNotifications(bool enabled) async {
    state = state.copyWith(reminderNotifications: enabled);
    await _saveSettings();
  }

  /// Обновляет настройку маркетинговых уведомлений
  Future<void> updateMarketingNotifications(bool enabled) async {
    state = state.copyWith(marketingNotifications: enabled);
    await _saveSettings();
  }

  /// Обновляет время напоминания
  Future<void> updateReminderHours(int hours) async {
    state = state.copyWith(reminderHoursBefore: hours);
    await _saveSettings();
  }
}

/// Провайдер для отправки уведомлений
final sendNotificationProvider = Provider<SendNotificationNotifier>((ref) {
  return SendNotificationNotifier(ref.read(notificationServiceProvider));
});

/// Нотификатор для отправки уведомлений
class SendNotificationNotifier {
  final NotificationService _service;

  SendNotificationNotifier(this._service);

  /// Отправить уведомление о новом отзыве
  Future<void> sendReviewNotification({
    required String specialistId,
    required String customerName,
    required int rating,
    required String reviewText,
  }) async {
    await _service.sendReviewNotification(
      specialistId: specialistId,
      customerName: customerName,
      rating: rating,
      reviewText: reviewText,
    );
  }

  /// Отправить напоминание об оплате
  Future<void> sendPaymentReminder({
    required String customerId,
    required String bookingId,
    required String eventName,
    required double amount,
    required DateTime dueDate,
  }) async {
    await _service.sendPaymentReminder(
      customerId: customerId,
      bookingId: bookingId,
      eventName: eventName,
      amount: amount,
      dueDate: dueDate,
    );
  }

  /// Отправить уведомление о статусе бронирования
  Future<void> sendBookingStatusNotification({
    required String customerId,
    required String bookingId,
    required String status,
    required String eventName,
  }) async {
    // Здесь будет логика отправки уведомления о статусе бронирования
  }

  /// Отправить уведомление о новом сообщении
  Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    // Здесь будет логика отправки уведомления о новом сообщении
  }
}
