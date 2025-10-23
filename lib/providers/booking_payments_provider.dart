import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingPayment {
  final String id;
  final String bookingId;
  final String status; // 'pending','paid','failed','refunded'
  final double amount;
  final DateTime updatedAt;
  final String? paymentMethod;
  final String? transactionId;

  BookingPayment({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.amount,
    required this.updatedAt,
    this.paymentMethod,
    this.transactionId,
  });

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      paymentMethod: json['paymentMethod'] as String?,
      transactionId: json['transactionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'status': status,
      'amount': amount,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    };
  }
}

/// Провайдер для получения данных о платеже по ID бронирования
final bookingPaymentsProvider =
    FutureProvider.family<BookingPayment?, String>((ref, bookingId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('payments')
        .doc(bookingId)
        .get();

    if (doc.exists && doc.data() != null) {
      return BookingPayment.fromJson(doc.data()!);
    }

    return null;
  } catch (e) {
    // В случае ошибки возвращаем null
    return null;
  }
});

/// Провайдер для получения всех платежей пользователя
final userPaymentsProvider =
    FutureProvider.family<List<BookingPayment>, String>((ref, userId) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => BookingPayment.fromJson(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});
