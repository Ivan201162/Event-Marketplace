import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Feed comment model
class FeedComment extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final String? userPhotoUrl;
  final String? userName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;
  final String? parentCommentId;
  final List<String> replies;

  const FeedComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
    this.parentCommentId,
    this.replies = const [],
    this.userPhotoUrl,
    this.userName,
  });

  /// Create FeedComment from Firestore document
  factory FeedComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatarUrl: data['authorAvatarUrl'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentCommentId: data['parentCommentId'],
      replies: List<String>.from(data['replies'] ?? []),
      userPhotoUrl: data['userPhotoUrl'],
      userName: data['userName'],
    );
  }

  /// Convert FeedComment to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'userPhotoUrl': userPhotoUrl,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'replies': replies,
    };
  }

  /// Create a copy with updated fields
  FeedComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    String? content,
    String? userPhotoUrl,
    String? userName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
    String? parentCommentId,
    List<String>? replies,
  }) {
    return FeedComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }

  /// Check if comment is liked by user
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

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        authorName,
        authorAvatarUrl,
        content,
        userPhotoUrl,
        userName,
        createdAt,
        updatedAt,
        likesCount,
        likedBy,
        parentCommentId,
        replies,
      ];

  @override
  String toString() {
    return 'FeedComment(id: $id, postId: $postId, authorId: $authorId, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}
