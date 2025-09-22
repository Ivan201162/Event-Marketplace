enum NotificationType {
  booking,
  message,
  review,
  reminder,
  system,
  promotion,
  cancellation,
  newPost,
  newStory,
  newEvent,
  newPortfolio,
  announcement,
  update,
  security,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.booking:
        return 'Бронирование';
      case NotificationType.message:
        return 'Сообщение';
      case NotificationType.review:
        return 'Отзыв';
      case NotificationType.reminder:
        return 'Напоминание';
      case NotificationType.system:
        return 'Системное';
      case NotificationType.promotion:
        return 'Промо';
      case NotificationType.cancellation:
        return 'Отмена';
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
      case NotificationType.update:
        return 'Обновление';
      case NotificationType.security:
        return 'Безопасность';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.booking:
        return '📅';
      case NotificationType.message:
        return '💬';
      case NotificationType.review:
        return '⭐';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.promotion:
        return '🎉';
      case NotificationType.cancellation:
        return '❌';
      case NotificationType.newPost:
        return '📝';
      case NotificationType.newStory:
        return '📖';
      case NotificationType.newEvent:
        return '🎊';
      case NotificationType.newPortfolio:
        return '🖼️';
      case NotificationType.announcement:
        return '📢';
      case NotificationType.update:
        return '🔄';
      case NotificationType.security:
        return '🔒';
    }
  }
}
