import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/specialist_schedule.dart';
import '../models/notification.dart';
import 'calendar_service.dart';
import 'notification_service.dart';
import 'fcm_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();
  final FCMService _fcmService = FCMService();

  // Stream: заявки по customerId
  Stream<List<Booking>> bookingsByCustomerStream(String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Booking.fromDocument(d)).toList());
  }

  // Stream: заявки по specialistId
  Stream<List<Booking>> bookingsBySpecialistStream(String specialistId) {
    return _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Booking.fromDocument(d)).toList());
  }

  // Общий стрим всех заявок (для админов/отладки)
  Stream<List<Booking>> getAllBookingsStream() {
    return _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Booking.fromDocument(d)).toList());
  }

  // Добавить/обновить заявку
  Future<void> addOrUpdateBooking(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toMap());
  }

  // Обновить статус
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({'status': status});
  }

  // Обновить платежный статус / аванс
  Future<void> updatePaymentStatus(String bookingId, {required bool prepaymentPaid, required String paymentStatus}) async {
    await _db.collection('bookings').doc(bookingId).update({
      'prepaymentPaid': prepaymentPaid,
      'paymentStatus': paymentStatus,
    });
  }

  // Получить занятые даты (confirmed) для календаря
  Future<List<DateTime>> getBusyDates(String specialistId) async {
    final qs = await _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: 'confirmed')
        .get();
    return qs.docs.map((d) => (d.data()['eventDate'] as Timestamp).toDate()).toList();
  }

  // Добавить тестовые заявки (для локального теста)
  Future<void> addTestBookings() async {
    final now = DateTime.now();
    final b1 = Booking(
      id: 'b_test_1',
      customerId: 'u_customer1',
      specialistId: 's1',
      eventDate: now.add(const Duration(days: 7)),
      status: 'pending',
      prepayment: 3000,
      totalPrice: 10000,
    );
    final b2 = Booking(
      id: 'b_test_2',
      customerId: 'u_customer2',
      specialistId: 's1',
      eventDate: now.add(const Duration(days: 14)),
      status: 'confirmed',
      prepayment: 4500,
      totalPrice: 15000,
    );

    await _db.collection('bookings').doc(b1.id).set(b1.toMap());
    await _db.collection('bookings').doc(b2.id).set(b2.toMap());
    
    // Добавляем события в календарь
    await _calendarService.createBookingEvent(
      specialistId: b1.specialistId,
      bookingId: b1.id,
      customerName: b1.customerId,
      startTime: b1.eventDate,
      endTime: b1.eventDate.add(const Duration(hours: 2)),
      description: 'Тестовое бронирование 1',
    );
    
    await _calendarService.createBookingEvent(
      specialistId: b2.specialistId,
      bookingId: b2.id,
      customerName: b2.customerId,
      startTime: b2.eventDate,
      endTime: b2.eventDate.add(const Duration(hours: 3)),
      description: 'Тестовое бронирование 2',
    );
  }

  // Добавить/обновить заявку с интеграцией календаря
  Future<void> addOrUpdateBookingWithCalendar(Booking booking) async {
    try {
      // Проверяем доступность даты
      final isAvailable = await _calendarService.isDateTimeAvailable(
        booking.specialistId,
        booking.eventDate,
      );
      
      if (!isAvailable) {
        throw Exception('Выбранная дата и время недоступны');
      }
      
      // Сохраняем заявку
      await addOrUpdateBooking(booking);
      
      // Если заявка подтверждена, добавляем событие в календарь
      if (booking.status == 'confirmed') {
        await _calendarService.createBookingEvent(
          specialistId: booking.specialistId,
          bookingId: booking.id,
          customerName: booking.customerId,
          startTime: booking.eventDate,
          endTime: booking.eventDate.add(const Duration(hours: 2)), // По умолчанию 2 часа
          description: 'Бронирование мероприятия',
        );
      }
    } catch (e) {
      print('Ошибка добавления заявки с календарем: $e');
      throw Exception('Не удалось создать заявку: $e');
    }
  }

  // Обновить статус заявки с интеграцией календаря и уведомлений
  Future<void> updateBookingStatusWithCalendar(String bookingId, String status) async {
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
          specialistId: booking.specialistId,
          bookingId: booking.id,
          customerName: booking.customerId,
          startTime: booking.eventDate,
          endTime: booking.eventDate.add(const Duration(hours: 2)),
          description: 'Подтвержденное бронирование',
        );
      } else if (status == 'rejected' || status == 'cancelled') {
        // Удаляем событие из календаря
        await _calendarService.removeBookingEvent(booking.specialistId, booking.id);
      }

      // Отправляем уведомления
      await _sendBookingStatusNotifications(booking, status);
    } catch (e) {
      print('Ошибка обновления статуса заявки с календарем: $e');
      throw Exception('Не удалось обновить статус заявки: $e');
    }
  }

  // Проверить доступность даты для специалиста
  Future<bool> isSpecialistAvailable(String specialistId, DateTime dateTime) async {
    return await _calendarService.isDateTimeAvailable(specialistId, dateTime);
  }

  // Получить доступные временные слоты для специалиста
  Future<List<DateTime>> getAvailableTimeSlots(
    String specialistId,
    DateTime date, {
    Duration slotDuration = const Duration(hours: 1),
  }) async {
    return await _calendarService.getAvailableTimeSlots(
      specialistId,
      date,
      slotDuration: slotDuration,
    );
  }

  // Получить события специалиста на дату
  Future<List<ScheduleEvent>> getSpecialistEventsForDate(
    String specialistId,
    DateTime date,
  ) async {
    return await _calendarService.getEventsForDate(specialistId, date);
  }

  // Отправить уведомления о статусе заявки
  Future<void> _sendBookingStatusNotifications(Booking booking, String status) async {
    try {
      NotificationType notificationType;
      String title;
      String body;

      switch (status) {
        case 'confirmed':
          notificationType = NotificationType.booking_confirmed;
          title = 'Заявка подтверждена!';
          body = 'Ваша заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} подтверждена';
          break;
        case 'rejected':
          notificationType = NotificationType.booking_rejected;
          title = 'Заявка отклонена';
          body = 'К сожалению, ваша заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} отклонена';
          break;
        case 'cancelled':
          notificationType = NotificationType.booking_cancelled;
          title = 'Заявка отменена';
          body = 'Заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} была отменена';
          break;
        default:
          return; // Не отправляем уведомления для других статусов
      }

      // Отправляем уведомление клиенту
      await _notificationService.createBookingNotification(
        userId: booking.customerId,
        type: notificationType,
        bookingId: booking.id,
        specialistName: 'Специалист ${booking.specialistId}',
        customerName: 'Клиент ${booking.customerId}',
        eventDate: booking.eventDate,
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
        await _notificationService.createBookingNotification(
          userId: booking.specialistId,
          type: notificationType,
          bookingId: booking.id,
          specialistName: 'Специалист ${booking.specialistId}',
          customerName: 'Клиент ${booking.customerId}',
          eventDate: booking.eventDate,
        );

        // Отправляем push-уведомление специалисту
        await _sendPushNotification(
          userId: booking.specialistId,
          title: 'Заявка отменена клиентом',
          body: 'Клиент отменил заявку на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year}',
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
  Future<void> _sendPaymentStatusNotifications(String paymentId, String status, String customerId, String specialistId) async {
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
      await _notificationService.createPaymentNotification(
        userId: customerId,
        type: notificationType,
        paymentId: paymentId,
        amount: 0, // TODO: Получить сумму из платежа
        currency: 'RUB',
      );

      // Отправляем уведомление специалисту
      await _notificationService.createPaymentNotification(
        userId: specialistId,
        type: notificationType,
        paymentId: paymentId,
        amount: 0, // TODO: Получить сумму из платежа
        currency: 'RUB',
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
      // Получаем FCM токен пользователя из базы данных
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final fcmToken = userData['fcmToken'];
        
        if (fcmToken != null) {
          // Отправляем локальное уведомление (в реальном приложении здесь был бы HTTP запрос к FCM API)
          await _fcmService.showLocalNotification(
            id: DateTime.now().millisecondsSinceEpoch,
            title: title,
            body: body,
            data: data,
          );
        }
      }
    } catch (e) {
      print('Ошибка отправки push-уведомления: $e');
    }
  }
}