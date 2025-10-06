import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Модель поста в ленте активности
class FeedPost extends Equatable {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorCity,
    required this.authorAvatar,
    required this.mediaUrl,
    required this.description,
    required this.createdAt,
    required this.likes,
    required this.commentsCount,
    required this.type,
    required this.taggedCategories,
    this.likedBy = const [],
    this.comments = const [],
  });

  /// Создание из Map (из Firestore)
  factory FeedPost.fromMap(Map<String, dynamic> map) => FeedPost(
        id: (map['id'] as String?) ?? '',
        authorId: (map['authorId'] as String?) ?? '',
        authorName: (map['authorName'] as String?) ?? '',
        authorCity: (map['authorCity'] as String?) ?? '',
        authorAvatar: (map['authorAvatar'] as String?) ?? '',
        mediaUrl: (map['mediaUrl'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        likes: (map['likes'] as int?) ?? 0,
        commentsCount: (map['commentsCount'] as int?) ?? 0,
        type: PostType.fromString((map['type'] as String?) ?? 'photo'),
        taggedCategories: List<String>.from(
            (map['taggedCategories'] as List<dynamic>?) ?? []),
        likedBy: List<String>.from((map['likedBy'] as List<dynamic>?) ?? []),
        comments: (map['comments'] as List<dynamic>?)
                ?.map((comment) =>
                    FeedComment.fromMap(comment as Map<String, dynamic>))
                .toList() ??
            [],
      );

  final String id;
  final String authorId;
  final String authorName;
  final String authorCity;
  final String authorAvatar;
  final String mediaUrl;
  final String description;
  final DateTime createdAt;
  final int likes;
  final int commentsCount;
  final PostType type;
  final List<String> taggedCategories;
  final List<String> likedBy;
  final List<FeedComment> comments;

  /// Преобразование в Map (для Firestore)
  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorCity': authorCity,
        'authorAvatar': authorAvatar,
        'mediaUrl': mediaUrl,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
        'likes': likes,
        'commentsCount': commentsCount,
        'type': type.value,
        'taggedCategories': taggedCategories,
        'likedBy': likedBy,
        'comments': comments.map((comment) => comment.toMap()).toList(),
      };

  /// Создание копии с изменениями
  FeedPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorCity,
    String? authorAvatar,
    String? mediaUrl,
    String? description,
    DateTime? createdAt,
    int? likes,
    int? commentsCount,
    PostType? type,
    List<String>? taggedCategories,
    List<String>? likedBy,
    List<FeedComment>? comments,
  }) =>
      FeedPost(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorCity: authorCity ?? this.authorCity,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
        likes: likes ?? this.likes,
        commentsCount: commentsCount ?? this.commentsCount,
        type: type ?? this.type,
        taggedCategories: taggedCategories ?? this.taggedCategories,
        likedBy: likedBy ?? this.likedBy,
        comments: comments ?? this.comments,
      );

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorCity,
        authorAvatar,
        mediaUrl,
        description,
        createdAt,
        likes,
        commentsCount,
        type,
        taggedCategories,
        likedBy,
        comments,
      ];
}

/// Тип поста
enum PostType {
  photo('photo'),
  video('video');

  const PostType(this.value);
  final String value;

  static PostType fromString(String value) {
    switch (value) {
      case 'video':
        return PostType.video;
      case 'photo':
      default:
        return PostType.photo;
    }
  }
}

/// Модель комментария к посту
class FeedComment extends Equatable {
  const FeedComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.createdAt,
  });

  /// Создание из Map (из Firestore)
  factory FeedComment.fromMap(Map<String, dynamic> map) => FeedComment(
        id: (map['id'] as String?) ?? '',
        authorId: (map['authorId'] as String?) ?? '',
        authorName: (map['authorName'] as String?) ?? '',
        authorAvatar: (map['authorAvatar'] as String?) ?? '',
        text: (map['text'] as String?) ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String text;
  final DateTime createdAt;

  /// Преобразование в Map (для Firestore)
  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Создание копии с изменениями
  FeedComment copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? text,
    DateTime? createdAt,
  }) =>
      FeedComment(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorName,
        authorAvatar,
        text,
        createdAt,
      ];
}

/// Фильтр для ленты
enum FeedFilter {
  all('all', 'Все'),
  subscriptions('subscriptions', 'Подписки'),
  photos('photos', 'Фото'),
  videos('videos', 'Видео'),
  categories('categories', 'Категории');

  const FeedFilter(this.value, this.displayName);
  final String value;
  final String displayName;

  static FeedFilter fromString(String value) {
    switch (value) {
      case 'subscriptions':
        return FeedFilter.subscriptions;
      case 'photos':
        return FeedFilter.photos;
      case 'videos':
        return FeedFilter.videos;
      case 'categories':
        return FeedFilter.categories;
      case 'all':
      default:
        return FeedFilter.all;
    }
  }
}
