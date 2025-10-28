import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Idea comment model
class IdeaComment extends Equatable {

  const IdeaComment({
    required this.id,
    required this.ideaId,
    required this.authorId,
    required this.authorName,
    required this.content, required this.createdAt, required this.updatedAt, this.authorAvatar,
    this.likesCount = 0,
    this.likedBy = const [],
    this.parentCommentId,
    this.replies = const [],
  });

  /// Create IdeaComment from Firestore document
  factory IdeaComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return IdeaComment(
      id: doc.id,
      ideaId: data['ideaId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentCommentId: data['parentCommentId'],
      replies: List<String>.from(data['replies'] ?? []),
    );
  }
  final String id;
  final String ideaId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;
  final String? parentCommentId;
  final List<String> replies;

  /// Convert IdeaComment to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ideaId': ideaId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'replies': replies,
    };
  }

  /// Create a copy with updated fields
  IdeaComment copyWith({
    String? id,
    String? ideaId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
    String? parentCommentId,
    List<String>? replies,
  }) {
    return IdeaComment(
      id: id ?? this.id,
      ideaId: ideaId ?? this.ideaId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
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
        ideaId,
        authorId,
        authorName,
        authorAvatar,
        content,
        createdAt,
        updatedAt,
        likesCount,
        likedBy,
        parentCommentId,
        replies,
      ];

  @override
  String toString() {
    return 'IdeaComment(id: $id, ideaId: $ideaId, authorId: $authorId, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}
