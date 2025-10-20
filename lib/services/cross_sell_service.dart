import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/booking.dart';
import '../models/cross_sell_suggestion.dart';
import '../models/specialist.dart';

/// Сервис для работы с кросс-селл предложениями
class CrossSellService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Создать кросс-селл предложение
  Future<String> createCrossSellSuggestion({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required List<CrossSellItem> suggestedItems,
    String? message,
  }) async {
    try {
      final now = DateTime.now();

      final suggestion = CrossSellSuggestion(
        id: '', // Будет сгенерирован Firestore
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        suggestedItems: suggestedItems,
        status: CrossSellStatus.pending,
        message: message,
        createdAt: now,
        metadata: {
          'expiresAt': now.add(const Duration(hours: 48)).toIso8601String(),
        },
      );

      final docRef = await _firestore.collection('crossSellSuggestions').add(suggestion.toMap());

      // Отправляем уведомление клиенту
      await _sendCrossSellNotification(customerId, suggestion);

      // Логируем создание предложения
      await _logCrossSellAction(docRef.id, 'created', specialistId);

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания кросс-селл предложения: $e');
    }
  }

  /// Принять кросс-селл предложение
  Future<void> acceptCrossSellSuggestion({
    required String suggestionId,
    required String customerId,
  }) async {
    try {
      final now = DateTime.now();

      // Обновляем статус предложения
      await _firestore.collection('crossSellSuggestions').doc(suggestionId).update({
        'status': CrossSellStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(now),
      });

      // Получаем данные предложения
      final suggestionDoc =
          await _firestore.collection('crossSellSuggestions').doc(suggestionId).get();
      if (!suggestionDoc.exists) throw Exception('Предложение не найдено');

      final suggestion = CrossSellSuggestion.fromDocument(suggestionDoc);

      // Создаем бронирования для каждого предложенного специалиста
      for (final item in suggestion.suggestedItems) {
        await _createBookingFromCrossSell(suggestion, item);
      }

      // Отправляем уведомление специалисту
      await _sendCrossSellAcceptedNotification(
        suggestion.specialistId,
        suggestion,
      );

      // Логируем принятие предложения
      await _logCrossSellAction(suggestionId, 'accepted', customerId);
    } catch (e) {
      throw Exception('Ошибка принятия кросс-селл предложения: $e');
    }
  }

  /// Отклонить кросс-селл предложение
  Future<void> rejectCrossSellSuggestion({
    required String suggestionId,
    required String customerId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();

      // Обновляем статус предложения
      await _firestore.collection('crossSellSuggestions').doc(suggestionId).update({
        'status': CrossSellStatus.rejected.name,
        'respondedAt': Timestamp.fromDate(now),
        'metadata.rejectionReason': reason,
      });

      // Получаем данные предложения
      final suggestionDoc =
          await _firestore.collection('crossSellSuggestions').doc(suggestionId).get();
      if (!suggestionDoc.exists) throw Exception('Предложение не найдено');

      final suggestion = CrossSellSuggestion.fromDocument(suggestionDoc);

      // Отправляем уведомление специалисту
      await _sendCrossSellRejectedNotification(
        suggestion.specialistId,
        suggestion,
        reason,
      );

      // Логируем отклонение предложения
      await _logCrossSellAction(suggestionId, 'rejected', customerId);
    } catch (e) {
      throw Exception('Ошибка отклонения кросс-селл предложения: $e');
    }
  }

  /// Отметить предложение как просмотренное
  Future<void> markAsViewed(String suggestionId) async {
    try {
      await _firestore.collection('crossSellSuggestions').doc(suggestionId).update({
        'status': CrossSellStatus.viewed.name,
        'viewedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка отметки предложения как просмотренного: $e');
    }
  }

  /// Получить кросс-селл предложения для клиента
  Future<List<CrossSellSuggestion>> getCustomerSuggestions(
    String customerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('crossSellSuggestions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(CrossSellSuggestion.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения кросс-селл предложений клиента: $e');
    }
  }

  /// Получить кросс-селл предложения для специалиста
  Future<List<CrossSellSuggestion>> getSpecialistSuggestions(
    String specialistId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('crossSellSuggestions')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(CrossSellSuggestion.fromDocument).toList();
    } catch (e) {
      throw Exception(
        'Ошибка получения кросс-селл предложений специалиста: $e',
      );
    }
  }

  /// Получить кросс-селл предложение по ID
  Future<CrossSellSuggestion?> getSuggestion(String suggestionId) async {
    try {
      final doc = await _firestore.collection('crossSellSuggestions').doc(suggestionId).get();
      if (doc.exists) {
        return CrossSellSuggestion.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения кросс-селл предложения: $e');
    }
  }

  /// Получить рекомендуемых специалистов для кросс-селла
  Future<List<CrossSellItem>> getRecommendedSpecialists({
    required String bookingId,
    required String customerId,
    required String specialistId,
  }) async {
    try {
      // Получаем данные бронирования
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Бронирование не найдено');

      final booking = Booking.fromDocument(bookingDoc);

      // Определяем рекомендуемые категории на основе текущего бронирования
      final recommendedCategories = _getRecommendedCategories(booking.serviceId);

      // Получаем специалистов по рекомендуемым категориям
      final specialists = <CrossSellItem>[];

      for (final categoryId in recommendedCategories) {
        final categorySpecialists = await _getSpecialistsByCategory(
          categoryId: categoryId,
          excludeSpecialistId: specialistId,
        );

        specialists.addAll(categorySpecialists);
      }

      return specialists;
    } catch (e) {
      throw Exception('Ошибка получения рекомендуемых специалистов: $e');
    }
  }

  /// Получить статистику кросс-селл предложений
  Future<Map<String, dynamic>> getCrossSellStats(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('crossSellSuggestions')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      var totalSuggestions = 0;
      var acceptedSuggestions = 0;
      var rejectedSuggestions = 0;
      var viewedSuggestions = 0;
      double totalRevenue = 0;

      for (final doc in snapshot.docs) {
        final suggestion = CrossSellSuggestion.fromDocument(doc);
        totalSuggestions++;

        switch (suggestion.status) {
          case CrossSellStatus.accepted:
            acceptedSuggestions++;
            totalRevenue += suggestion.totalCost;
            break;
          case CrossSellStatus.rejected:
            rejectedSuggestions++;
            break;
          case CrossSellStatus.viewed:
            viewedSuggestions++;
            break;
          case CrossSellStatus.pending:
          case CrossSellStatus.expired:
            break;
        }
      }

      return {
        'totalSuggestions': totalSuggestions,
        'acceptedSuggestions': acceptedSuggestions,
        'rejectedSuggestions': rejectedSuggestions,
        'viewedSuggestions': viewedSuggestions,
        'acceptanceRate': totalSuggestions > 0 ? (acceptedSuggestions / totalSuggestions) * 100 : 0,
        'totalRevenue': totalRevenue,
        'averageSuggestionValue': acceptedSuggestions > 0 ? totalRevenue / acceptedSuggestions : 0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики кросс-селл предложений: $e');
    }
  }

  /// Создать бронирование из кросс-селл предложения
  Future<void> _createBookingFromCrossSell(
    CrossSellSuggestion suggestion,
    CrossSellItem item,
  ) async {
    try {
      final now = DateTime.now();

      final booking = {
        'customerId': suggestion.customerId,
        'specialistId': item.specialistId,
        'categoryId': item.categoryId,
        'status': 'pending',
        'totalPrice': item.estimatedPrice,
        'description': item.description ?? suggestion.message,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'metadata': {
          'crossSellSuggestionId': suggestion.id,
          'crossSellItem': item.toMap(),
          'originalBookingId': suggestion.bookingId,
        },
      };

      await _firestore.collection('bookings').add(booking);
    } catch (e) {
      throw Exception(
        'Ошибка создания бронирования из кросс-селл предложения: $e',
      );
    }
  }

  /// Отправить уведомление о кросс-селл предложении
  Future<void> _sendCrossSellNotification(
    String customerId,
    CrossSellSuggestion suggestion,
  ) async {
    try {
      // Получаем FCM токены клиента
      final customerDoc = await _firestore.collection('users').doc(customerId).get();
      if (!customerDoc.exists) return;

      final customerData = customerDoc.data();
      final fcmTokens = List<String>.from(customerData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Рекомендуем дополнить заказ',
        'body': 'Добавьте ${suggestion.itemCount} специалистов для полного комплекта услуг',
        'data': {
          'type': 'cross_sell_suggestion',
          'suggestionId': suggestion.id,
          'itemCount': suggestion.itemCount.toString(),
          'totalCost': suggestion.totalCost.toString(),
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            data: {
              'title': notification['title'],
              'body': notification['body'],
              'type': 'cross_sell',
            },
          );
        } catch (e) {
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      debugPrint('Ошибка отправки уведомления о кросс-селл предложении: $e');
    }
  }

  /// Отправить уведомление о принятии кросс-селл предложения
  Future<void> _sendCrossSellAcceptedNotification(
    String specialistId,
    CrossSellSuggestion suggestion,
  ) async {
    try {
      // Получаем FCM токены специалиста
      final specialistDoc = await _firestore.collection('users').doc(specialistId).get();
      if (!specialistDoc.exists) return;

      final specialistData = specialistDoc.data();
      final fcmTokens = List<String>.from(specialistData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Кросс-селл предложение принято',
        'body': 'Клиент принял ваше предложение ${suggestion.itemCount} дополнительных услуг',
        'data': {
          'type': 'cross_sell_accepted',
          'suggestionId': suggestion.id,
          'itemCount': suggestion.itemCount.toString(),
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            data: {
              'title': notification['title'],
              'body': notification['body'],
              'type': 'cross_sell',
            },
          );
        } catch (e) {
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      debugPrint(
        'Ошибка отправки уведомления о принятии кросс-селл предложения: $e',
      );
    }
  }

  /// Отправить уведомление об отклонении кросс-селл предложения
  Future<void> _sendCrossSellRejectedNotification(
    String specialistId,
    CrossSellSuggestion suggestion,
    String? reason,
  ) async {
    try {
      // Получаем FCM токены специалиста
      final specialistDoc = await _firestore.collection('users').doc(specialistId).get();
      if (!specialistDoc.exists) return;

      final specialistData = specialistDoc.data();
      final fcmTokens = List<String>.from(specialistData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Кросс-селл предложение отклонено',
        'body': 'Клиент отклонил ваше предложение дополнительных услуг',
        'data': {
          'type': 'cross_sell_rejected',
          'suggestionId': suggestion.id,
          'reason': reason,
        },
      };

      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            data: {
              'title': notification['title'],
              'body': notification['body'],
              'type': 'cross_sell',
            },
          );
        } catch (e) {
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      debugPrint(
        'Ошибка отправки уведомления об отклонении кросс-селл предложения: $e',
      );
    }
  }

  /// Логировать действие с кросс-селл предложением
  Future<void> _logCrossSellAction(
    String suggestionId,
    String action,
    String userId,
  ) async {
    try {
      await _firestore.collection('crossSellLogs').add({
        'suggestionId': suggestionId,
        'action': action,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка логирования действия с кросс-селл предложением: $e');
    }
  }

  /// Получить рекомендуемые категории на основе текущей категории
  List<String> _getRecommendedCategories(String? currentCategoryId) {
    // Маппинг рекомендуемых категорий
    const categoryMapping = {
      'host': ['photographer', 'videographer', 'content_creator'],
      'photographer': ['videographer', 'content_creator', 'photo_studio'],
      'videographer': ['photographer', 'content_creator', 'photo_studio'],
      'content_creator': ['photographer', 'videographer'],
      'photo_studio': ['photographer', 'videographer', 'content_creator'],
      'musician': ['photographer', 'videographer', 'content_creator'],
      'dj': ['photographer', 'videographer', 'content_creator'],
    };

    if (currentCategoryId == null) return [];
    return categoryMapping[currentCategoryId] ?? [];
  }

  /// Получить специалистов по категории
  Future<List<CrossSellItem>> _getSpecialistsByCategory({
    required String categoryId,
    required String excludeSpecialistId,
    int limit = 3,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .where('categories', arrayContains: categoryId)
          .where('isActive', isEqualTo: true)
          .limit(limit + 1) // +1 чтобы исключить текущего специалиста
          .get();

      final specialists = <CrossSellItem>[];

      for (final doc in snapshot.docs) {
        final specialist = Specialist.fromDocument(doc);

        // Исключаем текущего специалиста
        if (specialist.id == excludeSpecialistId) continue;

        // Получаем название категории
        final categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
        final categoryName = categoryDoc.data()?['name'] ?? 'Неизвестная категория';

        specialists.add(
          CrossSellItem(
            id: specialist.id,
            specialistId: specialist.id,
            specialistName: specialist.name,
            categoryId: categoryId,
            categoryName: categoryName,
            description: specialist.description,
            estimatedPrice: specialist.hourlyRate ?? specialist.pricePerHour ?? 0.0,
            imageUrl: specialist.avatarUrl,
          ),
        );

        if (specialists.length >= limit) break;
      }

      return specialists;
    } catch (e) {
      throw Exception('Ошибка получения специалистов по категории: $e');
    }
  }
}
