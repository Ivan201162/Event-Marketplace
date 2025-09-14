import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String specialistId;
  final DateTime eventDate;
  final DateTime? endDate; // Время окончания события
  String status; // pending, confirmed, rejected
  final double prepayment;
  final double totalPrice;
  final DateTime createdAt;
  bool prepaymentPaid;
  String paymentStatus; // pending, paid, failed
  
  // Дополнительные поля для отображения
  final String? title;
  final String? description;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  Booking({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.eventDate,
    this.endDate,
    required this.status,
    required this.prepayment,
    required this.totalPrice,
    DateTime? createdAt,
    this.prepaymentPaid = false,
    this.paymentStatus = 'pending',
    this.title,
    this.description,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'specialistId': specialistId,
      'eventDate': Timestamp.fromDate(eventDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'prepayment': prepayment,
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'prepaymentPaid': prepaymentPaid,
      'paymentStatus': paymentStatus,
      'title': title,
      'description': description,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
    };
  }

  // Создать из документа Firestore
  factory Booking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending',
      prepayment: (data['prepayment'] is num) ? (data['prepayment'] as num).toDouble() : 0.0,
      totalPrice: (data['totalPrice'] is num) ? (data['totalPrice'] as num).toDouble() : 0.0,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      prepaymentPaid: data['prepaymentPaid'] ?? false,
      paymentStatus: data['paymentStatus'] ?? 'pending',
      title: data['title'],
      description: data['description'],
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      customerEmail: data['customerEmail'],
    );
  }
}
