import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус бронирования
enum BookingStatus {
  pending, // Ожидает подтверждения
  confirmed, // Подтверждено
  cancelled, // Отменено
  completed, // Завершено
  rejected, // Отклонено
}

/// Модель бронирования/заявки
class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.eventDate,
    required this.totalPrice,
    required this.prepayment,
    required this.status,
    this.message = '',
    required this.createdAt,
    this.updatedAt,
    // Дополнительные поля для совместимости
    this.eventId,
    this.eventTitle,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.bookingDate,
    this.participantsCount,
    this.notes,
    this.serviceId,
    this.organizerId,
    this.organizerName,
    this.expiresAt,
    this.specialistName,
    this.endDate,
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
    this.date,
    this.time,
    this.address,
    this.comment,
    this.serviceName,
    this.advancePaid,
    this.eventAddress,
    this.eventType,
    this.startTime,
    this.startDate,
    this.totalAmount,
    this.advanceAmount,
    this.location,
    this.duration,
    this.specialRequests,
    this.currency,
    this.dueDate,
    this.isPrepayment,
    this.isFinalPayment,
    this.prepaymentPaid,
    this.vkPlaylistUrl,
    this.discount,
    this.finalPrice,
  });

  /// Создать из документа Firestore
  factory Booking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      prepayment: (data['prepayment'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => BookingStatus.pending,
      ),
      message: data['message'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      // Дополнительные поля для совместимости
      eventId: data['eventId'] as String?,
      eventTitle: data['eventTitle'] as String?,
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      userEmail: data['userEmail'] as String?,
      userPhone: data['userPhone'] as String?,
      bookingDate: data['bookingDate'] != null
          ? (data['bookingDate'] as Timestamp).toDate()
          : null,
      participantsCount: data['participantsCount'] as int?,
      notes: data['notes'] as String?,
      organizerId: data['organizerId'] as String?,
      organizerName: data['organizerName'] as String?,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      specialistName: data['specialistName'] as String?,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
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
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      advanceAmount: (data['advanceAmount'] as num?)?.toDouble(),
      location: data['location'] as String?,
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'] as int)
          : null,
      specialRequests: data['specialRequests'] as String?,
      currency: data['currency'] as String?,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      isPrepayment: data['isPrepayment'] as bool?,
      isFinalPayment: data['isFinalPayment'] as bool?,
      prepaymentPaid: data['prepaymentPaid'] as bool?,
      vkPlaylistUrl: data['vkPlaylistUrl'] as String?,
      discount: (data['discount'] as num?)?.toDouble(),
      finalPrice: (data['finalPrice'] as num?)?.toDouble(),
    );
  }

  /// Создать объект из Map
  factory Booking.fromMap(Map<String, dynamic> map) {
    // Безопасное преобразование данных
    return Booking(
      id: map['id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      specialistId: map['specialistId'] as String? ?? '',
      eventDate: map['eventDate'] != null
          ? (map['eventDate'] is Timestamp
              ? (map['eventDate'] as Timestamp).toDate()
              : DateTime.parse(map['eventDate'].toString()))
          : DateTime.now(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      prepayment: (map['prepayment'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      message: map['message'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt'].toString()))
          : null,
      // Дополнительные поля для совместимости
      eventId: map['eventId'] as String?,
      eventTitle: map['eventTitle'] as String?,
      userId: map['userId'] as String?,
      userName: map['userName'] as String?,
      userEmail: map['userEmail'] as String?,
      userPhone: map['userPhone'] as String?,
      bookingDate: map['bookingDate'] != null
          ? (map['bookingDate'] is Timestamp
              ? (map['bookingDate'] as Timestamp).toDate()
              : DateTime.parse(map['bookingDate'].toString()))
          : null,
      participantsCount: map['participantsCount'] as int?,
      notes: map['notes'] as String?,
      serviceId: map['serviceId'] as String?,
      organizerId: map['organizerId'] as String?,
      organizerName: map['organizerName'] as String?,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] is Timestamp
              ? (map['expiresAt'] as Timestamp).toDate()
              : DateTime.parse(map['expiresAt'].toString()))
          : null,
      specialistName: map['specialistName'] as String?,
      endDate: map['endDate'] != null
          ? (map['endDate'] is Timestamp
              ? (map['endDate'] as Timestamp).toDate()
              : DateTime.parse(map['endDate'].toString()))
          : null,
      eventTime: map['eventTime'] as String?,
      eventDuration: map['eventDuration'] as int?,
      eventLocation: map['eventLocation'] as String?,
      eventAddress: map['eventAddress'] as String?,
      eventDescription: map['eventDescription'] as String?,
      specialRequests: map['specialRequests'] as String?,
      discount: (map['discount'] as num?)?.toDouble(),
      finalPrice: (map['finalPrice'] as num?)?.toDouble(),
    );
  }
  // Основные поля для системы заявок
  final String id;
  final String customerId;
  final String specialistId;
  final DateTime eventDate;
  final double totalPrice;
  final double prepayment;
  final BookingStatus status;
  final String message;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Дополнительные поля для совместимости
  final String? eventId;
  final String? eventTitle;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final DateTime? bookingDate;
  final int? participantsCount;
  final String? notes;
  final String? serviceId;
  final String? organizerId;
  final String? organizerName;
  final DateTime? expiresAt; // Время истечения подтверждения
  final String? specialistName;
  final DateTime? endDate;

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
  final DateTime? date;
  final String? time;
  final String? address;
  final String? comment;
  final String? serviceName;
  final double? advancePaid;
  final String? eventType;
  final String? startTime;
  final DateTime? startDate;
  final double? totalAmount;
  final double? advanceAmount;
  final String? location;
  final Duration? duration;
  final String? specialRequests;
  final String? currency;
  final DateTime? dueDate;
  final bool? isPrepayment;
  final bool? isFinalPayment;
  final bool? prepaymentPaid;
  final String? vkPlaylistUrl;

  // Поля для системы скидок
  final double? discount; // Процент скидки (0-100)
  final double? finalPrice; // Финальная цена после применения скидки

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        // Основные поля для системы заявок
        'customerId': customerId,
        'specialistId': specialistId,
        'eventDate': Timestamp.fromDate(eventDate),
        'totalPrice': totalPrice,
        'prepayment': prepayment,
        'status': status.name,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        // Дополнительные поля для совместимости
        'eventId': eventId,
        'eventTitle': eventTitle,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'bookingDate':
            bookingDate != null ? Timestamp.fromDate(bookingDate!) : null,
        'participantsCount': participantsCount,
        'notes': notes,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'specialistName': specialistName,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
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
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'location': location,
        'duration': duration?.inSeconds,
        'specialRequests': specialRequests,
        'currency': currency,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'isPrepayment': isPrepayment,
        'isFinalPayment': isFinalPayment,
        'prepaymentPaid': prepaymentPaid,
        'vkPlaylistUrl': vkPlaylistUrl,
        'discount': discount,
        'finalPrice': finalPrice,
      };

  /// Создать копию с изменениями
  Booking copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    DateTime? eventDate,
    double? totalPrice,
    double? prepayment,
    BookingStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Дополнительные поля для совместимости
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    DateTime? bookingDate,
    int? participantsCount,
    String? notes,
    String? organizerId,
    String? organizerName,
    DateTime? expiresAt,
    String? specialistName,
    String? serviceId,
    DateTime? endDate,
    DateTime? startDate,
    double? totalAmount,
    double? advanceAmount,
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
    double? discount,
    double? finalPrice,
  }) =>
      Booking(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        eventDate: eventDate ?? this.eventDate,
        totalPrice: totalPrice ?? this.totalPrice,
        prepayment: prepayment ?? this.prepayment,
        status: status ?? this.status,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        // Дополнительные поля для совместимости
        eventId: eventId ?? this.eventId,
        eventTitle: eventTitle ?? this.eventTitle,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
        userPhone: userPhone ?? this.userPhone,
        bookingDate: bookingDate ?? this.bookingDate,
        participantsCount: participantsCount ?? this.participantsCount,
        notes: notes ?? this.notes,
        organizerId: organizerId ?? this.organizerId,
        organizerName: organizerName ?? this.organizerName,
        expiresAt: expiresAt ?? this.expiresAt,
        specialistName: specialistName ?? this.specialistName,
        serviceId: serviceId ?? this.serviceId,
        endDate: endDate ?? this.endDate,
        startDate: startDate ?? this.startDate,
        totalAmount: totalAmount ?? this.totalAmount,
        advanceAmount: advanceAmount ?? this.advanceAmount,
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
        discount: discount ?? this.discount,
        finalPrice: finalPrice ?? this.finalPrice,
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

  /// Получить статус оплаты (для совместимости с UI)
  String get paymentStatus {
    // В реальном приложении здесь будет проверка статуса платежей
    return 'pending';
  }

  /// Проверить, оплачена ли предоплата
  bool get isPrepaymentPaid {
    // В реальном приложении здесь будет проверка статуса предоплаты
    return false;
  }

  /// Получить сумму к доплате
  double get remainingAmount {
    // В реальном приложении здесь будет расчет оставшейся суммы
    return finalPrice ?? totalPrice;
  }

  /// Получить финальную цену с учетом скидки
  double get effectivePrice => finalPrice ?? totalPrice;

  /// Проверить, есть ли скидка
  bool get hasDiscount => discount != null && discount! > 0;

  /// Получить размер скидки в рублях
  double get discountAmount {
    if (discount == null || discount! <= 0) return 0;
    return totalPrice * (discount! / 100);
  }

  /// Применить скидку и пересчитать финальную цену
  Booking applyDiscount(double discountPercent) {
    // Ограничиваем скидку максимум 100%
    final clampedDiscount = discountPercent.clamp(0.0, 100.0);
    final discountAmount = totalPrice * (clampedDiscount / 100);
    final newFinalPrice = (totalPrice - discountAmount).clamp(0.0, totalPrice);

    return copyWith(
      discount: clampedDiscount,
      finalPrice: newFinalPrice,
    );
  }
}
