import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель поста в ленте
class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.description, required this.likeCount, required this.commentCount, required this.isLiked, required this.isSaved, required this.isFollowing, required this.createdAt, this.authorAvatar,
    this.imageUrl,
    this.location,
    this.specialistPhotoUrl,
    this.specialistName,
    this.content,
    this.mediaUrls = const [],
    this.tags = const [],
    this.shares = 0,
    this.comments = const [],
  });

  /// Создание из Firestore документа
  factory FeedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return FeedPost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      location: data['location'],
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isLiked: data['isLiked'] ?? false,
      isSaved: data['isSaved'] ?? false,
      isFollowing: data['isFollowing'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specialistPhotoUrl: data['specialistPhotoUrl'],
      specialistName: data['specialistName'],
      content: data['content'],
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      shares: data['shares'] ?? 0,
      comments: List<String>.from(data['comments'] ?? []),
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String description;
  final String? imageUrl;
  final String? location;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final DateTime createdAt;
  final String? specialistPhotoUrl;
  final String? specialistName;
  final String? content;
  final List<String> mediaUrls;
  final List<String> tags;
  final int shares;
  final List<String> comments;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'description': description,
        'imageUrl': imageUrl,
        'location': location,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'isLiked': isLiked,
        'isSaved': isSaved,
        'isFollowing': isFollowing,
        'createdAt': Timestamp.fromDate(createdAt),
        'specialistPhotoUrl': specialistPhotoUrl,
        'specialistName': specialistName,
        'content': content,
        'mediaUrls': mediaUrls,
        'tags': tags,
        'shares': shares,
        'comments': comments,
      };

  /// Копирование с изменениями
  FeedPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? description,
    String? imageUrl,
    String? location,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    DateTime? createdAt,
    String? specialistPhotoUrl,
    String? specialistName,
    String? content,
    List<String>? mediaUrls,
    List<String>? tags,
    int? shares,
    List<String>? comments,
  }) =>
      FeedPost(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        location: location ?? this.location,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        isLiked: isLiked ?? this.isLiked,
        isSaved: isSaved ?? this.isSaved,
        isFollowing: isFollowing ?? this.isFollowing,
        createdAt: createdAt ?? this.createdAt,
        specialistPhotoUrl: specialistPhotoUrl ?? this.specialistPhotoUrl,
        specialistName: specialistName ?? this.specialistName,
        content: content ?? this.content,
        mediaUrls: mediaUrls ?? this.mediaUrls,
        tags: tags ?? this.tags,
        shares: shares ?? this.shares,
        comments: comments ?? this.comments,
      );

  /// Проверка, лайкнул ли пользователь пост
  bool isLikedBy(String userId) => isLiked;

  /// Получить количество лайков
  int get likes => likeCount;

  /// Получить количество комментариев
  int get comments => commentCount;
}
