import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип контента в сторис
enum StoryContentType {
  image, // Изображение
  video, // Видео
  text, // Текстовый пост
}

/// Статус сторис
enum StoryStatus {
  active, // Активная
  expired, // Истекшая
  deleted, // Удаленная
}

/// Модель сторис специалиста
class SpecialistStory {
  const SpecialistStory({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    this.specialistAvatar,
    required this.contentType,
    required this.contentUrl,
    this.thumbnailUrl,
    this.text,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.viewCount = 0,
    this.viewers = const [],
    this.metadata,
  });

  /// Создать из документа Firestore
  factory SpecialistStory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistStory(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistAvatar: data['specialistAvatar'],
      contentType: StoryContentType.values.firstWhere(
        (e) => e.name == data['contentType'],
        orElse: () => StoryContentType.image,
      ),
      contentUrl: data['contentUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      text: data['text'],
      caption: data['caption'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      status: StoryStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StoryStatus.active,
      ),
      viewCount: data['viewCount'] as int? ?? 0,
      viewers: List<String>.from(data['viewers'] ?? []),
      metadata: data['metadata'],
    );
  }
  final String id;
  final String specialistId;
  final String specialistName;
  final String? specialistAvatar;
  final StoryContentType contentType;
  final String contentUrl;
  final String? thumbnailUrl;
  final String? text;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final StoryStatus status;
  final int viewCount;
  final List<String> viewers;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'specialistId': specialistId,
    'specialistName': specialistName,
    'specialistAvatar': specialistAvatar,
    'contentType': contentType.name,
    'contentUrl': contentUrl,
    'thumbnailUrl': thumbnailUrl,
    'text': text,
    'caption': caption,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'status': status.name,
    'viewCount': viewCount,
    'viewers': viewers,
    'metadata': metadata,
  };

  /// Создать копию с изменениями
  SpecialistStory copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? specialistAvatar,
    StoryContentType? contentType,
    String? contentUrl,
    String? thumbnailUrl,
    String? text,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    StoryStatus? status,
    int? viewCount,
    List<String>? viewers,
    Map<String, dynamic>? metadata,
  }) => SpecialistStory(
    id: id ?? this.id,
    specialistId: specialistId ?? this.specialistId,
    specialistName: specialistName ?? this.specialistName,
    specialistAvatar: specialistAvatar ?? this.specialistAvatar,
    contentType: contentType ?? this.contentType,
    contentUrl: contentUrl ?? this.contentUrl,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    text: text ?? this.text,
    caption: caption ?? this.caption,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    status: status ?? this.status,
    viewCount: viewCount ?? this.viewCount,
    viewers: viewers ?? this.viewers,
    metadata: metadata ?? this.metadata,
  );

  /// Проверить, истекла ли сторис
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Проверить, активна ли сторис
  bool get isActive => status == StoryStatus.active && !isExpired;

  /// Получить время до истечения
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Проверить, просматривал ли пользователь сторис
  bool hasViewed(String userId) => viewers.contains(userId);

  /// Добавить просмотр
  SpecialistStory addView(String userId) {
    if (viewers.contains(userId)) return this;

    return copyWith(viewCount: viewCount + 1, viewers: [...viewers, userId]);
  }

  /// Получить тип контента для отображения
  String get displayContentType {
    switch (contentType) {
      case StoryContentType.image:
        return 'Фото';
      case StoryContentType.video:
        return 'Видео';
      case StoryContentType.text:
        return 'Текст';
    }
  }

  /// Получить иконку для типа контента
  String get contentTypeIcon {
    switch (contentType) {
      case StoryContentType.image:
        return '📷';
      case StoryContentType.video:
        return '🎥';
      case StoryContentType.text:
        return '📝';
    }
  }
}

/// Группа сторис специалиста
class SpecialistStoryGroup {
  const SpecialistStoryGroup({
    required this.specialistId,
    required this.specialistName,
    this.specialistAvatar,
    required this.stories,
    required this.hasUnviewedStories,
    required this.lastStoryAt,
  });

  /// Создать из списка сторис
  factory SpecialistStoryGroup.fromStories(List<SpecialistStory> stories, String userId) {
    if (stories.isEmpty) {
      throw ArgumentError('Список сторис не может быть пустым');
    }

    final firstStory = stories.first;
    final hasUnviewed = stories.any((story) => !story.hasViewed(userId));
    final lastStory = stories.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);

    return SpecialistStoryGroup(
      specialistId: firstStory.specialistId,
      specialistName: firstStory.specialistName,
      specialistAvatar: firstStory.specialistAvatar,
      stories: stories.where((story) => story.isActive).toList(),
      hasUnviewedStories: hasUnviewed,
      lastStoryAt: lastStory.createdAt,
    );
  }
  final String specialistId;
  final String specialistName;
  final String? specialistAvatar;
  final List<SpecialistStory> stories;
  final bool hasUnviewedStories;
  final DateTime lastStoryAt;

  /// Получить количество активных сторис
  int get activeStoriesCount => stories.length;

  /// Проверить, есть ли активные сторис
  bool get hasActiveStories => stories.isNotEmpty;

  /// Получить первую активную сторис
  SpecialistStory? get firstActiveStory => stories.isNotEmpty ? stories.first : null;

  /// Получить последнюю активную сторис
  SpecialistStory? get lastActiveStory => stories.isNotEmpty ? stories.last : null;
}

/// Статистика сторис
class StoryStats {
  const StoryStats({
    required this.totalStories,
    required this.activeStories,
    required this.expiredStories,
    required this.totalViews,
    required this.averageViews,
    required this.contentTypeStats,
    this.lastStoryAt,
  });

  /// Создать из списка сторис
  factory StoryStats.fromStories(List<SpecialistStory> stories) {
    final activeStories = stories.where((s) => s.isActive).length;
    final expiredStories = stories.where((s) => s.isExpired).length;
    final totalViews = stories.fold(0, (sum, story) => sum + story.viewCount);
    final averageViews = stories.isNotEmpty ? totalViews / stories.length : 0.0;

    final contentTypeStats = <StoryContentType, int>{};
    for (final story in stories) {
      contentTypeStats[story.contentType] = (contentTypeStats[story.contentType] ?? 0) + 1;
    }

    final lastStory = stories.isNotEmpty
        ? stories.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    return StoryStats(
      totalStories: stories.length,
      activeStories: activeStories,
      expiredStories: expiredStories,
      totalViews: totalViews,
      averageViews: averageViews,
      contentTypeStats: contentTypeStats,
      lastStoryAt: lastStory?.createdAt,
    );
  }
  final int totalStories;
  final int activeStories;
  final int expiredStories;
  final int totalViews;
  final double averageViews;
  final Map<StoryContentType, int> contentTypeStats;
  final DateTime? lastStoryAt;
}
