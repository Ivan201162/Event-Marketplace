import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус заявки
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

/// Модель заявки
class Booking {
  final String id;
  final String customerId;
  final String specialistId;
  final String eventType;
  final String description;
  final DateTime eventDate;
  final String location;
  final double budget;
  final BookingStatus status;
  final Map<String, dynamic>? requirements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.eventType,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.budget,
    required this.status,
    this.requirements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      eventType: data['eventType'] ?? '',
      description: data['description'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      budget: (data['budget'] ?? 0.0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      requirements:
          data['requirements'] != null ? Map<String, dynamic>.from(data['requirements']) : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'specialistId': specialistId,
      'eventType': eventType,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'budget': budget,
      'status': status.name,
      'requirements': requirements,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    String? eventType,
    String? description,
    DateTime? eventDate,
    String? location,
    double? budget,
    BookingStatus? status,
    Map<String, dynamic>? requirements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
