import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель сохраненной идеи пользователя
class SavedIdea {
  const SavedIdea({
    required this.id,
    required this.userId,
    required this.ideaId,
    required this.savedAt,
    this.notes,
    this.isFavorite = false,
    this.tags = const [],
  });

  /// Создать из документа Firestore
  factory SavedIdea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SavedIdea(
      id: doc.id,
      userId: data['userId'] ?? '',
      ideaId: data['ideaId'] ?? '',
      savedAt: data['savedAt'] != null
          ? (data['savedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'] as String?,
      isFavorite: data['isFavorite'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Создать из Map
  factory SavedIdea.fromMap(Map<String, dynamic> map) => SavedIdea(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        ideaId: map['ideaId'] ?? '',
        savedAt: map['savedAt'] != null
            ? (map['savedAt'] as Timestamp).toDate()
            : DateTime.now(),
        notes: map['notes'] as String?,
        isFavorite: map['isFavorite'] ?? false,
        tags: List<String>.from(map['tags'] ?? []),
      );

  final String id;
  final String userId;
  final String ideaId;
  final DateTime savedAt;
  final String? notes;
  final bool isFavorite;
  final List<String> tags;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'ideaId': ideaId,
        'savedAt': Timestamp.fromDate(savedAt),
        'notes': notes,
        'isFavorite': isFavorite,
        'tags': tags,
      };

  /// Копировать с изменениями
  SavedIdea copyWith({
    String? id,
    String? userId,
    String? ideaId,
    DateTime? savedAt,
    String? notes,
    bool? isFavorite,
    List<String>? tags,
  }) =>
      SavedIdea(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        ideaId: ideaId ?? this.ideaId,
        savedAt: savedAt ?? this.savedAt,
        notes: notes ?? this.notes,
        isFavorite: isFavorite ?? this.isFavorite,
        tags: tags ?? this.tags,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedIdea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SavedIdea(id: $id, userId: $userId, ideaId: $ideaId, isFavorite: $isFavorite)';
}
