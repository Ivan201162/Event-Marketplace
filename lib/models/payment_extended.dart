import 'package:cloud_firestore/cloud_firestore.dart';

/// Расширенная модель платежа с поддержкой предоплаты и PDF квитанций
class PaymentExtended {
  const PaymentExtended({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.type,
    this.installments = const [],
    this.receiptPdfUrl,
    this.invoicePdfUrl,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory PaymentExtended.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentExtended(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0.0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0.0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      type: PaymentType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => PaymentType.full,
      ),
      installments: (data['installments'] as List<dynamic>?)
              ?.map((e) => PaymentInstallment.fromMap(e))
              .toList() ??
          [],
      receiptPdfUrl: data['receiptPdfUrl'],
      invoicePdfUrl: data['invoicePdfUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final PaymentStatus status;
  final PaymentType type;
  final List<PaymentInstallment> installments;
  final String? receiptPdfUrl;
  final String? invoicePdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookingId': bookingId,
        'customerId': customerId,
        'specialistId': specialistId,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'status': status.name,
        'type': type.name,
        'installments': installments.map((e) => e.toMap()).toList(),
        'receiptPdfUrl': receiptPdfUrl,
        'invoicePdfUrl': invoicePdfUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
      };

  PaymentExtended copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    PaymentStatus? status,
    PaymentType? type,
    List<PaymentInstallment>? installments,
    String? receiptPdfUrl,
    String? invoicePdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      PaymentExtended(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        remainingAmount: remainingAmount ?? this.remainingAmount,
        status: status ?? this.status,
        type: type ?? this.type,
        installments: installments ?? this.installments,
        receiptPdfUrl: receiptPdfUrl ?? this.receiptPdfUrl,
        invoicePdfUrl: invoicePdfUrl ?? this.invoicePdfUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, полностью ли оплачен платеж
  bool get isFullyPaid => remainingAmount <= 0;

  /// Проверить, есть ли просроченные платежи
  bool get hasOverduePayments {
    final now = DateTime.now();
    return installments.any(
      (installment) =>
          installment.dueDate.isBefore(now) &&
          installment.status != PaymentStatus.completed,
    );
  }

  /// Получить следующий платеж к оплате
  PaymentInstallment? get nextPayment {
    final now = DateTime.now();
    final pendingInstallments = installments
        .where(
          (installment) =>
              installment.dueDate.isAfter(now) &&
              installment.status == PaymentStatus.pending,
        )
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return pendingInstallments.isNotEmpty ? pendingInstallments.first : null;
  }

  /// Получить процент оплаты
  double get paymentProgress =>
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
}

/// Статус платежа
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

/// Тип платежа
enum PaymentType {
  full, // Полная оплата
  partial, // Частичная оплата
  installment, // Рассрочка
  advance, // Предоплата
}

/// Платеж в рассрочку
class PaymentInstallment {
  const PaymentInstallment({
    required this.id,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.transactionId,
    this.receiptPdfUrl,
    this.metadata = const {},
  });

  factory PaymentInstallment.fromMap(Map<String, dynamic> map) =>
      PaymentInstallment(
        id: map['id'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
        dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: PaymentStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => PaymentStatus.pending,
        ),
        paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
        transactionId: map['transactionId'],
        receiptPdfUrl: map['receiptPdfUrl'],
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );
  final String id;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;
  final DateTime? paidAt;
  final String? transactionId;
  final String? receiptPdfUrl;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': status.name,
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
        'transactionId': transactionId,
        'receiptPdfUrl': receiptPdfUrl,
        'metadata': metadata,
      };

  PaymentInstallment copyWith({
    String? id,
    double? amount,
    DateTime? dueDate,
    PaymentStatus? status,
    DateTime? paidAt,
    String? transactionId,
    String? receiptPdfUrl,
    Map<String, dynamic>? metadata,
  }) =>
      PaymentInstallment(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        paidAt: paidAt ?? this.paidAt,
        transactionId: transactionId ?? this.transactionId,
        receiptPdfUrl: receiptPdfUrl ?? this.receiptPdfUrl,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, просрочен ли платеж
  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != PaymentStatus.completed;
}

/// Настройки предоплаты
class AdvancePaymentSettings {
  const AdvancePaymentSettings({
    this.availablePercentages = const [10.0, 30.0, 50.0],
    this.minAdvanceAmount = 1000.0,
    this.maxAdvanceAmount = 100000.0,
    this.allowCustomAmount = true,
    this.maxInstallments = 12,
    this.defaultInstallments = 3,
  });

  factory AdvancePaymentSettings.fromMap(Map<String, dynamic> map) =>
      AdvancePaymentSettings(
        availablePercentages: List<double>.from(
            map['availablePercentages'] ?? [10.0, 30.0, 50.0]),
        minAdvanceAmount: (map['minAdvanceAmount'] ?? 1000.0).toDouble(),
        maxAdvanceAmount: (map['maxAdvanceAmount'] ?? 100000.0).toDouble(),
        allowCustomAmount: map['allowCustomAmount'] ?? true,
        maxInstallments: map['maxInstallments'] ?? 12,
        defaultInstallments: map['defaultInstallments'] ?? 3,
      );
  final List<double> availablePercentages;
  final double minAdvanceAmount;
  final double maxAdvanceAmount;
  final bool allowCustomAmount;
  final int maxInstallments;
  final int defaultInstallments;

  Map<String, dynamic> toMap() => {
        'availablePercentages': availablePercentages,
        'minAdvanceAmount': minAdvanceAmount,
        'maxAdvanceAmount': maxAdvanceAmount,
        'allowCustomAmount': allowCustomAmount,
        'maxInstallments': maxInstallments,
        'defaultInstallments': defaultInstallments,
      };
}

/// PDF документ
class PaymentDocument {
  const PaymentDocument({
    required this.id,
    required this.paymentId,
    required this.type,
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    this.metadata = const {},
  });

  factory PaymentDocument.fromMap(Map<String, dynamic> map) => PaymentDocument(
        id: map['id'] ?? '',
        paymentId: map['paymentId'] ?? '',
        type: DocumentType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => DocumentType.receipt,
        ),
        url: map['url'] ?? '',
        fileName: map['fileName'] ?? '',
        fileSize: map['fileSize'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );
  final String id;
  final String paymentId;
  final DocumentType type;
  final String url;
  final String fileName;
  final int fileSize;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'paymentId': paymentId,
        'type': type.name,
        'url': url,
        'fileName': fileName,
        'fileSize': fileSize,
        'createdAt': Timestamp.fromDate(createdAt),
        'metadata': metadata,
      };
}

/// Тип документа
enum DocumentType {
  receipt, // Квитанция
  invoice, // Счёт
  contract, // Договор
  report, // Отчёт
}

/// Статистика платежей
class PaymentStats {
  const PaymentStats({
    required this.totalPayments,
    required this.completedPayments,
    required this.pendingPayments,
    required this.failedPayments,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paymentsByType,
    required this.paymentsByStatus,
    required this.lastUpdated,
  });

  factory PaymentStats.empty() => PaymentStats(
        totalPayments: 0,
        completedPayments: 0,
        pendingPayments: 0,
        failedPayments: 0,
        totalAmount: 0,
        paidAmount: 0,
        pendingAmount: 0,
        paymentsByType: {},
        paymentsByStatus: {},
        lastUpdated: DateTime.now(),
      );
  final int totalPayments;
  final int completedPayments;
  final int pendingPayments;
  final int failedPayments;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final Map<String, int> paymentsByType;
  final Map<String, int> paymentsByStatus;
  final DateTime lastUpdated;

  /// Получить процент успешных платежей
  double get successRate =>
      totalPayments > 0 ? (completedPayments / totalPayments) * 100 : 0;

  /// Получить процент оплаты
  double get paymentRate =>
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
}
