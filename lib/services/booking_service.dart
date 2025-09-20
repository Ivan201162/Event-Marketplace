import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/event.dart';
import 'notification_service.dart';

/// Сервис для работы с бронированиями
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Отправить уведомление о изменении статуса заявки
  Future<void> _sendStatusChangeNotification(
    Booking booking,
    BookingStatus oldStatus,
  ) async {
    if (booking.status == oldStatus) return;

    final statusMessages = {
      BookingStatus.pending: 'Ваша заявка ожидает подтверждения',
      BookingStatus.confirmed: 'Ваша заявка подтверждена!',
      BookingStatus.cancelled: 'Ваша заявка отменена',
      BookingStatus.completed: 'Ваша заявка завершена',
      BookingStatus.rejected: 'Ваша заявка отклонена',
    };

    final message = statusMessages[booking.status] ?? 'Статус заявки изменен';

    // Уведомление заказчику
    await _notificationService.sendNotification(
      userId: booking.userId,
      title: 'Статус заявки изменен',
      body: message,
      type: 'booking_status_changed',
      data: {
        'bookingId': booking.id,
        'eventId': booking.eventId,
        'status': booking.status.name,
      },
    );

    // Уведомление специалисту (если есть)
    if (booking.specialistId != null) {
      await _notificationService.sendNotification(
        userId: booking.specialistId!,
        title: 'Статус заявки изменен',
        body: 'Заявка "${booking.eventTitle}" - ${message.toLowerCase()}',
        type: 'booking_status_changed',
        data: {
          'bookingId': booking.id,
          'eventId': booking.eventId,
          'status': booking.status.name,
        },
      );
    }
  }

  /// Создать новое бронирование
  Future<String> createBooking(
    Booking booking, {
    Duration confirmationTimeout = const Duration(hours: 24),
  }) async {
    try {
      // Проверяем, есть ли свободные места
      final eventDoc =
          await _firestore.collection('events').doc(booking.eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Событие не найдено');
      }

      final event = Event.fromDocument(eventDoc);
      if (event.currentParticipants + booking.participantsCount >
          event.maxParticipants) {
        throw Exception('Недостаточно свободных мест');
      }

      // Устанавливаем время истечения подтверждения
      final expiresAt = DateTime.now().add(confirmationTimeout);
      final bookingWithExpiry = booking.copyWith(expiresAt: expiresAt);

      // Создаем бронирование
      final docRef = await _firestore
          .collection('bookings')
          .add(bookingWithExpiry.toMap());

      // Обновляем количество участников в событии
      await _firestore.collection('events').doc(booking.eventId).update({
        'currentParticipants': FieldValue.increment(booking.participantsCount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Отправляем уведомление организатору
      await _notificationService.sendBookingNotification(
        userId: booking.organizerId ?? booking.specialistId ?? '',
        eventTitle: booking.eventTitle,
        specialistName: booking.specialistName ?? booking.organizerName ?? '',
        bookingDate: booking.bookingDate,
        channel: NotificationChannel.push,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания бронирования: $e');
    }
  }

  /// Получить бронирования пользователя
  Stream<List<Booking>> getUserBookings(String userId) => _firestore
      .collection('bookings')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
      );

  /// Получить бронирования для события
  Stream<List<Booking>> getEventBookings(String eventId) => _firestore
      .collection('bookings')
      .where('eventId', isEqualTo: eventId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
      );

  /// Получить бронирование по ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения бронирования: $e');
    }
  }

  /// Обновить статус бронирования
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      final oldStatus = booking.status;

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Если бронирование отменяется, уменьшаем количество участников
      if (status == BookingStatus.cancelled &&
          booking.status != BookingStatus.cancelled) {
        await _firestore.collection('events').doc(booking.eventId).update({
          'currentParticipants':
              FieldValue.increment(-booking.participantsCount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Отправляем уведомление об отмене
        await _notificationService.sendCancellationNotification(
          userId: booking.organizerId ?? booking.specialistId ?? '',
          eventTitle: booking.eventTitle,
          specialistName: booking.specialistName ?? booking.organizerName ?? '',
          bookingDate: booking.bookingDate,
          channel: NotificationChannel.push,
        );
      }

      // Отправляем уведомления о изменении статуса
      final updatedBooking = booking.copyWith(status: status);
      await _sendStatusChangeNotification(updatedBooking, oldStatus);
    } catch (e) {
      throw Exception('Ошибка обновления статуса бронирования: $e');
    }
  }

  /// Отменить бронирование
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  /// Подтвердить бронирование
  Future<void> confirmBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.confirmed);
  }

  /// Завершить бронирование
  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.completed);
  }

  /// Удалить бронирование
  Future<void> deleteBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      // Если бронирование не отменено, уменьшаем количество участников
      if (booking.status != BookingStatus.cancelled) {
        await _firestore.collection('events').doc(booking.eventId).update({
          'currentParticipants':
              FieldValue.increment(-booking.participantsCount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления бронирования: $e');
    }
  }

  /// Проверить, забронировал ли пользователь событие
  Future<bool> hasUserBookedEvent(String userId, String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Ошибка проверки бронирования: $e');
    }
  }

  /// Проверить и обновить истекшие бронирования
  Future<void> checkExpiredBookings() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in snapshot.docs) {
        final booking = Booking.fromDocument(doc);

        // Отменяем истекшее бронирование
        await updateBookingStatus(
          booking.id,
          BookingStatus.cancelled,
        );

        // Отправляем уведомление пользователю
        await _notificationService.sendNotification(
          userId: booking.userId,
          title: 'Бронирование отменено',
          body:
              'Время подтверждения бронирования "${booking.eventTitle}" истекло',
          type: 'booking_expired',
          data: {
            'bookingId': booking.id,
            'eventId': booking.eventId,
          },
        );
      }
    } catch (e) {
      throw Exception('Ошибка проверки истекших бронирований: $e');
    }
  }

  /// Получить время до истечения подтверждения
  Duration? getTimeUntilExpiry(Booking booking) {
    if (booking.expiresAt == null) return null;

    final now = DateTime.now();
    final expiry = booking.expiresAt!;

    if (now.isAfter(expiry)) return null;

    return expiry.difference(now);
  }

  /// Получить статистику бронирований пользователя
  Future<Map<String, int>> getUserBookingStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      var total = 0;
      var pending = 0;
      var confirmed = 0;
      var cancelled = 0;
      var completed = 0;

      for (final doc in snapshot.docs) {
        final booking = Booking.fromDocument(doc);
        total++;

        switch (booking.status) {
          case BookingStatus.pending:
            pending++;
            break;
          case BookingStatus.confirmed:
            confirmed++;
            break;
          case BookingStatus.cancelled:
            cancelled++;
            break;
          case BookingStatus.completed:
            completed++;
            break;
          case BookingStatus.rejected:
            cancelled++; // Отклоненные считаем как отмененные
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'confirmed': confirmed,
        'cancelled': cancelled,
        'completed': completed,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики бронирований: $e');
    }
  }

  /// Получить статистику бронирований для события
  Future<Map<String, int>> getEventBookingStats(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('eventId', isEqualTo: eventId)
          .get();

      var total = 0;
      var pending = 0;
      var confirmed = 0;
      var cancelled = 0;
      var completed = 0;
      var totalParticipants = 0;

      for (final doc in snapshot.docs) {
        final booking = Booking.fromDocument(doc);
        total++;
        totalParticipants += booking.participantsCount;

        switch (booking.status) {
          case BookingStatus.pending:
            pending++;
            break;
          case BookingStatus.confirmed:
            confirmed++;
            break;
          case BookingStatus.cancelled:
            cancelled++;
            break;
          case BookingStatus.completed:
            completed++;
            break;
          case BookingStatus.rejected:
            cancelled++; // Отклоненные считаем как отмененные
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'confirmed': confirmed,
        'cancelled': cancelled,
        'completed': completed,
        'totalParticipants': totalParticipants,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики бронирований события: $e');
    }
  }

  /// Получить бронирования для специалиста
  Stream<List<Booking>> getBookingsForSpecialist(String specialistId) => _firestore
      .collection('bookings')
      .where('specialistId', isEqualTo: specialistId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
      );

  /// Добавить или обновить бронирование
  Future<void> addBooking(Booking booking) async {
    try {
      await _firestore.collection('bookings').doc(booking.id).set(booking.toMap());
    } catch (e) {
      throw Exception('Ошибка добавления бронирования: $e');
    }
  }
}
