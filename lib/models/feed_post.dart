import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель поста в ленте
class FeedPost {

  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.description,
    this.imageUrl,
    this.location,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isSaved,
    required this.isFollowing,
    required this.createdAt,
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
  }) => FeedPost(
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
    );
}