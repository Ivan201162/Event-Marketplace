import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус бронирования
enum BookingStatus {
  pending, // Ожидает подтверждения
  confirmed, // Подтверждено
  cancelled, // Отменено
  completed, // Завершено
  rejected, // Отклонено
}

/// Модель бронирования
class Booking {
  // Ссылка на плейлист VK

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
    this.expiresAt,
    this.customerId,
    this.specialistId,
    this.specialistName,
    this.endDate,
    this.prepayment,
    this.title,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.description,
    this.eventName,
    this.eventDescription,
    this.eventLocation,
    this.duration,
    this.specialRequests,
    this.currency,
    this.dueDate,
    this.isPrepayment,
    this.isFinalPayment,
    this.prepaymentPaid,
    this.vkPlaylistUrl,
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
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      customerId: data['customerId'],
      specialistId: data['specialistId'],
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      prepayment: (data['prepayment'] as num?)?.toDouble(),
      title: data['title'],
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      customerEmail: data['customerEmail'],
      description: data['description'],
      eventName: data['eventName'],
      eventDescription: data['eventDescription'],
      eventLocation: data['eventLocation'],
      duration:
          data['duration'] != null ? Duration(seconds: data['duration']) : null,
      specialRequests: data['specialRequests'],
      currency: data['currency'],
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isPrepayment: data['isPrepayment'],
      isFinalPayment: data['isFinalPayment'],
      prepaymentPaid: data['prepaymentPaid'],
      vkPlaylistUrl: data['vkPlaylistUrl'],
    );
  }

  /// Создать объект из Map
  factory Booking.fromMap(Map<String, dynamic> map) => Booking(
        id: map['id'] ?? '',
        eventId: map['eventId'] ?? '',
        eventTitle: map['eventTitle'] ?? '',
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        userEmail: map['userEmail'],
        userPhone: map['userPhone'],
        specialistId: map['specialistId'] ?? '',
        specialistName: map['specialistName'] ?? '',
        serviceId: map['serviceId'] ?? '',
        serviceName: map['serviceName'] ?? '',
        servicePrice: (map['servicePrice'] ?? 0).toDouble(),
        eventDate: map['eventDate'] != null
            ? (map['eventDate'] as Timestamp).toDate()
            : DateTime.now(),
        eventTime: map['eventTime'] ?? '',
        eventDuration: map['eventDuration'] ?? 0,
        eventLocation: map['eventLocation'] ?? '',
        eventAddress: map['eventAddress'] ?? '',
        eventDescription: map['eventDescription'] ?? '',
        specialRequests: map['specialRequests'] ?? '',
        status: BookingStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => BookingStatus.pending,
        ),
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
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
  final DateTime? expiresAt; // Время истечения подтверждения
  final String? customerId;
  final String? specialistId;
  final String? specialistName;
  final DateTime? endDate;
  final double? prepayment;

  // Дополнительные поля для совместимости
  final String? title;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? description;
  final String? eventName;
  final String? eventDescription;
  final String? eventLocation;
  final Duration? duration;
  final String? specialRequests;
  final String? currency;
  final DateTime? dueDate;
  final bool? isPrepayment;
  final bool? isFinalPayment;
  final bool? prepaymentPaid;
  final String? vkPlaylistUrl;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
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
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'customerId': customerId,
        'specialistId': specialistId,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'prepayment': prepayment,
        'title': title,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'description': description,
        'eventName': eventName,
        'eventDescription': eventDescription,
        'eventLocation': eventLocation,
        'duration': duration?.inSeconds,
        'specialRequests': specialRequests,
        'currency': currency,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'isPrepayment': isPrepayment,
        'isFinalPayment': isFinalPayment,
        'prepaymentPaid': prepaymentPaid,
        'vkPlaylistUrl': vkPlaylistUrl,
      };

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
    String? title,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? description,
    String? eventName,
    String? eventDescription,
    String? eventLocation,
    Duration? duration,
    String? specialRequests,
    String? currency,
    DateTime? dueDate,
    bool? isPrepayment,
    bool? isFinalPayment,
    bool? prepaymentPaid,
    String? vkPlaylistUrl,
  }) =>
      Booking(
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
        expiresAt: expiresAt,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        endDate: endDate ?? this.endDate,
        prepayment: prepayment ?? this.prepayment,
        title: title ?? this.title,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        customerEmail: customerEmail ?? this.customerEmail,
        description: description ?? this.description,
        eventName: eventName ?? this.eventName,
        eventDescription: eventDescription ?? this.eventDescription,
        eventLocation: eventLocation ?? this.eventLocation,
        duration: duration ?? this.duration,
        specialRequests: specialRequests ?? this.specialRequests,
        currency: currency ?? this.currency,
        dueDate: dueDate ?? this.dueDate,
        isPrepayment: isPrepayment ?? this.isPrepayment,
        isFinalPayment: isFinalPayment ?? this.isFinalPayment,
        prepaymentPaid: prepaymentPaid ?? this.prepaymentPaid,
        vkPlaylistUrl: vkPlaylistUrl ?? this.vkPlaylistUrl,
      );

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
      case BookingStatus.rejected:
        return 'red';
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
      case BookingStatus.rejected:
        return 'Отклонено';
    }
  }

  /// Проверить, можно ли отменить бронирование
  bool get canBeCancelled =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  /// Проверить, можно ли подтвердить бронирование
  bool get canBeConfirmed => status == BookingStatus.pending;

  /// Проверить, можно ли завершить бронирование
  bool get canBeCompleted => status == BookingStatus.confirmed;
}
