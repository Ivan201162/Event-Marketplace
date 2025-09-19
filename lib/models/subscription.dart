import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель подписки
class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.specialistId,
    required this.specialistName,
    this.specialistPhotoUrl,
    required this.createdAt,
    this.isActive = true,
    this.notificationsEnabled = true,
  });

  /// Создать из документа Firestore
  factory Subscription.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Subscription(
      id: doc.id,
      userId: data['userId'] as String,
      specialistId: data['specialistId'] as String,
      specialistName: data['specialistName'] as String,
      specialistPhotoUrl: data['specialistPhotoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
    );
  }
  final String id;
  final String userId;
  final String specialistId;
  final String specialistName;
  final String? specialistPhotoUrl;
  final DateTime createdAt;
  final bool isActive;
  final bool notificationsEnabled;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'specialistPhotoUrl': specialistPhotoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
        'notificationsEnabled': notificationsEnabled,
      };

  /// Создать копию с обновлёнными полями
  Subscription copyWith({
    String? id,
    String? userId,
    String? specialistId,
    String? specialistName,
    String? specialistPhotoUrl,
    DateTime? createdAt,
    bool? isActive,
    bool? notificationsEnabled,
  }) =>
      Subscription(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        specialistId: specialistId ?? this.specialistId,
        specialistName: specialistName ?? this.specialistName,
        specialistPhotoUrl: specialistPhotoUrl ?? this.specialistPhotoUrl,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Subscription(id: $id, userId: $userId, specialistId: $specialistId)';
}
