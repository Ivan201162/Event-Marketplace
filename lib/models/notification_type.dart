import 'package:flutter/foundation.dart';

/// Тип уведомления
enum NotificationType {
  booking,
  payment,
  review,
  message,
  system,
  promotion,
  reminder,
  update,
}

/// Расширение для NotificationType
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.booking:
        return 'Бронирование';
      case NotificationType.payment:
        return 'Платеж';
      case NotificationType.review:
        return 'Отзыв';
      case NotificationType.message:
        return 'Сообщение';
      case NotificationType.system:
        return 'Система';
      case NotificationType.promotion:
        return 'Акция';
      case NotificationType.reminder:
        return 'Напоминание';
      case NotificationType.update:
        return 'Обновление';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.booking:
        return '📅';
      case NotificationType.payment:
        return '💳';
      case NotificationType.review:
        return '⭐';
      case NotificationType.message:
        return '💬';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.promotion:
        return '🎉';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.update:
        return '🔄';
    }
  }
}
