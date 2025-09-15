import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/event.dart';
import 'notification_service.dart';

/// Сервис для работы с бронированиями
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Создать новое бронирование
  Future<String> createBooking(Booking booking) async {
    try {
      // Проверяем, есть ли свободные места
      final eventDoc = await _firestore.collection('events').doc(booking.eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Событие не найдено');
      }

      final event = Event.fromDocument(eventDoc);
      if (event.currentParticipants + booking.participantsCount > event.maxParticipants) {
        throw Exception('Недостаточно свободных мест');
      }

      // Создаем бронирование
      final docRef = await _firestore.collection('bookings').add(booking.toMap());
      
      // Обновляем количество участников в событии
      await _firestore.collection('events').doc(booking.eventId).update({
        'currentParticipants': FieldValue.increment(booking.participantsCount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Отправляем уведомление организатору
      await _notificationService.sendBookingNotification(
        organizerId: booking.organizerId!,
        eventTitle: booking.eventTitle,
        userName: booking.userName,
        participantsCount: booking.participantsCount,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания бронирования: $e');
    }
  }

  /// Получить бронирования пользователя
  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromDocument(doc))
            .toList());
  }

  /// Получить бронирования для события
  Stream<List<Booking>> getEventBookings(String eventId) {
    return _firestore
        .collection('bookings')
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromDocument(doc))
            .toList());
  }

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
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Бронирование не найдено');
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Если бронирование отменяется, уменьшаем количество участников
      if (status == BookingStatus.cancelled && booking.status != BookingStatus.cancelled) {
        await _firestore.collection('events').doc(booking.eventId).update({
          'currentParticipants': FieldValue.increment(-booking.participantsCount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Отправляем уведомление об отмене
        await _notificationService.sendCancellationNotification(
          organizerId: booking.organizerId!,
          eventTitle: booking.eventTitle,
          userName: booking.userName,
        );
      }
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
          'currentParticipants': FieldValue.increment(-booking.participantsCount),
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
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Ошибка проверки бронирования: $e');
    }
  }

  /// Получить статистику бронирований пользователя
  Future<Map<String, int>> getUserBookingStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      int total = 0;
      int pending = 0;
      int confirmed = 0;
      int cancelled = 0;
      int completed = 0;

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

      int total = 0;
      int pending = 0;
      int confirmed = 0;
      int cancelled = 0;
      int completed = 0;
      int totalParticipants = 0;

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
}