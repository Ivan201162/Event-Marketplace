/// Элемент портфолио специалиста
class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.specialistId,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.category,
    required this.createdAt,
    required this.views,
    required this.likes,
    this.tags = const [],
    this.location,
    this.eventDate,
    this.clientName,
    this.isPublic = true,
  });

  /// Создать из Map
  factory PortfolioItem.fromMap(Map<String, dynamic> map) => PortfolioItem(
    id: map['id'] as String,
    specialistId: map['specialistId'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    mediaUrl: map['mediaUrl'] as String,
    mediaType: PortfolioMediaType.fromString(map['mediaType'] as String),
    category: map['category'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    views: (map['views'] as int?) ?? 0,
    likes: (map['likes'] as int?) ?? 0,
    tags: List<String>.from((map['tags'] as List?) ?? []),
    location: map['location'] as String?,
    eventDate: map['eventDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['eventDate'] as int)
        : null,
    clientName: map['clientName'] as String?,
    isPublic: (map['isPublic'] as bool?) ?? true,
  );

  /// Уникальный идентификатор
  final String id;

  /// ID специалиста
  final String specialistId;

  /// Заголовок
  final String title;

  /// Описание
  final String description;

  /// URL медиафайла
  final String mediaUrl;

  /// Тип медиа (image, video)
  final PortfolioMediaType mediaType;

  /// Категория
  final String category;

  /// Дата создания
  final DateTime createdAt;

  /// Количество просмотров
  final int views;

  /// Количество лайков
  final int likes;

  /// Теги
  final List<String> tags;

  /// Местоположение
  final String? location;

  /// Дата мероприятия
  final DateTime? eventDate;

  /// Имя клиента
  final String? clientName;

  /// Публичный доступ
  final bool isPublic;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'specialistId': specialistId,
    'title': title,
    'description': description,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType.value,
    'category': category,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'views': views,
    'likes': likes,
    'tags': tags,
    'location': location,
    'eventDate': eventDate?.millisecondsSinceEpoch,
    'clientName': clientName,
    'isPublic': isPublic,
  };

  /// Создать копию с изменениями
  PortfolioItem copyWith({
    String? id,
    String? specialistId,
    String? title,
    String? description,
    String? mediaUrl,
    PortfolioMediaType? mediaType,
    String? category,
    DateTime? createdAt,
    int? views,
    int? likes,
    List<String>? tags,
    String? location,
    DateTime? eventDate,
    String? clientName,
    bool? isPublic,
  }) => PortfolioItem(
    id: id ?? this.id,
    specialistId: specialistId ?? this.specialistId,
    title: title ?? this.title,
    description: description ?? this.description,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    mediaType: mediaType ?? this.mediaType,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    views: views ?? this.views,
    likes: likes ?? this.likes,
    tags: tags ?? this.tags,
    location: location ?? this.location,
    eventDate: eventDate ?? this.eventDate,
    clientName: clientName ?? this.clientName,
    isPublic: isPublic ?? this.isPublic,
  );
}

/// Тип медиа в портфолио
enum PortfolioMediaType {
  image('image'),
  video('video');

  const PortfolioMediaType(this.value);
  final String value;

  static PortfolioMediaType fromString(String value) {
    switch (value) {
      case 'image':
        return PortfolioMediaType.image;
      case 'video':
        return PortfolioMediaType.video;
      default:
        return PortfolioMediaType.image;
    }
  }
}
