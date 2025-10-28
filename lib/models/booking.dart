import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Booking status enum
enum BookingStatus {
  pending('Ожидает подтверждения'),
  confirmed('Подтверждено'),
  inProgress('В процессе'),
  completed('Завершено'),
  cancelled('Отменено'),
  rejected('Отклонено');

  const BookingStatus(this.displayName);
  final String displayName;
}

/// Booking model
class Booking extends Equatable {

  const Booking({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    required this.clientId,
    required this.clientName,
    required this.service,
    required this.date,
    required this.time,
    required this.duration,
    required this.totalPrice,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.clientPhone,
    this.clientEmail,
    this.metadata,
    this.eventTitle,
    this.participantsCount,
    this.organizerName,
    this.eventDate,
    this.endDate,
  });

  /// Create Booking from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Booking(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      service: data['service'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      duration: data['duration'] ?? 1,
      totalPrice: data['totalPrice'] ?? 0,
      notes: data['notes'] ?? '',
      status: BookingStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'],
      clientPhone: data['clientPhone'],
      clientEmail: data['clientEmail'],
      metadata: data['metadata'],
      eventTitle: data['eventTitle'],
      participantsCount: data['participantsCount'],
      organizerName: data['organizerName'],
      eventDate: data['eventDate'] != null
          ? (data['eventDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create Booking from Firestore document
  factory Booking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Booking.fromMap(data, doc.id);
  }

  /// Create Booking from Map
  factory Booking.fromMap(Map<String, dynamic> data, [String? id]) {
    return Booking(
      id: id ?? data['id'] ?? '',
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      service: data['service'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      duration: data['duration'] ?? 0,
      totalPrice: data['totalPrice'] ?? 0,
      notes: data['notes'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'],
      clientPhone: data['clientPhone'],
      clientEmail: data['clientEmail'],
      metadata: data['metadata'],
      eventTitle: data['eventTitle'],
      participantsCount: data['participantsCount'],
      organizerName: data['organizerName'],
      eventDate: data['eventDate'] != null
          ? (data['eventDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String specialistId;
  final String specialistName;
  final String clientId;
  final String clientName;
  final String service;
  final DateTime date;
  final String time; // Format: "HH:mm"
  final int duration; // in hours
  final int totalPrice;
  final String notes;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? location;
  final String? clientPhone;
  final String? clientEmail;
  final Map<String, dynamic>? metadata;
  final String? eventTitle;
  final int? participantsCount;
  final String? organizerName;
  final DateTime? eventDate;
  final DateTime? endDate;

  /// Convert Booking to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'specialistId': specialistId,
      'specialistName': specialistName,
      'clientId': clientId,
      'clientName': clientName,
      'service': service,
      'date': Timestamp.fromDate(date),
      'time': time,
      'duration': duration,
      'totalPrice': totalPrice,
      'notes': notes,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'metadata': metadata,
      'eventTitle': eventTitle,
      'participantsCount': participantsCount,
      'organizerName': organizerName,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  /// Create a copy of Booking with updated fields
  Booking copyWith({
    String? id,
    String? specialistId,
    String? specialistName,
    String? clientId,
    String? clientName,
    String? service,
    DateTime? date,
    String? time,
    int? duration,
    int? totalPrice,
    String? notes,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    String? clientPhone,
    String? clientEmail,
    Map<String, dynamic>? metadata,
    String? eventTitle,
    int? participantsCount,
    String? organizerName,
    DateTime? eventDate,
    DateTime? endDate,
  }) {
    return Booking(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      service: service ?? this.service,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      metadata: metadata ?? this.metadata,
      eventTitle: eventTitle ?? this.eventTitle,
      participantsCount: participantsCount ?? this.participantsCount,
      organizerName: organizerName ?? this.organizerName,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Get formatted date string
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    return time;
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (duration == 1) return '1 час';
    if (duration < 5) return '$duration часа';
    return '$duration часов';
  }

  /// Get formatted price string
  String get formattedPrice {
    return '$totalPrice ₽';
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case BookingStatus.pending:
        return 'orange';
      case BookingStatus.confirmed:
        return 'green';
      case BookingStatus.inProgress:
        return 'blue';
      case BookingStatus.completed:
        return 'green';
      case BookingStatus.cancelled:
        return 'red';
      case BookingStatus.rejected:
        return 'red';
    }
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return status == BookingStatus.pending || status == BookingStatus.confirmed;
  }

  /// Check if booking can be confirmed
  bool get canBeConfirmed {
    return status == BookingStatus.pending;
  }

  /// Check if booking can be completed
  bool get canBeCompleted {
    return status == BookingStatus.inProgress;
  }

  /// Check if booking is active
  bool get isActive {
    return status == BookingStatus.confirmed ||
        status == BookingStatus.inProgress;
  }

  @override
  List<Object?> get props => [
        id,
        specialistId,
        specialistName,
        clientId,
        clientName,
        service,
        date,
        time,
        duration,
        totalPrice,
        notes,
        status,
        createdAt,
        updatedAt,
        location,
        clientPhone,
        clientEmail,
        metadata,
        eventTitle,
        participantsCount,
        organizerName,
        eventDate,
        endDate,
      ];
}
