import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/user.dart';
import 'notification_service.dart';

/// Сервис для работы с годовщинами и напоминаниями
class AnniversaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Проверить и отправить напоминания о годовщинах
  Future<void> checkAndSendAnniversaryReminders() async {
    if (!FeatureFlags.anniversaryRemindersEnabled) {
      return;
    }

    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final nextWeek = today.add(const Duration(days: 7));

      // Получаем пользователей с включенными напоминаниями
      final usersSnapshot = await _firestore
          .collection('users')
          .where('anniversaryRemindersEnabled', isEqualTo: true)
          .where('maritalStatus', isEqualTo: 'married')
          .get();

      for (final doc in usersSnapshot.docs) {
        final user = AppUser.fromDocument(doc);

        if (user.weddingDate == null) continue;

        final weddingDate = user.weddingDate!;
        final currentYear = today.year;
        final weddingThisYear =
            DateTime(currentYear, weddingDate.month, weddingDate.day);
        final weddingNextYear =
            DateTime(currentYear + 1, weddingDate.month, weddingDate.day);

        // Проверяем годовщину сегодня
        if (_isSameDay(today, weddingThisYear)) {
          await _sendAnniversaryNotification(user, 0); // Сегодня
        }
        // Проверяем годовщину завтра
        else if (_isSameDay(tomorrow, weddingThisYear)) {
          await _sendAnniversaryNotification(user, 1); // Завтра
        }
        // Проверяем годовщину через неделю
        else if (_isSameDay(nextWeek, weddingThisYear)) {
          await _sendAnniversaryNotification(user, 7); // Через неделю
        }
        // Проверяем годовщину в следующем году (если уже прошла в этом году)
        else if (weddingThisYear.isBefore(today) &&
            _isSameDay(nextWeek, weddingNextYear)) {
          final years = currentYear - weddingDate.year + 1;
          await _sendAnniversaryNotification(user, 7, years: years);
        }
      }
    } catch (e) {
      throw Exception('Ошибка проверки годовщин: $e');
    }
  }

  /// Отправить уведомление о годовщине
  Future<void> _sendAnniversaryNotification(
    AppUser user,
    int daysUntil, {
    int? years,
  }) async {
    final yearsMarried =
        years ?? (DateTime.now().year - user.weddingDate!.year);

    String title;
    String body;

    if (daysUntil == 0) {
      title = '🎉 Поздравляем с годовщиной!';
      body =
          'Сегодня $yearsMarried-я годовщина вашей свадьбы! Желаем счастья и любви!';
    } else if (daysUntil == 1) {
      title = 'Напоминание о годовщине';
      body =
          'Завтра $yearsMarried-я годовщина вашей свадьбы. Не забудьте поздравить друг друга!';
    } else {
      title = 'Приближается годовщина';
      body =
          'Через $daysUntil дней будет $yearsMarried-я годовщина вашей свадьбы. Время планировать празднование!';
    }

    await _notificationService.sendNotification(
      userId: user.id,
      title: title,
      body: body,
      type: 'anniversary_reminder',
      data: {
        'weddingDate': user.weddingDate!.toIso8601String(),
        'yearsMarried': yearsMarried.toString(),
        'daysUntil': daysUntil.toString(),
        'partnerName': user.partnerName ?? 'вашего партнера',
      },
    );
  }

  /// Проверить, совпадают ли дни
  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;

  /// Получить количество лет в браке
  int getYearsMarried(DateTime weddingDate) {
    final now = DateTime.now();
    var years = now.year - weddingDate.year;

    // Если день рождения еще не наступил в этом году
    if (now.month < weddingDate.month ||
        (now.month == weddingDate.month && now.day < weddingDate.day)) {
      years--;
    }

    return years;
  }

  /// Получить количество дней до следующей годовщины
  int getDaysUntilNextAnniversary(DateTime weddingDate) {
    final now = DateTime.now();
    final currentYear = now.year;
    final weddingThisYear =
        DateTime(currentYear, weddingDate.month, weddingDate.day);

    // Если годовщина уже прошла в этом году, считаем до следующего года
    if (weddingThisYear.isBefore(now)) {
      final weddingNextYear =
          DateTime(currentYear + 1, weddingDate.month, weddingDate.day);
      return weddingNextYear.difference(now).inDays;
    } else {
      return weddingThisYear.difference(now).inDays;
    }
  }

  /// Получить информацию о годовщине пользователя
  Map<String, dynamic> getAnniversaryInfo(AppUser user) {
    if (user.weddingDate == null) {
      return {
        'hasWeddingDate': false,
        'message': 'Дата свадьбы не указана',
      };
    }

    final yearsMarried = getYearsMarried(user.weddingDate!);
    final daysUntil = getDaysUntilNextAnniversary(user.weddingDate!);

    return {
      'hasWeddingDate': true,
      'yearsMarried': yearsMarried,
      'daysUntilNext': daysUntil,
      'nextAnniversary': DateTime(
        DateTime.now().year + (daysUntil > 365 ? 1 : 0),
        user.weddingDate!.month,
        user.weddingDate!.day,
      ),
      'partnerName': user.partnerName,
      'remindersEnabled': user.anniversaryRemindersEnabled,
    };
  }

  /// Обновить настройки напоминаний о годовщинах
  Future<void> updateAnniversarySettings({
    required String userId,
    required bool enabled,
    DateTime? weddingDate,
    String? partnerName,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'anniversaryRemindersEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (weddingDate != null) {
        updateData['weddingDate'] = Timestamp.fromDate(weddingDate);
      }

      if (partnerName != null) {
        updateData['partnerName'] = partnerName;
      }

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Ошибка обновления настроек годовщин: $e');
    }
  }

  /// Получить пользователей с годовщинами в указанный период
  Future<List<AppUser>> getUsersWithAnniversariesInPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final users = <AppUser>[];
      final usersSnapshot = await _firestore
          .collection('users')
          .where('anniversaryRemindersEnabled', isEqualTo: true)
          .where('maritalStatus', isEqualTo: 'married')
          .get();

      for (final doc in usersSnapshot.docs) {
        final user = AppUser.fromDocument(doc);

        if (user.weddingDate == null) continue;

        final weddingDate = user.weddingDate!;
        final currentYear = DateTime.now().year;
        final weddingThisYear =
            DateTime(currentYear, weddingDate.month, weddingDate.day);
        final weddingNextYear =
            DateTime(currentYear + 1, weddingDate.month, weddingDate.day);

        // Проверяем, попадает ли годовщина в указанный период
        if ((weddingThisYear.isAfter(startDate) &&
                weddingThisYear.isBefore(endDate)) ||
            (weddingNextYear.isAfter(startDate) &&
                weddingNextYear.isBefore(endDate))) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      throw Exception('Ошибка получения пользователей с годовщинами: $e');
    }
  }

  /// Получить годовщины клиентов
  Future<List<Map<String, dynamic>>> getCustomerAnniversaries(
      String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('anniversaries')
          .where('customerId', isEqualTo: customerId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения годовщин клиента: $e');
    }
  }

  /// Получить предстоящие годовщины
  Future<List<Map<String, dynamic>>> getUpcomingAnniversaries({
    int daysAhead = 30,
  }) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final snapshot = await _firestore
          .collection('anniversaries')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения предстоящих годовщин: $e');
    }
  }

  /// Добавить годовщину свадьбы
  Future<void> addWeddingAnniversary({
    required String customerId,
    required DateTime weddingDate,
    required String spouseName,
    String? notes,
  }) async {
    try {
      await _firestore.collection('anniversaries').add({
        'customerId': customerId,
        'type': 'wedding',
        'date': Timestamp.fromDate(weddingDate),
        'spouseName': spouseName,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка добавления годовщины свадьбы: $e');
    }
  }

  /// Удалить годовщину
  Future<void> deleteAnniversary(String anniversaryId) async {
    try {
      await _firestore.collection('anniversaries').doc(anniversaryId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления годовщины: $e');
    }
  }
}
