import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Media type for posts
enum MediaType {
  image,
  video,
  text,
}

/// Post model for feed
class Post extends Equatable {
  final String id;
  final String authorId;
  final String? text;
  final String? mediaUrl;
  final MediaType? mediaType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final String? authorName;
  final String? authorAvatarUrl;
  final List<String> tags;
  final bool isPinned;
  final String? location;

  const Post({
    required this.id,
    required this.authorId,
    this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.authorName,
    this.authorAvatarUrl,
    this.tags = const [],
    this.isPinned = false,
    this.location,
  });

  /// Create Post from Firestore document
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'] != null
          ? MediaType.values.firstWhere(
              (e) => e.toString().split('.').last == data['mediaType'],
              orElse: () => MediaType.text,
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      authorName: data['authorName'],
      authorAvatarUrl: data['authorAvatarUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      isPinned: data['isPinned'] ?? false,
      location: data['location'],
    );
  }

  /// Convert Post to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType?.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'tags': tags,
      'isPinned': isPinned,
      'location': location,
    };
  }

  /// Create a copy with updated fields
  Post copyWith({
    String? id,
    String? authorId,
    String? text,
    String? mediaUrl,
    MediaType? mediaType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    String? authorName,
    String? authorAvatarUrl,
    List<String>? tags,
    bool? isPinned,
    String? location,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      location: location ?? this.location,
    );
  }

  /// Check if post has media
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Check if post is liked by user
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }

  /// Get media type icon
  String get mediaTypeIcon {
    switch (mediaType) {
      case MediaType.image:
        return '🖼️';
      case MediaType.video:
        return '🎥';
      case MediaType.text:
      case null:
        return '📝';
    }
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        text,
        mediaUrl,
        mediaType,
        createdAt,
        updatedAt,
        likesCount,
        commentsCount,
        likedBy,
        authorName,
        authorAvatarUrl,
        tags,
        isPinned,
        location,
      ];

  @override
  String toString() {
    return 'Post(id: $id, authorId: $authorId, text: ${text?.substring(0, text!.length > 50 ? 50 : text!.length)}...)';
  }
}