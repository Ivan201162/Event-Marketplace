import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkActStatus { draft, pending, signed, completed }

class WorkAct {
  final String id;
  final String contractId;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final String customerName;
  final String specialistName;
  final List<WorkActService> services;
  final double totalAmount;
  final String currency;
  final DateTime eventDate;
  final String eventLocation;
  final String description;
  final List<String>? photos;
  final WorkActStatus status;
  final String? customerSignature;
  final String? specialistSignature;
  final DateTime? signedAt;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkAct({
    required this.id,
    required this.contractId,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.customerName,
    required this.specialistName,
    required this.services,
    required this.totalAmount,
    required this.currency,
    required this.eventDate,
    required this.eventLocation,
    required this.description,
    this.photos,
    required this.status,
    this.customerSignature,
    this.specialistSignature,
    this.signedAt,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkAct.fromMap(Map<String, dynamic> map, String id) {
    return WorkAct(
      id: id,
      contractId: map['contractId'] as String,
      bookingId: map['bookingId'] as String,
      customerId: map['customerId'] as String,
      specialistId: map['specialistId'] as String,
      customerName: map['customerName'] as String,
      specialistName: map['specialistName'] as String,
      services: (map['services'] as List)
          .map((e) => WorkActService.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      currency: map['currency'] as String,
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      eventLocation: map['eventLocation'] as String,
      description: map['description'] as String,
      photos: map['photos'] != null ? List<String>.from(map['photos']) : null,
      status: WorkActStatus.values.firstWhere(
          (e) => e.toString() == 'WorkActStatus.${map['status']}'),
      customerSignature: map['customerSignature'] as String?,
      specialistSignature: map['specialistSignature'] as String?,
      signedAt: map['signedAt'] != null
          ? (map['signedAt'] as Timestamp).toDate()
          : null,
      pdfUrl: map['pdfUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId,
      'bookingId': bookingId,
      'customerId': customerId,
      'specialistId': specialistId,
      'customerName': customerName,
      'specialistName': specialistName,
      'services': services.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'currency': currency,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventLocation': eventLocation,
      'description': description,
      'photos': photos,
      'status': status.toString().split('.').last,
      'customerSignature': customerSignature,
      'specialistSignature': specialistSignature,
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class WorkActService {
  final String name;
  final String description;
  final double price;
  final String currency;
  final int quantity;
  final String unit;
  final bool isCompleted;

  WorkActService({
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.unit,
    required this.isCompleted,
  });

  factory WorkActService.fromMap(Map<String, dynamic> map) {
    return WorkActService(
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      currency: map['currency'] as String,
      quantity: map['quantity'] as int,
      unit: map['unit'] as String,
      isCompleted: map['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'unit': unit,
      'isCompleted': isCompleted,
    };
  }
}