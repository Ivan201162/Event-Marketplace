import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';

/// Сервис для работы с подписками
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить подписки пользователя
  Stream<List<Subscription>> getUserSubscriptions(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subscription.fromDocument(doc))
            .toList());
  }

  /// Получить подписчиков специалиста
  Stream<List<Subscription>> getSpecialistSubscribers(String specialistId) {
    return _firestore
        .collection('subscriptions')
        .where('specialistId', isEqualTo: specialistId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subscription.fromDocument(doc))
            .toList());
  }

  /// Проверить, подписан ли пользователь на специалиста
  Future<bool> isSubscribed(String userId, String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Ошибка проверки подписки: $e');
    }
  }

  /// Подписаться на специалиста
  Future<String> subscribe(String userId, String specialistId,
      String specialistName, String? specialistPhotoUrl) async {
    try {
      // Проверить, не подписан ли уже
      final existingSubscription = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (existingSubscription.docs.isNotEmpty) {
        // Активировать существующую подписку
        final doc = existingSubscription.docs.first;
        await doc.reference.update({
          'isActive': true,
          'notificationsEnabled': true,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        return doc.id;
      } else {
        // Создать новую подписку
        final subscription = Subscription(
          id: '',
          userId: userId,
          specialistId: specialistId,
          specialistName: specialistName,
          specialistPhotoUrl: specialistPhotoUrl,
          createdAt: DateTime.now(),
          isActive: true,
          notificationsEnabled: true,
        );

        final docRef = await _firestore
            .collection('subscriptions')
            .add(subscription.toMap());
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Ошибка подписки: $e');
    }
  }

  /// Отписаться от специалиста
  Future<void> unsubscribe(String userId, String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'isActive': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Ошибка отписки: $e');
    }
  }

  /// Обновить настройки уведомлений
  Future<void> updateNotificationSettings(
      String subscriptionId, bool notificationsEnabled) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'notificationsEnabled': notificationsEnabled,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления настроек уведомлений: $e');
    }
  }

  /// Получить количество подписчиков специалиста
  Future<int> getSubscribersCount(String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Ошибка получения количества подписчиков: $e');
    }
  }

  /// Получить количество подписок пользователя
  Future<int> getSubscriptionsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Ошибка получения количества подписок: $e');
    }
  }

  /// Получить статистику подписок
  Future<Map<String, dynamic>> getSubscriptionStats(String specialistId) async {
    try {
      final subscribersQuery = await _firestore
          .collection('subscriptions')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .get();

      final totalSubscribers = subscribersQuery.docs.length;

      // Подсчитать подписчиков с включенными уведомлениями
      int subscribersWithNotifications = 0;
      for (final doc in subscribersQuery.docs) {
        if (doc.data()['notificationsEnabled'] == true) {
          subscribersWithNotifications++;
        }
      }

      return {
        'totalSubscribers': totalSubscribers,
        'subscribersWithNotifications': subscribersWithNotifications,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики подписок: $e');
    }
  }
}
