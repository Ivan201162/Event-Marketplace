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
  general,
  newPost,
  newStory,
  newEvent,
  newPortfolio,
  announcement,
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
      case NotificationType.general:
        return 'Общее';
      case NotificationType.newPost:
        return 'Новый пост';
      case NotificationType.newStory:
        return 'Новая история';
      case NotificationType.newEvent:
        return 'Новое событие';
      case NotificationType.newPortfolio:
        return 'Новое портфолио';
      case NotificationType.announcement:
        return 'Объявление';
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
      case NotificationType.general:
        return '📢';
      case NotificationType.newPost:
        return '📝';
      case NotificationType.newStory:
        return '📖';
      case NotificationType.newEvent:
        return '🎪';
      case NotificationType.newPortfolio:
        return '🖼️';
      case NotificationType.announcement:
        return '📢';
    }
  }
}
