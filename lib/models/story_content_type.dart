/// Тип контента истории
enum StoryContentType { image, video, text, poll, quiz, link }

/// Расширение для StoryContentType
extension StoryContentTypeExtension on StoryContentType {
  /// Получить название типа
  String get displayName {
    switch (this) {
      case StoryContentType.image:
        return 'Изображение';
      case StoryContentType.video:
        return 'Видео';
      case StoryContentType.text:
        return 'Текст';
      case StoryContentType.poll:
        return 'Опрос';
      case StoryContentType.quiz:
        return 'Викторина';
      case StoryContentType.link:
        return 'Ссылка';
    }
  }

  /// Получить иконку типа
  String get icon {
    switch (this) {
      case StoryContentType.image:
        return '🖼️';
      case StoryContentType.video:
        return '🎥';
      case StoryContentType.text:
        return '📝';
      case StoryContentType.poll:
        return '📊';
      case StoryContentType.quiz:
        return '🧩';
      case StoryContentType.link:
        return '🔗';
    }
  }

  /// Проверить, является ли тип медиа
  bool get isMedia {
    return this == StoryContentType.image || this == StoryContentType.video;
  }

  /// Проверить, является ли тип интерактивным
  bool get isInteractive {
    return this == StoryContentType.poll || this == StoryContentType.quiz;
  }
}
