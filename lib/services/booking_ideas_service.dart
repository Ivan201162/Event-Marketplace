import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/idea.dart';
import '../models/event_idea.dart';
import '../models/saved_idea.dart';

/// Сервис для работы с идеями в заявках
class BookingIdeasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Прикрепить идею к заявке
  Future<void> attachIdeaToBooking({
    required String bookingId,
    required String ideaId,
    required String userId,
    String? notes,
  }) async {
    try {
      await _firestore.collection('booking_ideas').add({
        'bookingId': bookingId,
        'ideaId': ideaId,
        'userId': userId,
        'attachedAt': FieldValue.serverTimestamp(),
        'notes': notes,
        'isActive': true,
      });

      // Увеличиваем счетчик использования идеи
      await _firestore.collection('ideas').doc(ideaId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Идея $ideaId прикреплена к заявке $bookingId');
    } catch (e) {
      debugPrint('Error attaching idea to booking: $e');
      throw Exception('Ошибка прикрепления идеи к заявке: $e');
    }
  }

  /// Прикрепить идею мероприятия к заявке
  Future<void> attachEventIdeaToBooking({
    required String bookingId,
    required String eventIdeaId,
    required String userId,
    String? notes,
  }) async {
    try {
      await _firestore.collection('booking_event_ideas').add({
        'bookingId': bookingId,
        'eventIdeaId': eventIdeaId,
        'userId': userId,
        'attachedAt': FieldValue.serverTimestamp(),
        'notes': notes,
        'isActive': true,
      });

      // Увеличиваем счетчик использования идеи
      await _firestore.collection('event_ideas').doc(eventIdeaId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Идея мероприятия $eventIdeaId прикреплена к заявке $bookingId');
    } catch (e) {
      debugPrint('Error attaching event idea to booking: $e');
      throw Exception('Ошибка прикрепления идеи мероприятия к заявке: $e');
    }
  }

  /// Открепить идею от заявки
  Future<void> detachIdeaFromBooking({
    required String bookingId,
    required String ideaId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('booking_ideas')
          .where('bookingId', isEqualTo: bookingId)
          .where('ideaId', isEqualTo: ideaId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Уменьшаем счетчик использования идеи
      await _firestore.collection('ideas').doc(ideaId).update({
        'usageCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Идея $ideaId откреплена от заявки $bookingId');
    } catch (e) {
      debugPrint('Error detaching idea from booking: $e');
      throw Exception('Ошибка открепления идеи от заявки: $e');
    }
  }

  /// Открепить идею мероприятия от заявки
  Future<void> detachEventIdeaFromBooking({
    required String bookingId,
    required String eventIdeaId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('booking_event_ideas')
          .where('bookingId', isEqualTo: bookingId)
          .where('eventIdeaId', isEqualTo: eventIdeaId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Уменьшаем счетчик использования идеи
      await _firestore.collection('event_ideas').doc(eventIdeaId).update({
        'usageCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Идея мероприятия $eventIdeaId откреплена от заявки $bookingId');
    } catch (e) {
      debugPrint('Error detaching event idea from booking: $e');
      throw Exception('Ошибка открепления идеи мероприятия от заявки: $e');
    }
  }

  /// Получить все идеи, прикрепленные к заявке
  Future<List<Idea>> getBookingIdeas(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('booking_ideas')
          .where('bookingId', isEqualTo: bookingId)
          .where('isActive', isEqualTo: true)
          .get();

      final ideas = <Idea>[];
      for (final doc in snapshot.docs) {
        final ideaId = doc.data()['ideaId'] as String;
        final ideaDoc = await _firestore.collection('ideas').doc(ideaId).get();
        if (ideaDoc.exists) {
          ideas.add(Idea.fromMap({
            'id': ideaDoc.id,
            ...ideaDoc.data()!,
          }));
        }
      }

      return ideas;
    } catch (e) {
      debugPrint('Error getting booking ideas: $e');
      return [];
    }
  }

  /// Получить все идеи мероприятий, прикрепленные к заявке
  Future<List<EventIdea>> getBookingEventIdeas(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('booking_event_ideas')
          .where('bookingId', isEqualTo: bookingId)
          .where('isActive', isEqualTo: true)
          .get();

      final ideas = <EventIdea>[];
      for (final doc in snapshot.docs) {
        final ideaId = doc.data()['eventIdeaId'] as String;
        final ideaDoc = await _firestore.collection('event_ideas').doc(ideaId).get();
        if (ideaDoc.exists) {
          ideas.add(EventIdea.fromDocument(ideaDoc));
        }
      }

      return ideas;
    } catch (e) {
      debugPrint('Error getting booking event ideas: $e');
      return [];
    }
  }

  /// Получить все заявки, к которым прикреплена идея
  Future<List<Booking>> getIdeaBookings(String ideaId) async {
    try {
      final snapshot = await _firestore
          .collection('booking_ideas')
          .where('ideaId', isEqualTo: ideaId)
          .where('isActive', isEqualTo: true)
          .get();

      final bookings = <Booking>[];
      for (final doc in snapshot.docs) {
        final bookingId = doc.data()['bookingId'] as String;
        final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
        if (bookingDoc.exists) {
          bookings.add(Booking.fromDocument(bookingDoc));
        }
      }

      return bookings;
    } catch (e) {
      debugPrint('Error getting idea bookings: $e');
      return [];
    }
  }

  /// Получить все заявки, к которым прикреплена идея мероприятия
  Future<List<Booking>> getEventIdeaBookings(String eventIdeaId) async {
    try {
      final snapshot = await _firestore
          .collection('booking_event_ideas')
          .where('eventIdeaId', isEqualTo: eventIdeaId)
          .where('isActive', isEqualTo: true)
          .get();

      final bookings = <Booking>[];
      for (final doc in snapshot.docs) {
        final bookingId = doc.data()['bookingId'] as String;
        final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
        if (bookingDoc.exists) {
          bookings.add(Booking.fromDocument(bookingDoc));
        }
      }

      return bookings;
    } catch (e) {
      debugPrint('Error getting event idea bookings: $e');
      return [];
    }
  }

  /// Получить статистику использования идей
  Future<Map<String, dynamic>> getIdeaUsageStats(String ideaId) async {
    try {
      final bookings = await getIdeaBookings(ideaId);
      
      return {
        'totalBookings': bookings.length,
        'activeBookings': bookings.where((b) => b.status == BookingStatus.confirmed).length,
        'completedBookings': bookings.where((b) => b.status == BookingStatus.completed).length,
        'totalRevenue': bookings.fold(0.0, (sum, booking) => sum + booking.totalPrice),
      };
    } catch (e) {
      debugPrint('Error getting idea usage stats: $e');
      return {};
    }
  }

  /// Получить статистику использования идей мероприятий
  Future<Map<String, dynamic>> getEventIdeaUsageStats(String eventIdeaId) async {
    try {
      final bookings = await getEventIdeaBookings(eventIdeaId);
      
      return {
        'totalBookings': bookings.length,
        'activeBookings': bookings.where((b) => b.status == BookingStatus.confirmed).length,
        'completedBookings': bookings.where((b) => b.status == BookingStatus.completed).length,
        'totalRevenue': bookings.fold(0.0, (sum, booking) => sum + booking.totalPrice),
      };
    } catch (e) {
      debugPrint('Error getting event idea usage stats: $e');
      return {};
    }
  }

  /// Создать доску вдохновения для заявки
  Future<String> createInspirationBoard({
    required String bookingId,
    required String userId,
    required String title,
    String? description,
    List<String>? ideaIds,
    List<String>? eventIdeaIds,
  }) async {
    try {
      final docRef = await _firestore.collection('inspiration_boards').add({
        'bookingId': bookingId,
        'userId': userId,
        'title': title,
        'description': description,
        'ideaIds': ideaIds ?? [],
        'eventIdeaIds': eventIdeaIds ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      debugPrint('Доска вдохновения создана: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating inspiration board: $e');
      throw Exception('Ошибка создания доски вдохновения: $e');
    }
  }

  /// Обновить доску вдохновения
  Future<void> updateInspirationBoard({
    required String boardId,
    String? title,
    String? description,
    List<String>? ideaIds,
    List<String>? eventIdeaIds,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (ideaIds != null) updates['ideaIds'] = ideaIds;
      if (eventIdeaIds != null) updates['eventIdeaIds'] = eventIdeaIds;

      await _firestore.collection('inspiration_boards').doc(boardId).update(updates);

      debugPrint('Доска вдохновения обновлена: $boardId');
    } catch (e) {
      debugPrint('Error updating inspiration board: $e');
      throw Exception('Ошибка обновления доски вдохновения: $e');
    }
  }

  /// Получить доску вдохновения для заявки
  Future<Map<String, dynamic>?> getInspirationBoard(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('inspiration_boards')
          .where('bookingId', isEqualTo: bookingId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error getting inspiration board: $e');
      return null;
    }
  }

  /// Добавить заметку к прикрепленной идее
  Future<void> addNoteToAttachedIdea({
    required String bookingId,
    required String ideaId,
    required String userId,
    required String note,
  }) async {
    try {
      await _firestore.collection('booking_idea_notes').add({
        'bookingId': bookingId,
        'ideaId': ideaId,
        'userId': userId,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Заметка добавлена к идее $ideaId в заявке $bookingId');
    } catch (e) {
      debugPrint('Error adding note to attached idea: $e');
      throw Exception('Ошибка добавления заметки к идее: $e');
    }
  }

  /// Получить заметки к прикрепленной идее
  Future<List<Map<String, dynamic>>> getAttachedIdeaNotes({
    required String bookingId,
    required String ideaId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('booking_idea_notes')
          .where('bookingId', isEqualTo: bookingId)
          .where('ideaId', isEqualTo: ideaId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting attached idea notes: $e');
      return [];
    }
  }

  /// Поделиться доской вдохновения со специалистом
  Future<void> shareInspirationBoardWithSpecialist({
    required String boardId,
    required String specialistId,
    required String customerId,
    String? message,
  }) async {
    try {
      await _firestore.collection('shared_inspiration_boards').add({
        'boardId': boardId,
        'specialistId': specialistId,
        'customerId': customerId,
        'message': message,
        'sharedAt': FieldValue.serverTimestamp(),
        'isViewed': false,
        'isActive': true,
      });

      debugPrint('Доска вдохновения $boardId поделена со специалистом $specialistId');
    } catch (e) {
      debugPrint('Error sharing inspiration board: $e');
      throw Exception('Ошибка поделиться доской вдохновения: $e');
    }
  }

  /// Получить поделенные доски вдохновения для специалиста
  Future<List<Map<String, dynamic>>> getSharedInspirationBoards(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('shared_inspiration_boards')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .orderBy('sharedAt', descending: true)
          .get();

      final boards = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final boardId = doc.data()['boardId'] as String;
        final boardDoc = await _firestore.collection('inspiration_boards').doc(boardId).get();
        if (boardDoc.exists) {
          boards.add({
            'shareId': doc.id,
            'boardId': boardId,
            'boardData': {
              'id': boardDoc.id,
              ...boardDoc.data()!,
            },
            'shareData': doc.data(),
          });
        }
      }

      return boards;
    } catch (e) {
      debugPrint('Error getting shared inspiration boards: $e');
      return [];
    }
  }

  /// Отметить доску вдохновения как просмотренную
  Future<void> markInspirationBoardAsViewed(String shareId) async {
    try {
      await _firestore.collection('shared_inspiration_boards').doc(shareId).update({
        'isViewed': true,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Доска вдохновения отмечена как просмотренная: $shareId');
    } catch (e) {
      debugPrint('Error marking inspiration board as viewed: $e');
    }
  }
}
