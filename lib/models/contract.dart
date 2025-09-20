import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Типы договоров
enum ContractType {
  service, // Договор на оказание услуг
  rental, // Договор аренды
  supply, // Договор поставки
}

/// Статусы договоров
enum ContractStatus {
  draft, // Черновик
  pending, // Ожидает подписания
  signed, // Подписан
  active, // Действующий
  completed, // Завершен
  cancelled, // Отменен
  expired, // Истек
}

/// Модель договора
class Contract {
  const Contract({
    required this.id,
    required this.contractNumber,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.type,
    required this.status,
    required this.title,
    required this.content,
    required this.terms,
    required this.createdAt,
    required this.updatedAt,
    this.signedAt,
    required this.expiresAt,
    required this.metadata,
    this.specialistName,
    this.startDate,
    this.endDate,
    this.totalAmount,
    this.currency,
  });

  /// Создать из документа Firestore
  factory Contract.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Contract(
      id: doc.id,
      contractNumber: data['contractNumber'] ?? '',
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      type: ContractType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ContractType.service,
      ),
      status: ContractStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ContractStatus.draft,
      ),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      terms: Map<String, dynamic>.from(data['terms'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      signedAt: data['signedAt'] != null
          ? (data['signedAt'] as Timestamp).toDate()
          : null,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      specialistName: data['specialistName'],
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      totalAmount: data['totalAmount']?.toDouble(),
      currency: data['currency'],
    );
  }
  final String id;
  final String contractNumber;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final ContractType type;
  final ContractStatus status;
  final String title;
  final String content;
  final Map<String, dynamic> terms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? signedAt;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;
  final String? specialistName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? totalAmount;
  final String? currency;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'contractNumber': contractNumber,
        'bookingId': bookingId,
        'customerId': customerId,
        'specialistId': specialistId,
        'type': type.name,
        'status': status.name,
        'title': title,
        'content': content,
        'terms': terms,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'metadata': metadata,
        'specialistName': specialistName,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'totalAmount': totalAmount,
        'currency': currency,
      };

  /// Создать копию с изменениями
  Contract copyWith({
    String? id,
    String? contractNumber,
    String? bookingId,
    String? customerId,
    String? specialistId,
    ContractType? type,
    ContractStatus? status,
    String? title,
    String? content,
    Map<String, dynamic>? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? signedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) =>
      Contract(
        id: id ?? this.id,
        contractNumber: contractNumber ?? this.contractNumber,
        bookingId: bookingId ?? this.bookingId,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        type: type ?? this.type,
        status: status ?? this.status,
        title: title ?? this.title,
        content: content ?? this.content,
        terms: terms ?? this.terms,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        signedAt: signedAt ?? this.signedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        metadata: metadata ?? this.metadata,
        specialistName: specialistName ?? this.specialistName,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        totalAmount: totalAmount ?? this.totalAmount,
        currency: currency ?? this.currency,
      );
}

/// Расширение для ContractStatus
extension ContractStatusExtension on ContractStatus {
  Color get statusColor {
    switch (this) {
      case ContractStatus.draft:
        return Colors.grey;
      case ContractStatus.pending:
        return Colors.orange;
      case ContractStatus.signed:
        return Colors.blue;
      case ContractStatus.active:
        return Colors.green;
      case ContractStatus.completed:
        return Colors.purple;
      case ContractStatus.cancelled:
        return Colors.red;
      case ContractStatus.expired:
        return Colors.brown;
    }
  }

  String get statusText {
    switch (this) {
      case ContractStatus.draft:
        return 'Черновик';
      case ContractStatus.pending:
        return 'Ожидает подписания';
      case ContractStatus.signed:
        return 'Подписан';
      case ContractStatus.active:
        return 'Действующий';
      case ContractStatus.completed:
        return 'Завершен';
      case ContractStatus.cancelled:
        return 'Отменен';
      case ContractStatus.expired:
        return 'Истек';
    }
  }
}
