import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для работы с календарем
class CalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создание события
  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? location,
    List<String>? participants,
    String? specialistId,
    String? requestId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final eventData = {
        'title': title,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'location': location,
        'participants': participants ?? [],
        'specialistId': specialistId,
        'requestId': requestId,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('events').add(eventData);
      return true;
    } catch (e) {
      print('Ошибка создания события: $e');
      return false;
    }
  }

  /// Получение событий пользователя
  Future<List<Map<String, dynamic>>> getUserEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query =
          _firestore.collection('events').where('userId', isEqualTo: user.uid);

      if (startDate != null) {
        query = query.where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('endDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.orderBy('startDate').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения событий: $e');
      return [];
    }
  }

  /// Получение событий на день
  Future<List<Map<String, dynamic>>> getEventsForDay(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      return await getUserEvents(
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      print('Ошибка получения событий на день: $e');
      return [];
    }
  }

  /// Получение событий на неделю
  Future<List<Map<String, dynamic>>> getEventsForWeek(
      DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 6));

      return await getUserEvents(
        startDate: weekStart,
        endDate: weekEnd,
      );
    } catch (e) {
      print('Ошибка получения событий на неделю: $e');
      return [];
    }
  }

  /// Получение событий на месяц
  Future<List<Map<String, dynamic>>> getEventsForMonth(
      DateTime monthStart) async {
    try {
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

      return await getUserEvents(
        startDate: monthStart,
        endDate: monthEnd,
      );
    } catch (e) {
      print('Ошибка получения событий на месяц: $e');
      return [];
    }
  }

  /// Обновление события
  Future<bool> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    List<String>? participants,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;

      final eventData = eventDoc.data()!;
      if (eventData['userId'] != user.uid) return false;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startDate != null)
        updateData['startDate'] = Timestamp.fromDate(startDate);
      if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);
      if (location != null) updateData['location'] = location;
      if (participants != null) updateData['participants'] = participants;

      await _firestore.collection('events').doc(eventId).update(updateData);
      return true;
    } catch (e) {
      print('Ошибка обновления события: $e');
      return false;
    }
  }

  /// Удаление события
  Future<bool> deleteEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;

      final eventData = eventDoc.data()!;
      if (eventData['userId'] != user.uid) return false;

      await _firestore.collection('events').doc(eventId).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления события: $e');
      return false;
    }
  }

  /// Получение доступности специалиста
  Future<List<Map<String, dynamic>>> getSpecialistAvailability({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('specialistId', isEqualTo: specialistId)
          .where('startDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения доступности специалиста: $e');
      return [];
    }
  }

  /// Проверка конфликтов времени
  Future<bool> hasTimeConflict({
    required DateTime startDate,
    required DateTime endDate,
    String? excludeEventId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      Query query = _firestore
          .collection('events')
          .where('userId', isEqualTo: user.uid)
          .where('startDate', isLessThan: Timestamp.fromDate(endDate))
          .where('endDate', isGreaterThan: Timestamp.fromDate(startDate));

      if (excludeEventId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeEventId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Ошибка проверки конфликтов времени: $e');
      return false;
    }
  }

  /// Получение статистики событий
  Future<Map<String, dynamic>> getEventStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await getUserEvents(
        startDate: startDate,
        endDate: endDate,
      );

      if (events.isEmpty) {
        return {
          'totalEvents': 0,
          'completedEvents': 0,
          'upcomingEvents': 0,
          'averageEventDuration': 0.0,
        };
      }

      final now = DateTime.now();
      int completedEvents = 0;
      int upcomingEvents = 0;
      double totalDuration = 0;

      for (final event in events) {
        final endDate = (event['endDate'] as Timestamp).toDate();
        final startDate = (event['startDate'] as Timestamp).toDate();

        if (endDate.isBefore(now)) {
          completedEvents++;
        } else {
          upcomingEvents++;
        }

        totalDuration += endDate.difference(startDate).inMinutes;
      }

      return {
        'totalEvents': events.length,
        'completedEvents': completedEvents,
        'upcomingEvents': upcomingEvents,
        'averageEventDuration': totalDuration / events.length,
      };
    } catch (e) {
      print('Ошибка получения статистики событий: $e');
      return {
        'totalEvents': 0,
        'completedEvents': 0,
        'upcomingEvents': 0,
        'averageEventDuration': 0.0,
      };
    }
  }

  /// Создание повторяющегося события
  Future<bool> createRecurringEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String recurrenceType, // 'daily', 'weekly', 'monthly'
    required int recurrenceCount,
    String? location,
    List<String>? participants,
    String? specialistId,
  }) async {
    try {
      final events = <Map<String, dynamic>>[];
      DateTime currentStart = startDate;
      DateTime currentEnd = endDate;

      for (int i = 0; i < recurrenceCount; i++) {
        events.add({
          'title': title,
          'description': description,
          'startDate': Timestamp.fromDate(currentStart),
          'endDate': Timestamp.fromDate(currentEnd),
          'location': location,
          'participants': participants ?? [],
          'specialistId': specialistId,
          'isRecurring': true,
          'recurrenceType': recurrenceType,
          'recurrenceIndex': i,
        });

        // Вычисление следующей даты
        switch (recurrenceType) {
          case 'daily':
            currentStart = currentStart.add(const Duration(days: 1));
            currentEnd = currentEnd.add(const Duration(days: 1));
            break;
          case 'weekly':
            currentStart = currentStart.add(const Duration(days: 7));
            currentEnd = currentEnd.add(const Duration(days: 7));
            break;
          case 'monthly':
            currentStart = DateTime(
                currentStart.year, currentStart.month + 1, currentStart.day);
            currentEnd =
                DateTime(currentEnd.year, currentEnd.month + 1, currentEnd.day);
            break;
        }
      }

      // Создание всех событий
      final batch = _firestore.batch();
      for (final eventData in events) {
        final docRef = _firestore.collection('events').doc();
        batch.set(docRef, {
          ...eventData,
          'userId': _auth.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Ошибка создания повторяющегося события: $e');
      return false;
    }
  }

  /// Экспорт событий в календарь
  Future<String> exportEventsToCalendar({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await getUserEvents(
        startDate: startDate,
        endDate: endDate,
      );

      final icsContent = StringBuffer();
      icsContent.writeln('BEGIN:VCALENDAR');
      icsContent.writeln('VERSION:2.0');
      icsContent.writeln('PRODID:-//Event Marketplace//Calendar//EN');

      for (final event in events) {
        final startDate = (event['startDate'] as Timestamp).toDate();
        final endDate = (event['endDate'] as Timestamp).toDate();

        icsContent.writeln('BEGIN:VEVENT');
        icsContent.writeln('UID:${event['id']}@eventmarketplace.com');
        icsContent.writeln('DTSTART:${_formatDateForICS(startDate)}');
        icsContent.writeln('DTEND:${_formatDateForICS(endDate)}');
        icsContent.writeln('SUMMARY:${event['title']}');
        icsContent.writeln('DESCRIPTION:${event['description']}');
        if (event['location'] != null) {
          icsContent.writeln('LOCATION:${event['location']}');
        }
        icsContent.writeln('END:VEVENT');
      }

      icsContent.writeln('END:VCALENDAR');
      return icsContent.toString();
    } catch (e) {
      print('Ошибка экспорта событий: $e');
      return '';
    }
  }

  /// Форматирование даты для ICS
  String _formatDateForICS(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}Z';
  }
}
