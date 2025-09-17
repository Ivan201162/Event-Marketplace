import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель сториса специалиста
class Story {
  final String id;
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final StoryType type;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? caption;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int views;
  final int likes;
  final List<String> viewers;
  final Map<String, dynamic> metadata;

  const Story({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    required this.type,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    required this.tags,
    required this.createdAt,
    required this.expiresAt,
    required this.views,
    required this.likes,
    required this.viewers,
    required this.metadata,
  });

  /// Создать из документа Firestore
  factory Story.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistPhotoUrl: data['specialistPhotoUrl'],
      type: StoryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => StoryType.image,
      ),
      mediaUrl: data['mediaUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      caption: data['caption'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      viewers: List<String>.from(data['viewers'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistPhotoUrl': specialistPhotoUrl,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'views': views,
      'likes': likes,
      'viewers': viewers,
      'metadata': metadata,
    };
  }

  /// Создать копию с изменениями
  Story copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? specialistPhotoUrl,
    StoryType? type,
    String? mediaUrl,
    String? thumbnailUrl,
    String? caption,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? views,
    int? likes,
    List<String>? viewers,
    Map<String, dynamic>? metadata,
  }) {
    return Story(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistPhotoUrl: specialistPhotoUrl ?? this.specialistPhotoUrl,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      viewers: viewers ?? this.viewers,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Проверить, истек ли срок действия сториса
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Проверить, просмотрел ли пользователь сторис
  bool isViewedBy(String userId) => viewers.contains(userId);
}

/// Типы сторисов
enum StoryType {
  image,
  video,
  text,
}
