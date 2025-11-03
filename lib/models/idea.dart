import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель идеи
class Idea {

  const Idea({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text, required this.media, required this.tags, required this.city, required this.likesCount, required this.commentsCount, required this.sharesCount, required this.isLiked, required this.isSaved, required this.createdAt, required this.updatedAt, this.authorAvatar,
  });

  factory Idea.fromMap(Map<String, dynamic> map, String id) {
    // Обработка Timestamp из Firestore
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value.toString().contains('Timestamp')) {
        // Это Firestore Timestamp, нужно обработать через toDate()
        return DateTime.now(); // Временная заглушка, реально нужно использовать cloud_firestore
      }
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return Idea(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'],
      text: map['text'] ?? '',
      media: List<String>.from(map['media'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      city: map['city'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isSaved: map['isSaved'] ?? false,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory Idea.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null for ${doc.id}');
    }
    return Idea.fromMap(data, doc.id);
  }
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String text;
  final List<String> media;
  final List<String> tags;
  final String city;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'media': media,
      'tags': tags,
      'city': city,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Idea copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? text,
    List<String>? media,
    List<String>? tags,
    String? city,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Idea(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      text: text ?? this.text,
      media: media ?? this.media,
      tags: tags ?? this.tags,
      city: city ?? this.city,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
