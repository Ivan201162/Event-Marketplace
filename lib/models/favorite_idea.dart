import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель избранной идеи
class FavoriteIdea {
  const FavoriteIdea({
    required this.id,
    required this.userId,
    required this.ideaId,
    required this.addedAt,
    this.notes,
    this.tags = const [],
    this.isAttachedToBooking = false,
    this.attachedBookingId,
  });

  final String id;
  final String userId;
  final String ideaId;
  final DateTime addedAt;
  final String? notes; // Заметки пользователя
  final List<String> tags; // Пользовательские теги
  final bool isAttachedToBooking;
  final String? attachedBookingId;

  /// Создать из Map (Firestore)
  factory FavoriteIdea.fromMap(Map<String, dynamic> map) =>
    FavoriteIdea(
      id: map['id'] as String,
      userId: map['userId'] as String,
      ideaId: map['ideaId'] as String,
      addedAt: (map['addedAt'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
      tags: List<String>.from((map['tags'] ?? <String>[]) as List),
      isAttachedToBooking: (map['isAttachedToBooking'] ?? false) as bool,
      attachedBookingId: map['attachedBookingId'] as String?,
    );

  /// Преобразовать в Map (Firestore)
  Map<String, dynamic> toMap() => {
      'id': id,
      'userId': userId,
      'ideaId': ideaId,
      'addedAt': Timestamp.fromDate(addedAt),
      'notes': notes,
      'tags': tags,
      'isAttachedToBooking': isAttachedToBooking,
      'attachedBookingId': attachedBookingId,
    };

  /// Создать копию с изменениями
  FavoriteIdea copyWith({
    String? id,
    String? userId,
    String? ideaId,
    DateTime? addedAt,
    String? notes,
    List<String>? tags,
    bool? isAttachedToBooking,
    String? attachedBookingId,
  }) =>
    FavoriteIdea(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ideaId: ideaId ?? this.ideaId,
      addedAt: addedAt ?? this.addedAt,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isAttachedToBooking: isAttachedToBooking ?? this.isAttachedToBooking,
      attachedBookingId: attachedBookingId ?? this.attachedBookingId,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is FavoriteIdea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
    'FavoriteIdea(id: $id, userId: $userId, ideaId: $ideaId)';
}