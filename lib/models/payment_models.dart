enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

enum PaymentType {
  booking,
  subscription,
  promotion,
  advertisement,
  donation,
}

enum PaymentMethod {
  card,
  sbp,
  yookassa,
  tinkoff,
  cash,
  bankTransfer,
  applePay,
  googlePay,
}

class Payment {
  final String id;
  final String userId;
  final double amount;
  final PaymentStatus status;
  final PaymentType type;
  final PaymentMethod method;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final Map<String, dynamic>? metadata;

  const Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.type,
    required this.method,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.metadata,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status']?.toString(),
        orElse: () => PaymentStatus.pending,
      ),
      type: PaymentType.values.firstWhere(
        (e) => e.name == map['type']?.toString(),
        orElse: () => PaymentType.booking,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method']?.toString(),
        orElse: () => PaymentMethod.card,
      ),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: map['completedAt'] != null 
          ? DateTime.tryParse(map['completedAt']?.toString() ?? '') 
          : null,
      transactionId: map['transactionId']?.toString(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'status': status.name,
      'type': type.name,
      'method': method.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'transactionId': transactionId,
      'metadata': metadata,
    };
  }
}
