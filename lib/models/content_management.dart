import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель медиа контента
class MediaContent {
  const MediaContent({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    required this.fileSize,
    required this.mimeType,
    this.metadata = const {},
    this.uploadedBy,
    this.specialistId,
    this.eventId,
    this.status = ContentStatus.uploaded,
    required this.uploadedAt,
    this.processedAt,
    this.publishedAt,
    this.tags = const [],
    this.processingInfo = const {},
  });

  /// Создать из документа Firestore
  factory MediaContent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return MediaContent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      type: MediaType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] as String?),
        orElse: () => MediaType.image,
      ),
      url: data['url'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      fileSize: data['fileSize'] as int? ?? 0,
      mimeType: data['mimeType'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<dynamic, dynamic>? ?? {},
      ),
      uploadedBy: data['uploadedBy'] as String?,
      specialistId: data['specialistId'] as String?,
      eventId: data['eventId'] as String?,
      status: ContentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] as String?),
        orElse: () => ContentStatus.uploaded,
      ),
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      publishedAt: data['publishedAt'] != null
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      processingInfo: Map<String, dynamic>.from(
        data['processingInfo'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }

  /// Создать из Map
  factory MediaContent.fromMap(Map<String, dynamic> data) => MediaContent(
        id: data['id'] as String? ?? '',
        title: data['title'] as String? ?? '',
        description: data['description'] as String?,
        type: MediaType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => MediaType.image,
        ),
        url: data['url'] as String? ?? '',
        thumbnailUrl: data['thumbnailUrl'] as String?,
        fileSize: data['fileSize'] as int? ?? 0,
        mimeType: data['mimeType'] as String? ?? '',
        metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {},
        ),
        uploadedBy: data['uploadedBy'] as String?,
        specialistId: data['specialistId'] as String?,
        eventId: data['eventId'] as String?,
        status: ContentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => ContentStatus.uploaded,
        ),
        uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
        processedAt: data['processedAt'] != null
            ? (data['processedAt'] as Timestamp).toDate()
            : null,
        publishedAt: data['publishedAt'] != null
            ? (data['publishedAt'] as Timestamp).toDate()
            : null,
        tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
        processingInfo: Map<String, dynamic>.from(
          data['processingInfo'] as Map<dynamic, dynamic>? ?? {},
        ),
      );
  final String id;
  final String title;
  final String? description;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final int fileSize;
  final String mimeType;
  final Map<String, dynamic> metadata;
  final String? uploadedBy;
  final String? specialistId;
  final String? eventId;
  final ContentStatus status;
  final DateTime uploadedAt;
  final DateTime? processedAt;
  final DateTime? publishedAt;
  final List<String> tags;
  final Map<String, dynamic> processingInfo;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'type': type.toString().split('.').last,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'metadata': metadata,
        'uploadedBy': uploadedBy,
        'specialistId': specialistId,
        'eventId': eventId,
        'status': status.toString().split('.').last,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'processedAt':
            processedAt != null ? Timestamp.fromDate(processedAt!) : null,
        'publishedAt':
            publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
        'tags': tags,
        'processingInfo': processingInfo,
      };

  /// Создать копию с изменениями
  MediaContent copyWith({
    String? id,
    String? title,
    String? description,
    MediaType? type,
    String? url,
    String? thumbnailUrl,
    int? fileSize,
    String? mimeType,
    Map<String, dynamic>? metadata,
    String? uploadedBy,
    String? specialistId,
    String? eventId,
    ContentStatus? status,
    DateTime? uploadedAt,
    DateTime? processedAt,
    DateTime? publishedAt,
    List<String>? tags,
    Map<String, dynamic>? processingInfo,
  }) =>
      MediaContent(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        fileSize: fileSize ?? this.fileSize,
        mimeType: mimeType ?? this.mimeType,
        metadata: metadata ?? this.metadata,
        uploadedBy: uploadedBy ?? this.uploadedBy,
        specialistId: specialistId ?? this.specialistId,
        eventId: eventId ?? this.eventId,
        status: status ?? this.status,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        processedAt: processedAt ?? this.processedAt,
        publishedAt: publishedAt ?? this.publishedAt,
        tags: tags ?? this.tags,
        processingInfo: processingInfo ?? this.processingInfo,
      );

  /// Проверить, обработан ли контент
  bool get isProcessed => status == ContentStatus.processed;

  /// Проверить, опубликован ли контент
  bool get isPublished => status == ContentStatus.published;

  /// Проверить, есть ли ошибка
  bool get hasError => status == ContentStatus.error;

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получить время обработки
  Duration? get processingTime {
    if (processedAt == null) return null;
    return processedAt!.difference(uploadedAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaContent &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.url == url &&
        other.thumbnailUrl == thumbnailUrl &&
        other.fileSize == fileSize &&
        other.mimeType == mimeType &&
        other.metadata == metadata &&
        other.uploadedBy == uploadedBy &&
        other.specialistId == specialistId &&
        other.eventId == eventId &&
        other.status == status &&
        other.uploadedAt == uploadedAt &&
        other.processedAt == processedAt &&
        other.publishedAt == publishedAt &&
        other.tags == tags &&
        other.processingInfo == processingInfo;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        type,
        url,
        thumbnailUrl,
        fileSize,
        mimeType,
        metadata,
        uploadedBy,
        specialistId,
        eventId,
        status,
        uploadedAt,
        processedAt,
        publishedAt,
        tags,
        processingInfo,
      );

  @override
  String toString() =>
      'MediaContent(id: $id, title: $title, type: $type, status: $status)';
}

/// Модель галереи контента
class ContentGallery {
  const ContentGallery({
    required this.id,
    required this.name,
    this.description,
    this.specialistId,
    this.eventId,
    this.mediaIds = const [],
    this.type = GalleryType.portfolio,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.settings = const {},
  });

  /// Создать из документа Firestore
  factory ContentGallery.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ContentGallery(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      specialistId: data['specialistId'] as String?,
      eventId: data['eventId'] as String?,
      mediaIds: List<String>.from(data['mediaIds'] as List<dynamic>? ?? []),
      type: GalleryType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => GalleryType.portfolio,
      ),
      isPublic: data['isPublic'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String?,
      settings: Map<String, dynamic>.from(
        data['settings'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }

  /// Создать из Map
  factory ContentGallery.fromMap(Map<String, dynamic> data) => ContentGallery(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        description: data['description'] as String?,
        specialistId: data['specialistId'] as String?,
        eventId: data['eventId'] as String?,
        mediaIds: List<String>.from(data['mediaIds'] as List<dynamic>? ?? []),
        type: GalleryType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => GalleryType.portfolio,
        ),
        isPublic: data['isPublic'] as bool? ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        createdBy: data['createdBy'] as String?,
        settings: Map<String, dynamic>.from(
          data['settings'] as Map<dynamic, dynamic>? ?? {},
        ),
      );
  final String id;
  final String name;
  final String? description;
  final String? specialistId;
  final String? eventId;
  final List<String> mediaIds;
  final GalleryType type;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final Map<String, dynamic> settings;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'specialistId': specialistId,
        'eventId': eventId,
        'mediaIds': mediaIds,
        'type': type.toString().split('.').last,
        'isPublic': isPublic,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'settings': settings,
      };

  /// Создать копию с изменениями
  ContentGallery copyWith({
    String? id,
    String? name,
    String? description,
    String? specialistId,
    String? eventId,
    List<String>? mediaIds,
    GalleryType? type,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? settings,
  }) =>
      ContentGallery(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        specialistId: specialistId ?? this.specialistId,
        eventId: eventId ?? this.eventId,
        mediaIds: mediaIds ?? this.mediaIds,
        type: type ?? this.type,
        isPublic: isPublic ?? this.isPublic,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        settings: settings ?? this.settings,
      );

  /// Получить количество медиа
  int get mediaCount => mediaIds.length;

  /// Проверить, пуста ли галерея
  bool get isEmpty => mediaIds.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentGallery &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.specialistId == specialistId &&
        other.eventId == eventId &&
        other.mediaIds == mediaIds &&
        other.type == type &&
        other.isPublic == isPublic &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.settings == settings;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        specialistId,
        eventId,
        mediaIds,
        type,
        isPublic,
        createdAt,
        updatedAt,
        createdBy,
        settings,
      );

  @override
  String toString() =>
      'ContentGallery(id: $id, name: $name, type: $type, mediaCount: $mediaCount)';
}

/// Модель обработки медиа
class MediaProcessing {
  const MediaProcessing({
    required this.id,
    required this.mediaId,
    required this.type,
    this.status = ProcessingStatus.pending,
    this.parameters = const {},
    this.resultUrl,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory MediaProcessing.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return MediaProcessing(
      id: doc.id,
      mediaId: data['mediaId'] as String? ?? '',
      type: ProcessingType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ProcessingType.thumbnail,
      ),
      status: ProcessingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ProcessingStatus.pending,
      ),
      parameters: Map<String, dynamic>.from(
        data['parameters'] as Map<dynamic, dynamic>? ?? {},
      ),
      resultUrl: data['resultUrl'] as String?,
      errorMessage: data['errorMessage'] as String?,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }

  /// Создать из Map
  factory MediaProcessing.fromMap(Map<String, dynamic> data) => MediaProcessing(
        id: data['id'] as String? ?? '',
        mediaId: data['mediaId'] as String? ?? '',
        type: ProcessingType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => ProcessingType.thumbnail,
        ),
        status: ProcessingStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => ProcessingStatus.pending,
        ),
        parameters: Map<String, dynamic>.from(
          data['parameters'] as Map<dynamic, dynamic>? ?? {},
        ),
        resultUrl: data['resultUrl'] as String?,
        errorMessage: data['errorMessage'] as String?,
        startedAt: (data['startedAt'] as Timestamp).toDate(),
        completedAt: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
        metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {},
        ),
      );
  final String id;
  final String mediaId;
  final ProcessingType type;
  final ProcessingStatus status;
  final Map<String, dynamic> parameters;
  final String? resultUrl;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'mediaId': mediaId,
        'type': type.toString().split('.').last,
        'status': status.toString().split('.').last,
        'parameters': parameters,
        'resultUrl': resultUrl,
        'errorMessage': errorMessage,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  MediaProcessing copyWith({
    String? id,
    String? mediaId,
    ProcessingType? type,
    ProcessingStatus? status,
    Map<String, dynamic>? parameters,
    String? resultUrl,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) =>
      MediaProcessing(
        id: id ?? this.id,
        mediaId: mediaId ?? this.mediaId,
        type: type ?? this.type,
        status: status ?? this.status,
        parameters: parameters ?? this.parameters,
        resultUrl: resultUrl ?? this.resultUrl,
        errorMessage: errorMessage ?? this.errorMessage,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, завершена ли обработка
  bool get isCompleted => status == ProcessingStatus.completed;

  /// Проверить, есть ли ошибка
  bool get hasError => status == ProcessingStatus.failed;

  /// Проверить, выполняется ли обработка
  bool get isInProgress => status == ProcessingStatus.inProgress;

  /// Получить продолжительность обработки
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaProcessing &&
        other.id == id &&
        other.mediaId == mediaId &&
        other.type == type &&
        other.status == status &&
        other.parameters == parameters &&
        other.resultUrl == resultUrl &&
        other.errorMessage == errorMessage &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        mediaId,
        type,
        status,
        parameters,
        resultUrl,
        errorMessage,
        startedAt,
        completedAt,
        metadata,
      );

  @override
  String toString() =>
      'MediaProcessing(id: $id, mediaId: $mediaId, type: $type, status: $status)';
}

/// Типы медиа
enum MediaType {
  image,
  video,
  audio,
  document,
  other,
}

/// Расширение для типов медиа
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
      case MediaType.other:
        return 'Другое';
    }
  }

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
      case MediaType.other:
        return '📎';
    }
  }

  List<String> get supportedMimeTypes {
    switch (this) {
      case MediaType.image:
        return ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
      case MediaType.video:
        return ['video/mp4', 'video/avi', 'video/mov', 'video/webm'];
      case MediaType.audio:
        return ['audio/mp3', 'audio/wav', 'audio/ogg', 'audio/m4a'];
      case MediaType.document:
        return ['application/pdf', 'text/plain', 'application/msword'];
      case MediaType.other:
        return [];
    }
  }
}

/// Статусы контента
enum ContentStatus {
  uploaded,
  processing,
  processed,
  published,
  archived,
  error,
}

/// Расширение для статусов контента
extension ContentStatusExtension on ContentStatus {
  String get displayName {
    switch (this) {
      case ContentStatus.uploaded:
        return 'Загружено';
      case ContentStatus.processing:
        return 'Обрабатывается';
      case ContentStatus.processed:
        return 'Обработано';
      case ContentStatus.published:
        return 'Опубликовано';
      case ContentStatus.archived:
        return 'Архивировано';
      case ContentStatus.error:
        return 'Ошибка';
    }
  }

  String get color {
    switch (this) {
      case ContentStatus.uploaded:
        return 'blue';
      case ContentStatus.processing:
        return 'orange';
      case ContentStatus.processed:
        return 'green';
      case ContentStatus.published:
        return 'purple';
      case ContentStatus.archived:
        return 'grey';
      case ContentStatus.error:
        return 'red';
    }
  }
}

/// Типы галерей
enum GalleryType {
  portfolio,
  event,
  showcase,
  archive,
  temporary,
}

/// Расширение для типов галерей
extension GalleryTypeExtension on GalleryType {
  String get displayName {
    switch (this) {
      case GalleryType.portfolio:
        return 'Портфолио';
      case GalleryType.event:
        return 'Событие';
      case GalleryType.showcase:
        return 'Витрина';
      case GalleryType.archive:
        return 'Архив';
      case GalleryType.temporary:
        return 'Временная';
    }
  }

  String get icon {
    switch (this) {
      case GalleryType.portfolio:
        return '🎨';
      case GalleryType.event:
        return '🎉';
      case GalleryType.showcase:
        return '🖼️';
      case GalleryType.archive:
        return '📦';
      case GalleryType.temporary:
        return '⏰';
    }
  }
}

/// Типы обработки
enum ProcessingType {
  thumbnail,
  resize,
  compress,
  watermark,
  filter,
  crop,
  rotate,
  convert,
}

/// Расширение для типов обработки
extension ProcessingTypeExtension on ProcessingType {
  String get displayName {
    switch (this) {
      case ProcessingType.thumbnail:
        return 'Миниатюра';
      case ProcessingType.resize:
        return 'Изменение размера';
      case ProcessingType.compress:
        return 'Сжатие';
      case ProcessingType.watermark:
        return 'Водяной знак';
      case ProcessingType.filter:
        return 'Фильтр';
      case ProcessingType.crop:
        return 'Обрезка';
      case ProcessingType.rotate:
        return 'Поворот';
      case ProcessingType.convert:
        return 'Конвертация';
    }
  }
}

/// Статусы обработки
enum ProcessingStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// Расширение для статусов обработки
extension ProcessingStatusExtension on ProcessingStatus {
  String get displayName {
    switch (this) {
      case ProcessingStatus.pending:
        return 'Ожидает';
      case ProcessingStatus.inProgress:
        return 'В процессе';
      case ProcessingStatus.completed:
        return 'Завершено';
      case ProcessingStatus.failed:
        return 'Ошибка';
      case ProcessingStatus.cancelled:
        return 'Отменено';
    }
  }

  String get color {
    switch (this) {
      case ProcessingStatus.pending:
        return 'orange';
      case ProcessingStatus.inProgress:
        return 'blue';
      case ProcessingStatus.completed:
        return 'green';
      case ProcessingStatus.failed:
        return 'red';
      case ProcessingStatus.cancelled:
        return 'grey';
    }
  }
}
