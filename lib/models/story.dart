import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель сторис специалиста
class Story {
  const Story({
    required this.id,
    required this.specialistId,
    required this.mediaUrl,
    this.text,
    required this.createdAt,
    required this.expiresAt,
    this.viewsCount = 0,
    this.viewedBy = const [],
    this.metadata,
  });

  /// Создать сторис из документа Firestore
  factory Story.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Story.fromMap(data, doc.id);
  }

  /// Создать сторис из Map
  factory Story.fromMap(Map<String, dynamic> data, [String? id]) => Story(
        id: id ?? data['id'] ?? '',
        specialistId: data['specialistId'] ?? '',
        mediaUrl: data['mediaUrl'] ?? '',
        text: data['text'],
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] is Timestamp
                ? (data['expiresAt'] as Timestamp).toDate()
                : DateTime.parse(data['expiresAt'].toString()))
            : DateTime.now().add(const Duration(hours: 24)),
        viewsCount: data['viewsCount'] as int? ?? 0,
        viewedBy: List<String>.from(data['viewedBy'] ?? []),
        metadata: data['metadata'],
      );

  /// Создать новый сторис с автоматическим временем истечения
  factory Story.create({
    required String id,
    required String specialistId,
    required String mediaUrl,
    String? text,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return Story(
      id: id,
      specialistId: specialistId,
      mediaUrl: mediaUrl,
      text: text,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      metadata: metadata,
    );
  }
  final String id;
  final String specialistId;
  final String mediaUrl; // фото/видео
  final String? text;
  final DateTime createdAt;
  final DateTime expiresAt; // автоматически удаляется через 24 часа
  final int viewsCount;
  final List<String> viewedBy; // список ID пользователей, которые просмотрели
  final Map<String, dynamic>? metadata;

  /// Проверить, истек ли сторис
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Проверить, просмотрел ли пользователь сторис
  bool hasViewedBy(String userId) => viewedBy.contains(userId);

  /// Проверить, просмотрел ли пользователь сторис (альтернативное название)
  bool isViewedBy(String userId) => viewedBy.contains(userId);

  /// Получить заголовок сторис
  String get caption => text ?? '';

  /// Получить количество просмотров
  int get viewCount => viewsCount;

  /// Получить время до истечения
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Получить время назад
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

  /// Проверить, является ли сторис изображением
  bool get isImage {
    final extension = mediaUrl.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Проверить, является ли сторис видео
  bool get isVideo {
    final extension = mediaUrl.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
  }

  /// Проверить, является ли сторис текстом
  bool get isText => text != null && text!.isNotEmpty && mediaUrl.isEmpty;

  /// Получить содержимое (URL медиа или текст)
  String get content => mediaUrl.isNotEmpty ? mediaUrl : (text ?? '');

  /// Получить цвет фона
  Color get backgroundColor => const Color(0xFF1A1A1A);

  /// Получить цвет текста
  Color get textColor => Colors.white;

  /// Получить размер шрифта
  double get fontSize => 16;

  /// Получить URL миниатюры
  String get thumbnailUrl => mediaUrl;

  /// Получить имя специалиста
  String get specialistName => metadata?['specialistName'] ?? '';

  /// Получить URL фото специалиста
  String get specialistPhotoUrl => metadata?['specialistPhotoUrl'] ?? '';

  /// Получить тип медиа
  String get type {
    if (isImage) return 'image';
    if (isVideo) return 'video';
    if (isText) return 'text';
    return 'unknown';
  }

  /// Получить количество лайков
  int get likes => metadata?['likes'] ?? 0;

  /// Получить ID автора (альтернативное название для specialistId)
  String get authorId => specialistId;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'mediaUrl': mediaUrl,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewsCount': viewsCount,
        'viewedBy': viewedBy,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  Story copyWith({
    String? id,
    String? specialistId,
    String? mediaUrl,
    String? text,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewsCount,
    List<String>? viewedBy,
    Map<String, dynamic>? metadata,
  }) =>
      Story(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        viewsCount: viewsCount ?? this.viewsCount,
        viewedBy: viewedBy ?? this.viewedBy,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Story && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Story(id: $id, specialistId: $specialistId, expiresAt: $expiresAt)';
}
