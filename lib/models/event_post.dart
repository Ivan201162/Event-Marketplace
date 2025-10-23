import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип поста
enum PostType { image, video, text, story }

/// Модель поста в ленте
class EventPost {
  const EventPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.tags = const [],
    this.location,
    this.eventDate,
  });

  /// Создать EventPost из Firestore документа
  factory EventPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Безопасное преобразование данных
    Map<String, dynamic> safeData;
    if (data is Map<String, dynamic>) {
      safeData = data;
    } else if (data is Map<dynamic, dynamic>) {
      safeData = data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('Document data is not a Map: ${data.runtimeType}');
    }

    return EventPost(
      id: doc.id,
      authorId: safeData['authorId'] ?? '',
      authorName: safeData['authorName'] ?? '',
      authorAvatar: safeData['authorAvatar'] ?? '',
      content: safeData['content'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.name == safeData['type'],
        orElse: () => PostType.text,
      ),
      createdAt: safeData['createdAt'] != null
          ? (safeData['createdAt'] is Timestamp
              ? (safeData['createdAt'] as Timestamp).toDate()
              : DateTime.parse(safeData['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: safeData['updatedAt'] != null
          ? (safeData['updatedAt'] is Timestamp
              ? (safeData['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(safeData['updatedAt'].toString()))
          : null,
      imageUrl: safeData['imageUrl'],
      videoUrl: safeData['videoUrl'],
      thumbnailUrl: safeData['thumbnailUrl'],
      likes: safeData['likes'] ?? 0,
      comments: safeData['comments'] ?? 0,
      shares: safeData['shares'] ?? 0,
      isLiked: safeData['isLiked'] ?? false,
      tags: List<String>.from(safeData['tags'] ?? []),
      location: safeData['location'],
      eventDate: safeData['eventDate'] != null
          ? (safeData['eventDate'] is Timestamp
              ? (safeData['eventDate'] as Timestamp).toDate()
              : DateTime.tryParse(safeData['eventDate'].toString()))
          : null,
    );
  }

  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final PostType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final List<String> tags;
  final String? location;
  final DateTime? eventDate;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'type': type.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'isLiked': isLiked,
        'tags': tags,
        'location': location,
        'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      };

  /// Создать копию с изменениями
  EventPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    PostType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? videoUrl,
    String? thumbnailUrl,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
    List<String>? tags,
    String? location,
    DateTime? eventDate,
  }) =>
      EventPost(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        content: content ?? this.content,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        imageUrl: imageUrl ?? this.imageUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        shares: shares ?? this.shares,
        isLiked: isLiked ?? this.isLiked,
        tags: tags ?? this.tags,
        location: location ?? this.location,
        eventDate: eventDate ?? this.eventDate,
      );

  @override
  String toString() =>
      'EventPost(id: $id, authorName: $authorName, content: $content, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
