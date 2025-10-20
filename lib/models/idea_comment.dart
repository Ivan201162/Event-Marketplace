import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель комментария к идее
class IdeaComment {
  const IdeaComment({
    required this.id,
    required this.ideaId,
    required this.userId,
    required this.userName,
    required this.text,
    this.parentId,
    this.replies = const [],
    this.likes = 0,
    this.isLiked = false,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String ideaId;
  final String userId;
  final String userName;
  final String text;
  final String? parentId;
  final List<IdeaComment> replies;
  final int likes;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Создать из Map
  factory IdeaComment.fromMap(Map<String, dynamic> data) {
    return IdeaComment(
      id: data['id'] as String? ?? '',
      ideaId: data['ideaId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      parentId: data['parentId'] as String?,
      replies: (data['replies'] as List<dynamic>?)
              ?.map((e) => IdeaComment.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      likes: data['likes'] as int? ?? 0,
      isLiked: data['isLiked'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] is Timestamp
              ? (data['deletedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['deletedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory IdeaComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return IdeaComment.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'ideaId': ideaId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'parentId': parentId,
        'replies': replies.map((e) => e.toMap()).toList(),
        'likes': likes,
        'isLiked': isLiked,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      };

  /// Копировать с изменениями
  IdeaComment copyWith({
    String? id,
    String? ideaId,
    String? userId,
    String? userName,
    String? text,
    String? parentId,
    List<IdeaComment>? replies,
    int? likes,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      IdeaComment(
        id: id ?? this.id,
        ideaId: ideaId ?? this.ideaId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        text: text ?? this.text,
        parentId: parentId ?? this.parentId,
        replies: replies ?? this.replies,
        likes: likes ?? this.likes,
        isLiked: isLiked ?? this.isLiked,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  /// Проверить, является ли комментарий удаленным
  bool get isDeleted => deletedAt != null;

  /// Проверить, является ли комментарий ответом
  bool get isReply => parentId != null;

  /// Получить количество ответов
  int get repliesCount => replies.length;
}
