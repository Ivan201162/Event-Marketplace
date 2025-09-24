import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Статусы акта выполненных работ
enum WorkActStatus {
  draft, // Черновик
  pending, // Ожидает подписания
  signed, // Подписан
  completed, // Завершен
  disputed, // Оспорен
}

/// Информация о подписи
class Signature {
  const Signature({
    required this.userId,
    required this.userName,
    required this.signature,
    required this.signedAt,
    this.signatureType, // 'digital' или 'drawn'
  });

  final String userId;
  final String userName;
  final String signature; // Base64 encoded signature image or digital signature
  final DateTime signedAt;
  final String? signatureType;

  factory Signature.fromMap(Map<String, dynamic> map) => Signature(
        userId: map['userId'] as String,
        userName: map['userName'] as String,
        signature: map['signature'] as String,
        signedAt: (map['signedAt'] as Timestamp).toDate(),
        signatureType: map['signatureType'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'signature': signature,
        'signedAt': Timestamp.fromDate(signedAt),
        'signatureType': signatureType,
      };
}

/// Модель акта выполненных работ
class WorkAct {
  const WorkAct({
    required this.id,
    required this.actNumber,
    required this.contractId,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.status,
    required this.title,
    required this.content,
    required this.workDescription,
    required this.workResults,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.signedAt,
    required this.workStartDate,
    required this.workEndDate,
    this.customerSignature,
    this.specialistSignature,
    this.attachments,
    this.notes,
    this.disputeReason,
    this.resolution,
  });

  /// Создать из документа Firestore
  factory WorkAct.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return WorkAct(
      id: doc.id,
      actNumber: data['actNumber'] as String? ?? '',
      contractId: data['contractId'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      status: WorkActStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WorkActStatus.draft,
      ),
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      workDescription: data['workDescription'] as String? ?? '',
      workResults: data['workResults'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'RUB',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      signedAt: data['signedAt'] != null
          ? (data['signedAt'] as Timestamp).toDate()
          : null,
      workStartDate: (data['workStartDate'] as Timestamp).toDate(),
      workEndDate: (data['workEndDate'] as Timestamp).toDate(),
      customerSignature: data['customerSignature'] != null
          ? Signature.fromMap(data['customerSignature'] as Map<String, dynamic>)
          : null,
      specialistSignature: data['specialistSignature'] != null
          ? Signature.fromMap(data['specialistSignature'] as Map<String, dynamic>)
          : null,
      attachments: data['attachments'] != null
          ? (data['attachments'] as List<dynamic>)
              .map((item) => item as String)
              .toList()
          : null,
      notes: data['notes'] as String?,
      disputeReason: data['disputeReason'] as String?,
      resolution: data['resolution'] as String?,
    );
  }

  final String id;
  final String actNumber;
  final String contractId;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final WorkActStatus status;
  final String title;
  final String content;
  final String workDescription;
  final String workResults;
  final double totalAmount;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? signedAt;
  final DateTime workStartDate;
  final DateTime workEndDate;
  final Signature? customerSignature;
  final Signature? specialistSignature;
  final List<String>? attachments;
  final String? notes;
  final String? disputeReason;
  final String? resolution;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'actNumber': actNumber,
        'contractId': contractId,
        'bookingId': bookingId,
        'customerId': customerId,
        'specialistId': specialistId,
        'status': status.name,
        'title': title,
        'content': content,
        'workDescription': workDescription,
        'workResults': workResults,
        'totalAmount': totalAmount,
        'currency': currency,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
        'workStartDate': Timestamp.fromDate(workStartDate),
        'workEndDate': Timestamp.fromDate(workEndDate),
        'customerSignature': customerSignature?.toMap(),
        'specialistSignature': specialistSignature?.toMap(),
        'attachments': attachments,
        'notes': notes,
        'disputeReason': disputeReason,
        'resolution': resolution,
      };

  /// Создать копию с изменениями
  WorkAct copyWith({
    String? id,
    String? actNumber,
    String? contractId,
    String? bookingId,
    String? customerId,
    String? specialistId,
    WorkActStatus? status,
    String? title,
    String? content,
    String? workDescription,
    String? workResults,
    double? totalAmount,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? signedAt,
    DateTime? workStartDate,
    DateTime? workEndDate,
    Signature? customerSignature,
    Signature? specialistSignature,
    List<String>? attachments,
    String? notes,
    String? disputeReason,
    String? resolution,
  }) =>
      WorkAct(
        id: id ?? this.id,
        actNumber: actNumber ?? this.actNumber,
        contractId: contractId ?? this.contractId,
        bookingId: bookingId ?? this.bookingId,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        status: status ?? this.status,
        title: title ?? this.title,
        content: content ?? this.content,
        workDescription: workDescription ?? this.workDescription,
        workResults: workResults ?? this.workResults,
        totalAmount: totalAmount ?? this.totalAmount,
        currency: currency ?? this.currency,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        signedAt: signedAt ?? this.signedAt,
        workStartDate: workStartDate ?? this.workStartDate,
        workEndDate: workEndDate ?? this.workEndDate,
        customerSignature: customerSignature ?? this.customerSignature,
        specialistSignature: specialistSignature ?? this.specialistSignature,
        attachments: attachments ?? this.attachments,
        notes: notes ?? this.notes,
        disputeReason: disputeReason ?? this.disputeReason,
        resolution: resolution ?? this.resolution,
      );
}

/// Расширение для WorkActStatus
extension WorkActStatusExtension on WorkActStatus {
  Color get statusColor {
    switch (this) {
      case WorkActStatus.draft:
        return Colors.grey;
      case WorkActStatus.pending:
        return Colors.orange;
      case WorkActStatus.signed:
        return Colors.green;
      case WorkActStatus.completed:
        return Colors.blue;
      case WorkActStatus.disputed:
        return Colors.red;
    }
  }

  String get statusText {
    switch (this) {
      case WorkActStatus.draft:
        return 'Черновик';
      case WorkActStatus.pending:
        return 'Ожидает подписания';
      case WorkActStatus.signed:
        return 'Подписан';
      case WorkActStatus.completed:
        return 'Завершен';
      case WorkActStatus.disputed:
        return 'Оспорен';
    }
  }

  IconData get statusIcon {
    switch (this) {
      case WorkActStatus.draft:
        return Icons.edit;
      case WorkActStatus.pending:
        return Icons.pending;
      case WorkActStatus.signed:
        return Icons.check_circle;
      case WorkActStatus.completed:
        return Icons.done_all;
      case WorkActStatus.disputed:
        return Icons.warning;
    }
  }
}
