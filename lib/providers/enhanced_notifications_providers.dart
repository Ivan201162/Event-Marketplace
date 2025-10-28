import 'package:event_marketplace_app/models/enhanced_notification.dart';
import 'package:event_marketplace_app/services/enhanced_notifications_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса уведомлений
final enhancedNotificationsServiceProvider =
    Provider<EnhancedNotificationsService>(
  (ref) => EnhancedNotificationsService(),
);

/// Провайдер уведомлений пользователя
final notificationsProvider =
    FutureProvider.family<List<EnhancedNotification>, String>((
  ref,
  userId,
) async {
  final service = ref.read(enhancedNotificationsServiceProvider);
  return service.getNotifications(userId: userId);
});

/// Провайдер непрочитанных уведомлений
final unreadNotificationsProvider =
    FutureProvider.family<List<EnhancedNotification>, String>((
  ref,
  userId,
) async {
  final service = ref.read(enhancedNotificationsServiceProvider);
  return service.getUnreadNotifications(userId: userId);
});

/// Провайдер архивированных уведомлений
final archivedNotificationsProvider =
    FutureProvider.family<List<EnhancedNotification>, String>((
  ref,
  userId,
) async {
  final service = ref.read(enhancedNotificationsServiceProvider);
  return service.getNotifications(userId: userId, includeArchived: true);
});

/// Провайдер уведомления по ID
final notificationProvider =
    FutureProvider.family<EnhancedNotification?, String>((
  ref,
  notificationId,
) async {
  final service = ref.read(enhancedNotificationsServiceProvider);
  return service.getNotificationById(notificationId);
});

/// Провайдер статистики уведомлений
final notificationStatsProvider =
    FutureProvider.family<NotificationStats, String>((
  ref,
  userId,
) async {
  final service = ref.read(enhancedNotificationsServiceProvider);
  return service.getNotificationStats(userId);
});

/// Провайдер состояния создания уведомления (мигрирован с StateNotifierProvider)
final createNotificationStateProvider =
    NotifierProvider<CreateNotificationStateNotifier, CreateNotificationState>(
  CreateNotificationStateNotifier.new,
);

/// Состояние создания уведомления
class CreateNotificationState {
  const CreateNotificationState(
      {this.isLoading = false, this.error, this.success = false,});

  final bool isLoading;
  final String? error;
  final bool success;

  CreateNotificationState copyWith(
          {bool? isLoading, String? error, bool? success,}) =>
      CreateNotificationState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        success: success ?? this.success,
      );
}

/// Нотификатор состояния создания уведомления (мигрирован с StateNotifier)
class CreateNotificationStateNotifier
    extends Notifier<CreateNotificationState> {
  @override
  CreateNotificationState build() {
    return const CreateNotificationState();
  }

  EnhancedNotificationsService get _service =>
      ref.read(enhancedNotificationsServiceProvider);

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.normal,
    String? category,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? expiresAt,
  }) async {
    state = state.copyWith(isLoading: true, success: false);

    try {
      await _service.createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        priority: priority,
        category: category,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        expiresAt: expiresAt,
      );

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const CreateNotificationState();
  }
}

/// Провайдер состояния уведомлений (мигрирован с StateNotifierProvider)
final notificationStateProvider = NotifierProvider.family<
    NotificationStateNotifier, NotificationState, String>(
  (ref, notificationId) => NotificationStateNotifier(notificationId),
);

/// Состояние уведомления
class NotificationState {
  const NotificationState(
      {this.isRead = false, this.isArchived = false, this.isLoading = false,});

  final bool isRead;
  final bool isArchived;
  final bool isLoading;

  NotificationState copyWith(
          {bool? isRead, bool? isArchived, bool? isLoading,}) =>
      NotificationState(
        isRead: isRead ?? this.isRead,
        isArchived: isArchived ?? this.isArchived,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Нотификатор состояния уведомления (мигрирован с StateNotifier)
class NotificationStateNotifier extends Notifier<NotificationState> {
  NotificationStateNotifier(this._notificationId);

  @override
  NotificationState build() {
    return const NotificationState();
  }

  final String _notificationId;
  EnhancedNotificationsService get _service =>
      ref.read(enhancedNotificationsServiceProvider);

  Future<void> markAsRead() async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.markAsRead(_notificationId);
      state = state.copyWith(isRead: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // TODO: Показать ошибку
    }
  }

  Future<void> archive() async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.archiveNotification(_notificationId);
      state = state.copyWith(isArchived: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // TODO: Показать ошибку
    }
  }

  Future<void> delete() async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.deleteNotification(_notificationId);
      // Уведомление удалено, состояние не имеет значения
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // TODO: Показать ошибку
    }
  }

  void setInitialState(bool isRead, bool isArchived) {
    state = state.copyWith(isRead: isRead, isArchived: isArchived);
  }
}

/// Провайдер настроек уведомлений (мигрирован с StateNotifierProvider)
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

/// Настройки уведомлений
class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.sound = true,
    this.vibration = true,
    this.badge = true,
    this.types = const {},
    this.frequency = NotificationFrequency.normal,
    this.quietHours = const QuietHours(),
  });

  final bool enabled;
  final bool sound;
  final bool vibration;
  final bool badge;
  final Map<NotificationType, bool> types;
  final NotificationFrequency frequency;
  final QuietHours quietHours;

  NotificationSettings copyWith({
    bool? enabled,
    bool? sound,
    bool? vibration,
    bool? badge,
    Map<NotificationType, bool>? types,
    NotificationFrequency? frequency,
    QuietHours? quietHours,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        sound: sound ?? this.sound,
        vibration: vibration ?? this.vibration,
        badge: badge ?? this.badge,
        types: types ?? this.types,
        frequency: frequency ?? this.frequency,
        quietHours: quietHours ?? this.quietHours,
      );
}

/// Частота уведомлений
enum NotificationFrequency {
  low('low'),
  normal('normal'),
  high('high');

  const NotificationFrequency(this.value);
  final String value;

  static NotificationFrequency fromString(String value) {
    switch (value) {
      case 'low':
        return NotificationFrequency.low;
      case 'normal':
        return NotificationFrequency.normal;
      case 'high':
        return NotificationFrequency.high;
      default:
        return NotificationFrequency.normal;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationFrequency.low:
        return 'Низкая';
      case NotificationFrequency.normal:
        return 'Обычная';
      case NotificationFrequency.high:
        return 'Высокая';
    }
  }
}

/// Тихие часы
class QuietHours {
  const QuietHours({
    this.enabled = false,
    this.startHour = 22,
    this.startMinute = 0,
    this.endHour = 8,
    this.endMinute = 0,
  });

  final bool enabled;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  QuietHours copyWith({
    bool? enabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        startHour: startHour ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour: endHour ?? this.endHour,
        endMinute: endMinute ?? this.endMinute,
      );
}

/// Нотификатор настроек уведомлений (мигрирован с StateNotifier)
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    return const NotificationSettings();
  }

  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void toggleSound() {
    state = state.copyWith(sound: !state.sound);
  }

  void toggleVibration() {
    state = state.copyWith(vibration: !state.vibration);
  }

  void toggleBadge() {
    state = state.copyWith(badge: !state.badge);
  }

  void toggleType(NotificationType type) {
    final newTypes = Map<NotificationType, bool>.from(state.types);
    newTypes[type] = !(newTypes[type] ?? true);
    state = state.copyWith(types: newTypes);
  }

  void setFrequency(NotificationFrequency frequency) {
    state = state.copyWith(frequency: frequency);
  }

  void setQuietHours(QuietHours quietHours) {
    state = state.copyWith(quietHours: quietHours);
  }
}
