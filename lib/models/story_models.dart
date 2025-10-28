import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/story_content_type.dart';

/// Статус истории
enum StoryStatus { draft, published, archived, deleted }

/// Модель истории
class Story {
  const Story({
    required this.id,
    required this.specialistId,
    required this.contentType,
    required this.status,
    required this.createdAt, this.title,
    this.description,
    this.mediaUrl,
    this.thumbnailUrl,
    this.duration,
    this.text,
    this.metadata = const {},
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isViewed = false,
    this.isShared = false,
    this.expiresAt,
    this.updatedAt,
  });

  /// Создать из Map
  factory Story.fromMap(Map<String, dynamic> data) {
    return Story(
      id: data['id'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      contentType: _parseContentType(data['contentType']),
      status: _parseStatus(data['status']),
      title: data['title'] as String?,
      description: data['description'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      duration: data['duration'] != null
          ? Duration(milliseconds: data['duration'] as int)
          : null,
      text: data['text'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      views: data['views'] as int? ?? 0,
      likes: data['likes'] as int? ?? 0,
      comments: data['comments'] as int? ?? 0,
      shares: data['shares'] as int? ?? 0,
      isLiked: data['isLiked'] as bool? ?? false,
      isViewed: data['isViewed'] as bool? ?? false,
      isShared: data['isShared'] as bool? ?? false,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] is Timestamp
              ? (data['expiresAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['expiresAt'].toString()))
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Story.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String specialistId;
  final StoryContentType contentType;
  final StoryStatus status;
  final String? title;
  final String? description;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? text;
  final Map<String, dynamic> metadata;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final bool isViewed;
  final bool isShared;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'contentType': contentType.name,
        'status': status.name,
        'title': title,
        'description': description,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration?.inMilliseconds,
        'text': text,
        'metadata': metadata,
        'views': views,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'isLiked': isLiked,
        'isViewed': isViewed,
        'isShared': isShared,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  Story copyWith({
    String? id,
    String? specialistId,
    StoryContentType? contentType,
    StoryStatus? status,
    String? title,
    String? description,
    String? mediaUrl,
    String? thumbnailUrl,
    Duration? duration,
    String? text,
    Map<String, dynamic>? metadata,
    int? views,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
    bool? isViewed,
    bool? isShared,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Story(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        contentType: contentType ?? this.contentType,
        status: status ?? this.status,
        title: title ?? this.title,
        description: description ?? this.description,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        duration: duration ?? this.duration,
        text: text ?? this.text,
        metadata: metadata ?? this.metadata,
        views: views ?? this.views,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        shares: shares ?? this.shares,
        isLiked: isLiked ?? this.isLiked,
        isViewed: isViewed ?? this.isViewed,
        isShared: isShared ?? this.isShared,
        expiresAt: expiresAt ?? this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа контента из строки
  static StoryContentType _parseContentType(String? contentType) {
    switch (contentType) {
      case 'image':
        return StoryContentType.image;
      case 'video':
        return StoryContentType.video;
      case 'text':
        return StoryContentType.text;
      case 'poll':
        return StoryContentType.poll;
      case 'quiz':
        return StoryContentType.quiz;
      case 'link':
        return StoryContentType.link;
      default:
        return StoryContentType.text;
    }
  }

  /// Парсинг статуса из строки
  static StoryStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft':
        return StoryStatus.draft;
      case 'published':
        return StoryStatus.published;
      case 'archived':
        return StoryStatus.archived;
      case 'deleted':
        return StoryStatus.deleted;
      default:
        return StoryStatus.draft;
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case StoryStatus.draft:
        return 'Черновик';
      case StoryStatus.published:
        return 'Опубликована';
      case StoryStatus.archived:
        return 'Архивирована';
      case StoryStatus.deleted:
        return 'Удалена';
    }
  }

  /// Проверить, опубликована ли история
  bool get isPublished => status == StoryStatus.published;

  /// Проверить, является ли история черновиком
  bool get isDraft => status == StoryStatus.draft;

  /// Проверить, архивирована ли история
  bool get isArchived => status == StoryStatus.archived;

  /// Проверить, удалена ли история
  bool get isDeleted => status == StoryStatus.deleted;

  /// Проверить, истекла ли история
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Проверить, является ли история медиа
  bool get isMedia => contentType.isMedia;

  /// Проверить, является ли история интерактивной
  bool get isInteractive => contentType.isInteractive;

  /// Получить отформатированную длительность
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Получить отформатированное количество просмотров
  String get formattedViews {
    if (views < 1000) {
      return views.toString();
    } else if (views < 1000000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    }
  }

  /// Получить отформатированное количество лайков
  String get formattedLikes {
    if (likes < 1000) {
      return likes.toString();
    } else if (likes < 1000000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    }
  }

  /// Получить отформатированное количество комментариев
  String get formattedComments {
    if (comments < 1000) {
      return comments.toString();
    } else if (comments < 1000000) {
      return '${(comments / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(comments / 1000000).toStringAsFixed(1)}M';
    }
  }

  /// Получить отформатированное количество репостов
  String get formattedShares {
    if (shares < 1000) {
      return shares.toString();
    } else if (shares < 1000000) {
      return '${(shares / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(shares / 1000000).toStringAsFixed(1)}M';
    }
  }
}

/// Модель просмотра истории
class StoryView {
  const StoryView({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.viewedAt,
    this.duration,
    this.isCompleted = false,
    this.metadata = const {},
  });

  /// Создать из Map
  factory StoryView.fromMap(Map<String, dynamic> data) {
    return StoryView(
      id: data['id'] as String? ?? '',
      storyId: data['storyId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      viewedAt: data['viewedAt'] != null
          ? (data['viewedAt'] is Timestamp
              ? (data['viewedAt'] as Timestamp).toDate()
              : DateTime.parse(data['viewedAt'].toString()))
          : DateTime.now(),
      duration: data['duration'] != null
          ? Duration(milliseconds: data['duration'] as int)
          : null,
      isCompleted: data['isCompleted'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из документа Firestore
  factory StoryView.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return StoryView.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String storyId;
  final String userId;
  final DateTime viewedAt;
  final Duration? duration;
  final bool isCompleted;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'storyId': storyId,
        'userId': userId,
        'viewedAt': Timestamp.fromDate(viewedAt),
        'duration': duration?.inMilliseconds,
        'isCompleted': isCompleted,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  StoryView copyWith({
    String? id,
    String? storyId,
    String? userId,
    DateTime? viewedAt,
    Duration? duration,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
  }) =>
      StoryView(
        id: id ?? this.id,
        storyId: storyId ?? this.storyId,
        userId: userId ?? this.userId,
        viewedAt: viewedAt ?? this.viewedAt,
        duration: duration ?? this.duration,
        isCompleted: isCompleted ?? this.isCompleted,
        metadata: metadata ?? this.metadata,
      );

  /// Получить отформатированную длительность просмотра
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Проверить, завершен ли просмотр
  bool get isCompleted => isCompleted;

  /// Проверить, есть ли длительность просмотра
  bool get hasDuration => duration != null;
}

/// Модель создания истории
class CreateStory {
  const CreateStory({
    required this.specialistId,
    required this.contentType,
    this.title,
    this.description,
    this.mediaUrl,
    this.thumbnailUrl,
    this.duration,
    this.text,
    this.metadata = const {},
    this.expiresAt,
  });

  /// Создать из Map
  factory CreateStory.fromMap(Map<String, dynamic> data) {
    return CreateStory(
      specialistId: data['specialistId'] as String? ?? '',
      contentType: _parseContentType(data['contentType']),
      title: data['title'] as String?,
      description: data['description'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      duration: data['duration'] != null
          ? Duration(milliseconds: data['duration'] as int)
          : null,
      text: data['text'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] is Timestamp
              ? (data['expiresAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['expiresAt'].toString()))
          : null,
    );
  }

  final String specialistId;
  final StoryContentType contentType;
  final String? title;
  final String? description;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? text;
  final Map<String, dynamic> metadata;
  final DateTime? expiresAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'contentType': contentType.name,
        'title': title,
        'description': description,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration?.inMilliseconds,
        'text': text,
        'metadata': metadata,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };

  /// Копировать с изменениями
  CreateStory copyWith({
    String? specialistId,
    StoryContentType? contentType,
    String? title,
    String? description,
    String? mediaUrl,
    String? thumbnailUrl,
    Duration? duration,
    String? text,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
  }) =>
      CreateStory(
        specialistId: specialistId ?? this.specialistId,
        contentType: contentType ?? this.contentType,
        title: title ?? this.title,
        description: description ?? this.description,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        duration: duration ?? this.duration,
        text: text ?? this.text,
        metadata: metadata ?? this.metadata,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  /// Парсинг типа контента из строки
  static StoryContentType _parseContentType(String? contentType) {
    switch (contentType) {
      case 'image':
        return StoryContentType.image;
      case 'video':
        return StoryContentType.video;
      case 'text':
        return StoryContentType.text;
      case 'poll':
        return StoryContentType.poll;
      case 'quiz':
        return StoryContentType.quiz;
      case 'link':
        return StoryContentType.link;
      default:
        return StoryContentType.text;
    }
  }

  /// Проверить, валидна ли история для создания
  bool get isValid {
    if (specialistId.isEmpty) return false;
    if (contentType == StoryContentType.text && (text?.isEmpty ?? true)) {
      return false;
    }
    if (contentType.isMedia && (mediaUrl?.isEmpty ?? true)) return false;
    return true;
  }

  /// Получить отформатированную длительность
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
