import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_organizer.dart';
import 'error_logging_service.dart';

/// Сервис для работы с организаторами мероприятий
class EventOrganizerService {
  factory EventOrganizerService() => _instance;
  EventOrganizerService._internal();
  static final EventOrganizerService _instance =
      EventOrganizerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  /// Получить организатора по ID пользователя
  Future<EventOrganizer?> getOrganizerByUserId(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('event_organizers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return EventOrganizer.fromDoc(snapshot.docs.first);
      }
      return null;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get organizer by user ID: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_organizer_by_user_id',
        additionalData: {'userId': userId},
      );
      return null;
    }
  }

  /// Получить организатора по ID
  Future<EventOrganizer?> getOrganizerById(String organizerId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('event_organizers')
          .doc(organizerId)
          .get();

      if (doc.exists) {
        return EventOrganizer.fromDoc(doc);
      }
      return null;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get organizer by ID: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_organizer_by_id',
        additionalData: {'organizerId': organizerId},
      );
      return null;
    }
  }

  /// Получить всех организаторов
  Future<List<EventOrganizer>> getAllOrganizers({
    String? city,
    List<String>? eventTypes,
    List<String>? specializations,
    double? minRating,
    bool? isVerified,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('event_organizers');

      // Фильтры
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }
      if (isVerified != null) {
        query = query.where('isVerified', isEqualTo: isVerified);
      }
      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Сортировка по рейтингу
      query = query.orderBy('rating', descending: true).limit(limit);

      final snapshot = await query.get();
      var organizers = snapshot.docs.map(EventOrganizer.fromDoc).toList();

      // Дополнительная фильтрация на клиенте
      if (eventTypes != null && eventTypes.isNotEmpty) {
        organizers = organizers
            .where((organizer) =>
                eventTypes.any((type) => organizer.eventTypes.contains(type)))
            .toList();
      }

      if (specializations != null && specializations.isNotEmpty) {
        organizers = organizers
            .where(
              (organizer) => specializations
                  .any((spec) => organizer.specializations.contains(spec)),
            )
            .toList();
      }

      return organizers;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get all organizers: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_all_organizers',
        additionalData: {
          'city': city,
          'eventTypes': eventTypes,
          'specializations': specializations,
          'minRating': minRating,
          'isVerified': isVerified,
        },
      );
      return [];
    }
  }

  /// Создать организатора
  Future<EventOrganizer?> createOrganizer({
    required String userId,
    required String companyName,
    String? description,
    String? website,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? region,
    required List<String> eventTypes,
    required List<String> specializations,
    Map<String, dynamic>? socialLinks,
    List<String>? portfolioImages,
    Map<String, dynamic>? businessHours,
    String? licenseNumber,
    String? taxId,
  }) async {
    try {
      final now = DateTime.now();
      final organizerId = _firestore.collection('event_organizers').doc().id;

      final organizer = EventOrganizer(
        id: organizerId,
        userId: userId,
        companyName: companyName,
        description: description,
        website: website,
        phone: phone,
        email: email,
        address: address,
        city: city,
        region: region,
        eventTypes: eventTypes,
        specializations: specializations,
        totalEvents: 0,
        completedEvents: 0,
        createdAt: now,
        updatedAt: now,
        isVerified: false,
        isActive: true,
        socialLinks: socialLinks,
        portfolioImages: portfolioImages,
        businessHours: businessHours,
        licenseNumber: licenseNumber,
        taxId: taxId,
      );

      await _firestore
          .collection('event_organizers')
          .doc(organizerId)
          .set(organizer.toMap());

      await _errorLogger.logInfo(
        message: 'Event organizer created',
        userId: userId,
        action: 'create_organizer',
        additionalData: {'organizerId': organizerId},
      );

      return organizer;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to create organizer: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'create_organizer',
      );
      return null;
    }
  }

  /// Обновить организатора
  Future<bool> updateOrganizer(
      String organizerId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('event_organizers')
          .doc(organizerId)
          .update(updates);

      await _errorLogger.logInfo(
        message: 'Event organizer updated',
        action: 'update_organizer',
        additionalData: {'organizerId': organizerId, 'updates': updates},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update organizer: $e',
        stackTrace: stackTrace.toString(),
        action: 'update_organizer',
        additionalData: {'organizerId': organizerId},
      );
      return false;
    }
  }

  /// Удалить организатора
  Future<bool> deleteOrganizer(String organizerId) async {
    try {
      await _firestore.collection('event_organizers').doc(organizerId).delete();

      await _errorLogger.logInfo(
        message: 'Event organizer deleted',
        action: 'delete_organizer',
        additionalData: {'organizerId': organizerId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to delete organizer: $e',
        stackTrace: stackTrace.toString(),
        action: 'delete_organizer',
        additionalData: {'organizerId': organizerId},
      );
      return false;
    }
  }

  /// Поиск организаторов
  Future<List<EventOrganizer>> searchOrganizers({
    String? query,
    String? city,
    List<String>? eventTypes,
    List<String>? specializations,
    double? minRating,
    double? maxRating,
    bool? isVerified,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('event_organizers');

      // Базовые фильтры
      if (city != null && city.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('city', isEqualTo: city);
      }
      if (isVerified != null) {
        firestoreQuery =
            firestoreQuery.where('isVerified', isEqualTo: isVerified);
      }
      if (minRating != null) {
        firestoreQuery =
            firestoreQuery.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Сортировка
      firestoreQuery =
          firestoreQuery.orderBy('rating', descending: true).limit(limit * 2);

      final snapshot = await firestoreQuery.get();
      var organizers = snapshot.docs.map(EventOrganizer.fromDoc).toList();

      // Фильтрация на клиенте
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        organizers = organizers
            .where(
              (organizer) =>
                  organizer.companyName.toLowerCase().contains(lowerQuery) ||
                  (organizer.description?.toLowerCase().contains(lowerQuery) ??
                      false) ||
                  organizer.specializations.any(
                    (spec) => spec.toLowerCase().contains(lowerQuery),
                  ) ||
                  organizer.eventTypes
                      .any((type) => type.toLowerCase().contains(lowerQuery)),
            )
            .toList();
      }

      if (eventTypes != null && eventTypes.isNotEmpty) {
        organizers = organizers
            .where((organizer) =>
                eventTypes.any((type) => organizer.eventTypes.contains(type)))
            .toList();
      }

      if (specializations != null && specializations.isNotEmpty) {
        organizers = organizers
            .where(
              (organizer) => specializations
                  .any((spec) => organizer.specializations.contains(spec)),
            )
            .toList();
      }

      if (maxRating != null) {
        organizers = organizers
            .where((organizer) =>
                organizer.rating == null || organizer.rating! <= maxRating)
            .toList();
      }

      return organizers.take(limit).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to search organizers: $e',
        stackTrace: stackTrace.toString(),
        action: 'search_organizers',
        additionalData: {
          'query': query,
          'city': city,
          'eventTypes': eventTypes,
          'specializations': specializations,
          'minRating': minRating,
          'maxRating': maxRating,
          'isVerified': isVerified,
        },
      );
      return [];
    }
  }

  /// Получить топ организаторов
  Future<List<EventOrganizer>> getTopOrganizers(
      {int limit = 10, String? city}) async {
    try {
      Query query = _firestore.collection('event_organizers');

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      query = query
          .where('isVerified', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map(EventOrganizer.fromDoc).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get top organizers: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_top_organizers',
        additionalData: {'city': city, 'limit': limit},
      );
      return [];
    }
  }

  /// Обновить рейтинг организатора
  Future<bool> updateOrganizerRating(
      String organizerId, double newRating) async {
    try {
      await _firestore.collection('event_organizers').doc(organizerId).update({
        'rating': newRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update organizer rating: $e',
        stackTrace: stackTrace.toString(),
        action: 'update_organizer_rating',
        additionalData: {'organizerId': organizerId, 'newRating': newRating},
      );
      return false;
    }
  }

  /// Увеличить счетчик мероприятий
  Future<bool> incrementEventCount(String organizerId,
      {bool completed = false}) async {
    try {
      final updates = <String, dynamic>{
        'totalEvents': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (completed) {
        updates['completedEvents'] = FieldValue.increment(1);
      }

      await _firestore
          .collection('event_organizers')
          .doc(organizerId)
          .update(updates);

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to increment event count: $e',
        stackTrace: stackTrace.toString(),
        action: 'increment_event_count',
        additionalData: {'organizerId': organizerId, 'completed': completed},
      );
      return false;
    }
  }

  /// Получить статистику организатора
  Future<Map<String, dynamic>> getOrganizerStats(String organizerId) async {
    try {
      final organizer = await getOrganizerById(organizerId);
      if (organizer == null) return {};

      // Получаем отзывы
      final reviewsSnapshot = await _firestore
          .collection('organizer_reviews')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      final reviews = reviewsSnapshot.docs;
      final totalReviews = reviews.length;
      final averageRating = totalReviews > 0
          ? reviews
                  .map((doc) => doc.data()['rating'] as double)
                  .reduce((a, b) => a + b) /
              totalReviews
          : 0.0;

      // Получаем мероприятия
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      final events = eventsSnapshot.docs;
      final totalEvents = events.length;
      final completedEvents =
          events.where((doc) => doc.data()['status'] == 'completed').length;

      return {
        'organizer': organizer,
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'totalEvents': totalEvents,
        'completedEvents': completedEvents,
        'completionRate': totalEvents > 0 ? completedEvents / totalEvents : 0.0,
      };
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get organizer stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_organizer_stats',
        additionalData: {'organizerId': organizerId},
      );
      return {};
    }
  }

  /// Проверить, является ли пользователь организатором
  Future<bool> isUserOrganizer(String userId) async {
    try {
      final organizer = await getOrganizerByUserId(userId);
      return organizer != null && organizer.isActive;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to check if user is organizer: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'is_user_organizer',
      );
      return false;
    }
  }
}
