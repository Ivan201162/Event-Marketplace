import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_type.dart';

/// Модель истории
class Story {
  final String id;
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final String? content;
  final String mediaUrl;
  final MediaType mediaType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewsCount;
  final List<String> viewedBy;
  final bool isActive;
  final String? thumbnailUrl;
  final int likes;
  final List<String> likedBy;

  const Story({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    this.content,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    this.viewsCount = 0,
    this.viewedBy = const [],
    this.isActive = true,
    this.thumbnailUrl,
    this.likes = 0,
    this.likedBy = const [],
  });

  /// Создать из документа Firestore
  factory Story.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Story(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      specialistName: data['specialistName'] as String,
      specialistPhotoUrl: data['specialistPhotoUrl'] as String?,
      content: data['content'] as String?,
      mediaUrl: data['mediaUrl'] as String,
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == data['mediaType'],
        orElse: () => MediaType.image,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      viewsCount: data['viewsCount'] ?? 0,
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      isActive: data['isActive'] ?? true,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistPhotoUrl': specialistPhotoUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewsCount': viewsCount,
      'viewedBy': viewedBy,
      'isActive': isActive,
      'thumbnailUrl': thumbnailUrl,
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  /// Создать копию с обновлёнными полями
  Story copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? specialistPhotoUrl,
    String? content,
    String? mediaUrl,
    MediaType? mediaType,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewsCount,
    List<String>? viewedBy,
    bool? isActive,
    String? thumbnailUrl,
    int? likes,
    List<String>? likedBy,
  }) {
    return Story(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistPhotoUrl: specialistPhotoUrl ?? this.specialistPhotoUrl,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewsCount: viewsCount ?? this.viewsCount,
      viewedBy: viewedBy ?? this.viewedBy,
      isActive: isActive ?? this.isActive,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  /// Проверить, истекла ли история
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Проверить, просмотрена ли история пользователем
  bool isViewedBy(String userId) => viewedBy.contains(userId);

  /// Получить тип истории (для совместимости)
  MediaType get type => mediaType;

  /// Получить подпись (для совместимости)
  String? get caption => content;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Story && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Story(id: $id, specialistId: $specialistId, mediaType: $mediaType)';
  }
}
