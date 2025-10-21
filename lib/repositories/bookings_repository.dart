import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Репозиторий для работы с заявками в Firestore
class BookingsRepository {
  factory BookingsRepository() => _instance;
  BookingsRepository._internal();
  static final BookingsRepository _instance = BookingsRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получение заявок клиента
  Stream<List<Map<String, dynamic>>> getCustomerBookings(String customerId) {
    try {
      debugPrint('BookingsRepository.getCustomerBookings: customerId=$customerId');

      return _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            debugPrint(
              'BookingsRepository.getCustomerBookings: получено ${snapshot.docs.length} заявок',
            );

            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return {'id': doc.id, ...data};
            }).toList();
          });
    } catch (e) {
      debugPrint('BookingsRepository.getCustomerBookings: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение заявок специалиста
  Stream<List<Map<String, dynamic>>> getSpecialistBookings(String specialistId) {
    try {
      debugPrint('BookingsRepository.getSpecialistBookings: specialistId=$specialistId');

      return _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            debugPrint(
              'BookingsRepository.getSpecialistBookings: получено ${snapshot.docs.length} заявок',
            );

            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return {'id': doc.id, ...data};
            }).toList();
          });
    } catch (e) {
      debugPrint('BookingsRepository.getSpecialistBookings: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение всех заявок (для админов)
  Stream<List<Map<String, dynamic>>> getAllBookings() {
    try {
      debugPrint('BookingsRepository.getAllBookings: получение всех заявок');

      return _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            debugPrint(
              'BookingsRepository.getAllBookings: получено ${snapshot.docs.length} заявок',
            );

            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return {'id': doc.id, ...data};
            }).toList();
          });
    } catch (e) {
      debugPrint('BookingsRepository.getAllBookings: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение конкретной заявки
  Future<Map<String, dynamic>?> getById(String bookingId) async {
    try {
      debugPrint('BookingsRepository.getById: bookingId=$bookingId');

      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        debugPrint('BookingsRepository.getById: заявка найдена, поля: ${data.keys.toList()}');
        return {'id': doc.id, ...data};
      }
      debugPrint('BookingsRepository.getById: заявка не найдена');
      return null;
    } catch (e) {
      debugPrint('BookingsRepository.getById: ошибка получения заявки: $e');
      return null;
    }
  }

  /// Создание новой заявки
  Future<String?> create(Map<String, dynamic> bookingData) async {
    try {
      debugPrint(
        'BookingsRepository.create: создание заявки с данными: ${bookingData.keys.toList()}',
      );

      final docRef = await _firestore.collection('bookings').add(bookingData);
      debugPrint('BookingsRepository.create: заявка создана с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('BookingsRepository.create: ошибка создания заявки: $e');
      return null;
    }
  }

  /// Обновление заявки
  Future<bool> update(String bookingId, Map<String, dynamic> updates) async {
    try {
      debugPrint(
        'BookingsRepository.update: обновление заявки $bookingId с полями: ${updates.keys.toList()}',
      );

      await _firestore.collection('bookings').doc(bookingId).update(updates);
      debugPrint('BookingsRepository.update: заявка обновлена успешно');
      return true;
    } catch (e) {
      debugPrint('BookingsRepository.update: ошибка обновления заявки: $e');
      return false;
    }
  }

  /// Удаление заявки
  Future<bool> delete(String bookingId) async {
    try {
      debugPrint('BookingsRepository.delete: удаление заявки $bookingId');

      await _firestore.collection('bookings').doc(bookingId).delete();
      debugPrint('BookingsRepository.delete: заявка удалена успешно');
      return true;
    } catch (e) {
      debugPrint('BookingsRepository.delete: ошибка удаления заявки: $e');
      return false;
    }
  }

  /// Обновление статуса заявки
  Future<bool> updateStatus(String bookingId, String status, {String? notes}) async {
    try {
      debugPrint(
        'BookingsRepository.updateStatus: обновление статуса заявки $bookingId на $status',
      );

      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updates);
      debugPrint('BookingsRepository.updateStatus: статус заявки обновлен успешно');
      return true;
    } catch (e) {
      debugPrint('BookingsRepository.updateStatus: ошибка обновления статуса: $e');
      return false;
    }
  }

  /// Получение заявок по статусу
  Stream<List<Map<String, dynamic>>> getBookingsByStatus(String status) {
    try {
      debugPrint('BookingsRepository.getBookingsByStatus: status=$status');

      return _firestore
          .collection('bookings')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            debugPrint(
              'BookingsRepository.getBookingsByStatus: получено ${snapshot.docs.length} заявок',
            );

            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return {'id': doc.id, ...data};
            }).toList();
          });
    } catch (e) {
      debugPrint('BookingsRepository.getBookingsByStatus: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение заявок по дате события
  Stream<List<Map<String, dynamic>>> getBookingsByEventDate(DateTime eventDate) {
    try {
      debugPrint('BookingsRepository.getBookingsByEventDate: eventDate=$eventDate');

      final startOfDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      final endOfDay = DateTime(eventDate.year, eventDate.month, eventDate.day, 23, 59, 59);

      return _firestore
          .collection('bookings')
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('eventDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
            debugPrint(
              'BookingsRepository.getBookingsByEventDate: получено ${snapshot.docs.length} заявок',
            );

            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return {'id': doc.id, ...data};
            }).toList();
          });
    } catch (e) {
      debugPrint('BookingsRepository.getBookingsByEventDate: ошибка запроса: $e');
      return Stream.value([]);
    }
  }
}
