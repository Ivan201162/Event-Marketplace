import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnershipStatus { pending, active, suspended, terminated }

enum PartnershipType { affiliate, reseller, influencer, corporate, media }

enum CommissionType { percentage, fixed, tiered }

enum PaymentStatus { pending, processed, paid, failed, cancelled }

class Partner {
  Partner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    required this.status,
    required this.commissionRate,
    required this.commissionType,
    required this.partnerCode,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.website,
    this.socialMedia,
    this.contactPerson,
    this.companyName,
    this.inn,
    this.bankDetails,
    this.paymentMethod,
    this.minimumPayout = 0.0,
    this.paymentSchedule,
    this.contractNumber,
    this.contractDate,
    this.notes,
    this.metadata,
  });

  factory Partner.fromMap(Map<String, dynamic> map) => Partner(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    type: PartnershipType.values.firstWhere(
      (e) => e.toString() == 'PartnershipType.${map['type']}',
      orElse: () => PartnershipType.affiliate,
    ),
    status: PartnershipStatus.values.firstWhere(
      (e) => e.toString() == 'PartnershipStatus.${map['status']}',
      orElse: () => PartnershipStatus.pending,
    ),
    commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
    commissionType: CommissionType.values.firstWhere(
      (e) => e.toString() == 'CommissionType.${map['commissionType']}',
      orElse: () => CommissionType.percentage,
    ),
    partnerCode: map['partnerCode'] ?? '',
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    description: map['description'],
    website: map['website'],
    socialMedia: Map<String, dynamic>.from(map['socialMedia'] ?? {}),
    contactPerson: map['contactPerson'],
    companyName: map['companyName'],
    inn: map['inn'],
    bankDetails: Map<String, dynamic>.from(map['bankDetails'] ?? {}),
    paymentMethod: map['paymentMethod'],
    minimumPayout: (map['minimumPayout'] ?? 1000.0).toDouble(),
    paymentSchedule: map['paymentSchedule'],
    contractNumber: map['contractNumber'],
    contractDate: map['contractDate'] != null ? (map['contractDate'] as Timestamp).toDate() : null,
    notes: map['notes'],
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String name;
  final String email;
  final String phone;
  final PartnershipType type;
  final PartnershipStatus status;
  final double commissionRate;
  final CommissionType commissionType;
  final String partnerCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? website;
  final Map<String, dynamic>? socialMedia;
  final String? contactPerson;
  final String? companyName;
  final String? inn;
  final Map<String, dynamic>? bankDetails;
  final String? paymentMethod;
  final double minimumPayout;
  final String? paymentSchedule;
  final String? contractNumber;
  final DateTime? contractDate;
  final String? notes;
  final Map<String, dynamic>? metadata;

  bool get isActive => status == PartnershipStatus.active;
  bool get isPending => status == PartnershipStatus.pending;
  bool get isSuspended => status == PartnershipStatus.suspended;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'commissionRate': commissionRate,
    'commissionType': commissionType.toString().split('.').last,
    'partnerCode': partnerCode,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'description': description,
    'website': website,
    'socialMedia': socialMedia,
    'contactPerson': contactPerson,
    'companyName': companyName,
    'inn': inn,
    'bankDetails': bankDetails,
    'paymentMethod': paymentMethod,
    'minimumPayout': minimumPayout,
    'paymentSchedule': paymentSchedule,
    'contractNumber': contractNumber,
    'contractDate': contractDate != null ? Timestamp.fromDate(contractDate!) : null,
    'notes': notes,
    'metadata': metadata,
  };

  Partner copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    PartnershipType? type,
    PartnershipStatus? status,
    double? commissionRate,
    CommissionType? commissionType,
    String? partnerCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? website,
    Map<String, dynamic>? socialMedia,
    String? contactPerson,
    String? companyName,
    String? inn,
    Map<String, dynamic>? bankDetails,
    String? paymentMethod,
    double? minimumPayout,
    String? paymentSchedule,
    String? contractNumber,
    DateTime? contractDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) => Partner(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    type: type ?? this.type,
    status: status ?? this.status,
    commissionRate: commissionRate ?? this.commissionRate,
    commissionType: commissionType ?? this.commissionType,
    partnerCode: partnerCode ?? this.partnerCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    description: description ?? this.description,
    website: website ?? this.website,
    socialMedia: socialMedia ?? this.socialMedia,
    contactPerson: contactPerson ?? this.contactPerson,
    companyName: companyName ?? this.companyName,
    inn: inn ?? this.inn,
    bankDetails: bankDetails ?? this.bankDetails,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    minimumPayout: minimumPayout ?? this.minimumPayout,
    paymentSchedule: paymentSchedule ?? this.paymentSchedule,
    contractNumber: contractNumber ?? this.contractNumber,
    contractDate: contractDate ?? this.contractDate,
    notes: notes ?? this.notes,
    metadata: metadata ?? this.metadata,
  );
}

class PartnerTransaction {
  PartnerTransaction({
    required this.id,
    required this.partnerId,
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.commissionAmount,
    required this.commissionRate,
    required this.commissionType,
    required this.createdAt,
    this.status = PaymentStatus.pending,
    this.paymentId,
    this.paidAt,
    this.description,
    this.metadata,
  });

  factory PartnerTransaction.fromMap(Map<String, dynamic> map) => PartnerTransaction(
    id: map['id'] ?? '',
    partnerId: map['partnerId'] ?? '',
    transactionId: map['transactionId'] ?? '',
    userId: map['userId'] ?? '',
    amount: (map['amount'] ?? 0.0).toDouble(),
    currency: map['currency'] ?? 'RUB',
    commissionAmount: (map['commissionAmount'] ?? 0.0).toDouble(),
    commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
    commissionType: CommissionType.values.firstWhere(
      (e) => e.toString() == 'CommissionType.${map['commissionType']}',
      orElse: () => CommissionType.percentage,
    ),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    status: PaymentStatus.values.firstWhere(
      (e) => e.toString() == 'PaymentStatus.${map['status']}',
      orElse: () => PaymentStatus.pending,
    ),
    paymentId: map['paymentId'],
    paidAt: map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
    description: map['description'],
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String partnerId;
  final String transactionId;
  final String userId;
  final double amount;
  final String currency;
  final double commissionAmount;
  final double commissionRate;
  final CommissionType commissionType;
  final DateTime createdAt;
  final PaymentStatus status;
  final String? paymentId;
  final DateTime? paidAt;
  final String? description;
  final Map<String, dynamic>? metadata;

  bool get isPaid => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
  bool get isProcessed => status == PaymentStatus.processed;

  Map<String, dynamic> toMap() => {
    'id': id,
    'partnerId': partnerId,
    'transactionId': transactionId,
    'userId': userId,
    'amount': amount,
    'currency': currency,
    'commissionAmount': commissionAmount,
    'commissionRate': commissionRate,
    'commissionType': commissionType.toString().split('.').last,
    'createdAt': Timestamp.fromDate(createdAt),
    'status': status.toString().split('.').last,
    'paymentId': paymentId,
    'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    'description': description,
    'metadata': metadata,
  };
}

class PartnerStats {
  PartnerStats({
    required this.partnerId,
    required this.period,
    required this.totalReferrals,
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalCommissions,
    required this.paidCommissions,
    required this.pendingCommissions,
    required this.conversionRate,
    required this.averageOrderValue,
    required this.updatedAt,
    this.metadata,
  });

  factory PartnerStats.fromMap(Map<String, dynamic> map) => PartnerStats(
    partnerId: map['partnerId'] ?? '',
    period: map['period'] ?? '',
    totalReferrals: map['totalReferrals'] ?? 0,
    totalTransactions: map['totalTransactions'] ?? 0,
    totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
    totalCommissions: (map['totalCommissions'] ?? 0.0).toDouble(),
    paidCommissions: (map['paidCommissions'] ?? 0.0).toDouble(),
    pendingCommissions: (map['pendingCommissions'] ?? 0.0).toDouble(),
    conversionRate: (map['conversionRate'] ?? 0.0).toDouble(),
    averageOrderValue: (map['averageOrderValue'] ?? 0.0).toDouble(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String partnerId;
  final String period;
  final int totalReferrals;
  final int totalTransactions;
  final double totalRevenue;
  final double totalCommissions;
  final double paidCommissions;
  final double pendingCommissions;
  final double conversionRate;
  final double averageOrderValue;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  double get unpaidCommissions => totalCommissions - paidCommissions;
  double get commissionRate => totalRevenue > 0 ? (totalCommissions / totalRevenue) * 100 : 0.0;

  Map<String, dynamic> toMap() => {
    'partnerId': partnerId,
    'period': period,
    'totalReferrals': totalReferrals,
    'totalTransactions': totalTransactions,
    'totalRevenue': totalRevenue,
    'totalCommissions': totalCommissions,
    'paidCommissions': paidCommissions,
    'pendingCommissions': pendingCommissions,
    'conversionRate': conversionRate,
    'averageOrderValue': averageOrderValue,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'metadata': metadata,
  };
}

class PartnerPayment {
  PartnerPayment({
    required this.id,
    required this.partnerId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMethod,
    this.paymentDetails,
    this.transactionIds = const [],
    this.processedAt,
    this.paidAt,
    this.failedReason,
    this.receiptUrl,
    this.metadata,
  });

  factory PartnerPayment.fromMap(Map<String, dynamic> map) => PartnerPayment(
    id: map['id'] ?? '',
    partnerId: map['partnerId'] ?? '',
    amount: (map['amount'] ?? 0.0).toDouble(),
    currency: map['currency'] ?? 'RUB',
    status: PaymentStatus.values.firstWhere(
      (e) => e.toString() == 'PaymentStatus.${map['status']}',
      orElse: () => PaymentStatus.pending,
    ),
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    paymentMethod: map['paymentMethod'],
    paymentDetails: Map<String, dynamic>.from(map['paymentDetails'] ?? {}),
    transactionIds: List<String>.from(map['transactionIds'] ?? []),
    processedAt: map['processedAt'] != null ? (map['processedAt'] as Timestamp).toDate() : null,
    paidAt: map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
    failedReason: map['failedReason'],
    receiptUrl: map['receiptUrl'],
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  final String id;
  final String partnerId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentMethod;
  final Map<String, dynamic>? paymentDetails;
  final List<String> transactionIds;
  final DateTime? processedAt;
  final DateTime? paidAt;
  final String? failedReason;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;

  bool get isPaid => status == PaymentStatus.paid;
  bool get isPending => status == PaymentStatus.pending;
  bool get isProcessed => status == PaymentStatus.processed;
  bool get isFailed => status == PaymentStatus.failed;

  Map<String, dynamic> toMap() => {
    'id': id,
    'partnerId': partnerId,
    'amount': amount,
    'currency': currency,
    'status': status.toString().split('.').last,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'paymentMethod': paymentMethod,
    'paymentDetails': paymentDetails,
    'transactionIds': transactionIds,
    'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    'failedReason': failedReason,
    'receiptUrl': receiptUrl,
    'metadata': metadata,
  };
}
