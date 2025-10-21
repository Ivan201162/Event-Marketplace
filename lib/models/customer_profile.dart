import 'package:cloud_firestore/cloud_firestore.dart';

import 'user.dart';

/// Профиль заказчика
class CustomerProfile {
  const CustomerProfile({
    required this.userId,
    this.photoURL,
    this.bio,
    this.maritalStatus,
    this.weddingDate,
    this.anniversaryDate,
    this.phoneNumber,
    this.location,
    this.interests = const [],
    this.eventTypes = const [],
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать профиль из документа Firestore
  factory CustomerProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CustomerProfile(
      userId: doc.id,
      photoURL: data['photoURL'] as String?,
      bio: data['bio'] as String?,
      maritalStatus: _parseMaritalStatus(data['maritalStatus']),
      weddingDate: data['weddingDate'] != null ? (data['weddingDate'] as Timestamp).toDate() : null,
      anniversaryDate: data['anniversaryDate'] != null
          ? (data['anniversaryDate'] as Timestamp).toDate()
          : null,
      phoneNumber: data['phoneNumber'] as String?,
      location: data['location'] as String?,
      interests: List<String>.from(data['interests'] as List<dynamic>? ?? []),
      eventTypes: List<String>.from(data['eventTypes'] as List<dynamic>? ?? []),
      preferences: data['preferences'] as Map<String, dynamic>?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
  final String userId;
  final String? photoURL;
  final String? bio;
  final MaritalStatus? maritalStatus;
  final DateTime? weddingDate;
  final DateTime? anniversaryDate;
  final String? phoneNumber;
  final String? location;
  final List<String> interests;
  final List<String> eventTypes; // Типы мероприятий, которые планирует
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'photoURL': photoURL,
    'bio': bio,
    'maritalStatus': maritalStatus?.name,
    'weddingDate': weddingDate != null ? Timestamp.fromDate(weddingDate!) : null,
    'anniversaryDate': anniversaryDate != null ? Timestamp.fromDate(anniversaryDate!) : null,
    'phoneNumber': phoneNumber,
    'location': location,
    'interests': interests,
    'eventTypes': eventTypes,
    'preferences': preferences,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Копировать с изменениями
  CustomerProfile copyWith({
    String? userId,
    String? photoURL,
    String? bio,
    MaritalStatus? maritalStatus,
    DateTime? weddingDate,
    DateTime? anniversaryDate,
    String? phoneNumber,
    String? location,
    List<String>? interests,
    List<String>? eventTypes,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CustomerProfile(
    userId: userId ?? this.userId,
    photoURL: photoURL ?? this.photoURL,
    bio: bio ?? this.bio,
    maritalStatus: maritalStatus ?? this.maritalStatus,
    weddingDate: weddingDate ?? this.weddingDate,
    anniversaryDate: anniversaryDate ?? this.anniversaryDate,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    location: location ?? this.location,
    interests: interests ?? this.interests,
    eventTypes: eventTypes ?? this.eventTypes,
    preferences: preferences ?? this.preferences,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Получить русское название семейного положения
  String get maritalStatusDisplayName {
    switch (maritalStatus) {
      case MaritalStatus.single:
        return 'Холост/не замужем';
      case MaritalStatus.married:
        return 'Женат/замужем';
      case MaritalStatus.divorced:
        return 'Разведен/разведена';
      case MaritalStatus.widowed:
        return 'Вдовец/вдова';
      case MaritalStatus.inRelationship:
        return 'В отношениях';
      case null:
        return 'Не указано';
    }
  }

  /// Проверить, есть ли напоминания о важных датах
  bool get hasImportantDates => weddingDate != null || anniversaryDate != null;

  /// Получить ближайшую важную дату
  DateTime? get nextImportantDate {
    final now = DateTime.now();
    final currentYear = now.year;

    DateTime? nextDate;

    if (weddingDate != null) {
      final weddingThisYear = DateTime(currentYear, weddingDate!.month, weddingDate!.day);
      if (weddingThisYear.isAfter(now)) {
        nextDate = weddingThisYear;
      } else {
        nextDate = DateTime(currentYear + 1, weddingDate!.month, weddingDate!.day);
      }
    }

    if (anniversaryDate != null) {
      final anniversaryThisYear = DateTime(
        currentYear,
        anniversaryDate!.month,
        anniversaryDate!.day,
      );
      if (anniversaryThisYear.isAfter(now)) {
        if (nextDate == null || anniversaryThisYear.isBefore(nextDate)) {
          nextDate = anniversaryThisYear;
        }
      } else {
        final nextAnniversary = DateTime(
          currentYear + 1,
          anniversaryDate!.month,
          anniversaryDate!.day,
        );
        if (nextDate == null || nextAnniversary.isBefore(nextDate)) {
          nextDate = nextAnniversary;
        }
      }
    }

    return nextDate;
  }

  /// Парсинг семейного положения из строки
  static MaritalStatus? _parseMaritalStatus(statusData) {
    if (statusData == null) return null;

    final statusString = statusData.toString().toLowerCase();
    switch (statusString) {
      case 'single':
        return MaritalStatus.single;
      case 'married':
        return MaritalStatus.married;
      case 'divorced':
        return MaritalStatus.divorced;
      case 'widowed':
        return MaritalStatus.widowed;
      case 'inrelationship':
        return MaritalStatus.inRelationship;
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerProfile && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'CustomerProfile(userId: $userId, maritalStatus: $maritalStatus, interests: $interests)';
}
