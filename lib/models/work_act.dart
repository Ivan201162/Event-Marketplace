import 'package:cloud_firestore/cloud_firestore.dart';

/// Статусы акта выполненных работ
enum WorkActStatus {
  draft, // Черновик
  pending, // Ожидает подтверждения
  completed, // Подтвержден
  rejected, // Отклонен
}

/// Модель акта выполненных работ
class WorkAct {
  const WorkAct({
    required this.id,
    required this.actNumber,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.status,
    required this.title,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.workDescription,
    this.workStartDate,
    this.workEndDate,
    this.customerSignature,
    this.specialistSignature,
    this.metadata = const {},
    this.currency = 'RUB',
  });

  /// Создать из документа Firestore
  factory WorkAct.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return WorkAct(
      id: doc.id,
      actNumber: data['actNumber'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      status: WorkActStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WorkActStatus.draft,
      ),
      title: data['title'] as String? ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      workDescription: data['workDescription'] as String?,
      workStartDate: data['workStartDate'] != null
          ? (data['workStartDate'] as Timestamp).toDate()
          : null,
      workEndDate: data['workEndDate'] != null
          ? (data['workEndDate'] as Timestamp).toDate()
          : null,
      customerSignature: data['customerSignature'] as String?,
      specialistSignature: data['specialistSignature'] as String?,
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<dynamic, dynamic>? ?? {},
      ),
      currency: data['currency'] as String? ?? 'RUB',
    );
  }

  final String id;
  final String actNumber;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final WorkActStatus status;
  final String title;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? workDescription;
  final DateTime? workStartDate;
  final DateTime? workEndDate;
  final String? customerSignature;
  final String? specialistSignature;
  final Map<String, dynamic> metadata;
  final String currency;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'actNumber': actNumber,
        'bookingId': bookingId,
        'customerId': customerId,
        'specialistId': specialistId,
        'status': status.name,
        'title': title,
        'totalAmount': totalAmount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'workDescription': workDescription,
        'workStartDate':
            workStartDate != null ? Timestamp.fromDate(workStartDate!) : null,
        'workEndDate':
            workEndDate != null ? Timestamp.fromDate(workEndDate!) : null,
        'customerSignature': customerSignature,
        'specialistSignature': specialistSignature,
        'metadata': metadata,
        'currency': currency,
      };

  /// Создать копию с изменениями
  WorkAct copyWith({
    String? id,
    String? actNumber,
    String? bookingId,
    String? customerId,
    String? specialistId,
    WorkActStatus? status,
    String? title,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? workDescription,
    DateTime? workStartDate,
    DateTime? workEndDate,
    String? customerSignature,
    String? specialistSignature,
    Map<String, dynamic>? metadata,
    String? currency,
  }) =>
      WorkAct(
        id: id ?? this.id,
        actNumber: actNumber ?? this.actNumber,
        bookingId: bookingId ?? this.bookingId,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        status: status ?? this.status,
        title: title ?? this.title,
        totalAmount: totalAmount ?? this.totalAmount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt ?? this.completedAt,
        workDescription: workDescription ?? this.workDescription,
        workStartDate: workStartDate ?? this.workStartDate,
        workEndDate: workEndDate ?? this.workEndDate,
        customerSignature: customerSignature ?? this.customerSignature,
        specialistSignature: specialistSignature ?? this.specialistSignature,
        metadata: metadata ?? this.metadata,
        currency: currency ?? this.currency,
      );

  /// Проверить, подписан ли акт обеими сторонами
  bool get isFullySigned =>
      customerSignature != null && specialistSignature != null;

  /// Проверить, может ли пользователь подписать акт
  bool canSignBy(String userId) {
    if (userId == customerId && customerSignature == null) return true;
    if (userId == specialistId && specialistSignature == null) return true;
    return false;
  }

  /// Проверить, подписан ли акт пользователем
  bool isSignedBy(String userId) {
    if (userId == customerId) return customerSignature != null;
    if (userId == specialistId) return specialistSignature != null;
    return false;
  }
}

/// Расширение для WorkActStatus
extension WorkActStatusExtension on WorkActStatus {
  String get statusText {
    switch (this) {
      case WorkActStatus.draft:
        return 'Черновик';
      case WorkActStatus.pending:
        return 'Ожидает подтверждения';
      case WorkActStatus.completed:
        return 'Подтвержден';
      case WorkActStatus.rejected:
        return 'Отклонен';
    }
  }

  String get statusDescription {
    switch (this) {
      case WorkActStatus.draft:
        return 'Акт создан, но еще не готов к подписанию';
      case WorkActStatus.pending:
        return 'Акт ожидает подписания сторонами';
      case WorkActStatus.completed:
        return 'Акт подписан и подтвержден обеими сторонами';
      case WorkActStatus.rejected:
        return 'Акт отклонен одной из сторон';
    }
  }
}
