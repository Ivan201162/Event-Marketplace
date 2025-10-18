import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель поста специалиста
class Post {
  const Post({
    required this.id,
    required this.specialistId,
    this.text,
    required this.mediaUrls,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.metadata,
  });

  /// Создать пост из документа Firestore
  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Post.fromMap(data, doc.id);
  }

  /// Создать пост из Map
  factory Post.fromMap(Map<String, dynamic> data, [String? id]) => Post(
        id: id ?? data['id'] ?? '',
        specialistId: data['specialistId'] ?? '',
        text: data['text'],
        mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        likesCount: data['likesCount'] as int? ?? 0,
        commentsCount: data['commentsCount'] as int? ?? 0,
        likedBy: List<String>.from(data['likedBy'] ?? []),
        metadata: data['metadata'],
      );
  final String id;
  final String specialistId;
  final String? text;
  final List<String> mediaUrls; // фото/видео
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy; // список ID пользователей, которые лайкнули
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'text': text,
        'mediaUrls': mediaUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'likedBy': likedBy,
        'metadata': metadata,
      };

  /// Преобразовать в Map для JSON сериализации (без Timestamp)
  Map<String, dynamic> toJson() => {
        'id': id,
        'specialistId': specialistId,
        'text': text,
        'mediaUrls': mediaUrls,
        'createdAt': createdAt.toIso8601String(),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'likedBy': likedBy,
        'metadata': metadata,
      };

  /// Создать пост из JSON
  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String? ?? '',
        specialistId: json['specialistId'] as String? ?? '',
        text: json['text'] as String?,
        mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        likesCount: json['likesCount'] as int? ?? 0,
        commentsCount: json['commentsCount'] as int? ?? 0,
        likedBy: List<String>.from(json['likedBy'] ?? []),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  /// Копировать с изменениями
  Post copyWith({
    String? id,
    String? specialistId,
    String? text,
    List<String>? mediaUrls,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    Map<String, dynamic>? metadata,
  }) =>
      Post(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        text: text ?? this.text,
        mediaUrls: mediaUrls ?? this.mediaUrls,
        createdAt: createdAt ?? this.createdAt,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedBy: likedBy ?? this.likedBy,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Post(id: $id, specialistId: $specialistId, text: $text)';
}
