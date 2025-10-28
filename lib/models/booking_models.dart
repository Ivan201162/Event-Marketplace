import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус бронирования
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
  refunded
}

/// Тип бронирования
enum BookingType { service, consultation, event, package, subscription }

/// Модель бронирования
class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.serviceId,
    required this.type,
    required this.status,
    required this.date,
    required this.time,
    required this.createdAt, this.duration,
    this.price,
    this.currency = 'RUB',
    this.description,
    this.notes,
    this.location,
    this.contactInfo,
    this.specialRequests,
    this.reminders = const [],
    this.attachments = const [],
    this.metadata = const {},
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.refundedAt,
    this.cancellationReason,
    this.refundReason,
    this.refundAmount,
    this.paymentId,
    this.reviewId,
    this.rating,
    this.feedback,
    this.updatedAt,
  });

  /// Создать из Map
  factory Booking.fromMap(Map<String, dynamic> data) {
    return Booking(
      id: data['id'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      date: data['date'] != null
          ? (data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date'].toString()))
          : DateTime.now(),
      time: data['time'] != null
          ? (data['time'] is Timestamp
              ? (data['time'] as Timestamp).toDate()
              : DateTime.parse(data['time'].toString()))
          : DateTime.now(),
      duration: data['duration'] != null
          ? Duration(milliseconds: data['duration'] as int)
          : null,
      price: (data['price'] as num?)?.toDouble(),
      currency: data['currency'] as String? ?? 'RUB',
      description: data['description'] as String?,
      notes: data['notes'] as String?,
      location: data['location'] as String?,
      contactInfo: data['contactInfo'] != null
          ? Map<String, dynamic>.from(data['contactInfo'])
          : null,
      specialRequests: data['specialRequests'] as String?,
      reminders: (data['reminders'] as List<dynamic>?)
              ?.map((e) =>
                  e is Timestamp ? e.toDate() : DateTime.parse(e.toString()),)
              .toList() ??
          [],
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] is Timestamp
              ? (data['confirmedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['confirmedAt'].toString()))
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] is Timestamp
              ? (data['completedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['completedAt'].toString()))
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] is Timestamp
              ? (data['cancelledAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['cancelledAt'].toString()))
          : null,
      refundedAt: data['refundedAt'] != null
          ? (data['refundedAt'] is Timestamp
              ? (data['refundedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['refundedAt'].toString()))
          : null,
      cancellationReason: data['cancellationReason'] as String?,
      refundReason: data['refundReason'] as String?,
      refundAmount: (data['refundAmount'] as num?)?.toDouble(),
      paymentId: data['paymentId'] as String?,
      reviewId: data['reviewId'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      feedback: data['feedback'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Booking.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String customerId;
  final String specialistId;
  final String serviceId;
  final BookingType type;
  final BookingStatus status;
  final DateTime date;
  final DateTime time;
  final Duration? duration;
  final double? price;
  final String currency;
  final String? description;
  final String? notes;
  final String? location;
  final Map<String, dynamic>? contactInfo;
  final String? specialRequests;
  final List<DateTime> reminders;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final String? cancellationReason;
  final String? refundReason;
  final double? refundAmount;
  final String? paymentId;
  final String? reviewId;
  final double? rating;
  final String? feedback;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'specialistId': specialistId,
        'serviceId': serviceId,
        'type': type.name,
        'status': status.name,
        'date': Timestamp.fromDate(date),
        'time': Timestamp.fromDate(time),
        'duration': duration?.inMilliseconds,
        'price': price,
        'currency': currency,
        'description': description,
        'notes': notes,
        'location': location,
        'contactInfo': contactInfo,
        'specialRequests': specialRequests,
        'reminders': reminders.map(Timestamp.fromDate).toList(),
        'attachments': attachments,
        'metadata': metadata,
        'confirmedAt':
            confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'cancelledAt':
            cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
        'refundedAt':
            refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
        'cancellationReason': cancellationReason,
        'refundReason': refundReason,
        'refundAmount': refundAmount,
        'paymentId': paymentId,
        'reviewId': reviewId,
        'rating': rating,
        'feedback': feedback,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  Booking copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    String? serviceId,
    BookingType? type,
    BookingStatus? status,
    DateTime? date,
    DateTime? time,
    Duration? duration,
    double? price,
    String? currency,
    String? description,
    String? notes,
    String? location,
    Map<String, dynamic>? contactInfo,
    String? specialRequests,
    List<DateTime>? reminders,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? refundedAt,
    String? cancellationReason,
    String? refundReason,
    double? refundAmount,
    String? paymentId,
    String? reviewId,
    double? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Booking(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        serviceId: serviceId ?? this.serviceId,
        type: type ?? this.type,
        status: status ?? this.status,
        date: date ?? this.date,
        time: time ?? this.time,
        duration: duration ?? this.duration,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        location: location ?? this.location,
        contactInfo: contactInfo ?? this.contactInfo,
        specialRequests: specialRequests ?? this.specialRequests,
        reminders: reminders ?? this.reminders,
        attachments: attachments ?? this.attachments,
        metadata: metadata ?? this.metadata,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        completedAt: completedAt ?? this.completedAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        refundedAt: refundedAt ?? this.refundedAt,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        refundReason: refundReason ?? this.refundReason,
        refundAmount: refundAmount ?? this.refundAmount,
        paymentId: paymentId ?? this.paymentId,
        reviewId: reviewId ?? this.reviewId,
        rating: rating ?? this.rating,
        feedback: feedback ?? this.feedback,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static BookingType _parseType(String? type) {
    switch (type) {
      case 'service':
        return BookingType.service;
      case 'consultation':
        return BookingType.consultation;
      case 'event':
        return BookingType.event;
      case 'package':
        return BookingType.package;
      case 'subscription':
        return BookingType.subscription;
      default:
        return BookingType.service;
    }
  }

  /// Парсинг статуса из строки
  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'inProgress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'noShow':
        return BookingStatus.noShow;
      case 'refunded':
        return BookingStatus.refunded;
      default:
        return BookingStatus.pending;
    }
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case BookingType.service:
        return 'Услуга';
      case BookingType.consultation:
        return 'Консультация';
      case BookingType.event:
        return 'Событие';
      case BookingType.package:
        return 'Пакет';
      case BookingType.subscription:
        return 'Подписка';
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.inProgress:
        return 'В процессе';
      case BookingStatus.completed:
        return 'Завершено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.noShow:
        return 'Не явился';
      case BookingStatus.refunded:
        return 'Возвращено';
    }
  }

  /// Проверить, ожидает ли бронирование
  bool get isPending => status == BookingStatus.pending;

  /// Проверить, подтверждено ли бронирование
  bool get isConfirmed => status == BookingStatus.confirmed;

  /// Проверить, в процессе ли бронирование
  bool get isInProgress => status == BookingStatus.inProgress;

  /// Проверить, завершено ли бронирование
  bool get isCompleted => status == BookingStatus.completed;

  /// Проверить, отменено ли бронирование
  bool get isCancelled => status == BookingStatus.cancelled;

  /// Проверить, не явился ли клиент
  bool get isNoShow => status == BookingStatus.noShow;

  /// Проверить, возвращено ли бронирование
  bool get isRefunded => status == BookingStatus.refunded;

  /// Проверить, есть ли цена
  bool get hasPrice => price != null;

  /// Проверить, есть ли описание
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// Проверить, есть ли заметки
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Проверить, есть ли специальные запросы
  bool get hasSpecialRequests =>
      specialRequests != null && specialRequests!.isNotEmpty;

  /// Проверить, есть ли напоминания
  bool get hasReminders => reminders.isNotEmpty;

  /// Проверить, есть ли вложения
  bool get hasAttachments => attachments.isNotEmpty;

  /// Проверить, есть ли отзыв
  bool get hasReview => reviewId != null;

  /// Проверить, есть ли рейтинг
  bool get hasRating => rating != null;

  /// Проверить, есть ли обратная связь
  bool get hasFeedback => feedback != null && feedback!.isNotEmpty;

  /// Проверить, есть ли причина отмены
  bool get hasCancellationReason =>
      cancellationReason != null && cancellationReason!.isNotEmpty;

  /// Проверить, есть ли причина возврата
  bool get hasRefundReason => refundReason != null && refundReason!.isNotEmpty;

  /// Проверить, есть ли сумма возврата
  bool get hasRefundAmount => refundAmount != null;

  /// Получить отформатированную цену
  String get formattedPrice {
    if (price == null) return 'Цена не указана';
    return '${price!.toStringAsFixed(2)} $currency';
  }

  /// Получить отформатированную сумму возврата
  String get formattedRefundAmount {
    if (refundAmount == null) return '';
    return '${refundAmount!.toStringAsFixed(2)} $currency';
  }

  /// Получить отформатированную длительность
  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes % 60;
    if (hours > 0) {
      return '$hoursч $minutesм';
    } else {
      return '$minutesм';
    }
  }

  /// Получить отформатированную дату
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Получить отформатированное время
  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Получить отформатированную дату и время
  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  /// Получить отформатированный рейтинг
  String get formattedRating {
    if (rating == null) return '';
    return '${rating!.toStringAsFixed(1)}/5.0';
  }

  /// Получить звезды для отображения
  List<bool> get stars {
    if (rating == null) return List.filled(5, false);
    final stars = <bool>[];
    for (var i = 1; i <= 5; i++) {
      stars.add(i <= rating!);
    }
    return stars;
  }
}
