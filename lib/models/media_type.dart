/// Типы медиа файлов
enum MediaType {
  image,
  video,
  audio,
  document,
}

/// Расширение для MediaType
extension MediaTypeExtension on MediaType {
  /// Получить расширения файлов для типа
  List<String> get extensions {
    switch (this) {
      case MediaType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      case MediaType.video:
        return ['mp4', 'avi', 'mov', 'wmv', 'flv'];
      case MediaType.audio:
        return ['mp3', 'wav', 'aac', 'ogg', 'm4a'];
      case MediaType.document:
        return ['pdf', 'doc', 'docx', 'txt', 'rtf'];
    }
  }

  /// Получить MIME типы для типа
  List<String> get mimeTypes {
    switch (this) {
      case MediaType.image:
        return ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
      case MediaType.video:
        return ['video/mp4', 'video/avi', 'video/quicktime', 'video/x-ms-wmv'];
      case MediaType.audio:
        return ['audio/mpeg', 'audio/wav', 'audio/aac', 'audio/ogg'];
      case MediaType.document:
        return ['application/pdf', 'application/msword', 'text/plain'];
    }
  }

  /// Получить максимальный размер файла в MB
  int get maxSizeMB {
    switch (this) {
      case MediaType.image:
        return 5;
      case MediaType.video:
        return 100;
      case MediaType.audio:
        return 50;
      case MediaType.document:
        return 10;
    }
  }

  /// Получить иконку для типа
  String get icon {
    switch (this) {
      case MediaType.image:
        return '🖼️';
      case MediaType.video:
        return '🎥';
      case MediaType.audio:
        return '🎵';
      case MediaType.document:
        return '📄';
    }
  }
}
