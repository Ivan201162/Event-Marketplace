/// Расширенная модель поста в ленте
class EnhancedFeedPost {
  const EnhancedFeedPost({
    required this.id,
    required this.authorId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.media = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.likes = const [],
    this.comments = const [],
    this.shares = const [],
    this.saves = const [],
    this.tags = const [],
    this.location,
    this.category,
    this.isSponsored = false,
    this.isPinned = false,
    this.isArchived = false,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Создать из Map
  factory EnhancedFeedPost.fromMap(Map<String, dynamic> map) => EnhancedFeedPost(
        id: map['id'] as String,
        authorId: map['authorId'] as String,
        content: map['content'] as String,
        type: FeedPostType.fromString(map['type'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        media: (map['media'] as List?)
                ?.map(
                  (media) => FeedPostMedia.fromMap(media as Map<String, dynamic>),
                )
                .toList() ??
            [],
        likesCount: (map['likesCount'] as int?) ?? 0,
        commentsCount: (map['commentsCount'] as int?) ?? 0,
        sharesCount: (map['sharesCount'] as int?) ?? 0,
        savesCount: (map['savesCount'] as int?) ?? 0,
        viewsCount: (map['viewsCount'] as int?) ?? 0,
        likes: List<String>.from((map['likes'] as List?) ?? []),
        comments: (map['comments'] as List?)
                ?.map(
                  (comment) => FeedPostComment.fromMap(comment as Map<String, dynamic>),
                )
                .toList() ??
            [],
        shares: (map['shares'] as List?)
                ?.map(
                  (share) => FeedPostShare.fromMap(share as Map<String, dynamic>),
                )
                .toList() ??
            [],
        saves: List<String>.from((map['saves'] as List?) ?? []),
        tags: List<String>.from((map['tags'] as List?) ?? []),
        location: map['location'] as String?,
        category: map['category'] as String?,
        isSponsored: (map['isSponsored'] as bool?) ?? false,
        isPinned: (map['isPinned'] as bool?) ?? false,
        isArchived: (map['isArchived'] as bool?) ?? false,
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
            : null,
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  /// Уникальный идентификатор
  final String id;

  /// ID автора
  final String authorId;

  /// Содержимое поста
  final String content;

  /// Тип поста
  final FeedPostType type;

  /// Дата создания
  final DateTime createdAt;

  /// Медиафайлы
  final List<FeedPostMedia> media;

  /// Количество лайков
  final int likesCount;

  /// Количество комментариев
  final int commentsCount;

  /// Количество репостов
  final int sharesCount;

  /// Количество сохранений
  final int savesCount;

  /// Количество просмотров
  final int viewsCount;

  /// Пользователи, поставившие лайк
  final List<String> likes;

  /// Комментарии
  final List<FeedPostComment> comments;

  /// Репосты
  final List<FeedPostShare> shares;

  /// Сохранения
  final List<String> saves;

  /// Теги
  final List<String> tags;

  /// Местоположение
  final String? location;

  /// Категория поста
  final String? category;

  /// Рекламный пост
  final bool isSponsored;

  /// Закреплённый пост
  final bool isPinned;

  /// Архивированный пост
  final bool isArchived;

  /// Дата обновления
  final DateTime? updatedAt;

  /// Дополнительные данные
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'content': content,
        'type': type.value,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'media': media.map((media) => media.toMap()).toList(),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'savesCount': savesCount,
        'viewsCount': viewsCount,
        'likes': likes,
        'comments': comments.map((comment) => comment.toMap()).toList(),
        'shares': shares.map((share) => share.toMap()).toList(),
        'saves': saves,
        'tags': tags,
        'location': location,
        'category': category,
        'isSponsored': isSponsored,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  EnhancedFeedPost copyWith({
    String? id,
    String? authorId,
    String? content,
    FeedPostType? type,
    DateTime? createdAt,
    List<FeedPostMedia>? media,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,
    int? viewsCount,
    List<String>? likes,
    List<FeedPostComment>? comments,
    List<FeedPostShare>? shares,
    List<String>? saves,
    List<String>? tags,
    String? location,
    String? category,
    bool? isSponsored,
    bool? isPinned,
    bool? isArchived,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      EnhancedFeedPost(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        content: content ?? this.content,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        media: media ?? this.media,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        sharesCount: sharesCount ?? this.sharesCount,
        savesCount: savesCount ?? this.savesCount,
        viewsCount: viewsCount ?? this.viewsCount,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        shares: shares ?? this.shares,
        saves: saves ?? this.saves,
        tags: tags ?? this.tags,
        location: location ?? this.location,
        category: category ?? this.category,
        isSponsored: isSponsored ?? this.isSponsored,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Тип поста в ленте
enum FeedPostType {
  text('text'),
  image('image'),
  video('video'),
  carousel('carousel'),
  reel('reel'),
  story('story'),
  live('live');

  const FeedPostType(this.value);
  final String value;

  static FeedPostType fromString(String value) {
    switch (value) {
      case 'text':
        return FeedPostType.text;
      case 'image':
        return FeedPostType.image;
      case 'video':
        return FeedPostType.video;
      case 'carousel':
        return FeedPostType.carousel;
      case 'reel':
        return FeedPostType.reel;
      case 'story':
        return FeedPostType.story;
      case 'live':
        return FeedPostType.live;
      default:
        return FeedPostType.text;
    }
  }

  String get displayName {
    switch (this) {
      case FeedPostType.text:
        return 'Текст';
      case FeedPostType.image:
        return 'Фото';
      case FeedPostType.video:
        return 'Видео';
      case FeedPostType.carousel:
        return 'Карусель';
      case FeedPostType.reel:
        return 'Reel';
      case FeedPostType.story:
        return 'История';
      case FeedPostType.live:
        return 'Прямой эфир';
    }
  }

  String get icon {
    switch (this) {
      case FeedPostType.text:
        return '📝';
      case FeedPostType.image:
        return '🖼️';
      case FeedPostType.video:
        return '🎥';
      case FeedPostType.carousel:
        return '🎠';
      case FeedPostType.reel:
        return '🎬';
      case FeedPostType.story:
        return '📖';
      case FeedPostType.live:
        return '🔴';
    }
  }
}

/// Медиафайл поста
class FeedPostMedia {
  const FeedPostMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.width,
    required this.height,
    this.thumbnailUrl,
    this.duration,
    this.caption,
    this.altText,
    this.metadata = const {},
  });

  factory FeedPostMedia.fromMap(Map<String, dynamic> map) => FeedPostMedia(
        id: map['id'] as String,
        url: map['url'] as String,
        type: FeedPostMediaType.fromString(map['type'] as String),
        width: map['width'] as int,
        height: map['height'] as int,
        thumbnailUrl: map['thumbnailUrl'] as String?,
        duration: map['duration'] != null ? Duration(milliseconds: map['duration'] as int) : null,
        caption: map['caption'] as String?,
        altText: map['altText'] as String?,
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  final String id;
  final String url;
  final FeedPostMediaType type;
  final int width;
  final int height;
  final String? thumbnailUrl;
  final Duration? duration;
  final String? caption;
  final String? altText;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'type': type.value,
        'width': width,
        'height': height,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration?.inMilliseconds,
        'caption': caption,
        'altText': altText,
        'metadata': metadata,
      };
}

/// Тип медиафайла поста
enum FeedPostMediaType {
  image('image'),
  video('video'),
  gif('gif'),
  audio('audio');

  const FeedPostMediaType(this.value);
  final String value;

  static FeedPostMediaType fromString(String value) {
    switch (value) {
      case 'image':
        return FeedPostMediaType.image;
      case 'video':
        return FeedPostMediaType.video;
      case 'gif':
        return FeedPostMediaType.gif;
      case 'audio':
        return FeedPostMediaType.audio;
      default:
        return FeedPostMediaType.image;
    }
  }

  String get icon {
    switch (this) {
      case FeedPostMediaType.image:
        return '🖼️';
      case FeedPostMediaType.video:
        return '🎥';
      case FeedPostMediaType.gif:
        return '🎞️';
      case FeedPostMediaType.audio:
        return '🎵';
    }
  }
}

/// Комментарий к посту
class FeedPostComment {
  const FeedPostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.replies = const [],
    this.likesCount = 0,
    this.likes = const [],
    this.mentions = const [],
    this.isEdited = false,
    this.editedAt,
  });

  factory FeedPostComment.fromMap(Map<String, dynamic> map) => FeedPostComment(
        id: map['id'] as String,
        postId: map['postId'] as String,
        authorId: map['authorId'] as String,
        text: map['text'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        parentId: map['parentId'] as String?,
        replies: (map['replies'] as List?)
                ?.map(
                  (reply) => FeedPostComment.fromMap(reply as Map<String, dynamic>),
                )
                .toList() ??
            [],
        likesCount: (map['likesCount'] as int?) ?? 0,
        likes: List<String>.from((map['likes'] as List?) ?? []),
        mentions: List<String>.from((map['mentions'] as List?) ?? []),
        isEdited: (map['isEdited'] as bool?) ?? false,
        editedAt: map['editedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'] as int)
            : null,
      );

  final String id;
  final String postId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final String? parentId;
  final List<FeedPostComment> replies;
  final int likesCount;
  final List<String> likes;
  final List<String> mentions;
  final bool isEdited;
  final DateTime? editedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'parentId': parentId,
        'replies': replies.map((reply) => reply.toMap()).toList(),
        'likesCount': likesCount,
        'likes': likes,
        'mentions': mentions,
        'isEdited': isEdited,
        'editedAt': editedAt?.millisecondsSinceEpoch,
      };
}

/// Репост поста
class FeedPostShare {
  const FeedPostShare({
    required this.id,
    required this.postId,
    required this.userId,
    required this.sharedAt,
    this.comment,
    this.targetChatId,
    this.targetUserId,
  });

  factory FeedPostShare.fromMap(Map<String, dynamic> map) => FeedPostShare(
        id: map['id'] as String,
        postId: map['postId'] as String,
        userId: map['userId'] as String,
        sharedAt: DateTime.fromMillisecondsSinceEpoch(map['sharedAt'] as int),
        comment: map['comment'] as String?,
        targetChatId: map['targetChatId'] as String?,
        targetUserId: map['targetUserId'] as String?,
      );

  final String id;
  final String postId;
  final String userId;
  final DateTime sharedAt;
  final String? comment;
  final String? targetChatId;
  final String? targetUserId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'sharedAt': sharedAt.millisecondsSinceEpoch,
        'comment': comment,
        'targetChatId': targetChatId,
        'targetUserId': targetUserId,
      };
}
