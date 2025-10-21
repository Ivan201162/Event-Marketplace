import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Статус предложения
enum ProposalStatus {
  pending, // Ожидает ответа
  accepted, // Принято
  rejected, // Отклонено
  expired, // Истекло
}

/// Специалист в предложении
class ProposalSpecialist {
  const ProposalSpecialist({
    required this.id,
    required this.name,
    required this.price,
    this.specialistId,
    this.specialistName,
    this.categoryId,
    this.categoryName,
    this.description,
    this.estimatedPrice,
  });

  final String id;
  final String name;
  final double price;
  final String? specialistId;
  final String? specialistName;
  final String? categoryId;
  final String? categoryName;
  final String? description;
  final double? estimatedPrice;
}

/// Модель предложения специалиста
class Proposal {
  const Proposal({
    required this.id,
    required this.bookingId,
    required this.specialistId,
    required this.customerId,
    required this.originalPrice,
    required this.discountPercent,
    required this.finalPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.message,
    this.notes,
  });

  /// Создать из документа Firestore
  factory Proposal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Proposal(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      customerId: data['customerId'] ?? '',
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 0.0,
      status: ProposalStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => ProposalStatus.pending,
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      message: data['message'] as String?,
      notes: data['notes'] as String?,
    );
  }

  /// Создать из Map
  factory Proposal.fromMap(Map<String, dynamic> map) => Proposal(
    id: map['id'] ?? '',
    bookingId: map['bookingId'] ?? '',
    specialistId: map['specialistId'] ?? '',
    customerId: map['customerId'] ?? '',
    originalPrice: (map['originalPrice'] ?? 0).toDouble(),
    discountPercent: (map['discountPercent'] ?? 0).toDouble(),
    finalPrice: (map['finalPrice'] ?? 0).toDouble(),
    status: ProposalStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => ProposalStatus.pending,
    ),
    createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
    message: map['message'] as String?,
    notes: map['notes'] as String?,
  );

  final String id;
  final String bookingId;
  final String specialistId;
  final String customerId;
  final double originalPrice;
  final double discountPercent;
  final double finalPrice;
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final String? message;
  final String? notes;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'bookingId': bookingId,
    'specialistId': specialistId,
    'customerId': customerId,
    'originalPrice': originalPrice,
    'discountPercent': discountPercent,
    'finalPrice': finalPrice,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'message': message,
    'notes': notes,
  };

  /// Копировать с изменениями
  Proposal copyWith({
    String? id,
    String? bookingId,
    String? specialistId,
    String? customerId,
    double? originalPrice,
    double? discountPercent,
    double? finalPrice,
    ProposalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? message,
    String? notes,
  }) => Proposal(
    id: id ?? this.id,
    bookingId: bookingId ?? this.bookingId,
    specialistId: specialistId ?? this.specialistId,
    customerId: customerId ?? this.customerId,
    originalPrice: originalPrice ?? this.originalPrice,
    discountPercent: discountPercent ?? this.discountPercent,
    finalPrice: finalPrice ?? this.finalPrice,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    message: message ?? this.message,
    notes: notes ?? this.notes,
  );

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case ProposalStatus.pending:
        return 'Ожидает ответа';
      case ProposalStatus.accepted:
        return 'Принято';
      case ProposalStatus.rejected:
        return 'Отклонено';
      case ProposalStatus.expired:
        return 'Истекло';
    }
  }

  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case ProposalStatus.pending:
        return 'orange';
      case ProposalStatus.accepted:
        return 'green';
      case ProposalStatus.rejected:
        return 'red';
      case ProposalStatus.expired:
        return 'grey';
    }
  }

  /// Получить цвет статуса как Color
  Color get color {
    switch (status) {
      case ProposalStatus.pending:
        return Colors.orange;
      case ProposalStatus.accepted:
        return Colors.green;
      case ProposalStatus.rejected:
        return Colors.red;
      case ProposalStatus.expired:
        return Colors.grey;
    }
  }

  /// Получить отображаемое название статуса
  String get displayName => statusDisplayName;

  /// Количество специалистов (для совместимости с UI)
  int get specialistCount => 1;

  /// Общая стоимость (для совместимости с UI)
  double get totalCost => finalPrice;

  /// Список специалистов (для совместимости с UI)
  List<ProposalSpecialist> get specialists => [
    ProposalSpecialist(
      id: specialistId,
      name: 'Специалист',
      price: finalPrice,
      specialistId: specialistId,
      specialistName: 'Специалист',
      categoryName: 'Услуга',
      description: message ?? 'Предложение специалиста',
      estimatedPrice: finalPrice,
    ),
  ];

  /// Можно ли ответить на предложение
  bool get canRespond => status == ProposalStatus.pending;

  /// Проверить, можно ли принять предложение
  bool get canBeAccepted => status == ProposalStatus.pending;

  /// Проверить, можно ли отклонить предложение
  bool get canBeRejected => status == ProposalStatus.pending;

  /// Проверить, истекло ли предложение
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Получить экономию от скидки
  double get savings => originalPrice - finalPrice;

  /// Получить текст скидки
  String get discountText =>
      discountPercent > 0 ? 'Скидка ${discountPercent.toInt()}%' : 'Без скидки';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proposal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Proposal(id: $id, discountPercent: $discountPercent%, finalPrice: $finalPrice)';
}
