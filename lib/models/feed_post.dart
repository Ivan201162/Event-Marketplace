import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель поста в ленте новостей
class FeedPost {
  final String id;
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final String content;
  final List<String> mediaUrls;
  final List<String> tags;
  final PostType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final int comments;
  final int shares;
  final List<String> likedBy;
  final Map<String, dynamic> metadata;

  const FeedPost({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    required this.content,
    required this.mediaUrls,
    required this.tags,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.likedBy,
    required this.metadata,
  });

  /// Создать из документа Firestore
  factory FeedPost.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedPost(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistPhotoUrl: data['specialistPhotoUrl'],
      content: data['content'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      type: PostType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PostType.text,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistPhotoUrl': specialistPhotoUrl,
      'content': content,
      'mediaUrls': mediaUrls,
      'tags': tags,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'likedBy': likedBy,
      'metadata': metadata,
    };
  }

  /// Создать копию с изменениями
  FeedPost copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? specialistPhotoUrl,
    String? content,
    List<String>? mediaUrls,
    List<String>? tags,
    PostType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    int? comments,
    int? shares,
    List<String>? likedBy,
    Map<String, dynamic>? metadata,
  }) {
    return FeedPost(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistPhotoUrl: specialistPhotoUrl ?? this.specialistPhotoUrl,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      likedBy: likedBy ?? this.likedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Проверить, лайкнул ли пользователь пост
  bool isLikedBy(String userId) => likedBy.contains(userId);
}

/// Модель комментария к посту
class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final List<String> likedBy;
  final String? parentCommentId;
  final List<String> replies;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likes,
    required this.likedBy,
    this.parentCommentId,
    required this.replies,
  });

  /// Создать из документа Firestore
  factory PostComment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentCommentId: data['parentCommentId'],
      replies: List<String>.from(data['replies'] ?? []),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likes': likes,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'replies': replies,
    };
  }

  /// Проверить, лайкнул ли пользователь комментарий
  bool isLikedBy(String userId) => likedBy.contains(userId);
}

/// Типы постов
enum PostType {
  text,
  image,
  video,
  event,
  portfolio,
  announcement,
}
