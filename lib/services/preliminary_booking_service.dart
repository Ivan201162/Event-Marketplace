import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';

/// Сервис для предварительного бронирования
class PreliminaryBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать предварительное бронирование
  Future<PreliminaryBooking> createPreliminaryBooking({
    required String specialistId,
    required String customerId,
    required DateTime eventDate,
    required Duration duration,
    required String eventTitle,
    required String eventDescription,
    required int participantsCount,
    String? eventLocation,
    String? specialRequests,
    Map<String, dynamic>? metadata,
  }) async {
    if (!FeatureFlags.preliminaryBookingEnabled) {
      throw Exception('Предварительное бронирование отключено');
    }

    try {
      // Проверяем доступность специалиста
      final isAvailable = await _checkSpecialistAvailability(
        specialistId: specialistId,
        eventDate: eventDate,
        duration: duration,
      );

      if (!isAvailable) {
        throw Exception('Специалист недоступен в указанное время');
      }

      // Создаем предварительное бронирование
      final preliminaryBooking = PreliminaryBooking(
        id: '',
        specialistId: specialistId,
        customerId: customerId,
        eventDate: eventDate,
        duration: duration,
        eventTitle: eventTitle,
        eventDescription: eventDescription,
        participantsCount: participantsCount,
        eventLocation: eventLocation,
        specialRequests: specialRequests,
        status: PreliminaryBookingStatus.pending,
        expiresAt: DateTime.now()
            .add(const Duration(hours: 24)), // 24 часа на подтверждение
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        confirmedAt: null,
        cancelledAt: null,
        metadata: metadata ?? {},
      );

      // Сохраняем в Firestore
      final docRef = await _firestore
          .collection('preliminary_bookings')
          .add(preliminaryBooking.toMap());

      // Отправляем уведомление специалисту
      await _notifySpecialist(docRef.id, specialistId, customerId);

      return preliminaryBooking.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания предварительного бронирования: $e');
    }
  }

  /// Подтвердить предварительное бронирование
  Future<Booking> confirmPreliminaryBooking({
    required String preliminaryBookingId,
    required String specialistId,
    required double totalPrice,
    double? prepayment,
    String? notes,
  }) async {
    try {
      final preliminaryBooking =
          await _getPreliminaryBooking(preliminaryBookingId);
      if (preliminaryBooking == null) {
        throw Exception('Предварительное бронирование не найдено');
      }

      if (preliminaryBooking.specialistId != specialistId) {
        throw Exception('Недостаточно прав для подтверждения бронирования');
      }

      if (preliminaryBooking.status != PreliminaryBookingStatus.pending) {
        throw Exception('Бронирование уже обработано');
      }

      if (preliminaryBooking.expiresAt.isBefore(DateTime.now())) {
        throw Exception('Время подтверждения истекло');
      }

      // Создаем обычное бронирование
      final booking = Booking(
        id: '',
        eventId: '', // Будет сгенерирован позже
        eventTitle: preliminaryBooking.eventTitle,
        userId: preliminaryBooking.customerId,
        userName: '', // Будет заполнено из профиля пользователя
        userEmail: '', // Будет заполнено из профиля пользователя
        userPhone: '', // Будет заполнено из профиля пользователя
        status: BookingStatus.confirmed,
        bookingDate: DateTime.now(),
        eventDate: preliminaryBooking.eventDate,
        participantsCount: preliminaryBooking.participantsCount,
        totalPrice: totalPrice,
        notes: notes ?? preliminaryBooking.specialRequests,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        organizerId: specialistId,
        organizerName: '', // Будет заполнено из профиля специалиста
        expiresAt: null,
        customerId: preliminaryBooking.customerId,
        specialistId: preliminaryBooking.specialistId,
        endDate: preliminaryBooking.eventDate.add(preliminaryBooking.duration),
        prepayment: prepayment,
        eventName: preliminaryBooking.eventTitle,
        eventDescription: preliminaryBooking.eventDescription,
        eventLocation: preliminaryBooking.eventLocation,
        duration: preliminaryBooking.duration,
        specialRequests: preliminaryBooking.specialRequests,
        currency: 'RUB',
        dueDate: preliminaryBooking.eventDate.subtract(const Duration(days: 1)),
        isPrepayment: prepayment != null && prepayment > 0,
        isFinalPayment: false,
        prepaymentPaid: false,
        vkPlaylistUrl: null,
      );

      // Сохраняем бронирование
      final bookingDocRef =
          await _firestore.collection('bookings').add(booking.toMap());

      // Обновляем статус предварительного бронирования
      await _firestore
          .collection('preliminary_bookings')
          .doc(preliminaryBookingId)
          .update({
        'status': PreliminaryBookingStatus.confirmed.name,
        'confirmedAt': Timestamp.fromDate(DateTime.now()),
        'bookingId': bookingDocRef.id,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Отправляем уведомление заказчику
      await _notifyCustomer(
          bookingDocRef.id, preliminaryBooking.customerId, specialistId);

      return booking.copyWith(id: bookingDocRef.id);
    } catch (e) {
      throw Exception('Ошибка подтверждения бронирования: $e');
    }
  }

  /// Отклонить предварительное бронирование
  Future<void> rejectPreliminaryBooking({
    required String preliminaryBookingId,
    required String specialistId,
    required String reason,
  }) async {
    try {
      final preliminaryBooking =
          await _getPreliminaryBooking(preliminaryBookingId);
      if (preliminaryBooking == null) {
        throw Exception('Предварительное бронирование не найдено');
      }

      if (preliminaryBooking.specialistId != specialistId) {
        throw Exception('Недостаточно прав для отклонения бронирования');
      }

      await _firestore
          .collection('preliminary_bookings')
          .doc(preliminaryBookingId)
          .update({
        'status': PreliminaryBookingStatus.rejected.name,
        'rejectedAt': Timestamp.fromDate(DateTime.now()),
        'rejectionReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Отправляем уведомление заказчику
      await _notifyCustomerRejection(
          preliminaryBooking.customerId, specialistId, reason);
    } catch (e) {
      throw Exception('Ошибка отклонения бронирования: $e');
    }
  }

  /// Отменить предварительное бронирование заказчиком
  Future<void> cancelPreliminaryBooking({
    required String preliminaryBookingId,
    required String customerId,
    String? reason,
  }) async {
    try {
      final preliminaryBooking =
          await _getPreliminaryBooking(preliminaryBookingId);
      if (preliminaryBooking == null) {
        throw Exception('Предварительное бронирование не найдено');
      }

      if (preliminaryBooking.customerId != customerId) {
        throw Exception('Недостаточно прав для отмены бронирования');
      }

      if (preliminaryBooking.status != PreliminaryBookingStatus.pending) {
        throw Exception('Бронирование уже обработано');
      }

      await _firestore
          .collection('preliminary_bookings')
          .doc(preliminaryBookingId)
          .update({
        'status': PreliminaryBookingStatus.cancelled.name,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'cancellationReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Отправляем уведомление специалисту
      await _notifySpecialistCancellation(
          preliminaryBooking.specialistId, customerId, reason);
    } catch (e) {
      throw Exception('Ошибка отмены бронирования: $e');
    }
  }

  /// Получить предварительные бронирования специалиста
  Future<List<PreliminaryBooking>> getSpecialistPreliminaryBookings(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('preliminary_bookings')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PreliminaryBooking.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения предварительных бронирований: $e');
    }
  }

  /// Получить предварительные бронирования заказчика
  Future<List<PreliminaryBooking>> getCustomerPreliminaryBookings(
      String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('preliminary_bookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PreliminaryBooking.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения предварительных бронирований: $e');
    }
  }

  /// Получить предварительное бронирование по ID
  Future<PreliminaryBooking?> getPreliminaryBooking(
      String preliminaryBookingId) async {
    return await _getPreliminaryBooking(preliminaryBookingId);
  }

  // Приватные методы

  Future<PreliminaryBooking?> _getPreliminaryBooking(
      String preliminaryBookingId) async {
    try {
      final doc = await _firestore
          .collection('preliminary_bookings')
          .doc(preliminaryBookingId)
          .get();
      if (doc.exists) {
        return PreliminaryBooking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _checkSpecialistAvailability({
    required String specialistId,
    required DateTime eventDate,
    required Duration duration,
  }) async {
    try {
      // TODO: Интегрировать с SpecialistScheduleService
      // Пока возвращаем true
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _notifySpecialist(String preliminaryBookingId,
      String specialistId, String customerId) async {
    try {
      // TODO: Отправить push-уведомление специалисту
      // TODO: Отправить email уведомление
    } catch (e) {
      // Игнорируем ошибки уведомлений
    }
  }

  Future<void> _notifyCustomer(
      String bookingId, String customerId, String specialistId) async {
    try {
      // TODO: Отправить push-уведомление заказчику
      // TODO: Отправить email уведомление
    } catch (e) {
      // Игнорируем ошибки уведомлений
    }
  }

  Future<void> _notifyCustomerRejection(
      String customerId, String specialistId, String reason) async {
    try {
      // TODO: Отправить push-уведомление заказчику об отклонении
      // TODO: Отправить email уведомление
    } catch (e) {
      // Игнорируем ошибки уведомлений
    }
  }

  Future<void> _notifySpecialistCancellation(
      String specialistId, String customerId, String? reason) async {
    try {
      // TODO: Отправить push-уведомление специалисту об отмене
      // TODO: Отправить email уведомление
    } catch (e) {
      // Игнорируем ошибки уведомлений
    }
  }
}

/// Модель предварительного бронирования
class PreliminaryBooking {
  final String id;
  final String specialistId;
  final String customerId;
  final DateTime eventDate;
  final Duration duration;
  final String eventTitle;
  final String eventDescription;
  final int participantsCount;
  final String? eventLocation;
  final String? specialRequests;
  final PreliminaryBookingStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final Map<String, dynamic> metadata;

  const PreliminaryBooking({
    required this.id,
    required this.specialistId,
    required this.customerId,
    required this.eventDate,
    required this.duration,
    required this.eventTitle,
    required this.eventDescription,
    required this.participantsCount,
    this.eventLocation,
    this.specialRequests,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.cancelledAt,
    required this.metadata,
  });

  /// Создать из документа Firestore
  factory PreliminaryBooking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PreliminaryBooking(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      customerId: data['customerId'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      duration:
          Duration(seconds: data['duration'] ?? 7200), // 2 часа по умолчанию
      eventTitle: data['eventTitle'] ?? '',
      eventDescription: data['eventDescription'] ?? '',
      participantsCount: data['participantsCount'] ?? 1,
      eventLocation: data['eventLocation'],
      specialRequests: data['specialRequests'],
      status: PreliminaryBookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PreliminaryBookingStatus.pending,
      ),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      confirmedAt: data['confirmedAt'] != null
          ? (data['confirmedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'customerId': customerId,
      'eventDate': Timestamp.fromDate(eventDate),
      'duration': duration.inSeconds,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'participantsCount': participantsCount,
      'eventLocation': eventLocation,
      'specialRequests': specialRequests,
      'status': status.name,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'metadata': metadata,
    };
  }

  /// Создать копию с изменениями
  PreliminaryBooking copyWith({
    String? id,
    String? specialistId,
    String? customerId,
    DateTime? eventDate,
    Duration? duration,
    String? eventTitle,
    String? eventDescription,
    int? participantsCount,
    String? eventLocation,
    String? specialRequests,
    PreliminaryBookingStatus? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    Map<String, dynamic>? metadata,
  }) {
    return PreliminaryBooking(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      customerId: customerId ?? this.customerId,
      eventDate: eventDate ?? this.eventDate,
      duration: duration ?? this.duration,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDescription: eventDescription ?? this.eventDescription,
      participantsCount: participantsCount ?? this.participantsCount,
      eventLocation: eventLocation ?? this.eventLocation,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Статусы предварительного бронирования
enum PreliminaryBookingStatus {
  pending, // Ожидает подтверждения
  confirmed, // Подтверждено
  rejected, // Отклонено
  cancelled, // Отменено заказчиком
  expired, // Истекло время подтверждения
}
