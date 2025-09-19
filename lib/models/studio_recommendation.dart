import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель рекомендации студии фотографом
class StudioRecommendation {
  const StudioRecommendation({
    required this.id,
    required this.photographerId,
    required this.studioId,
    required this.studioName,
    required this.studioUrl,
    this.message,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  /// Создать из документа Firestore
  factory StudioRecommendation.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudioRecommendation(
      id: doc.id,
      photographerId: data['photographerId'] ?? '',
      studioId: data['studioId'] ?? '',
      studioName: data['studioName'] ?? '',
      studioUrl: data['studioUrl'] ?? '',
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  /// Создать из Map
  factory StudioRecommendation.fromMap(Map<String, dynamic> data) =>
      StudioRecommendation(
        id: data['id'] ?? '',
        photographerId: data['photographerId'] ?? '',
        studioId: data['studioId'] ?? '',
        studioName: data['studioName'] ?? '',
        studioUrl: data['studioUrl'] ?? '',
        message: data['message'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
        isActive: data['isActive'] ?? true,
      );
  final String id;
  final String photographerId;
  final String studioId;
  final String studioName;
  final String studioUrl;
  final String? message;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'photographerId': photographerId,
        'studioId': studioId,
        'studioName': studioName,
        'studioUrl': studioUrl,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'isActive': isActive,
      };

  /// Создать копию с изменениями
  StudioRecommendation copyWith({
    String? id,
    String? photographerId,
    String? studioId,
    String? studioName,
    String? studioUrl,
    String? message,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
  }) =>
      StudioRecommendation(
        id: id ?? this.id,
        photographerId: photographerId ?? this.photographerId,
        studioId: studioId ?? this.studioId,
        studioName: studioName ?? this.studioName,
        studioUrl: studioUrl ?? this.studioUrl,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        isActive: isActive ?? this.isActive,
      );

  /// Проверить, не истекла ли рекомендация
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Проверить, активна ли рекомендация
  bool get isValid => isActive && !isExpired;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudioRecommendation &&
        other.id == id &&
        other.photographerId == photographerId &&
        other.studioId == studioId &&
        other.studioName == studioName &&
        other.studioUrl == studioUrl &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(
        id,
        photographerId,
        studioId,
        studioName,
        studioUrl,
        message,
        createdAt,
        expiresAt,
        isActive,
      );

  @override
  String toString() =>
      'StudioRecommendation(id: $id, photographerId: $photographerId, studioName: $studioName)';
}

/// Модель двойного бронирования (фотограф + студия)
class DualBooking {
  const DualBooking({
    required this.id,
    required this.customerId,
    required this.photographerId,
    required this.studioId,
    required this.studioOptionId,
    required this.startTime,
    required this.endTime,
    required this.photographerPrice,
    required this.studioPrice,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory DualBooking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DualBooking(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      photographerId: data['photographerId'] ?? '',
      studioId: data['studioId'] ?? '',
      studioOptionId: data['studioOptionId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      photographerPrice: (data['photographerPrice'] as num).toDouble(),
      studioPrice: (data['studioPrice'] as num).toDouble(),
      totalPrice: (data['totalPrice'] as num).toDouble(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory DualBooking.fromMap(Map<String, dynamic> data) => DualBooking(
        id: data['id'] ?? '',
        customerId: data['customerId'] ?? '',
        photographerId: data['photographerId'] ?? '',
        studioId: data['studioId'] ?? '',
        studioOptionId: data['studioOptionId'] ?? '',
        startTime: (data['startTime'] as Timestamp).toDate(),
        endTime: (data['endTime'] as Timestamp).toDate(),
        photographerPrice: (data['photographerPrice'] as num).toDouble(),
        studioPrice: (data['studioPrice'] as num).toDouble(),
        totalPrice: (data['totalPrice'] as num).toDouble(),
        status: data['status'] ?? 'pending',
        notes: data['notes'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final String customerId;
  final String photographerId;
  final String studioId;
  final String studioOptionId;
  final DateTime startTime;
  final DateTime endTime;
  final double photographerPrice;
  final double studioPrice;
  final double totalPrice;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'photographerId': photographerId,
        'studioId': studioId,
        'studioOptionId': studioOptionId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'photographerPrice': photographerPrice,
        'studioPrice': studioPrice,
        'totalPrice': totalPrice,
        'status': status,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создать копию с изменениями
  DualBooking copyWith({
    String? id,
    String? customerId,
    String? photographerId,
    String? studioId,
    String? studioOptionId,
    DateTime? startTime,
    DateTime? endTime,
    double? photographerPrice,
    double? studioPrice,
    double? totalPrice,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DualBooking(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        photographerId: photographerId ?? this.photographerId,
        studioId: studioId ?? this.studioId,
        studioOptionId: studioOptionId ?? this.studioOptionId,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        photographerPrice: photographerPrice ?? this.photographerPrice,
        studioPrice: studioPrice ?? this.studioPrice,
        totalPrice: totalPrice ?? this.totalPrice,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Получить продолжительность в часах
  double get durationInHours =>
      endTime.difference(startTime).inHours.toDouble();

  /// Проверить, активно ли бронирование
  bool get isActive => status == 'confirmed' || status == 'in_progress';

  /// Проверить, завершено ли бронирование
  bool get isCompleted => status == 'completed';

  /// Получить экономию от двойного бронирования
  double get savings {
    // Предполагаем 10% скидку при двойном бронировании
    final individualTotal = photographerPrice + studioPrice;
    return individualTotal * 0.1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DualBooking &&
        other.id == id &&
        other.customerId == customerId &&
        other.photographerId == photographerId &&
        other.studioId == studioId &&
        other.studioOptionId == studioOptionId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.photographerPrice == photographerPrice &&
        other.studioPrice == studioPrice &&
        other.totalPrice == totalPrice &&
        other.status == status &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        customerId,
        photographerId,
        studioId,
        studioOptionId,
        startTime,
        endTime,
        photographerPrice,
        studioPrice,
        totalPrice,
        status,
        notes,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'DualBooking(id: $id, customerId: $customerId, status: $status)';
}
