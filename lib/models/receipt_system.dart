import 'package:cloud_firestore/cloud_firestore.dart';

enum ReceiptStatus { pending, generated, sent, failed, cancelled }

enum ReceiptType { payment, refund, subscription, promotion, advertisement }

enum PaymentProvider { yookassa, cloudpayments, tinkoff, stripe, sberbank }

class Receipt {
  Receipt({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.createdAt,
    this.paymentProvider,
    this.receiptUrl,
    this.receiptData,
    this.email,
    this.phone,
    this.fiscalData,
    this.qrCode,
    this.sentAt,
    this.failedReason,
    this.metadata,
  });

  factory Receipt.fromMap(Map<String, dynamic> map) => Receipt(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    transactionId: map['transactionId'] ?? '',
    amount: (map['amount'] ?? 0.0).toDouble(),
    currency: map['currency'] ?? 'RUB',
    type: ReceiptType.values.firstWhere(
      (e) => e.toString() == 'ReceiptType.${map['type']}',
      orElse: () => ReceiptType.payment,
    ),
    status: ReceiptStatus.values.firstWhere(
      (e) => e.toString() == 'ReceiptStatus.${map['status']}',
      orElse: () => ReceiptStatus.pending,
    ),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    paymentProvider: map['paymentProvider'] != null
        ? PaymentProvider.values.firstWhere(
            (e) => e.toString() == 'PaymentProvider.${map['paymentProvider']}',
            orElse: () => PaymentProvider.yookassa,
          )
        : null,
    receiptUrl: map['receiptUrl'],
    receiptData: Map<String, dynamic>.from(map['receiptData'] ?? {}),
    email: map['email'],
    phone: map['phone'],
    fiscalData: Map<String, dynamic>.from(map['fiscalData'] ?? {}),
    qrCode: map['qrCode'],
    sentAt: map['sentAt'] != null ? (map['sentAt'] as Timestamp).toDate() : null,
    failedReason: map['failedReason'],
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String userId;
  final String transactionId;
  final double amount;
  final String currency;
  final ReceiptType type;
  final ReceiptStatus status;
  final DateTime createdAt;
  final PaymentProvider? paymentProvider;
  final String? receiptUrl;
  final Map<String, dynamic>? receiptData;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? fiscalData;
  final String? qrCode;
  final DateTime? sentAt;
  final String? failedReason;
  final Map<String, dynamic>? metadata;

  bool get isGenerated => status == ReceiptStatus.generated;
  bool get isSent => status == ReceiptStatus.sent;
  bool get isFailed => status == ReceiptStatus.failed;
  bool get isPending => status == ReceiptStatus.pending;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'transactionId': transactionId,
    'amount': amount,
    'currency': currency,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'createdAt': Timestamp.fromDate(createdAt),
    'paymentProvider': paymentProvider?.toString().split('.').last,
    'receiptUrl': receiptUrl,
    'receiptData': receiptData,
    'email': email,
    'phone': phone,
    'fiscalData': fiscalData,
    'qrCode': qrCode,
    'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    'failedReason': failedReason,
    'metadata': metadata,
  };

  Receipt copyWith({
    String? id,
    String? userId,
    String? transactionId,
    double? amount,
    String? currency,
    ReceiptType? type,
    ReceiptStatus? status,
    DateTime? createdAt,
    PaymentProvider? paymentProvider,
    String? receiptUrl,
    Map<String, dynamic>? receiptData,
    String? email,
    String? phone,
    Map<String, dynamic>? fiscalData,
    String? qrCode,
    DateTime? sentAt,
    String? failedReason,
    Map<String, dynamic>? metadata,
  }) => Receipt(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    transactionId: transactionId ?? this.transactionId,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    type: type ?? this.type,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    paymentProvider: paymentProvider ?? this.paymentProvider,
    receiptUrl: receiptUrl ?? this.receiptUrl,
    receiptData: receiptData ?? this.receiptData,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    fiscalData: fiscalData ?? this.fiscalData,
    qrCode: qrCode ?? this.qrCode,
    sentAt: sentAt ?? this.sentAt,
    failedReason: failedReason ?? this.failedReason,
    metadata: metadata ?? this.metadata,
  );
}

class FiscalReceipt {
  FiscalReceipt({
    required this.id,
    required this.receiptId,
    required this.fiscalDocumentNumber,
    required this.fiscalSign,
    required this.fiscalDriveNumber,
    required this.fiscalDocumentId,
    required this.fiscalTimestamp,
    required this.operator,
    required this.inn,
    required this.kktRegNumber,
    required this.createdAt,
    this.fiscalData,
    this.qrCode,
    this.ofdUrl,
  });

  factory FiscalReceipt.fromMap(Map<String, dynamic> map) => FiscalReceipt(
    id: map['id'] ?? '',
    receiptId: map['receiptId'] ?? '',
    fiscalDocumentNumber: map['fiscalDocumentNumber'] ?? '',
    fiscalSign: map['fiscalSign'] ?? '',
    fiscalDriveNumber: map['fiscalDriveNumber'] ?? '',
    fiscalDocumentId: map['fiscalDocumentId'] ?? '',
    fiscalTimestamp: (map['fiscalTimestamp'] as Timestamp).toDate(),
    operator: map['operator'] ?? '',
    inn: map['inn'] ?? '',
    kktRegNumber: map['kktRegNumber'] ?? '',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    fiscalData: Map<String, dynamic>.from(map['fiscalData'] ?? {}),
    qrCode: map['qrCode'],
    ofdUrl: map['ofdUrl'],
  );

  final String id;
  final String receiptId;
  final String fiscalDocumentNumber;
  final String fiscalSign;
  final String fiscalDriveNumber;
  final String fiscalDocumentId;
  final DateTime fiscalTimestamp;
  final String operator;
  final String inn;
  final String kktRegNumber;
  final DateTime createdAt;
  final Map<String, dynamic>? fiscalData;
  final String? qrCode;
  final String? ofdUrl;

  Map<String, dynamic> toMap() => {
    'id': id,
    'receiptId': receiptId,
    'fiscalDocumentNumber': fiscalDocumentNumber,
    'fiscalSign': fiscalSign,
    'fiscalDriveNumber': fiscalDriveNumber,
    'fiscalDocumentId': fiscalDocumentId,
    'fiscalTimestamp': Timestamp.fromDate(fiscalTimestamp),
    'operator': operator,
    'inn': inn,
    'kktRegNumber': kktRegNumber,
    'createdAt': Timestamp.fromDate(createdAt),
    'fiscalData': fiscalData,
    'qrCode': qrCode,
    'ofdUrl': ofdUrl,
  };
}

class ReceiptTemplate {
  ReceiptTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.template,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.variables,
    this.metadata,
  });

  factory ReceiptTemplate.fromMap(Map<String, dynamic> map) => ReceiptTemplate(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    type: ReceiptType.values.firstWhere(
      (e) => e.toString() == 'ReceiptType.${map['type']}',
      orElse: () => ReceiptType.payment,
    ),
    template: map['template'] ?? '',
    isActive: map['isActive'] ?? true,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    description: map['description'],
    variables: List<String>.from(map['variables'] ?? []),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String name;
  final ReceiptType type;
  final String template;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final List<String>? variables;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'template': template,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'description': description,
    'variables': variables,
    'metadata': metadata,
  };
}

class ReceiptSettings {
  ReceiptSettings({
    required this.id,
    required this.userId,
    required this.autoGenerate,
    required this.sendByEmail,
    required this.sendBySms,
    required this.email,
    required this.phone,
    required this.updatedAt,
    this.templateId,
    this.customFields,
  });

  factory ReceiptSettings.fromMap(Map<String, dynamic> map) => ReceiptSettings(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    autoGenerate: map['autoGenerate'] ?? true,
    sendByEmail: map['sendByEmail'] ?? true,
    sendBySms: map['sendBySms'] ?? false,
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    templateId: map['templateId'],
    customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
  );

  final String id;
  final String userId;
  final bool autoGenerate;
  final bool sendByEmail;
  final bool sendBySms;
  final String email;
  final String phone;
  final DateTime updatedAt;
  final String? templateId;
  final Map<String, dynamic>? customFields;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'autoGenerate': autoGenerate,
    'sendByEmail': sendByEmail,
    'sendBySms': sendBySms,
    'email': email,
    'phone': phone,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'templateId': templateId,
    'customFields': customFields,
  };
}
