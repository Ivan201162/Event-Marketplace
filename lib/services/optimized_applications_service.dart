import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';

/// Оптимизированный сервис для работы с заявками
class OptimizedApplicationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэш для заявок
  Map<String, List<Booking>> _cachedBookings = {};
  Map<String, DateTime> _bookingsCacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Получить заявки пользователя с реальным временем
  Stream<List<Booking>> getUserBookingsStream(String userId, {bool isSpecialist = false}) {
    final field = isSpecialist ? 'specialistId' : 'clientId';
    
    return _firestore
        .collection('bookings')
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _parseBookingFromFirestore(doc.id, data);
      }).toList();
    });
  }

  /// Получить заявки пользователя (одноразово)
  Future<List<Booking>> getUserBookings(
    String userId, {
    bool isSpecialist = false,
    BookingStatus? status,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = '${userId}_${isSpecialist}_${status?.name ?? 'all'}';
      
      // Проверяем кэш
      if (!forceRefresh && 
          _cachedBookings.containsKey(cacheKey) &&
          _bookingsCacheTime.containsKey(cacheKey) &&
          DateTime.now().difference(_bookingsCacheTime[cacheKey]!) < _cacheExpiry) {
        return _cachedBookings[cacheKey]!;
      }

      debugPrint('📋 Загрузка заявок пользователя: $userId');

      final field = isSpecialist ? 'specialistId' : 'clientId';
      Query query = _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      
      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        return _parseBookingFromFirestore(doc.id, data);
      }).toList();

      // Обновляем кэш
      _cachedBookings[cacheKey] = bookings;
      _bookingsCacheTime[cacheKey] = DateTime.now();

      debugPrint('✅ Загружено ${bookings.length} заявок');
      return bookings;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки заявок: $e');
      return _cachedBookings[cacheKey] ?? [];
    }
  }

  /// Создать новую заявку
  Future<String?> createBooking({
    required String specialistId,
    required String specialistName,
    required String clientId,
    required String clientName,
    required String service,
    required DateTime date,
    required String time,
    required int duration,
    required int totalPrice,
    String? notes,
    String? location,
  }) async {
    try {
      final bookingData = {
        'specialistId': specialistId,
        'specialistName': specialistName,
        'clientId': clientId,
        'clientName': clientName,
        'service': service,
        'date': Timestamp.fromDate(date),
        'time': time,
        'duration': duration,
        'totalPrice': totalPrice,
        'notes': notes,
        'location': location,
        'status': BookingStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('bookings').add(bookingData);
      
      // Очищаем кэш для обновления списков
      _clearUserCache(clientId);
      _clearUserCache(specialistId);
      
      debugPrint('✅ Заявка создана с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Ошибка создания заявки: $e');
      return null;
    }
  }

  /// Обновить статус заявки
  Future<bool> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Очищаем кэш
      _clearAllCache();
      
      debugPrint('✅ Статус заявки обновлён: $status');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса заявки: $e');
      return false;
    }
  }

  /// Получить заявку по ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!doc.exists) return null;
      
      return _parseBookingFromFirestore(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('❌ Ошибка получения заявки: $e');
      return null;
    }
  }

  /// Получить статистику заявок
  Future<Map<String, int>> getBookingStats(String userId, {bool isSpecialist = false}) async {
    try {
      final field = isSpecialist ? 'specialistId' : 'clientId';
      
      final snapshot = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики заявок: $e');
      return {};
    }
  }

  /// Получить заявки по статусу
  Future<List<Booking>> getBookingsByStatus(
    String userId,
    BookingStatus status, {
    bool isSpecialist = false,
  }) async {
    try {
      final field = isSpecialist ? 'specialistId' : 'clientId';
      
      final snapshot = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _parseBookingFromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки заявок по статусу: $e');
      return [];
    }
  }

  /// Отменить заявку
  Future<bool> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearAllCache();
      
      debugPrint('✅ Заявка отменена');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отмены заявки: $e');
      return false;
    }
  }

  /// Получить информацию о специалисте для заявки
  Future<Map<String, dynamic>?> getSpecialistInfo(String specialistId) async {
    try {
      final doc = await _firestore.collection('specialists').doc(specialistId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return {
        'id': specialistId,
        'name': data['name'] ?? 'Неизвестный специалист',
        'avatar': data['avatarUrl'],
        'category': data['category'],
        'rating': data['rating']?.toDouble() ?? 0.0,
        'city': data['city'],
        'isOnline': data['isOnline'] ?? false,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения информации о специалисте: $e');
      return null;
    }
  }

  /// Парсинг заявки из Firestore
  Booking _parseBookingFromFirestore(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      service: data['service'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] ?? '',
      duration: data['duration']?.toInt() ?? 0,
      totalPrice: data['totalPrice']?.toInt() ?? 0,
      notes: data['notes'],
      location: data['location'],
      status: BookingStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Очистить кэш пользователя
  void _clearUserCache(String userId) {
    final keysToRemove = _cachedBookings.keys.where((key) => key.startsWith(userId)).toList();
    for (final key in keysToRemove) {
      _cachedBookings.remove(key);
      _bookingsCacheTime.remove(key);
    }
  }

  /// Очистить весь кэш
  void _clearAllCache() {
    _cachedBookings.clear();
    _bookingsCacheTime.clear();
  }

  /// Очистить кэш
  void clearCache() {
    _clearAllCache();
    debugPrint('🧹 Кэш заявок очищен');
  }
}
