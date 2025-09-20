import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/safe_log.dart';
import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/calendar_event.dart';
import '../models/notification.dart';
import '../models/specialist_schedule.dart';
import 'calendar_service.dart';
import 'fcm_service.dart';
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();

  // Stream: заявки по customerId
  Stream<List<Booking>> bookingsByCustomerStream(String customerId) => _db
      .collection('bookings')
      .where('customerId', isEqualTo: customerId)
      .orderBy('eventDate', descending: false)
      .snapshots()
      .map((qs) => qs.docs.map(Booking.fromDocument).toList());

  // Stream: заявки по specialistId
  Stream<List<Booking>> bookingsBySpecialistStream(String specialistId) => _db
      .collection('bookings')
      .where('specialistId', isEqualTo: specialistId)
      .orderBy('eventDate', descending: false)
      .snapshots()
      .map((qs) => qs.docs.map(Booking.fromDocument).toList());

  // Общий стрим всех заявок (для админов/отладки)
  Stream<List<Booking>> getAllBookingsStream() => _db
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((qs) => qs.docs.map(Booking.fromDocument).toList());

  // Добавить/обновить заявку
  Future<void> addOrUpdateBooking(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toMap());
  }

  // Обновить статус
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({'status': status});
  }

  // Обновить платежный статус / аванс
  Future<void> updatePaymentStatus(
    String bookingId, {
    required bool prepaymentPaid,
    required String paymentStatus,
  }) async {
    await _db.collection('bookings').doc(bookingId).update({
      'prepaymentPaid': prepaymentPaid,
      'paymentStatus': paymentStatus,
    });
  }

  // Получить бронирования по специалисту
  Future<List<Booking>> getBookingsBySpecialist(String specialistId) async {
    final qs = await _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('eventDate', descending: false)
        .get();

    return qs.docs.map(Booking.fromDocument).toList();
  }

  // Получить бронирования по заказчику
  Future<List<Booking>> getBookingsByCustomer(String customerId) async {
    final qs = await _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('eventDate', descending: false)
        .get();

    return qs.docs.map(Booking.fromDocument).toList();
  }

  // Получить занятые даты (confirmed) для календаря
  Future<List<DateTime>> getBusyDates(String specialistId) async {
    final qs = await _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: 'confirmed')
        .get();
    return qs.docs
        .map((d) => (d.data()['eventDate'] as Timestamp).toDate())
        .toList();
  }

  // Получить занятые даты с временными интервалами
  Future<List<Map<String, dynamic>>> getBusyDateRanges(
    String specialistId,
  ) async {
    final qs = await _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    return qs.docs.map((d) {
      final data = d.data();
      return {
        'bookingId': d.id,
        'startTime': (data['eventDate'] as Timestamp).toDate(),
        'endTime': (data['endDate'] as Timestamp?)?.toDate() ??
            (data['eventDate'] as Timestamp)
                .toDate()
                .add(const Duration(hours: 2)),
        'customerId': data['customerId'],
        'title': data['title'] ?? 'Бронирование',
      };
    }).toList();
  }

  // Проверить конфликты бронирования
  Future<bool> hasBookingConflict(
    String specialistId,
    DateTime startTime,
    DateTime endTime, {
    String? excludeBookingId,
  }) async {
    final qs = await _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    for (final doc in qs.docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) continue;

      final data = doc.data();
      final existingStart = (data['eventDate'] as Timestamp).toDate();
      final existingEnd = (data['endDate'] as Timestamp?)?.toDate() ??
          existingStart.add(const Duration(hours: 2));

      // Проверяем пересечение временных интервалов
      if (startTime.isBefore(existingEnd) && endTime.isAfter(existingStart)) {
        return true; // Есть конфликт
      }
    }

    return false; // Конфликтов нет
  }

  // Добавить тестовые заявки (для локального теста)
  Future<void> addTestBookings() async {
    final now = DateTime.now();
    final b1 = Booking(
      id: 'b_test_1',
      eventId: 'e_test_1',
      eventTitle: 'Тестовое мероприятие 1',
      userId: 'u_customer1',
      userName: 'Тестовый клиент 1',
      status: BookingStatus.pending,
      bookingDate: now,
      eventDate: now.add(const Duration(days: 7)),
      participantsCount: 10,
      totalPrice: 10000,
      createdAt: now,
      updatedAt: now,
      customerId: 'u_customer1',
      specialistId: 's1',
      prepayment: 3000,
    );
    final b2 = Booking(
      id: 'b_test_2',
      eventId: 'e_test_2',
      eventTitle: 'Тестовое мероприятие 2',
      userId: 'u_customer2',
      userName: 'Тестовый клиент 2',
      status: BookingStatus.confirmed,
      bookingDate: now,
      eventDate: now.add(const Duration(days: 14)),
      participantsCount: 15,
      totalPrice: 15000,
      createdAt: now,
      updatedAt: now,
      customerId: 'u_customer2',
      specialistId: 's1',
      prepayment: 4500,
    );

    await _db.collection('bookings').doc(b1.id).set(b1.toMap());
    await _db.collection('bookings').doc(b2.id).set(b2.toMap());

    // Добавляем события в календарь
    await _calendarService.createBookingEvent(
      CalendarEvent(
        id: 'test_event_1',
        title: 'Тестовое бронирование 1',
        description: 'Тестовое бронирование 1',
        startTime: b1.eventDate,
        endTime: b1.eventDate.add(const Duration(hours: 2)),
        location: 'Тестовое место',
        specialistId: b1.specialistId ?? '',
        specialistName: b1.specialistName ?? '',
        customerId: b1.customerId ?? '',
        customerName: b1.customerName ?? '',
        bookingId: b1.id,
        status: CalendarEventStatus.confirmed,
        type: CalendarEventType.booking,
        isAllDay: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await _calendarService.createBookingEvent(
      CalendarEvent(
        id: 'test_event_2',
        title: 'Тестовое бронирование 2',
        description: 'Тестовое бронирование 2',
        startTime: b2.eventDate,
        endTime: b2.eventDate.add(const Duration(hours: 3)),
        location: 'Тестовое место',
        specialistId: b2.specialistId ?? '',
        specialistName: b2.specialistName ?? '',
        customerId: b2.customerId ?? '',
        customerName: b2.customerName ?? '',
        bookingId: b2.id,
        status: CalendarEventStatus.confirmed,
        type: CalendarEventType.booking,
        isAllDay: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Добавить/обновить заявку с интеграцией календаря
  Future<void> addOrUpdateBookingWithCalendar(Booking booking) async {
    try {
      // Определяем время окончания события
      final endTime =
          booking.endDate ?? booking.eventDate.add(const Duration(hours: 2));

      // Проверяем конфликты бронирования
      final hasConflict = await hasBookingConflict(
        booking.specialistId,
        booking.eventDate,
        endTime,
        excludeBookingId:
            booking.id, // Исключаем текущее бронирование при обновлении
      );

      if (hasConflict) {
        throw Exception('Выбранное время уже занято другим бронированием');
      }

      // Проверяем доступность через календарный сервис
      final isAvailable = await _calendarService.isDateTimeAvailable(
        booking.specialistId,
        booking.eventDate,
      );

      if (!isAvailable) {
        throw Exception(
          'Выбранная дата и время недоступны в расписании специалиста',
        );
      }

      // Сохраняем заявку
      await addOrUpdateBooking(booking);

      // Если заявка подтверждена, добавляем событие в календарь
      if (booking.status == 'confirmed') {
        await _calendarService.createBookingEvent(
          CalendarEvent(
            id: 'booking_${booking.id}',
            title: 'Бронирование мероприятия',
            description: 'Бронирование мероприятия',
            startTime: booking.eventDate,
            endTime: endTime,
            location: 'Место проведения мероприятия',
            specialistId: booking.specialistId ?? '',
            specialistName: booking.specialistName ?? '',
            customerId: booking.customerId ?? '',
            customerName: booking.customerName ?? '',
            bookingId: booking.id,
            status: CalendarEventStatus.confirmed,
            type: CalendarEventType.booking,
            isAllDay: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('Ошибка добавления заявки с календарем: $e');
      throw Exception('Не удалось создать заявку: $e');
    }
  }

  // Обновить статус заявки с интеграцией календаря и уведомлений
  Future<void> updateBookingStatusWithCalendar(
    String bookingId,
    String status,
  ) async {
    try {
      // Получаем заявку
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Заявка не найдена');
      }

      final booking = Booking.fromDocument(bookingDoc);

      // Обновляем статус
      await updateBookingStatus(bookingId, status);

      // Управляем событием в календаре
      if (status == 'confirmed') {
        // Добавляем событие в календарь
        await _calendarService.createBookingEvent(
          CalendarEvent(
            id: 'booking_${booking.id}',
            title: 'Подтвержденное бронирование',
            description: 'Подтвержденное бронирование',
            startTime: booking.eventDate,
            endTime: booking.eventDate.add(const Duration(hours: 2)),
            location: 'Место проведения мероприятия',
            specialistId: booking.specialistId ?? '',
            specialistName: booking.specialistName ?? '',
            customerId: booking.customerId ?? '',
            customerName: booking.customerName ?? '',
            bookingId: booking.id,
            status: CalendarEventStatus.confirmed,
            type: CalendarEventType.booking,
            isAllDay: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else if (status == 'rejected' || status == 'cancelled') {
        // Удаляем событие из календаря
        await _calendarService.removeBookingEvent('booking_${booking.id}');
      }

      // Отправляем уведомления
      await _sendBookingStatusNotifications(booking, status);
    } catch (e) {
      print('Ошибка обновления статуса заявки с календарем: $e');
      throw Exception('Не удалось обновить статус заявки: $e');
    }
  }

  // Проверить доступность даты для специалиста
  Future<bool> isSpecialistAvailable(
    String specialistId,
    DateTime dateTime,
  ) async =>
      _calendarService.isDateTimeAvailable(specialistId, dateTime);

  // Получить доступные временные слоты для специалиста
  Future<List<DateTime>> getAvailableTimeSlots(
    String specialistId,
    DateTime date, {
    Duration slotDuration = const Duration(hours: 1),
  }) async =>
      _calendarService.getAvailableTimeSlots(
        specialistId,
        date,
        slotDuration,
      );

  // Получить события специалиста на дату
  Future<List<ScheduleEvent>> getSpecialistEventsForDate(
    String specialistId,
    DateTime date,
  ) async =>
      await _calendarService.getEventsForDate(specialistId, date);

  // Отправить уведомления о статусе заявки
  Future<void> _sendBookingStatusNotifications(
    Booking booking,
    String status,
  ) async {
    try {
      NotificationType notificationType;
      String title;
      String body;

      switch (status) {
        case 'confirmed':
          notificationType = NotificationType.booking_confirmed;
          title = 'Заявка подтверждена!';
          body =
              'Ваша заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} подтверждена';
          break;
        case 'rejected':
          notificationType = NotificationType.booking_rejected;
          title = 'Заявка отклонена';
          body =
              'К сожалению, ваша заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} отклонена';
          break;
        case 'cancelled':
          notificationType = NotificationType.booking_cancelled;
          title = 'Заявка отменена';
          body =
              'Заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} была отменена';
          break;
        default:
          return; // Не отправляем уведомления для других статусов
      }

      // Отправляем уведомление клиенту
      await _notificationService.sendNotification(
        userId: booking.customerId!,
        title: title,
        body: body,
        type: NotificationType.booking,
        channel: NotificationChannel.push,
      );

      // Отправляем push-уведомление клиенту
      await _sendPushNotification(
        userId: booking.customerId,
        title: title,
        body: body,
        data: {
          'type': 'booking_$status',
          'bookingId': booking.id,
        },
      );

      // Отправляем уведомление специалисту (если статус изменил клиент)
      if (status == 'cancelled') {
        await _notificationService.sendNotification(
          userId: booking.specialistId!,
          title: title,
          body: body,
          type: NotificationType.booking,
          channel: NotificationChannel.push,
        );

        // Отправляем push-уведомление специалисту
        await _sendPushNotification(
          userId: booking.specialistId!,
          title: 'Заявка отменена клиентом',
          body:
              'Клиент отменил заявку на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year}',
          data: {
            'type': 'booking_cancelled',
            'bookingId': booking.id,
          },
        );
      }
    } catch (e) {
      print('Ошибка отправки уведомлений о заявке: $e');
    }
  }

  // Отправить уведомления о статусе платежа
  Future<void> _sendPaymentStatusNotifications(
    String paymentId,
    String status,
    String customerId,
    String specialistId,
  ) async {
    try {
      NotificationType notificationType;

      switch (status) {
        case 'completed':
          notificationType = NotificationType.payment_completed;
          break;
        case 'failed':
          notificationType = NotificationType.payment_failed;
          break;
        default:
          return; // Не отправляем уведомления для других статусов
      }

      // Отправляем уведомление клиенту
      await _notificationService.sendNotification(
        userId: customerId,
        title: status == 'completed' ? 'Платеж завершен' : 'Ошибка платежа',
        body: status == 'completed'
            ? 'Ваш платеж успешно обработан'
            : 'Произошла ошибка при обработке платежа',
        type: NotificationType.payment,
        channel: NotificationChannel.push,
      );

      // Отправляем уведомление специалисту
      await _notificationService.sendNotification(
        userId: specialistId,
        title: status == 'completed' ? 'Платеж получен' : 'Ошибка платежа',
        body: status == 'completed'
            ? 'Платеж от клиента успешно обработан'
            : 'Произошла ошибка при обработке платежа',
        type: NotificationType.payment,
        channel: NotificationChannel.push,
      );
    } catch (e) {
      print('Ошибка отправки уведомлений о платеже: $e');
    }
  }

  // Отправить push-уведомление
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Отправляем уведомление через FCM сервис
      await _fcmService.sendBookingNotification(
        userId: userId,
        title: title,
        body: body,
        bookingId: data?['bookingId'] ?? '',
        type: data?['type'] ?? 'booking_update',
      );
    } catch (e) {
      SafeLog.error('Ошибка отправки push-уведомления', e);
    }
  }

  // ========== ПАГИНАЦИЯ И ПОИСК ==========

  /// Получить события с пагинацией
  Future<PaginatedResult<Booking>> getBookingsPaginated({
    String? customerId,
    String? specialistId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy = 'eventDate',
    bool descending = false,
  }) async {
    try {
      var query = _db.collection('bookings');

      // Добавляем фильтры
      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      if (specialistId != null) {
        query = query.where('specialistId', isEqualTo: specialistId);
      }

      // Добавляем сортировку
      query = query.orderBy(orderBy!, descending: descending);

      // Добавляем лимит
      query = query.limit(limit);

      // Добавляем курсор пагинации
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final bookings = snapshot.docs.map(Booking.fromDocument).toList();

      SafeLog.debug('Получено ${bookings.length} бронирований с пагинацией');

      return PaginatedResult<Booking>(
        items: bookings,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e, stackTrace) {
      SafeLog.error(
        'Ошибка получения бронирований с пагинацией',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Поиск событий с debounce
  Stream<List<Booking>> searchBookingsDebounced({
    String? customerId,
    String? specialistId,
    String? searchQuery,
    Duration debounceDelay = const Duration(milliseconds: 500),
  }) {
    final controller = StreamController<List<Booking>>.broadcast();
    Timer? debounceTimer;

    void performSearch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(debounceDelay, () async {
        try {
          var query = _db.collection('bookings');

          if (customerId != null) {
            query = query.where('customerId', isEqualTo: customerId);
          }
          if (specialistId != null) {
            query = query.where('specialistId', isEqualTo: specialistId);
          }

          if (searchQuery != null && searchQuery.isNotEmpty) {
            // Простой поиск по названию события
            query = query
                .where('eventName', isGreaterThanOrEqualTo: searchQuery)
                .where(
                  'eventName',
                  isLessThanOrEqualTo: '$searchQuery\uf8ff',
                );
          }

          query = query.orderBy('eventDate', descending: true).limit(50);

          final snapshot = await query.get();
          final bookings = snapshot.docs.map(Booking.fromDocument).toList();

          SafeLog.debug(
            'Найдено ${bookings.length} бронирований по запросу "$searchQuery"',
          );
          controller.add(bookings);
        } catch (e, stackTrace) {
          SafeLog.error('Ошибка поиска бронирований', e, stackTrace);
          controller.addError(e);
        }
      });
    }

    // Выполняем поиск при первом запросе
    performSearch();

    return controller.stream;
  }

  /// Получить уведомления с пагинацией
  Future<PaginatedResult<AppNotification>> getNotificationsPaginated({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final notifications =
          snapshot.docs.map(AppNotification.fromDocument).toList();

      SafeLog.debug(
        'Получено ${notifications.length} уведомлений с пагинацией',
      );

      return PaginatedResult<AppNotification>(
        items: notifications,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e, stackTrace) {
      SafeLog.error('Ошибка получения уведомлений с пагинацией', e, stackTrace);
      rethrow;
    }
  }

  /// Поиск специалистов с debounce
  Stream<List<DocumentSnapshot>> searchSpecialistsDebounced({
    String? searchQuery,
    String? category,
    Duration debounceDelay = const Duration(milliseconds: 500),
  }) {
    final controller = StreamController<List<DocumentSnapshot>>.broadcast();
    Timer? debounceTimer;

    void performSearch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(debounceDelay, () async {
        try {
          var query = _db.collection('specialists');

          if (category != null && category.isNotEmpty) {
            query = query.where('category', isEqualTo: category);
          }

          if (searchQuery != null && searchQuery.isNotEmpty) {
            // Поиск по имени или описанию
            query = query
                .where('name', isGreaterThanOrEqualTo: searchQuery)
                .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
          }

          query = query.orderBy('name').limit(50);

          final snapshot = await query.get();
          SafeLog.debug(
            'Найдено ${snapshot.docs.length} специалистов по запросу "$searchQuery"',
          );
          controller.add(snapshot.docs);
        } catch (e, stackTrace) {
          SafeLog.error('Ошибка поиска специалистов', e, stackTrace);
          controller.addError(e);
        }
      });
    }

    performSearch();

    return controller.stream;
  }

  /// Очистка ресурсов
  void dispose() {
    // Закрываем все активные таймеры и контроллеры
    // В реальном приложении здесь можно добавить управление ресурсами
  }
}

/// Результат пагинированного запроса
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  /// Проверить, есть ли еще данные
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;
}
