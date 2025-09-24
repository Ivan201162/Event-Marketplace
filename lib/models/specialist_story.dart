import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип медиа в сторис
enum StoryMediaType {
  image,
  video,
}

/// Статус просмотра сторис
enum StoryViewStatus {
  notViewed,
  viewed,
  expired,
}

/// Модель сторис специалиста
class SpecialistStory {
  const SpecialistStory({
    required this.id,
    required this.specialistId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.hashtags = const [],
    required this.createdAt,
    required this.expiresAt,
    this.viewersCount = 0,
    this.isHighlighted = false,
    this.highlightTitle,
    this.location,
    this.tags = const [],
  });

  final String id;
  final String specialistId;
  final StoryMediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewersCount;
  final bool isHighlighted;
  final String? highlightTitle;
  final String? location;
  final List<String> tags;

  /// Создать из документа Firestore
  factory SpecialistStory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistStory(
      id: doc.id,
      specialistId: data['specialistId'] as String? ?? '',
      mediaType: StoryMediaType.values.firstWhere(
        (type) => type.name == data['mediaType'],
        orElse: () => StoryMediaType.image,
      ),
      mediaUrl: data['mediaUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      caption: data['caption'] as String?,
      hashtags: List<String>.from(data['hashtags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      viewersCount: data['viewersCount'] as int? ?? 0,
      isHighlighted: data['isHighlighted'] as bool? ?? false,
      highlightTitle: data['highlightTitle'] as String?,
      location: data['location'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Создать из Map
  factory SpecialistStory.fromMap(Map<String, dynamic> data) => SpecialistStory(
    id: data['id'] as String? ?? '',
    specialistId: data['specialistId'] as String? ?? '',
    mediaType: StoryMediaType.values.firstWhere(
      (type) => type.name == data['mediaType'],
      orElse: () => StoryMediaType.image,
    ),
    mediaUrl: data['mediaUrl'] as String? ?? '',
    thumbnailUrl: data['thumbnailUrl'] as String?,
    caption: data['caption'] as String?,
    hashtags: List<String>.from(data['hashtags'] ?? []),
    createdAt: data['createdAt'] is Timestamp 
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.parse(data['createdAt'] as String),
    expiresAt: data['expiresAt'] is Timestamp 
        ? (data['expiresAt'] as Timestamp).toDate()
        : DateTime.parse(data['expiresAt'] as String),
    viewersCount: data['viewersCount'] as int? ?? 0,
    isHighlighted: data['isHighlighted'] as bool? ?? false,
    highlightTitle: data['highlightTitle'] as String?,
    location: data['location'] as String?,
    tags: List<String>.from(data['tags'] ?? []),
  );

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'specialistId': specialistId,
    'mediaType': mediaType.name,
    'mediaUrl': mediaUrl,
    'thumbnailUrl': thumbnailUrl,
    'caption': caption,
    'hashtags': hashtags,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'viewersCount': viewersCount,
    'isHighlighted': isHighlighted,
    'highlightTitle': highlightTitle,
    'location': location,
    'tags': tags,
  };

  /// Копировать с изменениями
  SpecialistStory copyWith({
    String? id,
    String? specialistId,
    StoryMediaType? mediaType,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    List<String>? hashtags,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewersCount,
    bool? isHighlighted,
    String? highlightTitle,
    String? location,
    List<String>? tags,
  }) =>
      SpecialistStory(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        mediaType: mediaType ?? this.mediaType,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        caption: caption ?? this.caption,
        hashtags: hashtags ?? this.hashtags,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        viewersCount: viewersCount ?? this.viewersCount,
        isHighlighted: isHighlighted ?? this.isHighlighted,
        highlightTitle: highlightTitle ?? this.highlightTitle,
        location: location ?? this.location,
        tags: tags ?? this.tags,
      );

  /// Проверить, истекла ли сторис
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Получить оставшееся время до истечения
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Проверить, является ли сторис новой (менее 1 часа)
  bool get isNew => DateTime.now().difference(createdAt).inHours < 1;

  /// Получить прогресс просмотра (0.0 - 1.0)
  double getViewProgress(DateTime viewStartTime) {
    final totalDuration = expiresAt.difference(createdAt);
    final elapsed = DateTime.now().difference(viewStartTime);
    return (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Проверить, является ли сторис видео
  bool get isVideo => mediaType == StoryMediaType.video;

  /// Проверить, является ли сторис изображением
  bool get isImage => mediaType == StoryMediaType.image;
}

/// Модель просмотра сторис
class StoryView {
  const StoryView({
    required this.id,
    required this.storyId,
    required this.viewerId,
    required this.viewedAt,
    this.viewDuration,
  });

  final String id;
  final String storyId;
  final String viewerId;
  final DateTime viewedAt;
  final Duration? viewDuration;

  /// Создать из документа Firestore
  factory StoryView.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return StoryView(
      id: doc.id,
      storyId: data['storyId'] as String? ?? '',
      viewerId: data['viewerId'] as String? ?? '',
      viewedAt: (data['viewedAt'] as Timestamp).toDate(),
      viewDuration: data['viewDuration'] != null 
          ? Duration(milliseconds: data['viewDuration'] as int)
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'storyId': storyId,
    'viewerId': viewerId,
    'viewedAt': Timestamp.fromDate(viewedAt),
    'viewDuration': viewDuration?.inMilliseconds,
  };
}