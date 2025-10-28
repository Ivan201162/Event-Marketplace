import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Transaction type enum
enum TransactionType {
  income('Доход'),
  expense('Расход'),
  transfer('Перевод'),
  refund('Возврат'),
  commission('Комиссия'),
  bonus('Бонус');

  const TransactionType(this.displayName);
  final String displayName;
}

/// Transaction model
class Transaction extends Equatable {

  const Transaction({
    required this.id,
    required this.userId,
    required this.type, required this.amount, required this.currency, required this.description, required this.createdAt, required this.updatedAt, this.specialistId,
    this.paymentId,
    this.bookingId,
    this.category,
    this.metadata,
    this.referenceId,
    this.notes,
  });

  /// Create Transaction from Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Transaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      specialistId: data['specialistId'],
      paymentId: data['paymentId'],
      bookingId: data['bookingId'],
      type: TransactionType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => TransactionType.income,
      ),
      amount: data['amount'] ?? 0,
      currency: data['currency'] ?? 'RUB',
      description: data['description'] ?? '',
      category: data['category'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      referenceId: data['referenceId'],
      notes: data['notes'],
    );
  }
  final String id;
  final String userId;
  final String? specialistId;
  final String? paymentId;
  final String? bookingId;
  final TransactionType type;
  final int amount; // in kopecks
  final String currency;
  final String description;
  final String? category;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? referenceId; // External reference ID
  final String? notes;

  /// Convert Transaction to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'specialistId': specialistId,
      'paymentId': paymentId,
      'bookingId': bookingId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'description': description,
      'category': category,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'referenceId': referenceId,
      'notes': notes,
    };
  }

  /// Create a copy of Transaction with updated fields
  Transaction copyWith({
    String? id,
    String? userId,
    String? specialistId,
    String? paymentId,
    String? bookingId,
    TransactionType? type,
    int? amount,
    String? currency,
    String? description,
    String? category,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? referenceId,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialistId: specialistId ?? this.specialistId,
      paymentId: paymentId ?? this.paymentId,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      category: category ?? this.category,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      referenceId: referenceId ?? this.referenceId,
      notes: notes ?? this.notes,
    );
  }

  /// Get formatted amount string
  String get formattedAmount {
    final rubles = amount / 100;
    final sign = type == TransactionType.income ? '+' : '-';
    return '$sign${rubles.toStringAsFixed(2)} ₽';
  }

  /// Get absolute amount string
  String get formattedAbsoluteAmount {
    final rubles = amount / 100;
    return '${rubles.toStringAsFixed(2)} ₽';
  }

  /// Get type color
  String get typeColor {
    switch (type) {
      case TransactionType.income:
        return 'green';
      case TransactionType.expense:
        return 'red';
      case TransactionType.transfer:
        return 'blue';
      case TransactionType.refund:
        return 'purple';
      case TransactionType.commission:
        return 'orange';
      case TransactionType.bonus:
        return 'yellow';
    }
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case TransactionType.income:
        return '💰';
      case TransactionType.expense:
        return '💸';
      case TransactionType.transfer:
        return '🔄';
      case TransactionType.refund:
        return '↩️';
      case TransactionType.commission:
        return '📊';
      case TransactionType.bonus:
        return '🎁';
    }
  }

  /// Check if transaction is income
  bool get isIncome => type == TransactionType.income;

  /// Check if transaction is expense
  bool get isExpense => type == TransactionType.expense;

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    }
  }

  /// Get formatted time
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date and time
  String get formattedDateTime {
    return '$formattedDate в $formattedTime';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        specialistId,
        paymentId,
        bookingId,
        type,
        amount,
        currency,
        description,
        category,
        metadata,
        createdAt,
        updatedAt,
        referenceId,
        notes,
      ];
}
