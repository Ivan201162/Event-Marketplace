import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель поста в ленте
class FeedPost {
  const FeedPost({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    required this.content,
    this.images = const [],
    this.videos = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.isPinned = false,
    this.tags = const [],
    this.shares = 0,
  });

  /// Создать из документа Firestore
  factory FeedPost.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FeedPost(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      specialistName: data['specialistName'] as String,
      specialistPhotoUrl: data['specialistPhotoUrl'] as String?,
      content: data['content'] as String,
      images: List<String>.from(data['images'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isPinned: data['isPinned'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      shares: data['shares'] ?? 0,
    );
  }
  final String id;
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final String content;
  final List<String> images;
  final List<String> videos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final bool isPinned;
  final List<String> tags;
  final int shares;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'specialistName': specialistName,
        'specialistPhotoUrl': specialistPhotoUrl,
        'content': content,
        'images': images,
        'videos': videos,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'likedBy': likedBy,
        'isPinned': isPinned,
        'tags': tags,
        'shares': shares,
      };

  /// Создать копию с обновлёнными полями
  FeedPost copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? specialistPhotoUrl,
    String? content,
    List<String>? images,
    List<String>? videos,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    bool? isPinned,
    List<String>? tags,
    int? shares,
  }) =>
      FeedPost(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        specialistName: specialistName ?? this.specialistName,
        specialistPhotoUrl: specialistPhotoUrl ?? this.specialistPhotoUrl,
        content: content ?? this.content,
        images: images ?? this.images,
        videos: videos ?? this.videos,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedBy: likedBy ?? this.likedBy,
        isPinned: isPinned ?? this.isPinned,
        tags: tags ?? this.tags,
        shares: shares ?? this.shares,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Получить все медиа URL
  List<String> get mediaUrls => [...images, ...videos];

  /// Проверить, лайкнул ли пользователь пост
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Получить количество лайков
  int get likes => likesCount;

  /// Получить количество комментариев
  int get comments => commentsCount;

  @override
  String toString() =>
      'FeedPost(id: $id, specialistId: $specialistId, content: $content)';
}

/// Модель комментария к посту
class FeedComment {
  const FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
  });

  /// Создать из документа Firestore
  factory FeedComment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FeedComment(
      id: doc.id,
      postId: data['postId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'likesCount': likesCount,
        'likedBy': likedBy,
      };

  /// Создать копию с обновлёнными полями
  FeedComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
  }) =>
      FeedComment(
        id: id ?? this.id,
        postId: postId ?? this.postId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        likesCount: likesCount ?? this.likesCount,
        likedBy: likedBy ?? this.likedBy,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Проверить, лайкнул ли пользователь комментарий
  bool isLikedBy(String userId) => likedBy.contains(userId);

  @override
  String toString() => 'FeedComment(id: $id, postId: $postId, userId: $userId)';
}
