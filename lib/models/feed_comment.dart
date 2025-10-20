class FeedComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likes;
  final List<FeedComment> replies;
  final String? parentCommentId;
  final bool isEdited;
  final Map<String, dynamic>? metadata;

  const FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likes = const [],
    this.replies = const [],
    this.parentCommentId,
    this.isEdited = false,
    this.metadata,
  });

  factory FeedComment.fromMap(Map<String, dynamic> map) {
    return FeedComment(
      id: map['id']?.toString() ?? '',
      postId: map['postId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      userAvatar: map['userAvatar']?.toString(),
      content: map['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']?.toString() ?? '') : null,
      likes: (map['likes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      replies: (map['replies'] as List<dynamic>?)
              ?.map((e) => FeedComment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      parentCommentId: map['parentCommentId']?.toString(),
      isEdited: map['isEdited'] as bool? ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likes': likes,
      'replies': replies.map((e) => e.toMap()).toList(),
      'parentCommentId': parentCommentId,
      'isEdited': isEdited,
      'metadata': metadata,
    };
  }

  FeedComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likes,
    List<FeedComment>? replies,
    String? parentCommentId,
    bool? isEdited,
    Map<String, dynamic>? metadata,
  }) {
    return FeedComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
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
      metadata: metadata ?? this.metadata,
    );
  }
}
