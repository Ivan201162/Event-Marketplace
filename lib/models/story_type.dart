/// Тип истории
enum StoryType { photo, video, text, poll, quiz, image }

/// Расширение для StoryType
extension StoryTypeExtension on StoryType {
  String get displayName {
    switch (this) {
      case StoryType.photo:
        return 'Фото';
      case StoryType.video:
        return 'Видео';
      case StoryType.text:
        return 'Текст';
      case StoryType.poll:
        return 'Опрос';
      case StoryType.quiz:
        return 'Викторина';
      case StoryType.image:
        return 'Изображение';
    }
  }

  String get icon {
    switch (this) {
      case StoryType.photo:
        return '📷';
      case StoryType.video:
        return '🎥';
      case StoryType.text:
        return '📝';
      case StoryType.poll:
        return '📊';
      case StoryType.quiz:
        return '❓';
      case StoryType.image:
        return '🖼️';
    }
  }
}
