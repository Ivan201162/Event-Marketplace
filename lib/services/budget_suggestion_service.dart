import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/booking.dart';
import '../models/budget_suggestion.dart';
import '../models/specialist.dart';

/// Сервис для работы с предложениями по увеличению бюджета
class BudgetSuggestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Создать предложение по увеличению бюджета
  Future<String> createBudgetSuggestion({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required List<BudgetSuggestionItem> suggestions,
    String? message,
  }) async {
    try {
      final now = DateTime.now();

      final suggestion = BudgetSuggestion(
        id: '', // Будет сгенерирован Firestore
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        suggestions: suggestions,
        status: BudgetSuggestionStatus.pending,
        message: message,
        createdAt: now,
        metadata: {
          'expiresAt': now.add(const Duration(hours: 24)).toIso8601String()
        },
      );

      final docRef = await _firestore
          .collection('budgetSuggestions')
          .add(suggestion.toMap());

      // Отправляем уведомление клиенту
      await _sendBudgetSuggestionNotification(customerId, suggestion);

      // Логируем создание предложения
      await _logBudgetSuggestionAction(docRef.id, 'created', specialistId);

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания предложения по бюджету: $e');
    }
  }

  /// Принять предложение по бюджету
  Future<void> acceptBudgetSuggestion({
    required String suggestionId,
    required String customerId,
  }) async {
    try {
      final now = DateTime.now();

      // Обновляем статус предложения
      await _firestore
          .collection('budgetSuggestions')
          .doc(suggestionId)
          .update({
        'status': BudgetSuggestionStatus.accepted.name,
        'respondedAt': Timestamp.fromDate(now),
      });

      // Получаем данные предложения
      final suggestionDoc = await _firestore
          .collection('budgetSuggestions')
          .doc(suggestionId)
          .get();
      if (!suggestionDoc.exists) throw Exception('Предложение не найдено');

      final suggestion = BudgetSuggestion.fromDocument(suggestionDoc);

      // Создаем бронирования для каждого предложенного специалиста
      for (final item in suggestion.suggestions) {
        if (item.specialistId != null) {
          await _createBookingFromBudgetSuggestion(suggestion, item);
        }
      }

      // Отправляем уведомление специалисту
      await _sendBudgetSuggestionAcceptedNotification(
          suggestion.specialistId, suggestion);

      // Логируем принятие предложения
      await _logBudgetSuggestionAction(suggestionId, 'accepted', customerId);
    } catch (e) {
      throw Exception('Ошибка принятия предложения по бюджету: $e');
    }
  }

  /// Отклонить предложение по бюджету
  Future<void> rejectBudgetSuggestion({
    required String suggestionId,
    required String customerId,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();

      // Обновляем статус предложения
      await _firestore
          .collection('budgetSuggestions')
          .doc(suggestionId)
          .update({
        'status': BudgetSuggestionStatus.rejected.name,
        'respondedAt': Timestamp.fromDate(now),
        'metadata.rejectionReason': reason,
      });

      // Получаем данные предложения
      final suggestionDoc = await _firestore
          .collection('budgetSuggestions')
          .doc(suggestionId)
          .get();
      if (!suggestionDoc.exists) throw Exception('Предложение не найдено');

      final suggestion = BudgetSuggestion.fromDocument(suggestionDoc);

      // Отправляем уведомление специалисту
      await _sendBudgetSuggestionRejectedNotification(
          suggestion.specialistId, suggestion, reason);

      // Логируем отклонение предложения
      await _logBudgetSuggestionAction(suggestionId, 'rejected', customerId);
    } catch (e) {
      throw Exception('Ошибка отклонения предложения по бюджету: $e');
    }
  }

  /// Отметить предложение как просмотренное
  Future<void> markAsViewed(String suggestionId) async {
    try {
      await _firestore
          .collection('budgetSuggestions')
          .doc(suggestionId)
          .update({
        'status': BudgetSuggestionStatus.viewed.name,
        'viewedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка отметки предложения как просмотренного: $e');
    }
  }

  /// Получить предложения по бюджету для клиента
  Future<List<BudgetSuggestion>> getCustomerSuggestions(
      String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('budgetSuggestions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(BudgetSuggestion.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения предложений по бюджету клиента: $e');
    }
  }

  /// Получить предложения по бюджету для специалиста
  Future<List<BudgetSuggestion>> getSpecialistSuggestions(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('budgetSuggestions')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(BudgetSuggestion.fromDocument).toList();
    } catch (e) {
      throw Exception(
          'Ошибка получения предложений по бюджету специалиста: $e');
    }
  }

  /// Получить предложение по бюджету по ID
  Future<BudgetSuggestion?> getSuggestion(String suggestionId) async {
    try {
      final doc = await _firestore
          .collection('budgetSuggestions')
          .doc(suggestionId)
          .get();
      if (doc.exists) {
        return BudgetSuggestion.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения предложения по бюджету: $e');
    }
  }

  /// Анализировать бюджет и создать предложения
  Future<List<BudgetSuggestionItem>> analyzeBudgetAndCreateSuggestions({
    required String bookingId,
    required String customerId,
    required String specialistId,
  }) async {
    try {
      // Получаем данные бронирования
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Бронирование не найдено');

      final booking = Booking.fromDocument(bookingDoc);

      // Анализируем бюджет
      final analysis = await _analyzeBudget(booking);

      // Создаем предложения на основе анализа
      final suggestions = <BudgetSuggestionItem>[];

      for (final category in analysis['missingCategories']) {
        final suggestion = await _createSuggestionForCategory(
          categoryId: category,
          booking: booking,
          reason: analysis['reasons'][category],
        );
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      }

      return suggestions;
    } catch (e) {
      throw Exception('Ошибка анализа бюджета и создания предложений: $e');
    }
  }

  /// Получить статистику предложений по бюджету
  Future<Map<String, dynamic>> getBudgetSuggestionStats(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('budgetSuggestions')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      var totalSuggestions = 0;
      var acceptedSuggestions = 0;
      var rejectedSuggestions = 0;
      var viewedSuggestions = 0;
      double totalRevenue = 0;

      for (final doc in snapshot.docs) {
        final suggestion = BudgetSuggestion.fromDocument(doc);
        totalSuggestions++;

        switch (suggestion.status) {
          case BudgetSuggestionStatus.accepted:
            acceptedSuggestions++;
            totalRevenue += suggestion.totalCost;
            break;
          case BudgetSuggestionStatus.rejected:
            rejectedSuggestions++;
            break;
          case BudgetSuggestionStatus.viewed:
            viewedSuggestions++;
            break;
          case BudgetSuggestionStatus.pending:
          case BudgetSuggestionStatus.expired:
            break;
        }
      }

      return {
        'totalSuggestions': totalSuggestions,
        'acceptedSuggestions': acceptedSuggestions,
        'rejectedSuggestions': rejectedSuggestions,
        'viewedSuggestions': viewedSuggestions,
        'acceptanceRate': totalSuggestions > 0
            ? (acceptedSuggestions / totalSuggestions) * 100
            : 0,
        'totalRevenue': totalRevenue,
        'averageSuggestionValue':
            acceptedSuggestions > 0 ? totalRevenue / acceptedSuggestions : 0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики предложений по бюджету: $e');
    }
  }

  /// Создать бронирование из предложения по бюджету
  Future<void> _createBookingFromBudgetSuggestion(
    BudgetSuggestion suggestion,
    BudgetSuggestionItem item,
  ) async {
    try {
      final now = DateTime.now();

      final booking = {
        'customerId': suggestion.customerId,
        'specialistId': item.specialistId,
        'categoryId': item.categoryId,
        'status': 'pending',
        'totalPrice': item.estimatedPrice,
        'description': item.description,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'metadata': {
          'budgetSuggestionId': suggestion.id,
          'budgetSuggestionItem': item.toMap(),
          'originalBookingId': suggestion.bookingId,
        },
      };

      await _firestore.collection('bookings').add(booking);
    } catch (e) {
      throw Exception(
          'Ошибка создания бронирования из предложения по бюджету: $e');
    }
  }

  /// Отправить уведомление о предложении по бюджету
  Future<void> _sendBudgetSuggestionNotification(
    String customerId,
    BudgetSuggestion suggestion,
  ) async {
    try {
      // Получаем FCM токены клиента
      final customerDoc =
          await _firestore.collection('users').doc(customerId).get();
      if (!customerDoc.exists) return;

      final customerData = customerDoc.data();
      final fcmTokens = List<String>.from(customerData?['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Рекомендуем увеличить бюджет',
        'body':
            'Добавьте ${suggestion.suggestionCount} услуг для полного комплекта мероприятия',
        'data': {
          'type': 'budget_suggestion',
          'suggestionId': suggestion.id,
          'suggestionCount': suggestion.suggestionCount.toString(),
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
              'type': 'budget_suggestion',
            },
          );
        } catch (e) {
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      debugPrint('Ошибка отправки уведомления о предложении по бюджету: $e');
    }
  }

  /// Отправить уведомление о принятии предложения по бюджету
  Future<void> _sendBudgetSuggestionAcceptedNotification(
    String specialistId,
    BudgetSuggestion suggestion,
  ) async {
    try {
      // Получаем FCM токены специалиста
      final specialistDoc =
          await _firestore.collection('users').doc(specialistId).get();
      if (!specialistDoc.exists) return;

      final specialistData = specialistDoc.data();
      final fcmTokens = List<String>.from(specialistData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Предложение по бюджету принято',
        'body':
            'Клиент принял ваше предложение увеличить бюджет на ${suggestion.totalCost.toStringAsFixed(0)} ₽',
        'data': {
          'type': 'budget_suggestion_accepted',
          'suggestionId': suggestion.id,
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
              'type': 'budget_suggestion',
            },
          );
        } catch (e) {
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      debugPrint(
          'Ошибка отправки уведомления о принятии предложения по бюджету: $e');
    }
  }

  /// Отправить уведомление об отклонении предложения по бюджету
  Future<void> _sendBudgetSuggestionRejectedNotification(
    String specialistId,
    BudgetSuggestion suggestion,
    String? reason,
  ) async {
    try {
      // Получаем FCM токены специалиста
      final specialistDoc =
          await _firestore.collection('users').doc(specialistId).get();
      if (!specialistDoc.exists) return;

      final specialistData = specialistDoc.data();
      final fcmTokens = List<String>.from(specialistData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final notification = {
        'title': 'Предложение по бюджету отклонено',
        'body': 'Клиент отклонил ваше предложение увеличить бюджет',
        'data': {
          'type': 'budget_suggestion_rejected',
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
              'type': 'budget_suggestion',
            },
          );
        } catch (e) {
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }
    } catch (e) {
      debugPrint(
          'Ошибка отправки уведомления об отклонении предложения по бюджету: $e');
    }
  }

  /// Логировать действие с предложением по бюджету
  Future<void> _logBudgetSuggestionAction(
      String suggestionId, String action, String userId) async {
    try {
      await _firestore.collection('budgetSuggestionLogs').add({
        'suggestionId': suggestionId,
        'action': action,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка логирования действия с предложением по бюджету: $e');
    }
  }

  /// Анализировать бюджет бронирования
  Future<Map<String, dynamic>> _analyzeBudget(Booking booking) async {
    try {
      // Получаем средние цены по категориям
      final categoryPrices = await _getCategoryAveragePrices();

      // Определяем недостающие категории
      final missingCategories = <String>[];
      final reasons = <String, String>{};

      // Анализируем текущий бюджет
      final currentBudget = booking.totalPrice;
      final currentCategory = booking.serviceId;

      // Определяем рекомендуемые категории
      final recommendedCategories = _getRecommendedCategories(currentCategory);

      for (final categoryId in recommendedCategories) {
        final averagePrice = categoryPrices[categoryId] ?? 0;

        // Если средняя цена не превышает 30% от текущего бюджета
        if (averagePrice > 0 && averagePrice <= currentBudget * 0.3) {
          missingCategories.add(categoryId);
          reasons[categoryId] = _getCategoryReason(categoryId, averagePrice);
        }
      }

      return {
        'missingCategories': missingCategories,
        'reasons': reasons,
        'currentBudget': currentBudget,
        'recommendedBudget': currentBudget +
            missingCategories.fold(
                0, (sum, cat) => sum + (categoryPrices[cat] ?? 0)),
      };
    } catch (e) {
      throw Exception('Ошибка анализа бюджета: $e');
    }
  }

  /// Получить средние цены по категориям
  Future<Map<String, double>> _getCategoryAveragePrices() async {
    try {
      final snapshot = await _firestore
          .collection('specialistPriceStats')
          .where('categoryId', isNotEqualTo: 'overall')
          .get();

      final categoryPrices = <String, double>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final categoryId = data['categoryId'] as String?;
        final averagePrice = (data['averagePrice'] as num?)?.toDouble() ?? 0;

        if (categoryId != null && averagePrice > 0) {
          categoryPrices[categoryId] = averagePrice;
        }
      }

      return categoryPrices;
    } catch (e) {
      return {};
    }
  }

  /// Получить рекомендуемые категории
  List<String> _getRecommendedCategories(String? currentCategoryId) {
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

  /// Получить причину для категории
  String _getCategoryReason(String categoryId, double averagePrice) {
    const reasons = {
      'photographer': 'Фотограф запечатлит важные моменты мероприятия',
      'videographer': 'Видеограф создаст памятный фильм о событии',
      'content_creator': 'Контент-мейкер создаст материалы для соцсетей',
      'photo_studio': 'Фотостудия обеспечит профессиональную съемку',
      'musician': 'Музыкант создаст атмосферу мероприятия',
      'dj': 'DJ обеспечит музыкальное сопровождение',
    };

    return reasons[categoryId] ??
        'Дополнительная услуга для улучшения мероприятия';
  }

  /// Создать предложение для категории
  Future<BudgetSuggestionItem?> _createSuggestionForCategory({
    required String categoryId,
    required Booking booking,
    required String reason,
  }) async {
    try {
      // Получаем название категории
      final categoryDoc =
          await _firestore.collection('categories').doc(categoryId).get();
      final categoryName =
          categoryDoc.data()?['name'] ?? 'Неизвестная категория';

      // Получаем рекомендуемого специалиста
      final specialist =
          await _getRecommendedSpecialist(categoryId, booking.location);

      return BudgetSuggestionItem(
        id: categoryId,
        categoryId: categoryId,
        categoryName: categoryName,
        specialistId: specialist?.id,
        specialistName: specialist?.name,
        description: reason,
        estimatedPrice:
            specialist?.hourlyRate ?? specialist?.pricePerHour ?? 0.0,
        reason: reason,
      );
    } catch (e) {
      return null;
    }
  }

  /// Получить рекомендуемого специалиста
  Future<Specialist?> _getRecommendedSpecialist(
      String categoryId, String? location) async {
    try {
      var query = _firestore
          .collection('specialists')
          .where('categories', arrayContains: categoryId)
          .where('isActive', isEqualTo: true);

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      final snapshot =
          await query.orderBy('rating', descending: true).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        return Specialist.fromDocument(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
