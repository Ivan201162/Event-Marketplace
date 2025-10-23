import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/photo_studio.dart';
import '../models/specialist.dart';
import '../models/studio_recommendation.dart';

/// Сервис для работы с рекомендациями студий
class StudioRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Создать рекомендацию студии
  Future<String> createStudioRecommendation({
    required String photographerId,
    required String studioId,
    required String studioName,
    required String studioUrl,
    String? message,
    Duration? expiresIn,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = expiresIn != null
          ? now.add(expiresIn)
          : now.add(const Duration(days: 7));

      final recommendation = StudioRecommendation(
        id: '', // Будет сгенерирован Firestore
        photographerId: photographerId,
        studioId: studioId,
        studioName: studioName,
        studioUrl: studioUrl,
        message: message,
        createdAt: now,
        expiresAt: expiresAt,
      );

      final docRef = await _firestore
          .collection('studioRecommendations')
          .add(recommendation.toMap());

      // Логируем создание рекомендации
      await _logRecommendationAction(docRef.id, 'created', photographerId);

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания рекомендации студии: $e');
    }
  }

  /// Получить рекомендации фотографа
  Future<List<StudioRecommendation>> getPhotographerRecommendations(
      String photographerId) async {
    try {
      final snapshot = await _firestore
          .collection('studioRecommendations')
          .where('photographerId', isEqualTo: photographerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(StudioRecommendation.fromDocument)
          .where((rec) => rec.isValid)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций фотографа: $e');
    }
  }

  /// Получить рекомендации для студии
  Future<List<StudioRecommendation>> getStudioRecommendations(
      String studioId) async {
    try {
      final snapshot = await _firestore
          .collection('studioRecommendations')
          .where('studioId', isEqualTo: studioId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(StudioRecommendation.fromDocument)
          .where((rec) => rec.isValid)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций для студии: $e');
    }
  }

  /// Получить рекомендацию по ID
  Future<StudioRecommendation?> getRecommendation(
      String recommendationId) async {
    try {
      final doc = await _firestore
          .collection('studioRecommendations')
          .doc(recommendationId)
          .get();
      if (doc.exists) {
        return StudioRecommendation.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения рекомендации: $e');
    }
  }

  /// Деактивировать рекомендацию
  Future<void> deactivateRecommendation(String recommendationId) async {
    try {
      await _firestore
          .collection('studioRecommendations')
          .doc(recommendationId)
          .update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Ошибка деактивации рекомендации: $e');
    }
  }

  /// Создать двойное бронирование
  Future<String> createDualBooking({
    required String customerId,
    required String photographerId,
    required String studioId,
    required String studioOptionId,
    required DateTime startTime,
    required DateTime endTime,
    required double photographerPrice,
    required double studioPrice,
    String? notes,
  }) async {
    try {
      // Проверяем доступность времени для фотографа
      final photographerAvailable = await _isPhotographerAvailable(
        photographerId: photographerId,
        startTime: startTime,
        endTime: endTime,
      );

      if (!photographerAvailable) {
        throw Exception('Фотограф недоступен в указанное время');
      }

      // Проверяем доступность времени для студии
      final studioAvailable = await _isStudioAvailable(
        studioId: studioId,
        startTime: startTime,
        endTime: endTime,
      );

      if (!studioAvailable) {
        throw Exception('Студия недоступна в указанное время');
      }

      // Вычисляем общую стоимость с скидкой
      final individualTotal = photographerPrice + studioPrice;
      final discount = individualTotal * 0.1; // 10% скидка
      final totalPrice = individualTotal - discount;

      final now = DateTime.now();

      final dualBooking = DualBooking(
        id: '', // Будет сгенерирован Firestore
        customerId: customerId,
        photographerId: photographerId,
        studioId: studioId,
        studioOptionId: studioOptionId,
        startTime: startTime,
        endTime: endTime,
        photographerPrice: photographerPrice,
        studioPrice: studioPrice,
        totalPrice: totalPrice,
        status: 'pending',
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final docRef =
          await _firestore.collection('dualBookings').add(dualBooking.toMap());

      // Создаем отдельные бронирования
      await _createIndividualBookings(dualBooking);

      // Отправляем уведомления
      await _sendDualBookingNotifications(dualBooking);

      // Логируем создание двойного бронирования
      await _logDualBookingAction(docRef.id, 'created', customerId);

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания двойного бронирования: $e');
    }
  }

  /// Получить двойные бронирования клиента
  Future<List<DualBooking>> getCustomerDualBookings(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('dualBookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map(DualBooking.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения двойных бронирований клиента: $e');
    }
  }

  /// Получить двойные бронирования фотографа
  Future<List<DualBooking>> getPhotographerDualBookings(
      String photographerId) async {
    try {
      final snapshot = await _firestore
          .collection('dualBookings')
          .where('photographerId', isEqualTo: photographerId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map(DualBooking.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения двойных бронирований фотографа: $e');
    }
  }

  /// Получить двойные бронирования студии
  Future<List<DualBooking>> getStudioDualBookings(String studioId) async {
    try {
      final snapshot = await _firestore
          .collection('dualBookings')
          .where('studioId', isEqualTo: studioId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map(DualBooking.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения двойных бронирований студии: $e');
    }
  }

  /// Обновить статус двойного бронирования
  Future<void> updateDualBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('dualBookings').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем статусы отдельных бронирований
      await _updateIndividualBookingStatuses(bookingId, status);
    } catch (e) {
      throw Exception('Ошибка обновления статуса двойного бронирования: $e');
    }
  }

  /// Отменить двойное бронирование
  Future<void> cancelDualBooking(String bookingId) async {
    try {
      await updateDualBookingStatus(bookingId, 'cancelled');
    } catch (e) {
      throw Exception('Ошибка отмены двойного бронирования: $e');
    }
  }

  /// Получить рекомендуемые студии для фотографа
  Future<List<PhotoStudio>> getRecommendedStudiosForPhotographer(
      String photographerId) async {
    try {
      // Получаем информацию о фотографе
      final photographerDoc =
          await _firestore.collection('specialists').doc(photographerId).get();
      if (!photographerDoc.exists) throw Exception('Фотограф не найден');

      final photographer = Specialist.fromDocument(photographerDoc);
      final location = photographer.location;

      // Получаем студии в том же городе
      final studios = await _firestore
          .collection('photoStudios')
          .where('location', isEqualTo: location)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();

      return studios.docs.map(PhotoStudio.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендуемых студий: $e');
    }
  }

  /// Получить статистику рекомендаций
  Future<Map<String, dynamic>> getRecommendationStats(
      String photographerId) async {
    try {
      final snapshot = await _firestore
          .collection('studioRecommendations')
          .where('photographerId', isEqualTo: photographerId)
          .get();

      var totalRecommendations = 0;
      var activeRecommendations = 0;
      var expiredRecommendations = 0;

      for (final doc in snapshot.docs) {
        final recommendation = StudioRecommendation.fromDocument(doc);
        totalRecommendations++;

        if (recommendation.isValid) {
          activeRecommendations++;
        } else if (recommendation.isExpired) {
          expiredRecommendations++;
        }
      }

      return {
        'totalRecommendations': totalRecommendations,
        'activeRecommendations': activeRecommendations,
        'expiredRecommendations': expiredRecommendations,
        'successRate': totalRecommendations > 0
            ? (activeRecommendations / totalRecommendations) * 100
            : 0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики рекомендаций: $e');
    }
  }

  /// Проверить доступность фотографа
  Future<bool> _isPhotographerAvailable({
    required String photographerId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: photographerId)
          .where('status', whereIn: ['confirmed', 'in_progress']).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookingStart = (data['startTime'] as Timestamp).toDate();
        final bookingEnd = (data['endTime'] as Timestamp).toDate();

        // Проверяем пересечение временных интервалов
        if (startTime.isBefore(bookingEnd) && endTime.isAfter(bookingStart)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Проверить доступность студии
  Future<bool> _isStudioAvailable({
    required String studioId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('studioBookings')
          .where('studioId', isEqualTo: studioId)
          .where('status', whereIn: ['confirmed', 'in_progress']).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookingStart = (data['startTime'] as Timestamp).toDate();
        final bookingEnd = (data['endTime'] as Timestamp).toDate();

        // Проверяем пересечение временных интервалов
        if (startTime.isBefore(bookingEnd) && endTime.isAfter(bookingStart)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Создать отдельные бронирования
  Future<void> _createIndividualBookings(DualBooking dualBooking) async {
    try {
      // Создаем бронирование фотографа
      await _firestore.collection('bookings').add({
        'customerId': dualBooking.customerId,
        'specialistId': dualBooking.photographerId,
        'categoryId': 'photographer',
        'status': 'pending',
        'totalPrice': dualBooking.photographerPrice,
        'startTime': Timestamp.fromDate(dualBooking.startTime),
        'endTime': Timestamp.fromDate(dualBooking.endTime),
        'description': 'Двойное бронирование с фотостудией',
        'createdAt': Timestamp.fromDate(dualBooking.createdAt),
        'updatedAt': Timestamp.fromDate(dualBooking.updatedAt),
        'metadata': {'dualBookingId': dualBooking.id, 'type': 'dual_booking'},
      });

      // Создаем бронирование студии
      await _firestore.collection('studioBookings').add({
        'customerId': dualBooking.customerId,
        'studioId': dualBooking.studioId,
        'optionId': dualBooking.studioOptionId,
        'status': 'pending',
        'totalPrice': dualBooking.studioPrice,
        'startTime': Timestamp.fromDate(dualBooking.startTime),
        'endTime': Timestamp.fromDate(dualBooking.endTime),
        'notes': 'Двойное бронирование с фотографом',
        'createdAt': Timestamp.fromDate(dualBooking.createdAt),
        'updatedAt': Timestamp.fromDate(dualBooking.updatedAt),
        'metadata': {'dualBookingId': dualBooking.id, 'type': 'dual_booking'},
      });
    } catch (e) {
      throw Exception('Ошибка создания отдельных бронирований: $e');
    }
  }

  /// Обновить статусы отдельных бронирований
  Future<void> _updateIndividualBookingStatuses(
      String dualBookingId, String status) async {
    try {
      // Обновляем бронирование фотографа
      final photographerBookings = await _firestore
          .collection('bookings')
          .where('metadata.dualBookingId', isEqualTo: dualBookingId)
          .get();

      for (final doc in photographerBookings.docs) {
        await doc.reference.update({
          'status': status,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Обновляем бронирование студии
      final studioBookings = await _firestore
          .collection('studioBookings')
          .where('metadata.dualBookingId', isEqualTo: dualBookingId)
          .get();

      for (final doc in studioBookings.docs) {
        await doc.reference.update({
          'status': status,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Ошибка обновления статусов отдельных бронирований: $e');
    }
  }

  /// Отправить уведомления о двойном бронировании
  Future<void> _sendDualBookingNotifications(DualBooking dualBooking) async {
    try {
      // Уведомление фотографу
      await _sendNotificationToUser(
        userId: dualBooking.photographerId,
        title: 'Новое двойное бронирование',
        body:
            'Создано двойное бронирование с фотостудией на ${dualBooking.startTime.day}.${dualBooking.startTime.month}',
        data: {'type': 'dual_booking_created', 'bookingId': dualBooking.id},
      );

      // Уведомление студии (если есть владелец)
      // TODO(developer): Добавить поле ownerId в PhotoStudio
    } catch (e) {
      debugPrint('Ошибка отправки уведомлений о двойном бронировании: $e');
    }
  }

  /// Отправить уведомление пользователю
  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {'title': title, 'body': body, 'data': data};

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(to: token, notification: notification);
        } catch (e) {
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      debugPrint('Ошибка отправки уведомления пользователю: $e');
    }
  }

  /// Логировать действие с рекомендацией
  Future<void> _logRecommendationAction(
    String recommendationId,
    String action,
    String userId,
  ) async {
    try {
      await _firestore.collection('recommendationLogs').add({
        'recommendationId': recommendationId,
        'action': action,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка логирования действия с рекомендацией: $e');
    }
  }

  /// Логировать действие с двойным бронированием
  Future<void> _logDualBookingAction(
      String bookingId, String action, String userId) async {
    try {
      await _firestore.collection('dualBookingLogs').add({
        'bookingId': bookingId,
        'action': action,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка логирования действия с двойным бронированием: $e');
    }
  }
}
