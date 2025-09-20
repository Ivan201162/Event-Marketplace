import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель идеи для мероприятий
class Idea {
  const Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.category,
    required this.tags,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.likesCount,
    required this.savesCount,
    required this.commentsCount,
    required this.likedBy,
    required this.savedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublic,
    this.sourceUrl,
    this.metadata = const {},
  });

  /// Создать из Map
  factory Idea.fromMap(Map<String, dynamic> data) => Idea(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        images: List<String>.from(data['images'] ?? []),
        category: data['category'] ?? '',
        tags: List<String>.from(data['tags'] ?? []),
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? '',
        authorAvatar: data['authorAvatar'],
        likesCount: data['likesCount'] ?? 0,
        savesCount: data['savesCount'] ?? 0,
        commentsCount: data['commentsCount'] ?? 0,
        likedBy: List<String>.from(data['likedBy'] ?? []),
        savedBy: List<String>.from(data['savedBy'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        isPublic: data['isPublic'] ?? true,
        sourceUrl: data['sourceUrl'],
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String category;
  final List<String> tags;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final int likesCount;
  final int savesCount;
  final int commentsCount;
  final List<String> likedBy;
  final List<String> savedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final String? sourceUrl;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'images': images,
        'category': category,
        'tags': tags,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'likesCount': likesCount,
        'savesCount': savesCount,
        'commentsCount': commentsCount,
        'likedBy': likedBy,
        'savedBy': savedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isPublic': isPublic,
        'sourceUrl': sourceUrl,
        'metadata': metadata,
      };

  /// Геттеры для совместимости с виджетами
  String? get authorPhotoUrl => authorAvatar;
  int get viewsCount => metadata['viewsCount'] as int? ?? 0;
  String? get url => sourceUrl;

  /// Цвет категории
  String get categoryColor {
    switch (category.toLowerCase()) {
      case 'декор':
        return 'pink';
      case 'еда':
        return 'orange';
      case 'развлечения':
        return 'purple';
      case 'фото':
        return 'blue';
      case 'музыка':
        return 'green';
      case 'одежда':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Иконка категории
  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'декор':
        return '🎨';
      case 'еда':
        return '🍰';
      case 'развлечения':
        return '🎪';
      case 'фото':
        return '📸';
      case 'музыка':
        return '🎵';
      case 'одежда':
        return '👗';
      default:
        return '💡';
    }
  }

  /// Копировать с изменениями
  Idea copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    String? category,
    List<String>? tags,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    int? likesCount,
    int? savesCount,
    int? commentsCount,
    List<String>? likedBy,
    List<String>? savedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    String? sourceUrl,
    Map<String, dynamic>? metadata,
  }) =>
      Idea(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        images: images ?? this.images,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        likesCount: likesCount ?? this.likesCount,
        savesCount: savesCount ?? this.savesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedBy: likedBy ?? this.likedBy,
        savedBy: savedBy ?? this.savedBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPublic: isPublic ?? this.isPublic,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        metadata: metadata ?? this.metadata,
      );
}

/// Модель коллекции идей
class IdeaCollection {
  const IdeaCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    required this.ideaIds,
    required this.images,
    required this.isPublic,
    required this.followersCount,
    required this.followers,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Создать из Map
  factory IdeaCollection.fromMap(Map<String, dynamic> data) => IdeaCollection(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        ownerId: data['ownerId'] ?? '',
        ownerName: data['ownerName'] ?? '',
        ownerAvatar: data['ownerAvatar'],
        ideaIds: List<String>.from(data['ideaIds'] ?? []),
        images: List<String>.from(data['images'] ?? []),
        isPublic: data['isPublic'] ?? true,
        followersCount: data['followersCount'] ?? 0,
        followers: List<String>.from(data['followers'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final List<String> ideaIds;
  final List<String> images; // Превью изображений
  final bool isPublic;
  final int followersCount;
  final List<String> followers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerAvatar': ownerAvatar,
        'ideaIds': ideaIds,
        'images': images,
        'isPublic': isPublic,
        'followersCount': followersCount,
        'followers': followers,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
      };

  /// Копировать с изменениями
  IdeaCollection copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    List<String>? ideaIds,
    List<String>? images,
    bool? isPublic,
    int? followersCount,
    List<String>? followers,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      IdeaCollection(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        ownerId: ownerId ?? this.ownerId,
        ownerName: ownerName ?? this.ownerName,
        ownerAvatar: ownerAvatar ?? this.ownerAvatar,
        ideaIds: ideaIds ?? this.ideaIds,
        images: images ?? this.images,
        isPublic: isPublic ?? this.isPublic,
        followersCount: followersCount ?? this.followersCount,
        followers: followers ?? this.followers,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Модель комментария к идее
class IdeaComment {
  // Для ответов на комментарии

  const IdeaComment({
    required this.id,
    required this.ideaId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likedBy,
    required this.likesCount,
    this.parentCommentId,
  });

  /// Создать из Map
  factory IdeaComment.fromMap(Map<String, dynamic> data) => IdeaComment(
        id: data['id'] ?? '',
        ideaId: data['ideaId'] ?? '',
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? '',
        authorAvatar: data['authorAvatar'],
        content: data['content'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        likedBy: List<String>.from(data['likedBy'] ?? []),
        likesCount: data['likesCount'] ?? 0,
        parentCommentId: data['parentCommentId'],
      );
  final String id;
  final String ideaId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likedBy;
  final int likesCount;
  final String? parentCommentId;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'ideaId': ideaId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'likedBy': likedBy,
        'likesCount': likesCount,
        'parentCommentId': parentCommentId,
      };

  /// Копировать с изменениями
  IdeaComment copyWith({
    String? id,
    String? ideaId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likedBy,
    int? likesCount,
    String? parentCommentId,
  }) =>
      IdeaComment(
        id: id ?? this.id,
        ideaId: ideaId ?? this.ideaId,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        likedBy: likedBy ?? this.likedBy,
        likesCount: likesCount ?? this.likesCount,
        parentCommentId: parentCommentId ?? this.parentCommentId,
      );
}

/// Категории идей
enum IdeaCategory {
  wedding,
  birthday,
  corporate,
  holiday,
  graduation,
  anniversary,
  babyShower,
  other;

  String get displayName {
    switch (this) {
      case IdeaCategory.wedding:
        return 'Свадьба';
      case IdeaCategory.birthday:
        return 'День рождения';
      case IdeaCategory.corporate:
        return 'Корпоратив';
      case IdeaCategory.holiday:
        return 'Праздник';
      case IdeaCategory.graduation:
        return 'Выпускной';
      case IdeaCategory.anniversary:
        return 'Юбилей';
      case IdeaCategory.babyShower:
        return 'Baby Shower';
      case IdeaCategory.other:
        return 'Другое';
    }
  }

  /// Проверить, лайкнул ли пользователь
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Проверить, сохранил ли пользователь
  bool isSavedBy(String userId) => savedBy.contains(userId);
}
