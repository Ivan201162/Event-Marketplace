import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус идеи
enum IdeaStatus { draft, published, archived, deleted }

/// Тип идеи
enum IdeaType {
  event,
  decoration,
  entertainment,
  catering,
  photography,
  music,
  venue,
  other
}

/// Модель идеи
class Idea {
  const Idea({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.category,
    this.tags = const [],
    this.images = const [],
    this.videos = const [],
    this.attachments = const [],
    this.budget,
    this.duration,
    this.difficulty,
    this.materials = const [],
    this.tools = const [],
    this.steps = const [],
    this.tips = const [],
    this.warnings = const [],
    this.source,
    this.credits,
    this.license,
    this.views = 0,
    this.likes = 0,
    this.saves = 0,
    this.shares = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isShared = false,
    this.isPublic = true,
    this.isFeatured = false,
    this.isVerified = false,
    this.metadata = const {},
    this.publishedAt,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String authorId;
  final String title;
  final String description;
  final IdeaType type;
  final IdeaStatus status;
  final String? category;
  final List<String> tags;
  final List<String> images;
  final List<String> videos;
  final List<String> attachments;
  final double? budget;
  final Duration? duration;
  final int? difficulty; // 1-5
  final List<String> materials;
  final List<String> tools;
  final List<String> steps;
  final List<String> tips;
  final List<String> warnings;
  final String? source;
  final String? credits;
  final String? license;
  final int views;
  final int likes;
  final int saves;
  final int shares;
  final int comments;
  final bool isLiked;
  final bool isSaved;
  final bool isShared;
  final bool isPublic;
  final bool isFeatured;
  final bool isVerified;
  final Map<String, dynamic> metadata;
  final DateTime? publishedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory Idea.fromMap(Map<String, dynamic> data) {
    return Idea(
      id: data['id'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      category: data['category'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
      budget: (data['budget'] as num?)?.toDouble(),
      duration: data['duration'] != null
          ? Duration(milliseconds: data['duration'] as int)
          : null,
      difficulty: data['difficulty'] as int?,
      materials: List<String>.from(data['materials'] ?? []),
      tools: List<String>.from(data['tools'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
      tips: List<String>.from(data['tips'] ?? []),
      warnings: List<String>.from(data['warnings'] ?? []),
      source: data['source'] as String?,
      credits: data['credits'] as String?,
      license: data['license'] as String?,
      views: data['views'] as int? ?? 0,
      likes: data['likes'] as int? ?? 0,
      saves: data['saves'] as int? ?? 0,
      shares: data['shares'] as int? ?? 0,
      comments: data['comments'] as int? ?? 0,
      isLiked: data['isLiked'] as bool? ?? false,
      isSaved: data['isSaved'] as bool? ?? false,
      isShared: data['isShared'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      publishedAt: data['publishedAt'] != null
          ? (data['publishedAt'] is Timestamp
              ? (data['publishedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['publishedAt'].toString()))
          : null,
      archivedAt: data['archivedAt'] != null
          ? (data['archivedAt'] is Timestamp
              ? (data['archivedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['archivedAt'].toString()))
          : null,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] is Timestamp
              ? (data['deletedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['deletedAt'].toString()))
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
  factory Idea.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Idea.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'category': category,
        'tags': tags,
        'images': images,
        'videos': videos,
        'attachments': attachments,
        'budget': budget,
        'duration': duration?.inMilliseconds,
        'difficulty': difficulty,
        'materials': materials,
        'tools': tools,
        'steps': steps,
        'tips': tips,
        'warnings': warnings,
        'source': source,
        'credits': credits,
        'license': license,
        'views': views,
        'likes': likes,
        'saves': saves,
        'shares': shares,
        'comments': comments,
        'isLiked': isLiked,
        'isSaved': isSaved,
        'isShared': isShared,
        'isPublic': isPublic,
        'isFeatured': isFeatured,
        'isVerified': isVerified,
        'metadata': metadata,
        'publishedAt':
            publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
        'archivedAt':
            archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
        'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  Idea copyWith({
    String? id,
    String? authorId,
    String? title,
    String? description,
    IdeaType? type,
    IdeaStatus? status,
    String? category,
    List<String>? tags,
    List<String>? images,
    List<String>? videos,
    List<String>? attachments,
    double? budget,
    Duration? duration,
    int? difficulty,
    List<String>? materials,
    List<String>? tools,
    List<String>? steps,
    List<String>? tips,
    List<String>? warnings,
    String? source,
    String? credits,
    String? license,
    int? views,
    int? likes,
    int? saves,
    int? shares,
    int? comments,
    bool? isLiked,
    bool? isSaved,
    bool? isShared,
    bool? isPublic,
    bool? isFeatured,
    bool? isVerified,
    Map<String, dynamic>? metadata,
    DateTime? publishedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Idea(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        status: status ?? this.status,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        images: images ?? this.images,
        videos: videos ?? this.videos,
        attachments: attachments ?? this.attachments,
        budget: budget ?? this.budget,
        duration: duration ?? this.duration,
        difficulty: difficulty ?? this.difficulty,
        materials: materials ?? this.materials,
        tools: tools ?? this.tools,
        steps: steps ?? this.steps,
        tips: tips ?? this.tips,
        warnings: warnings ?? this.warnings,
        source: source ?? this.source,
        credits: credits ?? this.credits,
        license: license ?? this.license,
        views: views ?? this.views,
        likes: likes ?? this.likes,
        saves: saves ?? this.saves,
        shares: shares ?? this.shares,
        comments: comments ?? this.comments,
        isLiked: isLiked ?? this.isLiked,
        isSaved: isSaved ?? this.isSaved,
        isShared: isShared ?? this.isShared,
        isPublic: isPublic ?? this.isPublic,
        isFeatured: isFeatured ?? this.isFeatured,
        isVerified: isVerified ?? this.isVerified,
        metadata: metadata ?? this.metadata,
        publishedAt: publishedAt ?? this.publishedAt,
        archivedAt: archivedAt ?? this.archivedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static IdeaType _parseType(String? type) {
    switch (type) {
      case 'event':
        return IdeaType.event;
      case 'decoration':
        return IdeaType.decoration;
      case 'entertainment':
        return IdeaType.entertainment;
      case 'catering':
        return IdeaType.catering;
      case 'photography':
        return IdeaType.photography;
      case 'music':
        return IdeaType.music;
      case 'venue':
        return IdeaType.venue;
      case 'other':
        return IdeaType.other;
      default:
        return IdeaType.other;
    }
  }

  /// Парсинг статуса из строки
  static IdeaStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft':
        return IdeaStatus.draft;
      case 'published':
        return IdeaStatus.published;
      case 'archived':
        return IdeaStatus.archived;
      case 'deleted':
        return IdeaStatus.deleted;
      default:
        return IdeaStatus.draft;
    }
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case IdeaType.event:
        return 'Событие';
      case IdeaType.decoration:
        return 'Декор';
      case IdeaType.entertainment:
        return 'Развлечения';
      case IdeaType.catering:
        return 'Кейтеринг';
      case IdeaType.photography:
        return 'Фотография';
      case IdeaType.music:
        return 'Музыка';
      case IdeaType.venue:
        return 'Площадка';
      case IdeaType.other:
        return 'Другое';
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case IdeaStatus.draft:
        return 'Черновик';
      case IdeaStatus.published:
        return 'Опубликована';
      case IdeaStatus.archived:
        return 'Архивирована';
      case IdeaStatus.deleted:
        return 'Удалена';
    }
  }

  /// Проверить, опубликована ли идея
  bool get isPublished => status == IdeaStatus.published;

  /// Проверить, является ли идея черновиком
  bool get isDraft => status == IdeaStatus.draft;

  /// Проверить, архивирована ли идея
  bool get isArchived => status == IdeaStatus.archived;

  /// Проверить, удалена ли идея
  bool get isDeleted => status == IdeaStatus.deleted;

  /// Проверить, есть ли бюджет
  bool get hasBudget => budget != null;

  /// Проверить, есть ли длительность
  bool get hasDuration => duration != null;

  /// Проверить, есть ли сложность
  bool get hasDifficulty => difficulty != null;

  /// Проверить, есть ли материалы
  bool get hasMaterials => materials.isNotEmpty;

  /// Проверить, есть ли инструменты
  bool get hasTools => tools.isNotEmpty;

  /// Проверить, есть ли шаги
  bool get hasSteps => steps.isNotEmpty;

  /// Проверить, есть ли советы
  bool get hasTips => tips.isNotEmpty;

  /// Проверить, есть ли предупреждения
  bool get hasWarnings => warnings.isNotEmpty;

  /// Проверить, есть ли изображения
  bool get hasImages => images.isNotEmpty;

  /// Проверить, есть ли видео
  bool get hasVideos => videos.isNotEmpty;

  /// Проверить, есть ли вложения
  bool get hasAttachments => attachments.isNotEmpty;

  /// Проверить, есть ли теги
  bool get hasTags => tags.isNotEmpty;

  /// Проверить, есть ли источник
  bool get hasSource => source != null && source!.isNotEmpty;

  /// Проверить, есть ли кредиты
  bool get hasCredits => credits != null && credits!.isNotEmpty;

  /// Проверить, есть ли лицензия
  bool get hasLicense => license != null && license!.isNotEmpty;

  /// Получить отформатированный бюджет
  String get formattedBudget {
    if (budget == null) return 'Бюджет не указан';
    return '${budget!.toStringAsFixed(0)} ₽';
  }

  /// Получить отформатированную длительность
  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes % 60;
    if (hours > 0) {
      return '$hoursч $minutesм';
    } else {
      return '$minutesм';
    }
  }

  /// Получить отформатированную сложность
  String get formattedDifficulty {
    if (difficulty == null) return '';
    return '$difficulty/5';
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

  /// Получить отформатированное количество сохранений
  String get formattedSaves {
    if (saves < 1000) {
      return saves.toString();
    } else if (saves < 1000000) {
      return '${(saves / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(saves / 1000000).toStringAsFixed(1)}M';
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

  /// Получить звезды для отображения сложности
  List<bool> get difficultyStars {
    if (difficulty == null) return List.filled(5, false);
    final stars = <bool>[];
    for (int i = 1; i <= 5; i++) {
      stars.add(i <= difficulty!);
    }
    return stars;
  }
}
