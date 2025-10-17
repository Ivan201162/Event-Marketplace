import 'package:cloud_firestore/cloud_firestore.dart';

import 'story_type.dart';

/// Модель сторис
class Story {
  const Story({
    required this.id,
    required this.specialistId,
    required this.title,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewsCount = 0,
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
        title: data['title'] ?? '',
        mediaUrl: data['mediaUrl'] ?? '',
        thumbnailUrl: data['thumbnailUrl'] ?? '',
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
        metadata: data['metadata'],
      );

  final String id;
  final String specialistId;
  final String title;
  final String mediaUrl; // URL видео или изображения
  final String thumbnailUrl; // URL превью
  final DateTime createdAt;
  final DateTime expiresAt; // Время истечения (24 часа)
  final int viewsCount;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'title': title,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewsCount': viewsCount,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  Story copyWith({
    String? id,
    String? specialistId,
    String? title,
    String? mediaUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewsCount,
    Map<String, dynamic>? metadata,
  }) =>
      Story(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        title: title ?? this.title,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        viewsCount: viewsCount ?? this.viewsCount,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, активна ли история
  bool get isActive => expiresAt.isAfter(DateTime.now());

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

  /// Получить тип контента
  StoryType get type => mediaUrl.contains('video') ? StoryType.video : StoryType.image;

  /// Получить текст (для текстовых историй)
  String get text => title;

  /// Получить цвет фона
  String get backgroundColor => '#FF6B6B';

  /// Получить цвет текста
  String get textColor => '#FFFFFF';

  /// Получить размер шрифта
  double get fontSize => 16;

  /// Получить подпись
  String get caption => title;

  /// Получить количество просмотров
  int get viewCount => viewsCount;

  /// Получить количество лайков
  int get likes => 0;

  /// Проверить, просмотрена ли история пользователем
  bool isViewedBy(String userId) => false;

  /// Получить URL фото специалиста
  String get specialistPhotoUrl => '';

  /// Получить имя специалиста
  String get specialistName => '';

  /// Проверить, является ли сторис видео
  bool get isVideo => mediaUrl.contains('video');

  /// Проверить, является ли сторис изображением
  bool get isImage => !mediaUrl.contains('video');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Story && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Story(id: $id, title: $title, specialistId: $specialistId)';
}
