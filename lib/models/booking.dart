import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Модель бронирования
class Booking {
  Booking({
    required this.id,
    required this.specialistId,
    required this.clientId,
    required this.requestedDate, // YYYY-MM-DD string
    this.timeFrom, // HH:mm string
    this.timeTo, // HH:mm string
    this.durationOption, // '4h'|'5h'|'6h'|'custom'
    required this.eventType,
    this.message, // свободный текст клиента
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.chatId,
  });

  final String id;
  final String specialistId;
  final String clientId;
  final String requestedDate; // YYYY-MM-DD
  final String? timeFrom; // HH:mm
  final String? timeTo; // HH:mm
  final String? durationOption; // '4h'|'5h'|'6h'|'custom'
  final String eventType; // required
  final String? message; // свободный текст
  final BookingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? chatId;

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Поддержка старой схемы (date как Timestamp) и новой (requestedDate как string)
    String requestedDateStr;
    if (data.containsKey('requestedDate')) {
      requestedDateStr = data['requestedDate'] as String;
    } else if (data.containsKey('date')) {
      final date = (data['date'] as Timestamp).toDate();
      requestedDateStr = DateFormat('yyyy-MM-dd').format(date);
    } else {
      requestedDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    return Booking(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      clientId: data['clientId'] as String,
      requestedDate: requestedDateStr,
      timeFrom: data['timeFrom'] as String?,
      timeTo: data['timeTo'] as String?,
      durationOption: data['durationOption'] as String?,
      eventType: data['eventType'] as String? ?? 
                 (data['customEventType'] as String?) ?? 
                 'Мероприятие',
      message: data['message'] as String? ?? data['comment'] as String?,
      status: BookingStatus.fromString((data['status'] as String?) ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      chatId: data['chatId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'specialistId': specialistId,
      'clientId': clientId,
      'requestedDate': requestedDate,
      'timeFrom': timeFrom,
      'timeTo': timeTo,
      'durationOption': durationOption,
      'eventType': eventType,
      'message': message,
      'status': status.value,
      'chatId': chatId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Статус бронирования
enum BookingStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

/// DTO для создания бронирования
class BookingCreate {
  BookingCreate({
    required this.specialistId,
    required this.clientId,
    required this.requestedDate, // YYYY-MM-DD string
    this.timeFrom, // HH:mm string
    this.timeTo, // HH:mm string
    this.durationOption, // '4h'|'5h'|'6h'|'custom'
    required this.eventType,
    this.message, // свободный текст
  });

  final String specialistId;
  final String clientId;
  final String requestedDate; // YYYY-MM-DD
  final String? timeFrom; // HH:mm
  final String? timeTo; // HH:mm
  final String? durationOption; // '4h'|'5h'|'6h'|'custom'
  final String eventType; // required
  final String? message; // свободный текст
}
