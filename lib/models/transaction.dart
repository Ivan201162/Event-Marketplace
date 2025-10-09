import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  promotion,
  subscription,
  donation,
  boostPost,
}

enum TransactionStatus {
  pending,
  success,
  failed,
  cancelled,
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
        metadata: metadata ?? this.metadata,
      );
}
