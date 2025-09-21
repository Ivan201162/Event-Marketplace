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
    this.serviceId,
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
    this.eventTime,
    this.eventDuration,
    this.eventAddress,
    this.eventType,
    this.startTime,
    this.location,
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
    final data = doc.data()! as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String?,
      userPhone: data['userPhone'] as String?,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => BookingStatus.pending,
      ),
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      participantsCount: data['participantsCount'] as int? ?? 1,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      organizerId: data['organizerId'] as String?,
      organizerName: data['organizerName'] as String?,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      customerId: data['customerId'] as String?,
      specialistId: data['specialistId'] as String?,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      prepayment: (data['prepayment'] as num?)?.toDouble(),
      title: data['title'] as String?,
      customerName: data['customerName'] as String?,
      customerPhone: data['customerPhone'] as String?,
      customerEmail: data['customerEmail'] as String?,
      description: data['description'] as String?,
      eventName: data['eventName'] as String?,
      eventDescription: data['eventDescription'] as String?,
      eventLocation: data['eventLocation'] as String?,
      eventType: data['eventType'] as String?,
      startTime: data['startTime'] as String?,
      location: data['location'] as String?,
      duration:
          data['duration'] != null ? Duration(seconds: data['duration'] as int) : null,
      specialRequests: data['specialRequests'] as String?,
      currency: data['currency'] as String?,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isPrepayment: data['isPrepayment'] as bool?,
      isFinalPayment: data['isFinalPayment'] as bool?,
      prepaymentPaid: data['prepaymentPaid'] as bool?,
      vkPlaylistUrl: data['vkPlaylistUrl'] as String?,
    );
  }

  /// Создать объект из Map
  factory Booking.fromMap(Map<String, dynamic> map) => Booking(
        id: map['id'] as String? ?? '',
        eventId: map['eventId'] as String? ?? '',
        eventTitle: map['eventTitle'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? '',
        userEmail: map['userEmail'] as String?,
        userPhone: map['userPhone'] as String?,
        specialistId: map['specialistId'] as String? ?? '',
        specialistName: map['specialistName'] as String? ?? '',
        serviceId: map['serviceId'] as String? ?? '',
        bookingDate: map['bookingDate'] != null
            ? (map['bookingDate'] as Timestamp).toDate()
            : DateTime.now(),
        eventDate: map['eventDate'] != null
            ? (map['eventDate'] as Timestamp).toDate()
            : DateTime.now(),
        participantsCount: map['participantsCount'] as int? ?? 1,
        totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
        eventTime: map['eventTime'] as String? ?? '',
        eventDuration: map['eventDuration'] as int? ?? 0,
        eventLocation: map['eventLocation'] as String? ?? '',
        eventAddress: map['eventAddress'] as String? ?? '',
        eventDescription: map['eventDescription'] as String? ?? '',
        specialRequests: map['specialRequests'] as String? ?? '',
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
  final String? serviceId;
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
  final String? eventTime;
  final int? eventDuration;
  final String? eventAddress;
  final String? eventType;
  final String? startTime;
  final String? location;
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
        'eventType': eventType,
        'startTime': startTime,
        'location': location,
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
    String? serviceId,
    DateTime? endDate,
    DateTime? expiresAt,
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
        serviceId: serviceId ?? this.serviceId,
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
