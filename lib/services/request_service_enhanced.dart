import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

import '../models/request_enhanced.dart';

/// Расширенный сервис для работы с заявками
class RequestServiceEnhanced {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создание заявки
  static Future<String> createRequest({
    required String title,
    required String description,
    required String category,
    required String subcategory,
    required String location,
    required String city,
    required double latitude,
    required double longitude,
    required double budget,
    required DateTime deadline,
    required RequestPriority priority,
    required List<String> attachments,
    required List<String> tags,
    required List<String> requiredSkills,
    required String language,
    required bool isRemote,
    required int maxApplicants,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final requestId = _firestore.collection('requests').doc().id;
      final now = DateTime.now();

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final request = RequestEnhanced(
        id: requestId,
        title: title,
        description: description,
        category: category,
        subcategory: subcategory,
        location: location,
        city: city,
        latitude: latitude,
        longitude: longitude,
        budget: budget,
        deadline: deadline,
        status: RequestStatus.open,
        priority: priority,
        authorId: user.uid,
        authorName: userData['name'] ?? user.displayName ?? 'Пользователь',
        authorAvatar: userData['avatar'] ?? user.photoURL ?? '',
        attachments: attachments,
        tags: tags,
        requiredSkills: requiredSkills,
        language: language,
        isRemote: isRemote,
        maxApplicants: maxApplicants,
        applicants: [],
        createdAt: now,
        updatedAt: now,
        metadata: metadata ?? {},
        timeline: [
          RequestTimeline(
            id: '${requestId}_created',
            action: 'created',
            description: 'Заявка создана',
            userId: user.uid,
            userName: userData['name'] ?? user.displayName ?? 'Пользователь',
            timestamp: now,
            metadata: {},
          ),
        ],
        aiRecommendations: await _generateAIRecommendations(
          category: category,
          subcategory: subcategory,
          city: city,
          budget: budget,
          deadline: deadline,
        ),
        isVerified: userData['isVerified'] ?? false,
        rating: 0.0,
        views: 0,
        likes: 0,
        isPinned: false,
        sharedWith: [],
        analytics: {
          'createdAt': now.toIso8601String(),
          'authorId': user.uid,
          'category': category,
          'city': city,
          'budget': budget,
        },
      );

      await _firestore.collection('requests').doc(requestId).set(request.toFirestore());

      // Добавляем в аналитику
      await _updateAnalytics('request_created', {
        'requestId': requestId,
        'category': category,
        'city': city,
        'budget': budget,
      });

      return requestId;
    } catch (e) {
      throw Exception('Ошибка создания заявки: $e');
    }
  }

  /// Получение заявок с фильтрами
  static Future<List<RequestEnhanced>> getRequests({
    RequestFilters? filters,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('requests');

      // Применяем фильтры
      if (filters != null) {
        if (filters.category != null) {
          query = query.where('category', isEqualTo: filters.category);
        }
        if (filters.subcategory != null) {
          query = query.where('subcategory', isEqualTo: filters.subcategory);
        }
        if (filters.city != null) {
          query = query.where('city', isEqualTo: filters.city);
        }
        if (filters.status != null) {
          query = query.where('status', isEqualTo: filters.status!.value);
        }
        if (filters.priority != null) {
          query = query.where('priority', isEqualTo: filters.priority!.value);
        }
        if (filters.isRemote != null) {
          query = query.where('isRemote', isEqualTo: filters.isRemote);
        }
        if (filters.language != null) {
          query = query.where('language', isEqualTo: filters.language);
        }
        if (filters.minBudget != null) {
          query = query.where('budget', isGreaterThanOrEqualTo: filters.minBudget);
        }
        if (filters.maxBudget != null) {
          query = query.where('budget', isLessThanOrEqualTo: filters.maxBudget);
        }
        if (filters.startDate != null) {
          query = query.where('deadline', isGreaterThanOrEqualTo: Timestamp.fromDate(filters.startDate!));
        }
        if (filters.endDate != null) {
          query = query.where('deadline', isLessThanOrEqualTo: Timestamp.fromDate(filters.endDate!));
        }
      }

      // Сортировка
      query = query.orderBy('createdAt', descending: true);

      // Пагинация
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => RequestEnhanced.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения заявок: $e');
    }
  }

  /// Получение заявки по ID
  static Future<RequestEnhanced?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (doc.exists) {
        return RequestEnhanced.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения заявки: $e');
    }
  }

  /// Обновление заявки
  static Future<void> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Проверяем права на редактирование
      final request = await getRequestById(requestId);
      if (request == null) throw Exception('Заявка не найдена');
      if (request.authorId != user.uid) throw Exception('Нет прав на редактирование');

      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection('requests').doc(requestId).update(updates);

      // Добавляем в таймлайн
      await _addTimelineEntry(requestId, 'updated', 'Заявка обновлена', user.uid);
    } catch (e) {
      throw Exception('Ошибка обновления заявки: $e');
    }
  }

  /// Удаление заявки
  static Future<void> deleteRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Проверяем права на удаление
      final request = await getRequestById(requestId);
      if (request == null) throw Exception('Заявка не найдена');
      if (request.authorId != user.uid) throw Exception('Нет прав на удаление');

      await _firestore.collection('requests').doc(requestId).delete();

      // Добавляем в аналитику
      await _updateAnalytics('request_deleted', {
        'requestId': requestId,
        'category': request.category,
        'city': request.city,
      });
    } catch (e) {
      throw Exception('Ошибка удаления заявки: $e');
    }
  }

  /// Отклик на заявку
  static Future<void> applyToRequest(String requestId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final request = await getRequestById(requestId);
      if (request == null) throw Exception('Заявка не найдена');
      if (request.authorId == user.uid) throw Exception('Нельзя откликнуться на свою заявку');
      if (request.applicants.contains(user.uid)) throw Exception('Вы уже откликнулись на эту заявку');
      if (request.applicants.length >= request.maxApplicants) throw Exception('Достигнуто максимальное количество откликов');

      // Добавляем отклик
      await _firestore.collection('requests').doc(requestId).update({
        'applicants': FieldValue.arrayUnion([user.uid]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Создаем уведомление для автора
      await _createNotification(
        userId: request.authorId,
        title: 'Новый отклик на заявку',
        body: 'На вашу заявку "${request.title}" поступил новый отклик',
        data: {'requestId': requestId, 'type': 'request_application'},
      );

      // Добавляем в таймлайн
      await _addTimelineEntry(requestId, 'application', 'Новый отклик', user.uid);

      // Добавляем в аналитику
      await _updateAnalytics('request_application', {
        'requestId': requestId,
        'applicantId': user.uid,
        'category': request.category,
      });
    } catch (e) {
      throw Exception('Ошибка отклика на заявку: $e');
    }
  }

  /// Выбор исполнителя
  static Future<void> selectApplicant(String requestId, String applicantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final request = await getRequestById(requestId);
      if (request == null) throw Exception('Заявка не найдена');
      if (request.authorId != user.uid) throw Exception('Нет прав на выбор исполнителя');
      if (!request.applicants.contains(applicantId)) throw Exception('Пользователь не откликнулся на заявку');

      // Обновляем заявку
      await _firestore.collection('requests').doc(requestId).update({
        'selectedApplicantId': applicantId,
        'status': RequestStatus.inProgress.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Создаем уведомление для исполнителя
      await _createNotification(
        userId: applicantId,
        title: 'Вас выбрали исполнителем',
        body: 'Вас выбрали исполнителем для заявки "${request.title}"',
        data: {'requestId': requestId, 'type': 'request_selected'},
      );

      // Добавляем в таймлайн
      await _addTimelineEntry(requestId, 'selected', 'Исполнитель выбран', user.uid);

      // Добавляем в аналитику
      await _updateAnalytics('request_selected', {
        'requestId': requestId,
        'selectedApplicantId': applicantId,
        'category': request.category,
      });
    } catch (e) {
      throw Exception('Ошибка выбора исполнителя: $e');
    }
  }

  /// Завершение заявки
  static Future<void> completeRequest(String requestId, String? review, double? rating) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final request = await getRequestById(requestId);
      if (request == null) throw Exception('Заявка не найдена');
      if (request.authorId != user.uid) throw Exception('Нет прав на завершение заявки');

      // Обновляем заявку
      await _firestore.collection('requests').doc(requestId).update({
        'status': RequestStatus.completed.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Если есть отзыв и рейтинг, добавляем их
      if (review != null && rating != null && request.selectedApplicantId != null) {
        await _addReview(request.selectedApplicantId!, user.uid, review, rating);
      }

      // Добавляем в таймлайн
      await _addTimelineEntry(requestId, 'completed', 'Заявка завершена', user.uid);

      // Добавляем в аналитику
      await _updateAnalytics('request_completed', {
        'requestId': requestId,
        'category': request.category,
        'rating': rating,
      });
    } catch (e) {
      throw Exception('Ошибка завершения заявки: $e');
    }
  }

  /// Получение заявок пользователя
  static Future<List<RequestEnhanced>> getUserRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => RequestEnhanced.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения заявок пользователя: $e');
    }
  }

  /// Получение заявок по геолокации
  static Future<List<RequestEnhanced>> getNearbyRequests({
    required double latitude,
    required double longitude,
    required double radiusKm,
    RequestFilters? filters,
  }) async {
    try {
      // Получаем все заявки (Firestore не поддерживает геопространственные запросы)
      final allRequests = await getRequests(filters: filters, limit: 1000);
      
      // Фильтруем по расстоянию
      final nearbyRequests = <RequestEnhanced>[];
      for (final request in allRequests) {
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          request.latitude,
          request.longitude,
        );
        
        if (distance <= radiusKm * 1000) {
          nearbyRequests.add(request);
        }
      }

      // Сортируем по расстоянию
      nearbyRequests.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          latitude,
          longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = Geolocator.distanceBetween(
          latitude,
          longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return nearbyRequests;
    } catch (e) {
      throw Exception('Ошибка получения ближайших заявок: $e');
    }
  }

  /// AI рекомендации для заявки
  static Future<Map<String, dynamic>> _generateAIRecommendations({
    required String category,
    required String subcategory,
    required String city,
    required double budget,
    required DateTime deadline,
  }) async {
    // Здесь можно интегрировать с AI сервисом
    // Пока возвращаем базовые рекомендации
    return {
      'suggestedBudget': budget * 1.1, // +10% к бюджету
      'suggestedDeadline': deadline.add(const Duration(days: 1)),
      'suggestedSkills': _getSuggestedSkills(category, subcategory),
      'suggestedTags': _getSuggestedTags(category, subcategory),
      'marketAnalysis': {
        'averageBudget': budget * 0.9,
        'competitionLevel': _getCompetitionLevel(category, city),
        'successRate': _getSuccessRate(category, city),
      },
    };
  }

  /// Получение рекомендуемых навыков
  static List<String> _getSuggestedSkills(String category, String subcategory) {
    final skillsMap = {
      'photography': ['Фотография', 'Обработка фото', 'Студийная съемка'],
      'catering': ['Кулинария', 'Сервировка', 'Меню'],
      'music': ['Игра на инструментах', 'Вокал', 'DJ'],
      'decoration': ['Дизайн', 'Декорирование', 'Цветы'],
    };
    
    return skillsMap[category] ?? ['Навыки по категории'];
  }

  /// Получение рекомендуемых тегов
  static List<String> _getSuggestedTags(String category, String subcategory) {
    final tagsMap = {
      'photography': ['фото', 'съемка', 'портрет'],
      'catering': ['еда', 'кейтеринг', 'банкет'],
      'music': ['музыка', 'концерт', 'звук'],
      'decoration': ['декор', 'украшение', 'стиль'],
    };
    
    return tagsMap[category] ?? ['тег1', 'тег2'];
  }

  /// Получение уровня конкуренции
  static String _getCompetitionLevel(String category, String city) {
    final random = Random();
    final levels = ['Низкий', 'Средний', 'Высокий'];
    return levels[random.nextInt(levels.length)];
  }

  /// Получение процента успеха
  static double _getSuccessRate(String category, String city) {
    final random = Random();
    return 0.7 + random.nextDouble() * 0.3; // 70-100%
  }

  /// Добавление записи в таймлайн
  static Future<void> _addTimelineEntry(
    String requestId,
    String action,
    String description,
    String userId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final timelineEntry = RequestTimeline(
        id: '${requestId}_${DateTime.now().millisecondsSinceEpoch}',
        action: action,
        description: description,
        userId: userId,
        userName: userData['name'] ?? 'Пользователь',
        timestamp: DateTime.now(),
        metadata: {},
      );

      await _firestore.collection('requests').doc(requestId).update({
        'timeline': FieldValue.arrayUnion([timelineEntry.toMap()]),
      });
    } catch (e) {
      print('Ошибка добавления в таймлайн: $e');
    }
  }

  /// Создание уведомления
  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка создания уведомления: $e');
    }
  }

  /// Добавление отзыва
  static Future<void> _addReview(
    String userId,
    String authorId,
    String review,
    double rating,
  ) async {
    try {
      await _firestore.collection('reviews').add({
        'userId': userId,
        'authorId': authorId,
        'review': review,
        'rating': rating,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем рейтинг пользователя
      await _updateUserRating(userId, rating);
    } catch (e) {
      print('Ошибка добавления отзыва: $e');
    }
  }

  /// Обновление рейтинга пользователя
  static Future<void> _updateUserRating(String userId, double rating) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final currentRating = (userData['rating'] ?? 0.0).toDouble();
      final reviewCount = (userData['reviewCount'] ?? 0) + 1;
      final newRating = (currentRating * (reviewCount - 1) + rating) / reviewCount;

      await _firestore.collection('users').doc(userId).update({
        'rating': newRating,
        'reviewCount': reviewCount,
      });
    } catch (e) {
      print('Ошибка обновления рейтинга: $e');
    }
  }

  /// Обновление аналитики
  static Future<void> _updateAnalytics(String event, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('analytics').add({
        'event': event,
        'data': data,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка обновления аналитики: $e');
    }
  }
}



