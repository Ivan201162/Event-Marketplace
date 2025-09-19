import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель предложения специалистов в чат
class Proposal {
  const Proposal({
    required this.id,
    required this.chatId,
    required this.organizerId,
    required this.customerId,
    required this.specialists,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
    this.respondedBy,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory Proposal.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Proposal(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      organizerId: data['organizerId'] ?? '',
      customerId: data['customerId'] ?? '',
      specialists: (data['specialists'] as List<dynamic>?)
              ?.map(
                (s) => ProposalSpecialist.fromMap(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
      status: ProposalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProposalStatus.pending,
      ),
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      respondedBy: data['respondedBy'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Создать из Map
  factory Proposal.fromMap(Map<String, dynamic> data) => Proposal(
        id: data['id'] ?? '',
        chatId: data['chatId'] ?? '',
        organizerId: data['organizerId'] ?? '',
        customerId: data['customerId'] ?? '',
        specialists: (data['specialists'] as List<dynamic>?)
                ?.map(
                  (s) => ProposalSpecialist.fromMap(s as Map<String, dynamic>),
                )
                .toList() ??
            [],
        status: ProposalStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => ProposalStatus.pending,
        ),
        message: data['message'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        respondedAt: data['respondedAt'] != null
            ? (data['respondedAt'] as Timestamp).toDate()
            : null,
        respondedBy: data['respondedBy'],
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
      );
  final String id;
  final String chatId;
  final String organizerId;
  final String customerId;
  final List<ProposalSpecialist> specialists;
  final ProposalStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? respondedBy;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'organizerId': organizerId,
        'customerId': customerId,
        'specialists': specialists.map((s) => s.toMap()).toList(),
        'status': status.name,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'respondedAt':
            respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
        'respondedBy': respondedBy,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  Proposal copyWith({
    String? id,
    String? chatId,
    String? organizerId,
    String? customerId,
    List<ProposalSpecialist>? specialists,
    ProposalStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? respondedBy,
    Map<String, dynamic>? metadata,
  }) =>
      Proposal(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        organizerId: organizerId ?? this.organizerId,
        customerId: customerId ?? this.customerId,
        specialists: specialists ?? this.specialists,
        status: status ?? this.status,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        respondedAt: respondedAt ?? this.respondedAt,
        respondedBy: respondedBy ?? this.respondedBy,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, можно ли ответить на предложение
  bool get canRespond => status == ProposalStatus.pending;

  /// Проверить, принято ли предложение
  bool get isAccepted => status == ProposalStatus.accepted;

  /// Проверить, отклонено ли предложение
  bool get isRejected => status == ProposalStatus.rejected;

  /// Получить количество специалистов
  int get specialistCount => specialists.length;

  /// Получить общую стоимость предложения
  double get totalCost => specialists.fold(
        0,
        (sum, specialist) => sum + (specialist.estimatedPrice ?? 0),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Proposal &&
        other.id == id &&
        other.chatId == chatId &&
        other.organizerId == organizerId &&
        other.customerId == customerId &&
        other.specialists == specialists &&
        other.status == status &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.respondedAt == respondedAt &&
        other.respondedBy == respondedBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        chatId,
        organizerId,
        customerId,
        specialists,
        status,
        message,
        createdAt,
        respondedAt,
        respondedBy,
      );

  @override
  String toString() =>
      'Proposal(id: $id, chatId: $chatId, status: $status, specialistCount: $specialistCount)';
}

/// Специалист в предложении
class ProposalSpecialist {
  const ProposalSpecialist({
    required this.specialistId,
    required this.specialistName,
    required this.categoryId,
    required this.categoryName,
    this.estimatedPrice,
    this.description,
    this.metadata,
  });

  /// Создать из Map
  factory ProposalSpecialist.fromMap(Map<String, dynamic> data) =>
      ProposalSpecialist(
        specialistId: data['specialistId'] ?? '',
        specialistName: data['specialistName'] ?? '',
        categoryId: data['categoryId'] ?? '',
        categoryName: data['categoryName'] ?? '',
        estimatedPrice: data['estimatedPrice']?.toDouble(),
        description: data['description'],
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
      );
  final String specialistId;
  final String specialistName;
  final String categoryId;
  final String categoryName;
  final double? estimatedPrice;
  final String? description;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'specialistName': specialistName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'estimatedPrice': estimatedPrice,
        'description': description,
        'metadata': metadata,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProposalSpecialist &&
        other.specialistId == specialistId &&
        other.specialistName == specialistName &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.estimatedPrice == estimatedPrice &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(
        specialistId,
        specialistName,
        categoryId,
        categoryName,
        estimatedPrice,
        description,
      );

  @override
  String toString() =>
      'ProposalSpecialist(specialistId: $specialistId, specialistName: $specialistName, categoryName: $categoryName)';
}

/// Статус предложения
enum ProposalStatus {
  pending,
  accepted,
  rejected,
  expired,
}

/// Расширение для статуса предложения
extension ProposalStatusExtension on ProposalStatus {
  String get displayName {
    switch (this) {
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

  String get description {
    switch (this) {
      case ProposalStatus.pending:
        return 'Предложение ожидает вашего ответа';
      case ProposalStatus.accepted:
        return 'Предложение было принято';
      case ProposalStatus.rejected:
        return 'Предложение было отклонено';
      case ProposalStatus.expired:
        return 'Время действия предложения истекло';
    }
  }

  Color get color {
    switch (this) {
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
}
