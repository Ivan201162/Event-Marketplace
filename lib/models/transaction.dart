import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  promotion,
  subscription,
  donation,
  boostPost,
  advertisement,
  profileBoost,
  categoryBoost,
  searchBoost,
  premiumUpgrade,
  adCampaign,
}

enum TransactionStatus {
  pending,
  success,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

class Transaction {
  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.timestamp,
    required this.description,
    this.targetUserId,
    this.postId,
    this.subscriptionId,
    this.promotionId,
    this.adId,
    this.paymentMethod,
    this.paymentProvider,
    this.externalTransactionId,
    this.refundAmount,
    this.refundReason,
    this.metadata,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        type: TransactionType.values.firstWhere(
          (e) => e.toString() == 'TransactionType.${map['type']}',
          orElse: () => TransactionType.donation,
        ),
        amount: (map['amount'] ?? 0.0).toDouble(),
        currency: map['currency'] ?? 'RUB',
        status: TransactionStatus.values.firstWhere(
          (e) => e.toString() == 'TransactionStatus.${map['status']}',
          orElse: () => TransactionStatus.pending,
        ),
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        description: map['description'] ?? '',
        targetUserId: map['targetUserId'],
        postId: map['postId'],
        subscriptionId: map['subscriptionId'],
        promotionId: map['promotionId'],
        adId: map['adId'],
        paymentMethod: map['paymentMethod'],
        paymentProvider: map['paymentProvider'],
        externalTransactionId: map['externalTransactionId'],
        refundAmount: map['refundAmount']?.toDouble(),
        refundReason: map['refundReason'],
        metadata: map['metadata'],
      );
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final DateTime timestamp;
  final String description;
  final String? targetUserId; // For donations
  final String? postId; // For post boosting
  final String? subscriptionId; // For subscription payments
  final String? promotionId; // For promotion payments
  final String? adId; // For advertisement payments
  final String? paymentMethod; // card, apple_pay, google_pay, etc.
  final String? paymentProvider; // stripe, yookassa, etc.
  final String? externalTransactionId; // External payment system ID
  final double? refundAmount;
  final String? refundReason;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.toString().split('.').last,
        'amount': amount,
        'currency': currency,
        'status': status.toString().split('.').last,
        'timestamp': Timestamp.fromDate(timestamp),
        'description': description,
        'targetUserId': targetUserId,
        'postId': postId,
        'subscriptionId': subscriptionId,
        'promotionId': promotionId,
        'adId': adId,
        'paymentMethod': paymentMethod,
        'paymentProvider': paymentProvider,
        'externalTransactionId': externalTransactionId,
        'refundAmount': refundAmount,
        'refundReason': refundReason,
        'metadata': metadata,
      };

  Transaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? currency,
    TransactionStatus? status,
    DateTime? timestamp,
    String? description,
    String? targetUserId,
    String? postId,
    String? subscriptionId,
    String? promotionId,
    String? adId,
    String? paymentMethod,
    String? paymentProvider,
    String? externalTransactionId,
    double? refundAmount,
    String? refundReason,
    Map<String, dynamic>? metadata,
  }) =>
      Transaction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        timestamp: timestamp ?? this.timestamp,
        description: description ?? this.description,
        targetUserId: targetUserId ?? this.targetUserId,
        postId: postId ?? this.postId,
        subscriptionId: subscriptionId ?? this.subscriptionId,
        promotionId: promotionId ?? this.promotionId,
        adId: adId ?? this.adId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentProvider: paymentProvider ?? this.paymentProvider,
        externalTransactionId: externalTransactionId ?? this.externalTransactionId,
        refundAmount: refundAmount ?? this.refundAmount,
        refundReason: refundReason ?? this.refundReason,
        metadata: metadata ?? this.metadata,
      );
}


