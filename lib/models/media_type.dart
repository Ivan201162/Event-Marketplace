/// Тип медиа-контента
enum MediaType {
  image,
  video,
  audio,
  document,
}

/// Расширение для MediaType
extension MediaTypeExtension on MediaType {
  String get displayName {
    switch (this) {
      case MediaType.image:
        return 'Изображение';
      case MediaType.video:
        return 'Видео';
      case MediaType.audio:
        return 'Аудио';
      case MediaType.document:
        return 'Документ';
    }
  }

  String get mimeType {
    switch (this) {
      case MediaType.image:
        return 'image/*';
      case MediaType.video:
        return 'video/*';
      case MediaType.audio:
        return 'audio/*';
      case MediaType.document:
        return 'application/*';
    }
  }
}
