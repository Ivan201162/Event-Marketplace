import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель комментария к идее
class IdeaComment {
  const IdeaComment({
    required this.id,
    required this.ideaId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likes = 0,
    this.replies = const [],
    this.parentCommentId,
    this.isEdited = false,
    this.isDeleted = false,
    this.authorName,
    this.authorAvatar,
    this.likesCount,
  });

  /// Создать из Map (Firestore)
  factory IdeaComment.fromMap(Map<String, dynamic> map) => IdeaComment(
        id: map['id'] as String,
        ideaId: map['ideaId'] as String,
        userId: map['userId'] as String,
        userName: map['userName'] as String,
        userAvatar: map['userAvatar'] as String?,
        content: map['content'] as String,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : null,
        likes: (map['likes'] ?? 0) as int,
        replies: List<String>.from((map['replies'] ?? <String>[]) as List),
        parentCommentId: map['parentCommentId'] as String?,
        isEdited: (map['isEdited'] ?? false) as bool,
        isDeleted: (map['isDeleted'] ?? false) as bool,
        authorName: map['authorName'] as String?,
        authorAvatar: map['authorAvatar'] as String?,
        likesCount: (map['likesCount'] ?? 0) as int?,
      );

  final String id;
  final String ideaId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likes;
  final List<String> replies; // ID ответов
  final String? parentCommentId; // ID родительского комментария
  final bool isEdited;
  final bool isDeleted;
  final String? authorName;
  final String? authorAvatar;
  final int? likesCount;

  /// Преобразовать в Map (Firestore)
  Map<String, dynamic> toMap() => {
        'id': id,
        'ideaId': ideaId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'likes': likes,
        'replies': replies,
        'parentCommentId': parentCommentId,
        'isEdited': isEdited,
        'isDeleted': isDeleted,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'likesCount': likesCount,
      };

  /// Создать копию с изменениями
  IdeaComment copyWith({
    String? id,
    String? ideaId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    List<String>? replies,
    String? parentCommentId,
    bool? isEdited,
    bool? isDeleted,
    String? authorName,
    String? authorAvatar,
    int? likesCount,
  }) =>
      IdeaComment(
        id: id ?? this.id,
        ideaId: ideaId ?? this.ideaId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userAvatar: userAvatar ?? this.userAvatar,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        likes: likes ?? this.likes,
        replies: replies ?? this.replies,
        parentCommentId: parentCommentId ?? this.parentCommentId,
        isEdited: isEdited ?? this.isEdited,
        isDeleted: isDeleted ?? this.isDeleted,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        likesCount: likesCount ?? this.likesCount,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is IdeaComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'IdeaComment(id: $id, ideaId: $ideaId, userId: $userId, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
}
