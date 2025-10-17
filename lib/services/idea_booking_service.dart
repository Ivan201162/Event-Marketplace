import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../models/booking.dart';
import '../models/event_idea.dart';

/// Сервис для интеграции идей с заявками
class IdeaBookingService {
  factory IdeaBookingService() => _instance;
  IdeaBookingService._internal();

  static final IdeaBookingService _instance = IdeaBookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Прикрепить идею к заявке
  Future<void> attachIdeaToBooking({
    required String bookingId,
    required String ideaId,
    required String userId,
    String? notes,
  }) async {
    try {
      final attachmentId = _uuid.v4();
      final now = DateTime.now();

      final attachment = {
        'id': attachmentId,
        'bookingId': bookingId,
        'ideaId': ideaId,
        'userId': userId,
        'notes': notes,
        'attachedAt': Timestamp.fromDate(now),
      };

      await _firestore.collection('idea_booking_attachments').doc(attachmentId).set(attachment);

      // Обновляем заявку, добавляя ID прикрепленной идеи
      await _firestore.collection('bookings').doc(bookingId).update({
        'attachedIdeas': FieldValue.arrayUnion([ideaId]),
        'updatedAt': Timestamp.fromDate(now),
      });

      AppLogger.logI(
        'Прикреплена идея $ideaId к заявке $bookingId',
        'idea_booking_service',
      );
    } on Exception catch (e) {
      AppLogger.logE(
        'Ошибка прикрепления идеи к заявке',
        'idea_booking_service',
        e,
      );
      rethrow;
    }
  }

  /// Открепить идею от заявки
  Future<void> detachIdeaFromBooking({
    required String bookingId,
    required String ideaId,
  }) async {
    try {
      // Удаляем прикрепление
      final snapshot = await _firestore
          .collection('idea_booking_attachments')
          .where('bookingId', isEqualTo: bookingId)
          .where('ideaId', isEqualTo: ideaId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Обновляем заявку, удаляя ID идеи
      batch.update(_firestore.collection('bookings').doc(bookingId), {
        'attachedIdeas': FieldValue.arrayRemove([ideaId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();

      AppLogger.logI(
        'Откреплена идея $ideaId от заявки $bookingId',
        'idea_booking_service',
      );
    } on Exception catch (e) {
      AppLogger.logE(
        'Ошибка открепления идеи от заявки',
        'idea_booking_service',
        e,
      );
      rethrow;
    }
  }

  /// Получить идеи, прикрепленные к заявке
  Future<List<EventIdea>> getBookingAttachedIdeas(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('idea_booking_attachments')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final ideaIds = snapshot.docs.map((doc) => doc.data()['ideaId'] as String).toList();

      final ideasSnapshot = await _firestore
          .collection('event_ideas')
          .where(FieldPath.documentId, whereIn: ideaIds)
          .get();

      final ideas = ideasSnapshot.docs.map((doc) => EventIdea.fromMap(doc.data())).toList();

      AppLogger.logI(
        'Получено идей для заявки $bookingId: ${ideas.length}',
        'idea_booking_service',
      );
      return ideas;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения идей заявки', 'idea_booking_service', e);
      rethrow;
    }
  }

  /// Получить заявки, к которым прикреплена идея
  Future<List<Booking>> getIdeaAttachedBookings(String ideaId) async {
    try {
      final snapshot = await _firestore
          .collection('idea_booking_attachments')
          .where('ideaId', isEqualTo: ideaId)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final bookingIds = snapshot.docs.map((doc) => doc.data()['bookingId'] as String).toList();

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where(FieldPath.documentId, whereIn: bookingIds)
          .get();

      final bookings = bookingsSnapshot.docs.map(Booking.fromDocument).toList();

      AppLogger.logI(
        'Получено заявок для идеи $ideaId: ${bookings.length}',
        'idea_booking_service',
      );
      return bookings;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения заявок идеи', 'idea_booking_service', e);
      rethrow;
    }
  }

  /// Проверить, прикреплена ли идея к заявке
  Future<bool> isIdeaAttachedToBooking({
    required String bookingId,
    required String ideaId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('idea_booking_attachments')
          .where('bookingId', isEqualTo: bookingId)
          .where('ideaId', isEqualTo: ideaId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } on Exception catch (e) {
      AppLogger.logE(
        'Ошибка проверки прикрепления идеи',
        'idea_booking_service',
        e,
      );
      return false;
    }
  }

  /// Получить все прикрепления пользователя
  Future<List<Map<String, dynamic>>> getUserIdeaAttachments(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('idea_booking_attachments')
          .where('userId', isEqualTo: userId)
          .orderBy('attachedAt', descending: true)
          .get();

      final attachments = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();

      AppLogger.logI(
        'Получено прикреплений пользователя $userId: ${attachments.length}',
        'idea_booking_service',
      );
      return attachments;
    } on Exception catch (e) {
      AppLogger.logE(
        'Ошибка получения прикреплений пользователя',
        'idea_booking_service',
        e,
      );
      rethrow;
    }
  }

  /// Получить статистику использования идей в заявках
  Future<Map<String, int>> getIdeaUsageStats() async {
    try {
      final snapshot = await _firestore.collection('idea_booking_attachments').get();

      final stats = <String, int>{};
      for (final doc in snapshot.docs) {
        final ideaId = doc.data()['ideaId'] as String;
        stats[ideaId] = (stats[ideaId] ?? 0) + 1;
      }

      AppLogger.logI(
        'Получена статистика использования идей',
        'idea_booking_service',
      );
      return stats;
    } on Exception catch (e) {
      AppLogger.logE(
        'Ошибка получения статистики идей',
        'idea_booking_service',
        e,
      );
      return {};
    }
  }
}
