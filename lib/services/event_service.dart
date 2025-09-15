import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

/// Сервис для работы с событиями
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все события
  Stream<List<Event>> getAllEvents() {
    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Получить события пользователя
  Stream<List<Event>> getUserEvents(String userId) {
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Получить событие по ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return Event.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения события: $e');
    }
  }

  /// Создать новое событие
  Future<String> createEvent(Event event) async {
    try {
      final docRef = await _firestore.collection('events').add(event.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания события: $e');
    }
  }

  /// Обновить событие
  Future<void> updateEvent(String eventId, Event event) async {
    try {
      await _firestore.collection('events').doc(eventId).update(event.toMap());
    } catch (e) {
      throw Exception('Ошибка обновления события: $e');
    }
  }

  /// Удалить событие
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления события: $e');
    }
  }

  /// Поиск событий
  Stream<List<Event>> searchEvents(String query) {
    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Получить события по категории
  Stream<List<Event>> getEventsByCategory(EventCategory category) {
    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('category', isEqualTo: category.name)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Получить события по дате
  Stream<List<Event>> getEventsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Получить события в диапазоне дат
  Stream<List<Event>> getEventsByDateRange(DateTime startDate, DateTime endDate) {
    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Получить популярные события
  Stream<List<Event>> getPopularEvents({int limit = 10}) {
    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('currentParticipants', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Получить ближайшие события
  Stream<List<Event>> getUpcomingEvents({int limit = 10}) {
    final now = DateTime.now();
    
    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('date', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }

  /// Обновить количество участников
  Future<void> updateParticipantsCount(String eventId, int newCount) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'currentParticipants': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка обновления количества участников: $e');
    }
  }

  /// Изменить статус события
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка обновления статуса события: $e');
    }
  }

  /// Получить статистику событий пользователя
  Future<Map<String, int>> getUserEventStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          .get();

      int total = 0;
      int active = 0;
      int completed = 0;
      int cancelled = 0;

      for (final doc in snapshot.docs) {
        final event = Event.fromDocument(doc);
        total++;
        
        switch (event.status) {
          case EventStatus.active:
            active++;
            break;
          case EventStatus.completed:
            completed++;
            break;
          case EventStatus.cancelled:
            cancelled++;
            break;
          default:
            break;
        }
      }

      return {
        'total': total,
        'active': active,
        'completed': completed,
        'cancelled': cancelled,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Получить события с фильтрацией
  Stream<List<Event>> getFilteredEvents(EventFilter filter) {
    Query query = _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: 'active');

    // Фильтр по дате
    if (filter.startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
    }
    if (filter.endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
    }

    // Фильтр по категории
    if (filter.categories != null && filter.categories!.isNotEmpty) {
      query = query.where('category', whereIn: filter.categories!.map((c) => c.name).toList());
    }

    // Фильтр по цене
    if (filter.minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: filter.minPrice!);
    }
    if (filter.maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: filter.maxPrice!);
    }

    // Фильтр по организатору
    if (filter.organizerId != null) {
      query = query.where('organizerId', isEqualTo: filter.organizerId!);
    }

    return query
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromDocument(doc))
            .toList());
  }
}
