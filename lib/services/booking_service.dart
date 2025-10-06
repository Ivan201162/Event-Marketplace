import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

/// Сервис для работы с заявками и бронированиями
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать новую заявку
  Future<String> createBooking({
    required String customerId,
    required String specialistId,
    required DateTime eventDate,
    required double totalPrice,
    required double prepayment,
    String message = '',
    String? title,
    String? location,
    String? eventTime,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? specialistName,
  }) async {
    try {
      final bookingData = {
        'customerId': customerId,
        'specialistId': specialistId,
        'eventDate': Timestamp.fromDate(eventDate),
        'totalPrice': totalPrice,
        'prepayment': prepayment,
        'status': BookingStatus.pending.name,
        'message': message,
        'title': title,
        'location': location,
        'eventTime': eventTime,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'specialistName': specialistName,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      final docRef = await _firestore.collection('bookings').add(bookingData);
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания заявки: $e');
    }
  }

  /// Обновить статус заявки
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления статуса заявки: $e');
    }
  }

  /// Обновить заявку
  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('bookings').doc(bookingId).update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления заявки: $e');
    }
  }

  /// Получить заявку по ID
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения заявки: $e');
    }
  }

  /// Получить заявки заказчика
  Stream<List<Booking>> getCustomerBookings(String customerId) => _firestore
      .collection('bookings')
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
      );

  /// Получить заявки специалиста
  Stream<List<Booking>> getSpecialistBookings(String specialistId) => _firestore
      .collection('bookings')
      .where('specialistId', isEqualTo: specialistId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
      );

  /// Получить заявки по статусу
  Stream<List<Booking>> getBookingsByStatus(BookingStatus status) => _firestore
      .collection('bookings')
      .where('status', isEqualTo: status.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
      );

  /// Получить заявки заказчика по статусу
  Stream<List<Booking>> getCustomerBookingsByStatus(
    String customerId,
    BookingStatus status,
  ) =>
      _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
          );

  /// Получить заявки специалиста по статусу
  Stream<List<Booking>> getSpecialistBookingsByStatus(
    String specialistId,
    BookingStatus status,
  ) =>
      _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
          );

  /// Удалить заявку
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления заявки: $e');
    }
  }

  /// Подтвердить заявку
  Future<void> confirmBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.confirmed);
  }

  /// Отклонить заявку
  Future<void> rejectBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.rejected);
  }

  /// Отменить заявку
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  /// Завершить заявку
  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.completed);
  }

  /// Получить статистику заявок для пользователя
  Future<Map<String, int>> getBookingStats(
    String userId, {
    bool isSpecialist = false,
  }) async {
    try {
      final field = isSpecialist ? 'specialistId' : 'customerId';
      final snapshot = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'rejected': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;

        stats['total'] = (stats['total'] ?? 0) + 1;
        if (status != null && stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Ошибка получения статистики заявок: $e');
    }
  }

  /// Проверить, есть ли конфликтующие заявки
  Future<bool> hasBookingConflict(
    String specialistId,
    DateTime eventDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('eventDate', isEqualTo: Timestamp.fromDate(eventDate))
          .where(
        'status',
        whereIn: [
          BookingStatus.pending.name,
          BookingStatus.confirmed.name,
        ],
      ).get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Ошибка проверки конфликтов заявок: $e');
    }
  }

  /// Получить заявки в определенном диапазоне дат
  Stream<List<Booking>> getBookingsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    bool isSpecialist = false,
  }) {
    final field = isSpecialist ? 'specialistId' : 'customerId';

    return _firestore
        .collection('bookings')
        .where(field, isEqualTo: userId)
        .where(
          'eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('eventDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('eventDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Booking.fromDocument).toList(),
        );
  }
}
