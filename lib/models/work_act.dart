import 'package:cloud_firestore/cloud_firestore.dart';

/// Статусы акта выполненных работ
enum WorkActStatus {
  draft, // Черновик
  pending, // Ожидает подписания
  signed, // Подписан
  completed, // Завершен
}

/// Модель акта выполненных работ
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
  final String? description; // Описание выполненных работ
  final List<String>? photos; // Фото выполненных работ
  final WorkActStatus status;
  final DateTime? signedAt;
  final String? customerSignature;
  final String? specialistSignature;
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
    this.description,
    this.photos,
    required this.status,
    this.signedAt,
    this.customerSignature,
    this.specialistSignature,
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
      services: (map['services'] as List<dynamic>)
          .map((service) => WorkActService.fromMap(service as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      currency: map['currency'] as String,
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      eventLocation: map['eventLocation'] as String,
      description: map['description'] as String?,
      photos: (map['photos'] as List<dynamic>?)?.cast<String>(),
      status: WorkActStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => WorkActStatus.draft,
      ),
      signedAt: (map['signedAt'] as Timestamp?)?.toDate(),
      customerSignature: map['customerSignature'] as String?,
      specialistSignature: map['specialistSignature'] as String?,
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
      'services': services.map((service) => service.toMap()).toList(),
      'totalAmount': totalAmount,
      'currency': currency,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventLocation': eventLocation,
      'description': description,
      'photos': photos,
      'status': status.name,
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'customerSignature': customerSignature,
      'specialistSignature': specialistSignature,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Создать копию с обновленными полями
  WorkAct copyWith({
    String? id,
    String? contractId,
    String? bookingId,
    String? customerId,
    String? specialistId,
    String? customerName,
    String? specialistName,
    List<WorkActService>? services,
    double? totalAmount,
    String? currency,
    DateTime? eventDate,
    String? eventLocation,
    String? description,
    List<String>? photos,
    WorkActStatus? status,
    DateTime? signedAt,
    String? customerSignature,
    String? specialistSignature,
    String? pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkAct(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      customerName: customerName ?? this.customerName,
      specialistName: specialistName ?? this.specialistName,
      services: services ?? this.services,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      signedAt: signedAt ?? this.signedAt,
      customerSignature: customerSignature ?? this.customerSignature,
      specialistSignature: specialistSignature ?? this.specialistSignature,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Услуга в акте выполненных работ
class WorkActService {
  final String name;
  final String description;
  final double price;
  final String currency;
  final int quantity;
  final String unit;
  final bool isCompleted; // Выполнена ли услуга
  final String? notes; // Примечания

  WorkActService({
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.quantity,
    required this.unit,
    required this.isCompleted,
    this.notes,
  });

  factory WorkActService.fromMap(Map<String, dynamic> map) {
    return WorkActService(
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      currency: map['currency'] as String,
      quantity: map['quantity'] as int,
      unit: map['unit'] as String,
      isCompleted: map['isCompleted'] as bool? ?? true,
      notes: map['notes'] as String?,
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
      'notes': notes,
    };
  }

  /// Общая стоимость услуги
  double get totalPrice => price * quantity;
}
