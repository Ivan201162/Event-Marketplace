import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус бронирования
enum BookingStatus {
  pending, // Ожидает подтверждения
  confirmed, // Подтверждено
  cancelled, // Отменено
  completed, // Завершено
}

/// Модель бронирования
class Booking {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? userPhone;
  final BookingStatus status;
  final DateTime bookingDate;
  final DateTime eventDate;
  final int participantsCount;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? organizerId;
  final String? organizerName;
  final String? customerId;
  final String? specialistId;
  final DateTime? endDate;
  final double? prepayment;

  const Booking({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.userPhone,
    required this.status,
    required this.bookingDate,
    required this.eventDate,
    required this.participantsCount,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.organizerId,
    this.organizerName,
    this.customerId,
    this.specialistId,
    this.endDate,
    this.prepayment,
  });

  /// Создать из документа Firestore
  factory Booking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'],
      userPhone: data['userPhone'],
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      participantsCount: data['participantsCount'] ?? 1,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      organizerId: data['organizerId'],
      organizerName: data['organizerName'],
      customerId: data['customerId'],
      specialistId: data['specialistId'],
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      prepayment: (data['prepayment'] as num?)?.toDouble(),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'status': status.name,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'eventDate': Timestamp.fromDate(eventDate),
      'participantsCount': participantsCount,
      'totalPrice': totalPrice,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'customerId': customerId,
      'specialistId': specialistId,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'prepayment': prepayment,
    };
  }

  /// Создать копию с изменениями
  Booking copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    BookingStatus? status,
    DateTime? bookingDate,
    DateTime? eventDate,
    int? participantsCount,
    double? totalPrice,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organizerId,
    String? organizerName,
    String? customerId,
    String? specialistId,
    DateTime? endDate,
    double? prepayment,
  }) {
    return Booking(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      status: status ?? this.status,
      bookingDate: bookingDate ?? this.bookingDate,
      eventDate: eventDate ?? this.eventDate,
      participantsCount: participantsCount ?? this.participantsCount,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      customerId: customerId ?? this.customerId,
      specialistId: specialistId ?? this.specialistId,
      endDate: endDate ?? this.endDate,
      prepayment: prepayment ?? this.prepayment,
    );
  }

  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case BookingStatus.pending:
        return 'orange';
      case BookingStatus.confirmed:
        return 'green';
      case BookingStatus.cancelled:
        return 'red';
      case BookingStatus.completed:
        return 'blue';
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает подтверждения';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.completed:
        return 'Завершено';
    }
  }

  /// Проверить, можно ли отменить бронирование
  bool get canBeCancelled {
    return status == BookingStatus.pending || status == BookingStatus.confirmed;
  }

  /// Проверить, можно ли подтвердить бронирование
  bool get canBeConfirmed {
    return status == BookingStatus.pending;
  }

  /// Проверить, можно ли завершить бронирование
  bool get canBeCompleted {
    return status == BookingStatus.confirmed;
  }
}
