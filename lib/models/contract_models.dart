import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус контракта
enum ContractStatus {
  draft, // Черновик
  pending, // Ожидает подписания
  signed, // Подписан
  completed, // Завершён
  cancelled, // Отменён
}

/// Тип документа
enum DocumentType {
  contract, // Договор
  act, // Акт выполненных работ
  invoice, // Счёт
  receipt, // Квитанция
}

/// Модель контракта
class Contract {
  const Contract({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.status,
    required this.createdAt,
    this.signedByCustomer,
    this.signedBySpecialist,
    this.customerSignature,
    this.specialistSignature,
    this.contractUrl,
    this.actUrl,
    this.invoiceUrl,
    this.receiptUrl,
    this.terms,
    this.amount,
    this.prepaymentAmount,
    this.finalAmount,
    this.completedAt,
    this.cancelledAt,
    this.metadata,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final ContractStatus status;
  final DateTime createdAt;
  final DateTime? signedByCustomer;
  final DateTime? signedBySpecialist;
  final String? customerSignature;
  final String? specialistSignature;
  final String? contractUrl;
  final String? actUrl;
  final String? invoiceUrl;
  final String? receiptUrl;
  final String? terms;
  final double? amount;
  final double? prepaymentAmount;
  final double? finalAmount;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final Map<String, dynamic>? metadata;

  /// Создать из Map
  factory Contract.fromMap(Map<String, dynamic> data) {
    return Contract(
      id: data['id'] as String,
      bookingId: data['bookingId'] as String,
      customerId: data['customerId'] as String,
      specialistId: data['specialistId'] as String,
      status: ContractStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ContractStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      signedByCustomer: data['signedByCustomer'] != null
          ? (data['signedByCustomer'] as Timestamp).toDate()
          : null,
      signedBySpecialist: data['signedBySpecialist'] != null
          ? (data['signedBySpecialist'] as Timestamp).toDate()
          : null,
      customerSignature: data['customerSignature'] as String?,
      specialistSignature: data['specialistSignature'] as String?,
      contractUrl: data['contractUrl'] as String?,
      actUrl: data['actUrl'] as String?,
      invoiceUrl: data['invoiceUrl'] as String?,
      receiptUrl: data['receiptUrl'] as String?,
      terms: data['terms'] as String?,
      amount: data['amount'] != null ? (data['amount'] as num).toDouble() : null,
      prepaymentAmount: data['prepaymentAmount'] != null
          ? (data['prepaymentAmount'] as num).toDouble()
          : null,
      finalAmount: data['finalAmount'] != null
          ? (data['finalAmount'] as num).toDouble()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'signedByCustomer': signedByCustomer != null
          ? Timestamp.fromDate(signedByCustomer!)
          : null,
      'signedBySpecialist': signedBySpecialist != null
          ? Timestamp.fromDate(signedBySpecialist!)
          : null,
      'customerSignature': customerSignature,
      'specialistSignature': specialistSignature,
      'contractUrl': contractUrl,
      'actUrl': actUrl,
      'invoiceUrl': invoiceUrl,
      'receiptUrl': receiptUrl,
      'terms': terms,
      'amount': amount,
      'prepaymentAmount': prepaymentAmount,
      'finalAmount': finalAmount,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'metadata': metadata,
    };
  }

  /// Копировать с изменениями
  Contract copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    ContractStatus? status,
    DateTime? createdAt,
    DateTime? signedByCustomer,
    DateTime? signedBySpecialist,
    String? customerSignature,
    String? specialistSignature,
    String? contractUrl,
    String? actUrl,
    String? invoiceUrl,
    String? receiptUrl,
    String? terms,
    double? amount,
    double? prepaymentAmount,
    double? finalAmount,
    DateTime? completedAt,
    DateTime? cancelledAt,
    Map<String, dynamic>? metadata,
  }) {
    return Contract(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      signedByCustomer: signedByCustomer ?? this.signedByCustomer,
      signedBySpecialist: signedBySpecialist ?? this.signedBySpecialist,
      customerSignature: customerSignature ?? this.customerSignature,
      specialistSignature: specialistSignature ?? this.specialistSignature,
      contractUrl: contractUrl ?? this.contractUrl,
      actUrl: actUrl ?? this.actUrl,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      terms: terms ?? this.terms,
      amount: amount ?? this.amount,
      prepaymentAmount: prepaymentAmount ?? this.prepaymentAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Получить отображаемое имя статуса
  String get statusDisplayName {
    switch (status) {
      case ContractStatus.draft:
        return 'Черновик';
      case ContractStatus.pending:
        return 'Ожидает подписания';
      case ContractStatus.signed:
        return 'Подписан';
      case ContractStatus.completed:
        return 'Завершён';
      case ContractStatus.cancelled:
        return 'Отменён';
    }
  }

  /// Проверить, подписан ли контракт
  bool get isSigned => status == ContractStatus.signed;

  /// Проверить, завершён ли контракт
  bool get isCompleted => status == ContractStatus.completed;

  /// Проверить, отменён ли контракт
  bool get isCancelled => status == ContractStatus.cancelled;

  /// Проверить, ожидает ли подписания
  bool get isPending => status == ContractStatus.pending;

  /// Проверить, является ли черновиком
  bool get isDraft => status == ContractStatus.draft;

  /// Проверить, подписан ли клиентом
  bool get isSignedByCustomer => signedByCustomer != null;

  /// Проверить, подписан ли специалистом
  bool get isSignedBySpecialist => signedBySpecialist != null;

  /// Проверить, подписан ли обеими сторонами
  bool get isSignedByBoth => isSignedByCustomer && isSignedBySpecialist;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contract &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Contract{id: $id, bookingId: $bookingId, status: $status}';
  }
}

/// Модель документа
class Document {
  const Document({
    required this.id,
    required this.contractId,
    required this.type,
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    this.downloadedAt,
    this.metadata,
  });

  final String id;
  final String contractId;
  final DocumentType type;
  final String url;
  final String fileName;
  final int fileSize;
  final DateTime createdAt;
  final DateTime? downloadedAt;
  final Map<String, dynamic>? metadata;

  /// Создать из Map
  factory Document.fromMap(Map<String, dynamic> data) {
    return Document(
      id: data['id'] as String,
      contractId: data['contractId'] as String,
      type: DocumentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => DocumentType.contract,
      ),
      url: data['url'] as String,
      fileName: data['fileName'] as String,
      fileSize: data['fileSize'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      downloadedAt: data['downloadedAt'] != null
          ? (data['downloadedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractId': contractId,
      'type': type.name,
      'url': url,
      'fileName': fileName,
      'fileSize': fileSize,
      'createdAt': Timestamp.fromDate(createdAt),
      'downloadedAt': downloadedAt != null
          ? Timestamp.fromDate(downloadedAt!)
          : null,
      'metadata': metadata,
    };
  }

  /// Получить отображаемое имя типа документа
  String get typeDisplayName {
    switch (type) {
      case DocumentType.contract:
        return 'Договор';
      case DocumentType.act:
        return 'Акт выполненных работ';
      case DocumentType.invoice:
        return 'Счёт';
      case DocumentType.receipt:
        return 'Квитанция';
    }
  }

  /// Получить размер файла в читаемом формате
  String get fileSizeDisplay {
    if (fileSize < 1024) {
      return '$fileSize Б';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} КБ';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Document{id: $id, type: $type, fileName: $fileName}';
  }
}
