import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель идеи
class Idea {
  const Idea({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    required this.category,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.createdAt,
    this.likesCount = 0,
    this.savesCount = 0,
    this.sharesCount = 0,
    this.commentCount = 0,
    this.viewsCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.savedBy = const [],
    this.tags = const [],
    this.metadata,
  });

  /// Создать идею из документа Firestore
  factory Idea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Idea.fromMap(data, doc.id);
  }

  /// Создать идею из документа Firestore (алиас для совместимости)
  factory Idea.fromFirestore(DocumentSnapshot doc) => Idea.fromDocument(doc);

  /// Создать идею из Map
  factory Idea.fromMap(Map<String, dynamic> data, [String? id]) => Idea(
        id: id ?? data['id'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'],
        videoUrl: data['videoUrl'],
        category: data['category'] ?? '',
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'],
        authorAvatar: data['authorAvatar'],
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        likesCount: data['likesCount'] as int? ?? 0,
        savesCount: data['savesCount'] as int? ?? 0,
        sharesCount: data['sharesCount'] as int? ?? 0,
        commentCount: data['commentCount'] as int? ?? 0,
        viewsCount: data['viewsCount'] as int? ?? 0,
        commentsCount: data['commentsCount'] as int? ?? 0,
        likedBy: List<String>.from(data['likedBy'] ?? []),
        savedBy: List<String>.from(data['savedBy'] ?? []),
        tags: List<String>.from(data['tags'] ?? []),
        metadata: data['metadata'],
      );

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final String category;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final int likesCount;
  final int savesCount;
  final int sharesCount;
  final int commentCount;
  final int viewsCount;
  final int commentsCount;
  final List<String> likedBy;
  final List<String> savedBy;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  // Геттеры для совместимости
  List<String> get images => imageUrl != null ? [imageUrl!] : [];
  String? get authorPhotoUrl => authorAvatar;
  String get categoryColor => _getCategoryColor(category);
  String get categoryIcon => _getCategoryIcon(category);

  String _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wedding':
        return '#FF69B4';
      case 'corporate':
        return '#4169E1';
      case 'birthday':
        return '#FFD700';
      case 'anniversary':
        return '#FF6347';
      case 'graduation':
        return '#32CD32';
      case 'conference':
        return '#9370DB';
      case 'exhibition':
        return '#FF8C00';
      case 'festival':
        return '#FF1493';
      case 'sports':
        return '#00CED1';
      case 'charity':
        return '#DC143C';
      default:
        return '#666666';
    }
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wedding':
        return '💒';
      case 'corporate':
        return '🏢';
      case 'birthday':
        return '🎂';
      case 'anniversary':
        return '🎉';
      case 'graduation':
        return '🎓';
      case 'conference':
        return '📊';
      case 'exhibition':
        return '🎨';
      case 'festival':
        return '🎪';
      case 'sports':
        return '⚽';
      case 'charity':
        return '❤️';
      default:
        return '📝';
    }
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'category': category,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'createdAt': Timestamp.fromDate(createdAt),
        'likesCount': likesCount,
        'savesCount': savesCount,
        'sharesCount': sharesCount,
        'commentCount': commentCount,
        'viewsCount': viewsCount,
        'commentsCount': commentsCount,
        'likedBy': likedBy,
        'savedBy': savedBy,
        'tags': tags,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  Idea copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? category,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    DateTime? createdAt,
    int? likesCount,
    int? savesCount,
    int? sharesCount,
    int? commentCount,
    int? viewsCount,
    int? commentsCount,
    List<String>? likedBy,
    List<String>? savedBy,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) =>
      Idea(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        category: category ?? this.category,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorAvatar: authorAvatar ?? this.authorAvatar,
        createdAt: createdAt ?? this.createdAt,
        likesCount: likesCount ?? this.likesCount,
        savesCount: savesCount ?? this.savesCount,
        sharesCount: sharesCount ?? this.sharesCount,
        commentCount: commentCount ?? this.commentCount,
        viewsCount: viewsCount ?? this.viewsCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedBy: likedBy ?? this.likedBy,
        savedBy: savedBy ?? this.savedBy,
        tags: tags ?? this.tags,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, является ли идея видео
  bool get isVideo => videoUrl != null;

  /// Проверить, является ли идея изображением
  bool get isImage => imageUrl != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Idea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Получить количество лайков
  int get likeCount => likesCount;

  /// Получить количество комментариев
  int get commentCountValue => 0; // TODO(developer): Добавить поле для комментариев

  /// Проверить, лайкнута ли идея (для совместимости)
  bool get isLiked => false; // TODO(developer): Передавать userId

  /// Проверить, сохранена ли идея (для совместимости)
  bool get isSaved => false; // TODO(developer): Передавать userId

  @override
  String toString() => 'Idea(id: $id, title: $title, category: $category)';
}
