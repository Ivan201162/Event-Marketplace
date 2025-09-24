import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип контента поста
enum PostContentType {
  text,     // Текстовый пост
  image,    // Пост с изображением
  video,    // Пост с видео
  carousel, // Карусель изображений
}

/// Модель поста специалиста
class SpecialistPost {
  const SpecialistPost({
    required this.id,
    required this.specialistId,
    required this.contentType,
    required this.content,
    this.mediaUrls = const [],
    this.caption,
    this.hashtags = const [],
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.location,
    this.tags = const [],
  });

  final String id;
  final String specialistId;
  final PostContentType contentType;
  final String content;
  final List<String> mediaUrls;
  final String? caption;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isPinned;
  final bool isArchived;
  final String? location;
  final List<String> tags;

  /// Создать из документа Firestore
  factory SpecialistPost.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistPost(
      id: doc.id,
      specialistId: data['specialistId'] as String? ?? '',
      contentType: PostContentType.values.firstWhere(
        (type) => type.name == data['contentType'],
        orElse: () => PostContentType.text,
      ),
      content: data['content'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      caption: data['caption'] as String?,
      hashtags: List<String>.from(data['hashtags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      likesCount: data['likesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      sharesCount: data['sharesCount'] as int? ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      isArchived: data['isArchived'] as bool? ?? false,
      location: data['location'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Создать из Map
  factory SpecialistPost.fromMap(Map<String, dynamic> data) => SpecialistPost(
    id: data['id'] as String? ?? '',
    specialistId: data['specialistId'] as String? ?? '',
    contentType: PostContentType.values.firstWhere(
      (type) => type.name == data['contentType'],
      orElse: () => PostContentType.text,
    ),
    content: data['content'] as String? ?? '',
    mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
    caption: data['caption'] as String?,
    hashtags: List<String>.from(data['hashtags'] ?? []),
    createdAt: data['createdAt'] is Timestamp 
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.parse(data['createdAt'] as String),
    updatedAt: data['updatedAt'] != null 
        ? (data['updatedAt'] is Timestamp 
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.parse(data['updatedAt'] as String))
        : null,
    likesCount: data['likesCount'] as int? ?? 0,
    commentsCount: data['commentsCount'] as int? ?? 0,
    sharesCount: data['sharesCount'] as int? ?? 0,
    isPinned: data['isPinned'] as bool? ?? false,
    isArchived: data['isArchived'] as bool? ?? false,
    location: data['location'] as String?,
    tags: List<String>.from(data['tags'] ?? []),
  );

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'specialistId': specialistId,
    'contentType': contentType.name,
    'content': content,
    'mediaUrls': mediaUrls,
    'caption': caption,
    'hashtags': hashtags,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'location': location,
    'tags': tags,
  };

  /// Копировать с изменениями
  SpecialistPost copyWith({
    String? id,
    String? specialistId,
    PostContentType? contentType,
    String? content,
    List<String>? mediaUrls,
    String? caption,
    List<String>? hashtags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isPinned,
    bool? isArchived,
    String? location,
    List<String>? tags,
  }) =>
      SpecialistPost(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        contentType: contentType ?? this.contentType,
        content: content ?? this.content,
        mediaUrls: mediaUrls ?? this.mediaUrls,
        caption: caption ?? this.caption,
        hashtags: hashtags ?? this.hashtags,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        sharesCount: sharesCount ?? this.sharesCount,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        location: location ?? this.location,
        tags: tags ?? this.tags,
      );

  /// Проверить, является ли пост популярным
  bool get isPopular => likesCount > 10 || commentsCount > 5;

  /// Получить время публикации в читаемом формате
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  /// Проверить, содержит ли пост медиа
  bool get hasMedia => mediaUrls.isNotEmpty;

  /// Получить первый URL медиа
  String? get firstMediaUrl => mediaUrls.isNotEmpty ? mediaUrls.first : null;
}