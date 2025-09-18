import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/booking_discount.dart';

/// Сервис для работы со скидками
class DiscountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Предложить скидку для бронирования
  Future<void> offerDiscount({
    required String bookingId,
    required double oldPrice,
    required double newPrice,
    required String specialistId,
    required String customerId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 48)); // 48 часов на ответ

      final discount = BookingDiscount(
        isOffered: true,
        oldPrice: oldPrice,
        newPrice: newPrice,
        percent: ((oldPrice - newPrice) / oldPrice) * 100,
        offeredAt: now,
        expiresAt: expiresAt,
        offeredBy: 'specialist',
        reason: reason,
      );

      // Обновляем бронирование со скидкой
      await _firestore.collection('bookings').doc(bookingId).update({
        'discount': discount.toMap(),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Отправляем уведомление клиенту
      await _sendDiscountNotification(customerId, discount);

      // Логируем предложение скидки
      await _logDiscountOffer(bookingId, specialistId, customerId, discount);
    } catch (e) {
      throw Exception('Ошибка предложения скидки: $e');
    }
  }

  /// Принять скидку
  Future<void> acceptDiscount({
    required String bookingId,
    required String customerId,
  }) async {
    try {
      final now = DateTime.now();

      // Получаем текущее бронирование
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Бронирование не найдено');

      final bookingData = bookingDoc.data()!;
      final discountData = bookingData['discount'] as Map<String, dynamic>?;

      if (discountData == null) throw Exception('Скидка не найдена');

      final discount = BookingDiscount.fromMap(discountData);
      if (!discount.isActive) throw Exception('Скидка неактивна');

      // Обновляем скидку как принятую
      final updatedDiscount = discount.copyWith(
        isAccepted: true,
        acceptedAt: now,
        acceptedBy: customerId,
      );

      // Обновляем цену в бронировании
      await _firestore.collection('bookings').doc(bookingId).update({
        'discount': updatedDiscount.toMap(),
        'totalPrice': updatedDiscount.newPrice,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Отправляем уведомление специалисту
      await _sendDiscountAcceptedNotification(
          bookingData['specialistId'], updatedDiscount);

      // Логируем принятие скидки
      await _logDiscountAcceptance(bookingId, customerId, updatedDiscount);
    } catch (e) {
      throw Exception('Ошибка принятия скидки: $e');
    }
  }

  /// Отклонить скидку
  Future<void> rejectDiscount({
    required String bookingId,
    required String customerId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();

      // Получаем текущее бронирование
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Бронирование не найдено');

      final bookingData = bookingDoc.data()!;
      final discountData = bookingData['discount'] as Map<String, dynamic>?;

      if (discountData == null) throw Exception('Скидка не найдена');

      final discount = BookingDiscount.fromMap(discountData);
      if (!discount.isActive) throw Exception('Скидка неактивна');

      // Обновляем скидку как отклоненную (истекает)
      final updatedDiscount = discount.copyWith(
        expiresAt: now,
        reason: reason,
      );

      await _firestore.collection('bookings').doc(bookingId).update({
        'discount': updatedDiscount.toMap(),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Отправляем уведомление специалисту
      await _sendDiscountRejectedNotification(
          bookingData['specialistId'], reason);

      // Логируем отклонение скидки
      await _logDiscountRejection(bookingId, customerId, reason);
    } catch (e) {
      throw Exception('Ошибка отклонения скидки: $e');
    }
  }

  /// Получить скидку для бронирования
  Future<BookingDiscount?> getBookingDiscount(String bookingId) async {
    try {
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return null;

      final bookingData = bookingDoc.data()!;
      final discountData = bookingData['discount'] as Map<String, dynamic>?;

      if (discountData == null) return null;

      return BookingDiscount.fromMap(discountData);
    } catch (e) {
      throw Exception('Ошибка получения скидки: $e');
    }
  }

  /// Проверить, можно ли предложить скидку
  Future<bool> canOfferDiscount(String bookingId) async {
    try {
      final discount = await getBookingDiscount(bookingId);
      if (discount == null) return true;

      // Нельзя предложить скидку, если уже есть активная
      return !discount.isActive;
    } catch (e) {
      return false;
    }
  }

  /// Получить статистику скидок для специалиста
  Future<Map<String, dynamic>> getSpecialistDiscountStats(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('discount.isOffered', isEqualTo: true)
          .get();

      int totalOffered = 0;
      int accepted = 0;
      int rejected = 0;
      int expired = 0;
      double totalSavings = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final discountData = data['discount'] as Map<String, dynamic>?;
        if (discountData == null) continue;

        final discount = BookingDiscount.fromMap(discountData);
        totalOffered++;

        switch (discount.status) {
          case DiscountStatus.accepted:
            accepted++;
            if (discount.savings != null) {
              totalSavings += discount.savings!;
            }
            break;
          case DiscountStatus.expired:
            expired++;
            break;
          case DiscountStatus.pending:
            // Считаем как отклоненные, если истекли
            if (discount.isExpired) {
              expired++;
            }
            break;
          case DiscountStatus.notOffered:
            break;
        }
      }

      rejected = totalOffered - accepted - expired;

      return {
        'totalOffered': totalOffered,
        'accepted': accepted,
        'rejected': rejected,
        'expired': expired,
        'acceptanceRate':
            totalOffered > 0 ? (accepted / totalOffered) * 100 : 0,
        'totalSavings': totalSavings,
        'averageSavings': accepted > 0 ? totalSavings / accepted : 0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики скидок: $e');
    }
  }

  /// Отправить уведомление о предложении скидки
  Future<void> _sendDiscountNotification(
      String customerId, BookingDiscount discount) async {
    try {
      // Получаем FCM токены клиента
      final customerDoc =
          await _firestore.collection('users').doc(customerId).get();
      if (!customerDoc.exists) return;

      final customerData = customerDoc.data()!;
      final fcmTokens = List<String>.from(customerData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Предложение скидки',
        'body':
            'Специалист предложил скидку ${discount.discountPercent?.toStringAsFixed(0)}% на ваше бронирование',
        'data': {
          'type': 'discount_offered',
          'discountPercent': discount.discountPercent?.toString(),
          'savings': discount.savings?.toString(),
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            notification: notification,
          );
        } catch (e) {
          print('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      print('Ошибка отправки уведомления о скидке: $e');
    }
  }

  /// Отправить уведомление о принятии скидки
  Future<void> _sendDiscountAcceptedNotification(
      String specialistId, BookingDiscount discount) async {
    try {
      // Получаем FCM токены специалиста
      final specialistDoc =
          await _firestore.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return;

      final specialistData = specialistDoc.data()!;
      final fcmTokens = List<String>.from(specialistData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Скидка принята',
        'body':
            'Клиент принял ваше предложение скидки ${discount.discountPercent?.toStringAsFixed(0)}%',
        'data': {
          'type': 'discount_accepted',
          'discountPercent': discount.discountPercent?.toString(),
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            notification: notification,
          );
        } catch (e) {
          print('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      print('Ошибка отправки уведомления о принятии скидки: $e');
    }
  }

  /// Отправить уведомление об отклонении скидки
  Future<void> _sendDiscountRejectedNotification(
      String specialistId, String? reason) async {
    try {
      // Получаем FCM токены специалиста
      final specialistDoc =
          await _firestore.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return;

      final specialistData = specialistDoc.data()!;
      final fcmTokens = List<String>.from(specialistData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Скидка отклонена',
        'body': 'Клиент отклонил ваше предложение скидки',
        'data': {
          'type': 'discount_rejected',
          'reason': reason,
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            notification: notification,
          );
        } catch (e) {
          print('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      print('Ошибка отправки уведомления об отклонении скидки: $e');
    }
  }

  /// Логировать предложение скидки
  Future<void> _logDiscountOffer(String bookingId, String specialistId,
      String customerId, BookingDiscount discount) async {
    try {
      await _firestore.collection('discountLogs').add({
        'bookingId': bookingId,
        'specialistId': specialistId,
        'customerId': customerId,
        'action': 'offered',
        'discount': discount.toMap(),
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка логирования предложения скидки: $e');
    }
  }

  /// Логировать принятие скидки
  Future<void> _logDiscountAcceptance(
      String bookingId, String customerId, BookingDiscount discount) async {
    try {
      await _firestore.collection('discountLogs').add({
        'bookingId': bookingId,
        'customerId': customerId,
        'action': 'accepted',
        'discount': discount.toMap(),
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка логирования принятия скидки: $e');
    }
  }

  /// Логировать отклонение скидки
  Future<void> _logDiscountRejection(
      String bookingId, String customerId, String? reason) async {
    try {
      await _firestore.collection('discountLogs').add({
        'bookingId': bookingId,
        'customerId': customerId,
        'action': 'rejected',
        'reason': reason,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка логирования отклонения скидки: $e');
    }
  }
}
