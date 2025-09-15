import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель идеи
class Idea {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final IdeaStatus status;
  final IdeaType type;
  final int likesCount;
  final int viewsCount;
  final int savesCount;
  final int commentsCount;
  final List<String> likedBy;
  final List<String> savedBy;
  final List<IdeaImage> images;
  final List<IdeaComment> comments;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.tags = const [],
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.status,
    required this.type,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.savedBy = const [],
    this.images = const [],
    this.comments = const [],
    this.metadata = const {},
    this.isPublic = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Idea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Idea(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      status: IdeaStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => IdeaStatus.draft,
      ),
      type: IdeaType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => IdeaType.general,
      ),
      likesCount: data['likesCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      savesCount: data['savesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      savedBy: List<String>.from(data['savedBy'] ?? []),
      images: (data['images'] as List<dynamic>?)
          ?.map((e) => IdeaImage.fromMap(e))
          .toList() ?? [],
      comments: (data['comments'] as List<dynamic>?)
          ?.map((e) => IdeaComment.fromMap(e))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isPublic: data['isPublic'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'status': status.name,
      'type': type.name,
      'likesCount': likesCount,
      'viewsCount': viewsCount,
      'savesCount': savesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'savedBy': savedBy,
      'images': images.map((e) => e.toMap()).toList(),
      'comments': comments.map((e) => e.toMap()).toList(),
      'metadata': metadata,
      'isPublic': isPublic,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Idea copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    IdeaStatus? status,
    IdeaType? type,
    int? likesCount,
    int? viewsCount,
    int? savesCount,
    int? commentsCount,
    List<String>? likedBy,
    List<String>? savedBy,
    List<IdeaImage>? images,
    List<IdeaComment>? comments,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      status: status ?? this.status,
      type: type ?? this.type,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      savesCount: savesCount ?? this.savesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      savedBy: savedBy ?? this.savedBy,
      images: images ?? this.images,
      comments: comments ?? this.comments,
      metadata: metadata ?? this.metadata,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Проверить, лайкнул ли пользователь идею
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  /// Проверить, сохранил ли пользователь идею
  bool isSavedBy(String userId) {
    return savedBy.contains(userId);
  }

  /// Получить цвет категории
  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'декор':
        return Colors.pink;
      case 'еда':
        return Colors.orange;
      case 'развлечения':
        return Colors.purple;
      case 'фото':
        return Colors.blue;
      case 'музыка':
        return Colors.green;
      case 'одежда':
        return Colors.red;
      case 'подарки':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// Получить иконку категории
  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'декор':
        return Icons.home;
      case 'еда':
        return Icons.restaurant;
      case 'развлечения':
        return Icons.celebration;
      case 'фото':
        return Icons.camera_alt;
      case 'музыка':
        return Icons.music_note;
      case 'одежда':
        return Icons.checkroom;
      case 'подарки':
        return Icons.card_giftcard;
      default:
        return Icons.lightbulb;
    }
  }

  /// Получить цвет статуса
  Color get statusColor {
    switch (status) {
      case IdeaStatus.draft:
        return Colors.grey;
      case IdeaStatus.published:
        return Colors.green;
      case IdeaStatus.archived:
        return Colors.orange;
      case IdeaStatus.deleted:
        return Colors.red;
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case IdeaStatus.draft:
        return 'Черновик';
      case IdeaStatus.published:
        return 'Опубликовано';
      case IdeaStatus.archived:
        return 'Архив';
      case IdeaStatus.deleted:
        return 'Удалено';
    }
  }
}

/// Статус идеи
enum IdeaStatus {
  draft,
  published,
  archived,
  deleted,
}

/// Тип идеи
enum IdeaType {
  general,
  wedding,
  birthday,
  corporate,
  holiday,
  other,
}

/// Изображение идеи
class IdeaImage {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final int order;
  final DateTime createdAt;

  const IdeaImage({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.order = 0,
    required this.createdAt,
  });

  factory IdeaImage.fromMap(Map<String, dynamic> map) {
    return IdeaImage(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      caption: map['caption'],
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  IdeaImage copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    String? caption,
    int? order,
    DateTime? createdAt,
  }) {
    return IdeaImage(
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Комментарий к идее
class IdeaComment {
  final String id;
  final String ideaId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String content;
  final List<String> likedBy;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IdeaComment({
    required this.id,
    required this.ideaId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.content,
    this.likedBy = const [],
    this.likesCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IdeaComment.fromMap(Map<String, dynamic> map) {
    return IdeaComment(
      id: map['id'] ?? '',
      ideaId: map['ideaId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhotoUrl: map['authorPhotoUrl'],
      content: map['content'] ?? '',
      likedBy: List<String>.from(map['likedBy'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ideaId': ideaId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'likedBy': likedBy,
      'likesCount': likesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  IdeaComment copyWith({
    String? id,
    String? ideaId,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    String? content,
    List<String>? likedBy,
    int? likesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdeaComment(
      id: id ?? this.id,
      ideaId: ideaId ?? this.ideaId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      content: content ?? this.content,
      likedBy: likedBy ?? this.likedBy,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Проверить, лайкнул ли пользователь комментарий
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}

/// Фильтр для идей
class IdeaFilter {
  final String? category;
  final List<String>? tags;
  final IdeaStatus? status;
  final IdeaType? type;
  final String? authorId;
  final bool? isPublic;
  final bool? isFeatured;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final IdeaSortBy sortBy;
  final bool sortAscending;

  const IdeaFilter({
    this.category,
    this.tags,
    this.status,
    this.type,
    this.authorId,
    this.isPublic,
    this.isFeatured,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.sortBy = IdeaSortBy.date,
    this.sortAscending = false,
  });

  IdeaFilter copyWith({
    String? category,
    List<String>? tags,
    IdeaStatus? status,
    IdeaType? type,
    String? authorId,
    bool? isPublic,
    bool? isFeatured,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    IdeaSortBy? sortBy,
    bool? sortAscending,
  }) {
    return IdeaFilter(
      category: category ?? this.category,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// Сортировка идей
enum IdeaSortBy {
  date,
  likes,
  views,
  saves,
  comments,
  title,
}

/// Статистика идей
class IdeaStats {
  final int totalIdeas;
  final int publishedIdeas;
  final int draftIdeas;
  final int archivedIdeas;
  final int totalLikes;
  final int totalViews;
  final int totalSaves;
  final int totalComments;
  final Map<String, int> ideasByCategory;
  final Map<String, int> ideasByType;
  final List<String> topTags;
  final List<String> topAuthors;

  const IdeaStats({
    required this.totalIdeas,
    required this.publishedIdeas,
    required this.draftIdeas,
    required this.archivedIdeas,
    required this.totalLikes,
    required this.totalViews,
    required this.totalSaves,
    required this.totalComments,
    required this.ideasByCategory,
    required this.ideasByType,
    required this.topTags,
    required this.topAuthors,
  });

  factory IdeaStats.empty() {
    return const IdeaStats(
      totalIdeas: 0,
      publishedIdeas: 0,
      draftIdeas: 0,
      archivedIdeas: 0,
      totalLikes: 0,
      totalViews: 0,
      totalSaves: 0,
      totalComments: 0,
      ideasByCategory: {},
      ideasByType: {},
      topTags: [],
      topAuthors: [],
    );
  }
}

/// Коллекция идей пользователя
class IdeaCollection {
  final String id;
  final String name;
  final String description;
  final String userId;
  final List<String> ideaIds;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IdeaCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    this.ideaIds = const [],
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IdeaCollection.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return IdeaCollection(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      ideaIds: List<String>.from(data['ideaIds'] ?? []),
      isPublic: data['isPublic'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
      'ideaIds': ideaIds,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  IdeaCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    List<String>? ideaIds,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdeaCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      ideaIds: ideaIds ?? this.ideaIds,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
