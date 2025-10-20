import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель коллекции идей
class IdeaCollection {
  const IdeaCollection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.ideas = const [],
    this.isPublic = false,
    this.likes = 0,
    this.isLiked = false,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<String> ideas; // ID идей в коллекции
  final bool isPublic;
  final int likes;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory IdeaCollection.fromMap(Map<String, dynamic> data) {
    return IdeaCollection(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      ideas: List<String>.from(data['ideas'] ?? []),
      isPublic: data['isPublic'] as bool? ?? false,
      likes: data['likes'] as int? ?? 0,
      isLiked: data['isLiked'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory IdeaCollection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return IdeaCollection.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
        'coverImageUrl': coverImageUrl,
        'ideas': ideas,
        'isPublic': isPublic,
        'likes': likes,
        'isLiked': isLiked,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  IdeaCollection copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? coverImageUrl,
    List<String>? ideas,
    bool? isPublic,
    int? likes,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      IdeaCollection(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        description: description ?? this.description,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        ideas: ideas ?? this.ideas,
        isPublic: isPublic ?? this.isPublic,
        likes: likes ?? this.likes,
        isLiked: isLiked ?? this.isLiked,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Получить количество идей в коллекции
  int get ideasCount => ideas.length;

  /// Проверить, пуста ли коллекция
  bool get isEmpty => ideas.isEmpty;

  /// Проверить, содержит ли коллекция указанную идею
  bool containsIdea(String ideaId) => ideas.contains(ideaId);
}
