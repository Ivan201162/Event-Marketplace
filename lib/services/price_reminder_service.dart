import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Сервис для напоминаний об обновлении цен
class PriceReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Получить специалистов, которым нужно напомнить об обновлении цен
  Future<List<Specialist>> getSpecialistsNeedingPriceUpdate() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('specialists')
          .where('isActive', isEqualTo: true)
          .where('lastPriceUpdateAt',
              isLessThan: Timestamp.fromDate(thirtyDaysAgo),)
          .get();

      return snapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения специалистов для напоминания: $e');
    }
  }

  /// Отправить напоминание об обновлении цен
  Future<void> sendPriceUpdateReminder(String specialistId) async {
    try {
      // Получаем FCM токены специалиста
      final specialistDoc =
          await _firestore.collection('specialists').doc(specialistId).get();

      if (!specialistDoc.exists) return;

      final specialistData = specialistDoc.data();
      final fcmTokens = List<String>.from(specialistData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      // Создаем уведомление
      final notification = {
        'title': 'Обновите цены на услуги',
        'body':
            'Ваши цены не обновлялись более 30 дней. Обновите их для привлечения клиентов.',
        'data': {'type': 'price_update_reminder', 'specialistId': specialistId},
      };

      // Отправляем уведомление на все токены
      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(to: token, notification: notification);
        } catch (e) {
          // Логируем ошибку, но продолжаем с другими токенами
          debugPrint('Ошибка отправки уведомления на токен $token: $e');
        }
      }

      // Обновляем время последнего напоминания
      await _firestore.collection('specialists').doc(specialistId).update({
        'lastPriceReminderAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка отправки напоминания: $e');
    }
  }

  /// Отправить напоминания всем специалистам, которым нужно обновить цены
  Future<void> sendBulkPriceUpdateReminders() async {
    try {
      final specialists = await getSpecialistsNeedingPriceUpdate();

      for (final specialist in specialists) {
        await sendPriceUpdateReminder(specialist.id);

        // Небольшая задержка между отправками
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      throw Exception('Ошибка массовой отправки напоминаний: $e');
    }
  }

  /// Получить статистику напоминаний
  Future<Map<String, int>> getReminderStats() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Специалисты, которым нужно напомнить
      final needReminderSnapshot = await _firestore
          .collection('specialists')
          .where('isActive', isEqualTo: true)
          .where('lastPriceUpdateAt',
              isLessThan: Timestamp.fromDate(thirtyDaysAgo),)
          .get();

      // Специалисты, которым уже напомнили
      final remindedSnapshot = await _firestore
          .collection('specialists')
          .where('isActive', isEqualTo: true)
          .where('lastPriceReminderAt',
              isGreaterThan: Timestamp.fromDate(thirtyDaysAgo),)
          .get();

      return {
        'needReminder': needReminderSnapshot.docs.length,
        'reminded': remindedSnapshot.docs.length,
        'total':
            needReminderSnapshot.docs.length + remindedSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики напоминаний: $e');
    }
  }

  /// Отметить, что специалист обновил цены
  Future<void> markPricesUpdated(String specialistId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'lastPriceUpdateAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception(
          'Ошибка обновления времени последнего обновления цен: $e',);
    }
  }

  /// Получить специалистов с устаревшими ценами (для админки)
  Future<List<Map<String, dynamic>>> getSpecialistsWithOutdatedPrices() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('specialists')
          .where('isActive', isEqualTo: true)
          .where('lastPriceUpdateAt',
              isLessThan: Timestamp.fromDate(thirtyDaysAgo),)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'lastPriceUpdateAt': data['lastPriceUpdateAt'],
          'lastPriceReminderAt': data['lastPriceReminderAt'],
          'daysSinceUpdate': DateTime.now()
              .difference((data['lastPriceUpdateAt'] as Timestamp).toDate())
              .inDays,
        };
      }).toList();
    } catch (e) {
      throw Exception('Ошибка получения специалистов с устаревшими ценами: $e');
    }
  }
}
