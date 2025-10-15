/// Расширенная модель идеи
class EnhancedIdea {
  const EnhancedIdea({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
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
    this.category,
    this.collectionId,
    this.specialistId,
    this.budget,
    this.timeline,
    this.location,
    this.isPublic = true,
    this.isFeatured = false,
    this.isArchived = false,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Создать из Map
  factory EnhancedIdea.fromMap(Map<String, dynamic> map) => EnhancedIdea(
        id: map['id'] as String,
        authorId: map['authorId'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        type: IdeaType.fromString(map['type'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        media: (map['media'] as List?)
                ?.map(
                  (media) => IdeaMedia.fromMap(media as Map<String, dynamic>),
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
                  (comment) =>
                      IdeaComment.fromMap(comment as Map<String, dynamic>),
                )
                .toList() ??
            [],
        shares: (map['shares'] as List?)
                ?.map(
                  (share) => IdeaShare.fromMap(share as Map<String, dynamic>),
                )
                .toList() ??
            [],
        saves: List<String>.from((map['saves'] as List?) ?? []),
        tags: List<String>.from((map['tags'] as List?) ?? []),
        category: map['category'] as String?,
        collectionId: map['collectionId'] as String?,
        specialistId: map['specialistId'] as String?,
        budget: (map['budget'] as num?)?.toDouble(),
        timeline: map['timeline'] as String?,
        location: map['location'] as String?,
        isPublic: (map['isPublic'] as bool?) ?? true,
        isFeatured: (map['isFeatured'] as bool?) ?? false,
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

  /// Заголовок идеи
  final String title;

  /// Описание идеи
  final String description;

  /// Тип идеи
  final IdeaType type;

  /// Дата создания
  final DateTime createdAt;

  /// Медиафайлы
  final List<IdeaMedia> media;

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
  final List<IdeaComment> comments;

  /// Репосты
  final List<IdeaShare> shares;

  /// Сохранения
  final List<String> saves;

  /// Теги
  final List<String> tags;

  /// Категория
  final String? category;

  /// ID коллекции
  final String? collectionId;

  /// ID связанного специалиста
  final String? specialistId;

  /// Бюджет
  final double? budget;

  /// Временные рамки
  final String? timeline;

  /// Местоположение
  final String? location;

  /// Публичная идея
  final bool isPublic;

  /// Рекомендуемая идея
  final bool isFeatured;

  /// Архивированная идея
  final bool isArchived;

  /// Дата обновления
  final DateTime? updatedAt;

  /// Дополнительные данные
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'title': title,
        'description': description,
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
        'category': category,
        'collectionId': collectionId,
        'specialistId': specialistId,
        'budget': budget,
        'timeline': timeline,
        'location': location,
        'isPublic': isPublic,
        'isFeatured': isFeatured,
        'isArchived': isArchived,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  EnhancedIdea copyWith({
    String? id,
    String? authorId,
    String? title,
    String? description,
    IdeaType? type,
    DateTime? createdAt,
    List<IdeaMedia>? media,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,
    int? viewsCount,
    List<String>? likes,
    List<IdeaComment>? comments,
    List<IdeaShare>? shares,
    List<String>? saves,
    List<String>? tags,
    String? category,
    String? collectionId,
    String? specialistId,
    double? budget,
    String? timeline,
    String? location,
    bool? isPublic,
    bool? isFeatured,
    bool? isArchived,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      EnhancedIdea(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        title: title ?? this.title,
        description: description ?? this.description,
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
        category: category ?? this.category,
        collectionId: collectionId ?? this.collectionId,
        specialistId: specialistId ?? this.specialistId,
        budget: budget ?? this.budget,
        timeline: timeline ?? this.timeline,
        location: location ?? this.location,
        isPublic: isPublic ?? this.isPublic,
        isFeatured: isFeatured ?? this.isFeatured,
        isArchived: isArchived ?? this.isArchived,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Тип идеи
enum IdeaType {
  general('general'),
  event('event'),
  wedding('wedding'),
  corporate('corporate'),
  birthday('birthday'),
  holiday('holiday'),
  photo('photo'),
  video('video'),
  design('design'),
  music('music'),
  food('food'),
  decoration('decoration');

  const IdeaType(this.value);
  final String value;

  static IdeaType fromString(String value) {
    switch (value) {
      case 'general':
        return IdeaType.general;
      case 'event':
        return IdeaType.event;
      case 'wedding':
        return IdeaType.wedding;
      case 'corporate':
        return IdeaType.corporate;
      case 'birthday':
        return IdeaType.birthday;
      case 'holiday':
        return IdeaType.holiday;
      case 'photo':
        return IdeaType.photo;
      case 'video':
        return IdeaType.video;
      case 'design':
        return IdeaType.design;
      case 'music':
        return IdeaType.music;
      case 'food':
        return IdeaType.food;
      case 'decoration':
        return IdeaType.decoration;
      default:
        return IdeaType.general;
    }
  }

  String get displayName {
    switch (this) {
      case IdeaType.general:
        return 'Общее';
      case IdeaType.event:
        return 'Событие';
      case IdeaType.wedding:
        return 'Свадьба';
      case IdeaType.corporate:
        return 'Корпоратив';
      case IdeaType.birthday:
        return 'День рождения';
      case IdeaType.holiday:
        return 'Праздник';
      case IdeaType.photo:
        return 'Фотосъёмка';
      case IdeaType.video:
        return 'Видеосъёмка';
      case IdeaType.design:
        return 'Дизайн';
      case IdeaType.music:
        return 'Музыка';
      case IdeaType.food:
        return 'Кейтеринг';
      case IdeaType.decoration:
        return 'Оформление';
    }
  }

  String get icon {
    switch (this) {
      case IdeaType.general:
        return '💡';
      case IdeaType.event:
        return '🎉';
      case IdeaType.wedding:
        return '💒';
      case IdeaType.corporate:
        return '🏢';
      case IdeaType.birthday:
        return '🎂';
      case IdeaType.holiday:
        return '🎊';
      case IdeaType.photo:
        return '📸';
      case IdeaType.video:
        return '🎥';
      case IdeaType.design:
        return '🎨';
      case IdeaType.music:
        return '🎵';
      case IdeaType.food:
        return '🍽️';
      case IdeaType.decoration:
        return '🎭';
    }
  }
}

/// Медиафайл идеи
class IdeaMedia {
  const IdeaMedia({
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

  factory IdeaMedia.fromMap(Map<String, dynamic> map) => IdeaMedia(
        id: map['id'] as String,
        url: map['url'] as String,
        type: IdeaMediaType.fromString(map['type'] as String),
        width: map['width'] as int,
        height: map['height'] as int,
        thumbnailUrl: map['thumbnailUrl'] as String?,
        duration: map['duration'] != null
            ? Duration(milliseconds: map['duration'] as int)
            : null,
        caption: map['caption'] as String?,
        altText: map['altText'] as String?,
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  final String id;
  final String url;
  final IdeaMediaType type;
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

/// Тип медиафайла идеи
enum IdeaMediaType {
  image('image'),
  video('video'),
  gif('gif'),
  audio('audio');

  const IdeaMediaType(this.value);
  final String value;

  static IdeaMediaType fromString(String value) {
    switch (value) {
      case 'image':
        return IdeaMediaType.image;
      case 'video':
        return IdeaMediaType.video;
      case 'gif':
        return IdeaMediaType.gif;
      case 'audio':
        return IdeaMediaType.audio;
      default:
        return IdeaMediaType.image;
    }
  }

  String get icon {
    switch (this) {
      case IdeaMediaType.image:
        return '🖼️';
      case IdeaMediaType.video:
        return '🎥';
      case IdeaMediaType.gif:
        return '🎞️';
      case IdeaMediaType.audio:
        return '🎵';
    }
  }
}

/// Комментарий к идее
class IdeaComment {
  const IdeaComment({
    required this.id,
    required this.ideaId,
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

  factory IdeaComment.fromMap(Map<String, dynamic> map) => IdeaComment(
        id: map['id'] as String,
        ideaId: map['ideaId'] as String,
        authorId: map['authorId'] as String,
        text: map['text'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        parentId: map['parentId'] as String?,
        replies: (map['replies'] as List?)
                ?.map(
                  (reply) => IdeaComment.fromMap(reply as Map<String, dynamic>),
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
  final String ideaId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final String? parentId;
  final List<IdeaComment> replies;
  final int likesCount;
  final List<String> likes;
  final List<String> mentions;
  final bool isEdited;
  final DateTime? editedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'ideaId': ideaId,
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

/// Репост идеи
class IdeaShare {
  const IdeaShare({
    required this.id,
    required this.ideaId,
    required this.userId,
    required this.sharedAt,
    this.comment,
    this.targetChatId,
    this.targetUserId,
  });

  factory IdeaShare.fromMap(Map<String, dynamic> map) => IdeaShare(
        id: map['id'] as String,
        ideaId: map['ideaId'] as String,
        userId: map['userId'] as String,
        sharedAt: DateTime.fromMillisecondsSinceEpoch(map['sharedAt'] as int),
        comment: map['comment'] as String?,
        targetChatId: map['targetChatId'] as String?,
        targetUserId: map['targetUserId'] as String?,
      );

  final String id;
  final String ideaId;
  final String userId;
  final DateTime sharedAt;
  final String? comment;
  final String? targetChatId;
  final String? targetUserId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'ideaId': ideaId,
        'userId': userId,
        'sharedAt': sharedAt.millisecondsSinceEpoch,
        'comment': comment,
        'targetChatId': targetChatId,
        'targetUserId': targetUserId,
      };
}

/// Коллекция идей
class IdeaCollection {
  const IdeaCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.createdAt,
    this.ideas = const [],
    this.coverImageUrl,
    this.isPublic = true,
    this.followersCount = 0,
    this.followers = const [],
    this.tags = const [],
    this.updatedAt,
  });

  factory IdeaCollection.fromMap(Map<String, dynamic> map) => IdeaCollection(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        authorId: map['authorId'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        ideas: List<String>.from((map['ideas'] as List?) ?? []),
        coverImageUrl: map['coverImageUrl'] as String?,
        isPublic: (map['isPublic'] as bool?) ?? true,
        followersCount: (map['followersCount'] as int?) ?? 0,
        followers: List<String>.from((map['followers'] as List?) ?? []),
        tags: List<String>.from((map['tags'] as List?) ?? []),
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
            : null,
      );

  final String id;
  final String name;
  final String description;
  final String authorId;
  final DateTime createdAt;
  final List<String> ideas;
  final String? coverImageUrl;
  final bool isPublic;
  final int followersCount;
  final List<String> followers;
  final List<String> tags;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'authorId': authorId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'ideas': ideas,
        'coverImageUrl': coverImageUrl,
        'isPublic': isPublic,
        'followersCount': followersCount,
        'followers': followers,
        'tags': tags,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
      };
}
