/// Типы контента для историй
enum StoryContentType {
  text,
  image,
  video,
  poll,
  question,
  music,
  location,
  mention,
  hashtag,
  link,
}

extension StoryContentTypeExtension on StoryContentType {
  String get displayName {
    switch (this) {
      case StoryContentType.text:
        return 'Текст';
      case StoryContentType.image:
        return 'Изображение';
      case StoryContentType.video:
        return 'Видео';
      case StoryContentType.poll:
        return 'Опрос';
      case StoryContentType.question:
        return 'Вопрос';
      case StoryContentType.music:
        return 'Музыка';
      case StoryContentType.location:
        return 'Местоположение';
      case StoryContentType.mention:
        return 'Упоминание';
      case StoryContentType.hashtag:
        return 'Хештег';
      case StoryContentType.link:
        return 'Ссылка';
    }
  }

  String get icon {
    switch (this) {
      case StoryContentType.text:
        return 'text_fields';
      case StoryContentType.image:
        return 'image';
      case StoryContentType.video:
        return 'videocam';
      case StoryContentType.poll:
        return 'poll';
      case StoryContentType.question:
        return 'help_outline';
      case StoryContentType.music:
        return 'music_note';
      case StoryContentType.location:
        return 'location_on';
      case StoryContentType.mention:
        return 'alternate_email';
      case StoryContentType.hashtag:
        return 'tag';
      case StoryContentType.link:
        return 'link';
    }
  }
}