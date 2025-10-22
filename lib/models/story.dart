import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Типы контента сторис
enum StoryType {
  image('image'),
  video('video'),
  text('text');

  const StoryType(this.value);
  final String value;

  static StoryType fromString(String value) {
    return StoryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StoryType.image,
    );
  }
}

/// Приватность сторис
enum StoryPrivacy {
  public('public'),
  followers('followers'),
  closeFriends('close_friends');

  const StoryPrivacy(this.value);
  final String value;

  static StoryPrivacy fromString(String value) {
    return StoryPrivacy.values.firstWhere(
      (privacy) => privacy.value == value,
      orElse: () => StoryPrivacy.public,
    );
  }
}

/// Модель сторис
class Story extends Equatable {
  final String id;
  final String userId;
  final String? content; // URL изображения/видео или текст
  final String? mediaUrl; // URL медиа файла
  final String? thumbnailUrl; // URL превью
  final String? caption; // Подпись к сторис
  final String? title; // Заголовок сторис
  final StoryType type;
  final StoryPrivacy privacy;
  final List<String> mentions; // @username упоминания
  final List<String> viewers; // ID пользователей, которые просмотрели
  final List<Map<String, dynamic>> reactions; // реакции с эмодзи
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isHighlighted; // закрепленная сторис
  final String? highlightTitle; // название для закрепленной сторис
  final Map<String, dynamic>? metadata; // дополнительная информация
  final int likes; // Количество лайков
  final bool isVideo; // Является ли видео
  final String? specialistName; // Имя специалиста
  final String? specialistPhotoUrl; // Фото специалиста
  final String? timeAgo; // Время назад

  const Story({
    required this.id,
    required this.userId,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.caption,
    this.title,
    this.type = StoryType.image,
    this.privacy = StoryPrivacy.public,
    this.mentions = const [],
    this.viewers = const [],
    this.reactions = const [],
    required this.createdAt,
    required this.expiresAt,
    this.isHighlighted = false,
    this.highlightTitle,
    this.metadata,
    this.likes = 0,
    this.isVideo = false,
    this.specialistName,
    this.specialistPhotoUrl,
    this.timeAgo,
  });

  /// Создать Story из Firestore документа
  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'],
      mediaUrl: data['mediaUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      caption: data['caption'],
      title: data['title'],
      type: StoryType.fromString(data['type'] ?? 'image'),
      privacy: StoryPrivacy.fromString(data['privacy'] ?? 'public'),
      mentions: List<String>.from(data['mentions'] ?? []),
      viewers: List<String>.from(data['viewers'] ?? []),
      reactions: List<Map<String, dynamic>>.from(data['reactions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isHighlighted: data['isHighlighted'] ?? false,
      highlightTitle: data['highlightTitle'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      likes: data['likes'] ?? 0,
      isVideo: data['isVideo'] ?? false,
      specialistName: data['specialistName'],
      specialistPhotoUrl: data['specialistPhotoUrl'],
      timeAgo: data['timeAgo'],
    );
  }

  /// Конвертировать Story в Firestore документ
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'title': title,
      'type': type.value,
      'privacy': privacy.value,
      'mentions': mentions,
      'viewers': viewers,
      'reactions': reactions,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isHighlighted': isHighlighted,
      'highlightTitle': highlightTitle,
      'metadata': metadata,
      'likes': likes,
      'isVideo': isVideo,
      'specialistName': specialistName,
      'specialistPhotoUrl': specialistPhotoUrl,
      'timeAgo': timeAgo,
    };
  }

  /// Создать копию с обновленными полями
  Story copyWith({
    String? id,
    String? userId,
    String? content,
    StoryType? type,
    StoryPrivacy? privacy,
    List<String>? mentions,
    List<String>? viewers,
    List<Map<String, dynamic>>? reactions,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isHighlighted,
    String? highlightTitle,
    Map<String, dynamic>? metadata,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      type: type ?? this.type,
      privacy: privacy ?? this.privacy,
      mentions: mentions ?? this.mentions,
      viewers: viewers ?? this.viewers,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      highlightTitle: highlightTitle ?? this.highlightTitle,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Проверить, истекла ли сторис
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Получить количество просмотров
  int get viewCount => viewers.length;

  /// Получить количество реакций
  int get reactionCount => reactions.length;

  /// Проверить, просмотрел ли пользователь сторис
  bool hasViewed(String userId) => viewers.contains(userId);

  /// Получить время до истечения
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  /// Получить отформатированное время создания
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }

  /// Проверить, просмотрена ли сторис пользователем
  bool isViewedBy(String userId) {
    return viewers.contains(userId);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        content,
        mediaUrl,
        thumbnailUrl,
        caption,
        title,
        type,
        privacy,
        mentions,
        viewers,
        reactions,
        createdAt,
        expiresAt,
        isHighlighted,
        highlightTitle,
        metadata,
        likes,
        isVideo,
        specialistName,
        specialistPhotoUrl,
        timeAgo,
      ];

  @override
  String toString() {
    return 'Story(id: $id, userId: $userId, type: $type, privacy: $privacy, viewCount: $viewCount)';
  }
}