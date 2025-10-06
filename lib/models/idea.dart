import 'package:cloud_firestore/cloud_firestore.dart';

/// Категория идеи
enum IdeaCategory {
  wedding('Свадьба', '💒'),
  birthday('День рождения', '🎂'),
  corporate('Корпоратив', '🏢'),
  children('Детский праздник', '🎈'),
  photo('Фотосессия', '📸'),
  video('Видеосъемка', '🎥'),
  decoration('Оформление', '🎨'),
  music('Музыка', '🎵'),
  food('Кейтеринг', '🍽️'),
  flowers('Цветы', '🌸'),
  other('Другое', '💡');

  const IdeaCategory(this.displayName, this.emoji);

  final String displayName;
  final String emoji;
}

/// Статус идеи
enum IdeaStatus {
  active, // Активная
  archived, // Архивированная
  deleted, // Удаленная
}

/// Модель идеи
class Idea {
  const Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    this.videoUrl,
    required this.category,
    required this.tags,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.likesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.likedBy = const [],
    this.savedBy = const [],
    this.metadata,
  });

  /// Создать из документа Firestore
  factory Idea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Idea(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      category: IdeaCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => IdeaCategory.other,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: IdeaStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => IdeaStatus.active,
      ),
      likesCount: data['likesCount'] as int? ?? 0,
      savesCount: data['savesCount'] as int? ?? 0,
      viewsCount: data['viewsCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      savedBy: List<String>.from(data['savedBy'] ?? []),
      metadata: data['metadata'],
    );
  }
  final String id;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String? videoUrl;
  final IdeaCategory category;
  final List<String> tags;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IdeaStatus status;
  final int likesCount;
  final int savesCount;
  final int viewsCount;
  final List<String> likedBy;
  final List<String> savedBy;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'category': category.name,
        'tags': tags,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'status': status.name,
        'likesCount': likesCount,
        'savesCount': savesCount,
        'viewsCount': viewsCount,
        'likedBy': likedBy,
        'savedBy': savedBy,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  Idea copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? imageUrls,
    String? videoUrl,
    IdeaCategory? category,
    List<String>? tags,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    IdeaStatus? status,
    int? likesCount,
    int? savesCount,
    int? viewsCount,
    List<String>? likedBy,
    List<String>? savedBy,
    Map<String, dynamic>? metadata,
  }) =>
      Idea(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrls: imageUrls ?? this.imageUrls,
        videoUrl: videoUrl ?? this.videoUrl,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        status: status ?? this.status,
        likesCount: likesCount ?? this.likesCount,
        savesCount: savesCount ?? this.savesCount,
        viewsCount: viewsCount ?? this.viewsCount,
        likedBy: likedBy ?? this.likedBy,
        savedBy: savedBy ?? this.savedBy,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, лайкнул ли пользователь идею
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Проверить, сохранил ли пользователь идею
  bool isSavedBy(String userId) => savedBy.contains(userId);

  /// Добавить лайк
  Idea addLike(String userId) {
    if (likedBy.contains(userId)) return this;

    return copyWith(
      likesCount: likesCount + 1,
      likedBy: [...likedBy, userId],
    );
  }

  /// Убрать лайк
  Idea removeLike(String userId) {
    if (!likedBy.contains(userId)) return this;

    return copyWith(
      likesCount: likesCount - 1,
      likedBy: likedBy.where((id) => id != userId).toList(),
    );
  }

  /// Добавить в сохраненные
  Idea addSave(String userId) {
    if (savedBy.contains(userId)) return this;

    return copyWith(
      savesCount: savesCount + 1,
      savedBy: [...savedBy, userId],
    );
  }

  /// Убрать из сохраненных
  Idea removeSave(String userId) {
    if (!savedBy.contains(userId)) return this;

    return copyWith(
      savesCount: savesCount - 1,
      savedBy: savedBy.where((id) => id != userId).toList(),
    );
  }

  /// Добавить просмотр
  Idea addView() => copyWith(viewsCount: viewsCount + 1);

  /// Получить основное изображение
  String? get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Проверить, есть ли видео
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Проверить, есть ли изображения
  bool get hasImages => imageUrls.isNotEmpty;

  /// Получить количество медиафайлов
  int get mediaCount => imageUrls.length + (hasVideo ? 1 : 0);
}

/// Коллекция идей пользователя
class IdeaCollection {
  const IdeaCollection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.ideaIds,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
  });

  /// Создать из документа Firestore
  factory IdeaCollection.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return IdeaCollection(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      ideaIds: List<String>.from(data['ideaIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isPublic: data['isPublic'] as bool? ?? false,
    );
  }
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> ideaIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
        'ideaIds': ideaIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isPublic': isPublic,
      };

  /// Создать копию с изменениями
  IdeaCollection copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? ideaIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
  }) =>
      IdeaCollection(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        description: description ?? this.description,
        ideaIds: ideaIds ?? this.ideaIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPublic: isPublic ?? this.isPublic,
      );

  /// Добавить идею в коллекцию
  IdeaCollection addIdea(String ideaId) {
    if (ideaIds.contains(ideaId)) return this;

    return copyWith(
      ideaIds: [...ideaIds, ideaId],
      updatedAt: DateTime.now(),
    );
  }

  /// Удалить идею из коллекции
  IdeaCollection removeIdea(String ideaId) => copyWith(
        ideaIds: ideaIds.where((id) => id != ideaId).toList(),
        updatedAt: DateTime.now(),
      );

  /// Проверить, содержит ли коллекция идею
  bool containsIdea(String ideaId) => ideaIds.contains(ideaId);

  /// Получить количество идей
  int get ideasCount => ideaIds.length;
}

/// Статистика идей
class IdeaStats {
  const IdeaStats({
    required this.totalIdeas,
    required this.totalLikes,
    required this.totalSaves,
    required this.totalViews,
    required this.categoryStats,
    required this.topTags,
    this.lastIdeaAt,
  });

  /// Создать из списка идей
  factory IdeaStats.fromIdeas(List<Idea> ideas) {
    final totalLikes = ideas.fold(0, (sum, idea) => sum + idea.likesCount);
    final totalSaves = ideas.fold(0, (sum, idea) => sum + idea.savesCount);
    final totalViews = ideas.fold(0, (sum, idea) => sum + idea.viewsCount);

    final categoryStats = <IdeaCategory, int>{};
    for (final idea in ideas) {
      categoryStats[idea.category] = (categoryStats[idea.category] ?? 0) + 1;
    }

    final tagCounts = <String, int>{};
    for (final idea in ideas) {
      for (final tag in idea.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final lastIdea = ideas.isNotEmpty
        ? ideas.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    return IdeaStats(
      totalIdeas: ideas.length,
      totalLikes: totalLikes,
      totalSaves: totalSaves,
      totalViews: totalViews,
      categoryStats: categoryStats,
      topTags: topTags.take(10).map((e) => e.key).toList(),
      lastIdeaAt: lastIdea?.createdAt,
    );
  }
  final int totalIdeas;
  final int totalLikes;
  final int totalSaves;
  final int totalViews;
  final Map<IdeaCategory, int> categoryStats;
  final List<String> topTags;
  final DateTime? lastIdeaAt;
}
