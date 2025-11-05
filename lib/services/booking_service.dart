import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/services/chat_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Service for managing bookings (Stage 7+8)
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  /// Создать бронирование
  /// Если у специалиста autoAcceptBookings == true, сразу принимает заявку
  Future<String> createBooking({
    required String specialistId,
    required String clientId,
    required String requestedDate, // YYYY-MM-DD
    String? timeFrom, // HH:mm
    String? timeTo, // HH:mm
    String? durationOption, // '4h'|'5h'|'6h'|'custom'
    required String eventType,
    String? message,
  }) async {
    try {
      // Проверяем autoAcceptBookings
      final userDoc = await _firestore.collection('users').doc(specialistId).get();
      final autoAccept = (userDoc.data()?['autoAcceptBookings'] as bool?) ?? false;

      // Создаём или получаем чат
      final chatId = await _chatService.getOrCreatePrivateChat(clientId, specialistId);

      // Формируем стартовое сообщение
      final timeStr = _formatTimeString(timeFrom, timeTo, durationOption);
      final dateStr = DateFormat('d MMMM yyyy', 'ru').format(DateTime.parse(requestedDate));
      final initialMessage = 'Здравствуйте, хочу заказать у вас $eventType на $dateStr${timeStr.isNotEmpty ? ' с $timeStr' : ''}${message != null && message.isNotEmpty ? '. $message' : ''}';

      // Определяем начальный статус
      final initialStatus = autoAccept ? BookingStatus.accepted : BookingStatus.pending;

      // Создаём документ бронирования
      final bookingData = {
        'specialistId': specialistId,
        'clientId': clientId,
        'requestedDate': requestedDate,
        'timeFrom': timeFrom,
        'timeTo': timeTo,
        'durationOption': durationOption,
        'eventType': eventType,
        'message': message,
        'status': initialStatus.value,
        'chatId': chatId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final bookingRef = await _firestore.collection('bookings').add(bookingData);
      final bookingId = bookingRef.id;

      debugLog("BOOKING_CREATE:$bookingId");

      // Отправляем стартовое сообщение в чат
      await _sendInitialBookingMessage(chatId, {
        'eventType': eventType,
        'date': dateStr,
        'time': timeStr,
        'message': message,
      });

      // Обновляем календарь специалиста
      if (autoAccept) {
        // Если авто-принятие, сразу помечаем день как занятый
        await _updateSpecialistCalendar(specialistId, requestedDate, 'accept', bookingId);
        await _chatService.addSystemMessage(chatId, '✅ Заявка подтверждена автоматически');
        debugLog("AUTO_ACCEPT:ON");
      } else {
        // Иначе увеличиваем pendingCount
        await _updateSpecialistCalendar(specialistId, requestedDate, 'pending', null);
        debugLog("AUTO_ACCEPT:OFF");
      }

      // Логируем push-уведомление
      debugLog("PUSH:booking_created:${specialistId}:{\"bookingId\":\"$bookingId\",\"date\":\"$requestedDate\"}");

      return bookingId;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      debugLog("BOOKING_ERR:create:$e");
      rethrow;
    }
  }

  /// Принять бронирование
  /// Транзакция: проверяем, что день свободен, затем принимаем
  Future<void> acceptBooking(String bookingId) async {
    try {
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');

      final booking = Booking.fromFirestore(bookingDoc);
      if (booking.status != BookingStatus.pending) {
        throw Exception('Booking is not pending');
      }

      await _firestore.runTransaction((transaction) async {
        // Проверяем календарь специалиста
        final calendarRef = _firestore
            .collection('specialist_calendar')
            .doc(booking.specialistId)
            .collection('days')
            .doc(booking.requestedDate);

        final calendarDoc = await transaction.get(calendarRef);
        final calendarData = calendarDoc.data();

        // Если уже есть acceptedBookingId, бросаем ошибку
        if (calendarData != null && calendarData['acceptedBookingId'] != null) {
          throw Exception('Date already booked');
        }

        // Обновляем бронирование
        transaction.update(
          _firestore.collection('bookings').doc(bookingId),
          {
            'status': BookingStatus.accepted.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Обновляем календарь
        final pendingCount = (calendarData?['pendingCount'] as num?)?.toInt() ?? 0;
        transaction.set(calendarRef, {
          'acceptedBookingId': bookingId,
          'pendingCount': (pendingCount - 1).clamp(0, 999),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // Отправляем системное сообщение
      if (booking.chatId != null) {
        await _chatService.addSystemMessage(booking.chatId!, '✅ Заявка одобрена');
      }

      // Отклоняем остальные pending на эту дату
      await _declineOtherPendingBookings(booking.specialistId, booking.requestedDate, bookingId);

      debugLog("BOOKING_ACCEPT:$bookingId");
      debugLog("PUSH:booking_accepted:${booking.clientId}:{\"bookingId\":\"$bookingId\"}");
    } catch (e) {
      debugPrint('Error accepting booking: $e');
      debugLog("BOOKING_ERR:accept:$e");
      rethrow;
    }
  }

  /// Отклонить бронирование
  Future<void> declineBooking(String bookingId, {String? reason}) async {
    try {
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');

      final booking = Booking.fromFirestore(bookingDoc);

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.declined.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Уменьшаем pendingCount в календаре
      await _updateSpecialistCalendar(booking.specialistId, booking.requestedDate, 'decline', null);

      // Отправляем системное сообщение
      if (booking.chatId != null) {
        final message = reason != null ? '❌ Заявка отклонена. Причина: $reason' : '❌ Заявка отклонена';
        await _chatService.addSystemMessage(booking.chatId!, message);
      }

      debugLog("BOOKING_DECLINE:$bookingId");
      debugLog("PUSH:booking_declined:${booking.clientId}:{\"bookingId\":\"$bookingId\"}");
    } catch (e) {
      debugPrint('Error declining booking: $e');
      debugLog("BOOKING_ERR:decline:$e");
      rethrow;
    }
  }

  /// Отменить бронирование (клиент)
  Future<void> cancelBooking(String bookingId) async {
    try {
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');

      final booking = Booking.fromFirestore(bookingDoc);

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Если это была принятая заявка, освобождаем день
      if (booking.status == BookingStatus.accepted) {
        await _updateSpecialistCalendar(booking.specialistId, booking.requestedDate, 'cancel', bookingId);
      } else {
        // Иначе просто уменьшаем pendingCount
        await _updateSpecialistCalendar(booking.specialistId, booking.requestedDate, 'decline', null);
      }

      // Отправляем системное сообщение
      if (booking.chatId != null) {
        await _chatService.addSystemMessage(booking.chatId!, '🚫 Клиент отменил заявку');
      }

      debugLog("BOOKING_CANCEL:$bookingId");
      debugLog("PUSH:booking_cancelled:${booking.specialistId}:{\"bookingId\":\"$bookingId\"}");
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      debugLog("BOOKING_ERR:cancel:$e");
      rethrow;
    }
  }

  /// Поток заявок на конкретный день специалиста
  Stream<List<Booking>> watchBookingsBySpecialistDay(String specialistId, String dayId) {
    return _firestore
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('requestedDate', isEqualTo: dayId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Booking.fromFirestore).toList());
  }

  /// Получить заявку по ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting booking: $e');
      return null;
    }
  }

  /// Получить или создать чат (алиас для совместимости)
  Future<String> ensureChat(String clientId, String specialistId) async {
    return await _chatService.getOrCreatePrivateChat(clientId, specialistId);
  }

  /// Отправить стартовое сообщение о бронировании
  Future<void> sendInitialBookingMessage(String chatId, Map<String, dynamic> payload) async {
    await _sendInitialBookingMessage(chatId, payload);
  }

  /// Подтвердить бронирование (алиас для acceptBooking)
  Future<void> confirmBooking(String bookingId) async {
    await acceptBooking(bookingId);
  }

  /// Отклонить бронирование (алиас для declineBooking)
  Future<void> rejectBooking(String bookingId) async {
    await declineBooking(bookingId);
  }

  /// Получить политику календаря (алиас для getAutoAcceptBookings)
  Future<String> getCalendarPolicy(String specialistId) async {
    final autoAccept = await getAutoAcceptBookings(specialistId);
    return autoAccept ? 'auto' : 'manual';
  }

  /// Установить политику календаря (алиас для setAutoAcceptBookings)
  Future<void> setCalendarPolicy(String specialistId, String policy) async {
    await setAutoAcceptBookings(specialistId, policy == 'auto');
  }

  /// Получить заявки на день (для совместимости)
  Future<List<Booking>> getBookingsForDate(String specialistId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final snapshot = await _firestore
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('requestedDate', isEqualTo: dateStr)
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(Booking.fromFirestore).toList();
  }

  /// Поток заявок на день (для совместимости)
  Stream<List<Booking>> bookingsForDay(String specialistId, DateTime day) {
    final dayId = DateFormat('yyyy-MM-dd').format(day);
    return watchBookingsBySpecialistDay(specialistId, dayId);
  }

  /// Получить настройку autoAcceptBookings специалиста
  Future<bool> getAutoAcceptBookings(String specialistId) async {
    try {
      final doc = await _firestore.collection('users').doc(specialistId).get();
      return (doc.data()?['autoAcceptBookings'] as bool?) ?? false;
    } catch (e) {
      debugPrint('Error getting autoAcceptBookings: $e');
      return false;
    }
  }

  /// Установить autoAcceptBookings
  Future<void> setAutoAcceptBookings(String specialistId, bool value) async {
    try {
      await _firestore.collection('users').doc(specialistId).set(
        {'autoAcceptBookings': value},
        SetOptions(merge: true),
      );
      debugLog("AUTO_ACCEPT:${value ? 'ON' : 'OFF'}");
    } catch (e) {
      debugPrint('Error setting autoAcceptBookings: $e');
      rethrow;
    }
  }

  /// Получить метаданные дня календаря специалиста
  Future<Map<String, dynamic>> getCalendarDayMeta(String specialistId, String dayId) async {
    try {
      final doc = await _firestore
          .collection('specialist_calendar')
          .doc(specialistId)
          .collection('days')
          .doc(dayId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'acceptedBookingId': data['acceptedBookingId'] as String?,
          'pendingCount': (data['pendingCount'] as num?)?.toInt() ?? 0,
        };
      }
      return {
        'acceptedBookingId': null,
        'pendingCount': 0,
      };
    } catch (e) {
      debugPrint('Error getting calendar day meta: $e');
      return {
        'acceptedBookingId': null,
        'pendingCount': 0,
      };
    }
  }

  /// Получить ближайшие свободные дни специалиста
  Future<List<String>> getNextAvailableDays(String specialistId, {int count = 7}) async {
    try {
      final today = DateTime.now();
      final availableDays = <String>[];

      for (int i = 0; i < 30 && availableDays.length < count; i++) {
        final checkDate = today.add(Duration(days: i));
        final dayId = DateFormat('yyyy-MM-dd').format(checkDate);

        final meta = await getCalendarDayMeta(specialistId, dayId);
        if (meta['acceptedBookingId'] == null && (meta['pendingCount'] as int) == 0) {
          availableDays.add(dayId);
        }
      }

      return availableDays;
    } catch (e) {
      debugPrint('Error getting next available days: $e');
      return [];
    }
  }

  /// Получить количество подтвержденных заказов специалиста
  Future<int> getConfirmedBookingsCount(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.accepted.value)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting confirmed bookings count: $e');
      return 0;
    }
  }

  // Приватные методы

  /// Обновить календарь специалиста
  Future<void> _updateSpecialistCalendar(
    String specialistId,
    String dayId,
    String action, // 'pending', 'accept', 'decline', 'cancel'
    String? bookingId,
  ) async {
    final calendarRef = _firestore
        .collection('specialist_calendar')
        .doc(specialistId)
        .collection('days')
        .doc(dayId);

    try {
      await _firestore.runTransaction((transaction) async {
        final calendarDoc = await transaction.get(calendarRef);
        final calendarData = calendarDoc.data();

        int pendingCount = (calendarData?['pendingCount'] as num?)?.toInt() ?? 0;
        String? acceptedBookingId = calendarData?['acceptedBookingId'] as String?;

        if (action == 'pending') {
          pendingCount++;
        } else if (action == 'accept') {
          acceptedBookingId = bookingId;
          pendingCount = (pendingCount - 1).clamp(0, 999);
        } else if (action == 'decline') {
          pendingCount = (pendingCount - 1).clamp(0, 999);
        } else if (action == 'cancel') {
          acceptedBookingId = null;
          // pendingCount не меняем при отмене принятой заявки
        }

        transaction.set(calendarRef, {
          'acceptedBookingId': acceptedBookingId,
          'pendingCount': pendingCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Логируем после транзакции
        final finalPendingCount = acceptedBookingId != null ? 0 : pendingCount;
        debugLog("CAL_DAY_META:$finalPendingCount:${action == 'accept'}");
      });
    } catch (e) {
      debugPrint('Error updating specialist calendar: $e');
      debugLog("BOOKING_ERR:update_calendar:$e");
    }
  }

  /// Отклонить остальные pending заявки на дату
  Future<void> _declineOtherPendingBookings(String specialistId, String dayId, String excludeBookingId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('requestedDate', isEqualTo: dayId)
          .where('status', isEqualTo: BookingStatus.pending.value)
          .get();

      for (final doc in snapshot.docs) {
        if (doc.id != excludeBookingId) {
          await declineBooking(doc.id);
        }
      }
    } catch (e) {
      debugPrint('Error declining other pending bookings: $e');
    }
  }

  /// Отправить стартовое сообщение о бронировании
  Future<void> _sendInitialBookingMessage(String chatId, Map<String, dynamic> payload) async {
    final eventType = payload['eventType'] as String? ?? 'мероприятие';
    final date = payload['date'] as String? ?? '';
    final time = payload['time'] as String? ?? '';
    final message = payload['message'] as String?;

    String text = 'Здравствуйте, хочу заказать у вас $eventType на $date';
    if (time.isNotEmpty) {
      text += ' с $time';
    }
    if (message != null && message.isNotEmpty) {
      text += '. $message';
    }

    await _chatService.addSystemMessage(chatId, text);
  }

  /// Форматировать строку времени
  String _formatTimeString(String? timeFrom, String? timeTo, String? durationOption) {
    if (timeFrom != null && timeTo != null) {
      return '$timeFrom до $timeTo';
    }
    if (durationOption != null) {
      switch (durationOption) {
        case '4h':
          return '4 часа';
        case '5h':
          return '5 часов';
        case '6h':
          return '6 часов';
        case 'custom':
          return 'индивидуально';
        default:
          return '';
      }
    }
    return '';
  }
}






