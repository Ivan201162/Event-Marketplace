import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель комментария к идее
class IdeaComment {
  final String id;
  final String ideaId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final String? parentCommentId; // для ответов на комментарии
  final Map<String, dynamic> metadata;

  const IdeaComment({
    required this.id,
    required this.ideaId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.likesCount,
    required this.likedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.parentCommentId,
    this.metadata = const {},
  });

  /// Создать из Map
  factory IdeaComment.fromMap(Map<String, dynamic> data) {
    return IdeaComment(
      id: data['id'] ?? '',
      ideaId: data['ideaId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      content: data['content'] ?? '',
      likesCount: data['likesCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isEdited: data['isEdited'] as bool? ?? false,
      parentCommentId: data['parentCommentId'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ideaId': ideaId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEdited': isEdited,
      'parentCommentId': parentCommentId,
      'metadata': metadata,
    };
  }

  /// Геттеры для совместимости с виджетами
  String? get authorPhotoUrl => authorAvatar;

  /// Проверить, лайкнул ли пользователь комментарий
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Копировать с изменениями
  IdeaComment copyWith({
    String? id,
    String? ideaId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    int? likesCount,
    List<String>? likedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    String? parentCommentId,
    Map<String, dynamic>? metadata,
  }) {
    return IdeaComment(
      id: id ?? this.id,
      ideaId: ideaId ?? this.ideaId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      metadata: metadata ?? this.metadata,
    );
  }
}
