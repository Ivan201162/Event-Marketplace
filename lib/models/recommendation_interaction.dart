import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы взаимодействий с рекомендациями
enum RecommendationInteractionType {
  view,
  click,
  like,
  dislike,
  share,
  bookmark,
  contact,
  book,
}

/// Модель взаимодействия с рекомендацией
class RecommendationInteraction {
  final String id;
  final String userId;
  final String specialistId;
  final RecommendationInteractionType type;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const RecommendationInteraction({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.type,
    required this.createdAt,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory RecommendationInteraction.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RecommendationInteraction(
      id: doc.id,
      userId: data['userId'] as String,
      specialistId: data['specialistId'] as String,
      type: RecommendationInteractionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RecommendationInteractionType.view,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'specialistId': specialistId,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  /// Создать копию с обновлёнными полями
  RecommendationInteraction copyWith({
    String? id,
    String? userId,
    String? specialistId,
    RecommendationInteractionType? type,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return RecommendationInteraction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecommendationInteraction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecommendationInteraction(id: $id, userId: $userId, specialistId: $specialistId, type: $type)';
  }
}
