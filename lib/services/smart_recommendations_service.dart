import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/specialist.dart';
import '../models/app_user.dart';
import 'fcm_service.dart';

/// Сервис для умных рекомендаций и уведомлений
class SmartRecommendationsService {
  factory SmartRecommendationsService() => _instance;
  SmartRecommendationsService._internal();
  static final SmartRecommendationsService _instance = SmartRecommendationsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  /// Анализировать бронирование и отправить рекомендации
  Future<void> analyzeBookingAndRecommend(Booking booking) async {
    try {
      // Получаем данные заказчика
      final customerDoc = await _firestore
          .collection('users')
          .doc(booking.customerId)
          .get();
      
      if (!customerDoc.exists) return;
      
      final customer = customerDoc.data()!;
      final selectedCategories = _extractCategoriesFromBooking(booking);
      final budget = booking.totalPrice;
      
      // Отправляем cross-sell рекомендации
      await _fcmService.sendCrossSellRecommendation(
        booking.customerId ?? '',
        selectedCategories,
      );
      
      // Отправляем рекомендации по бюджету
      await _fcmService.sendBudgetRecommendation(
        booking.customerId ?? '',
        budget,
        selectedCategories,
      );
      
      // Планируем напоминание об оплате
      await _schedulePaymentReminder(booking);
      
    } catch (e) {
      print('Error analyzing booking and recommending: $e');
    }
  }

  /// Извлечь категории из бронирования
  List<String> _extractCategoriesFromBooking(Booking booking) {
    // Здесь можно добавить логику извлечения категорий из бронирования
    // Пока возвращаем пустой список
    return [];
  }

  /// Запланировать напоминание об оплате
  Future<void> _schedulePaymentReminder(Booking booking) async {
    try {
      final eventDate = booking.eventDate;
      final reminderDate = eventDate.subtract(const Duration(days: 3));
      
      // Планируем напоминание за 3 дня до события
      await _fcmService.scheduleNotification(
        title: 'Напоминание об оплате',
        body: 'До вашего события "${booking.eventTitle}" осталось 3 дня. Не забудьте произвести оплату!',
        scheduledTime: reminderDate,
        payload: 'payment_reminder_${booking.id}',
      );
      
    } catch (e) {
      print('Error scheduling payment reminder: $e');
    }
  }

  /// Отправить напоминание специалисту об обновлении цен
  Future<void> sendPriceUpdateReminderToSpecialist(String specialistId) async {
    try {
      await _fcmService.sendPriceUpdateReminder(specialistId);
    } catch (e) {
      print('Error sending price update reminder to specialist: $e');
    }
  }

  /// Отправить уведомление о новой публикации от избранного специалиста
  Future<void> notifyFavoriteSpecialistUpdate(String customerId, String specialistId) async {
    try {
      final specialistDoc = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .get();
      
      if (!specialistDoc.exists) return;
      
      final specialist = specialistDoc.data()!;
      final specialistName = specialist['name'] as String? ?? 'Специалист';
      
      await _fcmService.sendFavoriteSpecialistUpdate(
        customerId,
        specialistId,
        specialistName,
      );
      
    } catch (e) {
      print('Error notifying favorite specialist update: $e');
    }
  }

  /// Анализировать активность специалиста и отправлять напоминания
  Future<void> analyzeSpecialistActivity(String specialistId) async {
    try {
      final specialistDoc = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .get();
      
      if (!specialistDoc.exists) return;
      
      final specialist = specialistDoc.data()!;
      final lastPriceUpdate = specialist['lastPriceUpdate'] as Timestamp?;
      final lastPriceReminder = specialist['lastPriceReminder'] as Timestamp?;
      
      // Проверяем, нужно ли отправить напоминание об обновлении цен
      if (lastPriceUpdate != null) {
        final daysSinceUpdate = DateTime.now().difference(lastPriceUpdate.toDate()).inDays;
        final daysSinceReminder = lastPriceReminder != null 
            ? DateTime.now().difference(lastPriceReminder.toDate()).inDays 
            : 999;
        
        // Отправляем напоминание, если прошло 7+ дней с обновления и 3+ дня с последнего напоминания
        if (daysSinceUpdate >= 7 && daysSinceReminder >= 3) {
          await _fcmService.sendPriceUpdateReminder(specialistId);
        }
      }
      
    } catch (e) {
      print('Error analyzing specialist activity: $e');
    }
  }

  /// Отправить уведомление о новом сообщении с учетом рабочего времени
  Future<void> sendChatNotificationRespectingHours({
    required String specialistId,
    required String customerId,
    required String message,
  }) async {
    try {
      await _fcmService.sendNotificationRespectingWorkingHours(
        specialistId: specialistId,
        title: 'Новое сообщение',
        body: message,
        payload: 'chat_message_$customerId',
      );
      
    } catch (e) {
      print('Error sending chat notification respecting hours: $e');
    }
  }

  /// Анализировать предпочтения пользователя и отправлять персонализированные рекомендации
  Future<void> sendPersonalizedRecommendations(String userId) async {
    try {
      // Получаем историю бронирований пользователя
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      if (bookingsQuery.docs.isEmpty) return;
      
      // Анализируем предпочтения
      final categories = <String, int>{};
      double totalSpent = 0;
      
      for (final doc in bookingsQuery.docs) {
        final booking = doc.data();
        totalSpent += (booking['totalPrice'] as num?)?.toDouble() ?? 0;
        
        // Здесь можно добавить логику извлечения категорий
        // Пока используем заглушку
      }
      
      // Отправляем персонализированные рекомендации
      if (totalSpent > 100000) {
        await _fcmService.sendLocalNotification(
          title: 'VIP статус',
          body: 'Вы потратили ${totalSpent.toStringAsFixed(0)} ₽ на мероприятия! Получите скидку 10% на следующее бронирование.',
          payload: 'vip_discount',
        );
      }
      
    } catch (e) {
      print('Error sending personalized recommendations: $e');
    }
  }

  /// Запустить ежедневную проверку для отправки напоминаний
  Future<void> runDailyRemindersCheck() async {
    try {
      // Получаем всех специалистов
      final specialistsQuery = await _firestore
          .collection('specialists')
          .get();
      
      for (final doc in specialistsQuery.docs) {
        await analyzeSpecialistActivity(doc.id);
      }
      
      // Получаем все активные бронирования
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .get();
      
      for (final doc in bookingsQuery.docs) {
        final booking = Booking.fromDocument(doc);
        await _checkPaymentReminder(booking);
      }
      
    } catch (e) {
      print('Error running daily reminders check: $e');
    }
  }

  /// Проверить необходимость напоминания об оплате
  Future<void> _checkPaymentReminder(Booking booking) async {
    try {
      final eventDate = booking.eventDate;
      final now = DateTime.now();
      final daysUntilEvent = eventDate.difference(now).inDays;
      
      // Напоминаем за 3 дня до события
      if (daysUntilEvent == 3) {
        await _fcmService.sendPaymentReminder(booking.customerId ?? '', booking.id);
      }
      
    } catch (e) {
      print('Error checking payment reminder: $e');
    }
  }
}
