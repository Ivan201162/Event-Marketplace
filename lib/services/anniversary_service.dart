import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/wedding_anniversary.dart';
import '../models/user.dart';
import '../core/feature_flags.dart';

/// Сервис для работы с годовщинами свадьбы
class AnniversaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить годовщину свадьбы для заказчика
  Future<String> addWeddingAnniversary({
    required String customerId,
    required String customerName,
    String? customerEmail,
    required DateTime weddingDate,
  }) async {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      throw Exception('Отслеживание годовщин отключено');
    }

    try {
      final yearsMarried =
          WeddingAnniversary.calculateYearsMarried(weddingDate);
      final nextAnniversary =
          WeddingAnniversary.calculateNextAnniversary(weddingDate);

      final anniversary = WeddingAnniversary(
        id: '', // Будет установлен Firestore
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        weddingDate: weddingDate,
        yearsMarried: yearsMarried,
        nextAnniversary: nextAnniversary,
        isActive: true,
        reminderDates: ['30', '7', '1'], // За 30, 7 и 1 день
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('wedding_anniversaries')
          .add(anniversary.toMap());

      // Создаем напоминания
      await _createReminders(docRef.id, anniversary);

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding wedding anniversary: $e');
      throw Exception('Ошибка добавления годовщины: $e');
    }
  }

  /// Получить годовщины заказчика
  Stream<List<WeddingAnniversary>> getCustomerAnniversaries(String customerId) {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('wedding_anniversaries')
        .where('customerId', isEqualTo: customerId)
        .where('isActive', isEqualTo: true)
        .orderBy('weddingDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WeddingAnniversary.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Получить годовщину по ID
  Future<WeddingAnniversary?> getAnniversaryById(String anniversaryId) async {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection('wedding_anniversaries')
          .doc(anniversaryId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return WeddingAnniversary.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('Error getting anniversary: $e');
      return null;
    }
  }

  /// Обновить годовщину
  Future<void> updateAnniversary(
      String anniversaryId, Map<String, dynamic> updates) async {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      throw Exception('Отслеживание годовщин отключено');
    }

    try {
      await _firestore
          .collection('wedding_anniversaries')
          .doc(anniversaryId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating anniversary: $e');
      throw Exception('Ошибка обновления годовщины: $e');
    }
  }

  /// Удалить годовщину
  Future<void> deleteAnniversary(String anniversaryId) async {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      throw Exception('Отслеживание годовщин отключено');
    }

    try {
      await _firestore
          .collection('wedding_anniversaries')
          .doc(anniversaryId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting anniversary: $e');
      throw Exception('Ошибка удаления годовщины: $e');
    }
  }

  /// Получить предстоящие годовщины
  Stream<List<WeddingAnniversary>> getUpcomingAnniversaries(
      {int daysAhead = 30}) {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));

    return _firestore
        .collection('wedding_anniversaries')
        .where('isActive', isEqualTo: true)
        .where('nextAnniversary', isGreaterThanOrEqualTo: now)
        .where('nextAnniversary', isLessThanOrEqualTo: futureDate)
        .orderBy('nextAnniversary')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WeddingAnniversary.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Создать напоминания для годовщины
  Future<void> _createReminders(
      String anniversaryId, WeddingAnniversary anniversary) async {
    try {
      final reminders = <Map<String, dynamic>>[];

      for (final days in anniversary.reminderDates) {
        final daysInt = int.tryParse(days) ?? 7;
        final reminderDate =
            anniversary.nextAnniversary.subtract(Duration(days: daysInt));

        if (reminderDate.isAfter(DateTime.now())) {
          final message = _generateReminderMessage(anniversary, daysInt);

          reminders.add({
            'anniversaryId': anniversaryId,
            'customerId': anniversary.customerId,
            'reminderDate': Timestamp.fromDate(reminderDate),
            'message': message,
            'isSent': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (reminders.isNotEmpty) {
        final batch = _firestore.batch();
        for (final reminder in reminders) {
          final docRef = _firestore.collection('anniversary_reminders').doc();
          batch.set(docRef, reminder);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error creating reminders: $e');
    }
  }

  /// Сгенерировать сообщение напоминания
  String _generateReminderMessage(
      WeddingAnniversary anniversary, int daysAhead) {
    final anniversaryName = anniversary.anniversaryName;
    final years = anniversary.yearsMarried + 1; // Следующая годовщина

    if (daysAhead == 30) {
      return 'Через месяц у вас $anniversaryName! Уже $years лет вместе. Время подумать о праздновании! 💕';
    } else if (daysAhead == 7) {
      return 'Через неделю $anniversaryName! $years лет счастливого брака. Не забудьте поздравить друг друга! 🎉';
    } else if (daysAhead == 1) {
      return 'Завтра $anniversaryName! $years лет любви и верности. С днем годовщины! 💍';
    } else {
      return 'Через $daysAhead дней у вас $anniversaryName! $years лет вместе. 💕';
    }
  }

  /// Получить рекомендации для годовщины
  Future<List<String>> getAnniversaryRecommendations(
      WeddingAnniversary anniversary) async {
    // В реальном приложении здесь может быть логика получения рекомендаций
    // на основе истории заказов, предпочтений и т.д.
    return anniversary.anniversaryRecommendations;
  }

  /// Получить специалистов для годовщины
  Future<List<Map<String, dynamic>>> getAnniversarySpecialists(
      WeddingAnniversary anniversary) async {
    try {
      // Получаем специалистов, которые могут помочь с организацией годовщины
      final specialistsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.specialist.name)
          .limit(10)
          .get();

      final specialists = <Map<String, dynamic>>[];

      for (final doc in specialistsQuery.docs) {
        final specialist = AppUser.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        // TODO: Добавить логику фильтрации специалистов по категориям
        // подходящим для годовщин (фотографы, организаторы, декораторы и т.д.)

        specialists.add({
          'id': specialist.id,
          'name': specialist.displayName,
          'photo': specialist.photoURL,
          'category':
              'Организатор мероприятий', // TODO: Получить реальную категорию
          'rating': 4.8, // TODO: Получить реальный рейтинг
          'price': 'от 15000 ₽', // TODO: Получить реальную цену
        });
      }

      return specialists;
    } catch (e) {
      debugPrint('Error getting anniversary specialists: $e');
      return [];
    }
  }

  /// Отправить напоминание о годовщине
  Future<void> sendAnniversaryReminder(String reminderId) async {
    try {
      final reminderDoc = await _firestore
          .collection('anniversary_reminders')
          .doc(reminderId)
          .get();

      if (!reminderDoc.exists) {
        return;
      }

      final reminder = AnniversaryReminder.fromMap({
        'id': reminderDoc.id,
        ...reminderDoc.data()!,
      });

      // TODO: Отправить push-уведомление или email
      debugPrint('Sending anniversary reminder: ${reminder.message}');

      // Отмечаем напоминание как отправленное
      await _firestore
          .collection('anniversary_reminders')
          .doc(reminderId)
          .update({
        'isSent': true,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending anniversary reminder: $e');
    }
  }

  /// Получить статистику годовщин
  Future<Map<String, dynamic>> getAnniversaryStats() async {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      return {};
    }

    try {
      final anniversariesQuery = await _firestore
          .collection('wedding_anniversaries')
          .where('isActive', isEqualTo: true)
          .get();

      final stats = <String, dynamic>{
        'total_anniversaries': 0,
        'upcoming_this_month': 0,
        'upcoming_this_year': 0,
        'average_years_married': 0.0,
        'milestone_anniversaries': 0,
      };

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      final nextMonth = DateTime(now.year, now.month + 1);
      final thisYear = DateTime(now.year);
      final nextYear = DateTime(now.year + 1);

      int totalYears = 0;
      int milestoneCount = 0;

      for (final doc in anniversariesQuery.docs) {
        final anniversary = WeddingAnniversary.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        stats['total_anniversaries'] =
            (stats['total_anniversaries'] as int) + 1;
        totalYears += anniversary.yearsMarried;

        // Подсчет предстоящих годовщин
        if (anniversary.nextAnniversary.isAfter(thisMonth) &&
            anniversary.nextAnniversary.isBefore(nextMonth)) {
          stats['upcoming_this_month'] =
              (stats['upcoming_this_month'] as int) + 1;
        }

        if (anniversary.nextAnniversary.isAfter(thisYear) &&
            anniversary.nextAnniversary.isBefore(nextYear)) {
          stats['upcoming_this_year'] =
              (stats['upcoming_this_year'] as int) + 1;
        }

        // Подсчет юбилейных годовщин
        if ([1, 5, 10, 15, 20, 25, 30, 40, 50]
            .contains(anniversary.yearsMarried + 1)) {
          milestoneCount++;
        }
      }

      if (stats['total_anniversaries'] > 0) {
        stats['average_years_married'] =
            totalYears / (stats['total_anniversaries'] as int);
      }
      stats['milestone_anniversaries'] = milestoneCount;

      return stats;
    } catch (e) {
      debugPrint('Error getting anniversary stats: $e');
      return {};
    }
  }

  /// Обновить годовщины (пересчитать годы и следующую годовщину)
  Future<void> updateAnniversaries() async {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      return;
    }

    try {
      final anniversariesQuery = await _firestore
          .collection('wedding_anniversaries')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      for (final doc in anniversariesQuery.docs) {
        final anniversary = WeddingAnniversary.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        final newYearsMarried =
            WeddingAnniversary.calculateYearsMarried(anniversary.weddingDate);
        final newNextAnniversary = WeddingAnniversary.calculateNextAnniversary(
            anniversary.weddingDate);

        // Обновляем только если что-то изменилось
        if (newYearsMarried != anniversary.yearsMarried ||
            newNextAnniversary != anniversary.nextAnniversary) {
          batch.update(doc.reference, {
            'yearsMarried': newYearsMarried,
            'nextAnniversary': Timestamp.fromDate(newNextAnniversary),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Создаем новые напоминания для обновленной годовщины
          final updatedAnniversary = anniversary.copyWith(
            yearsMarried: newYearsMarried,
            nextAnniversary: newNextAnniversary,
          );

          await _createReminders(doc.id, updatedAnniversary);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating anniversaries: $e');
    }
  }
}
