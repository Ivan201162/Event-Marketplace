import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification.dart';
import '../models/notification_template.dart';
import '../models/specialist_recommendation.dart';
import '../models/subscription.dart';
import '../models/subscription_notification.dart';

/// Сервис для работы с подписками
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить подписки пользователя
  Stream<List<Subscription>> getUserSubscriptions(String userId) => _firestore
      .collection('subscriptions')
      .where('userId', isEqualTo: userId)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Subscription.fromDocument).toList(),
      );

  /// Получить подписчиков специалиста
  Stream<List<Subscription>> getSpecialistSubscribers(String specialistId) =>
      _firestore
          .collection('subscriptions')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map(Subscription.fromDocument).toList(),
          );

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
  Future<String> subscribe(
    String userId,
    String specialistId,
    String specialistName,
    String? specialistPhotoUrl,
  ) async {
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
    String subscriptionId,
    bool notificationsEnabled,
  ) async {
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
      var subscribersWithNotifications = 0;
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

  /// Получить уведомления пользователя
  Stream<List<SubscriptionNotification>> getUserNotifications(String userId) =>
      _firestore
          .collection('subscription_notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => SubscriptionNotification(
                    id: doc.id,
                    userId: doc.data()['userId'] ?? '',
                    specialistId: doc.data()['specialistId'] ?? '',
                    type: NotificationType.values.firstWhere(
                      (e) => e.toString().split('.').last == doc.data()['type'],
                      orElse: () => NotificationType.system,
                    ),
                    title: doc.data()['title'] ?? '',
                    body: doc.data()['body'] ?? '',
                    data: Map<String, dynamic>.from(doc.data()['data'] ?? {}),
                    createdAt: (doc.data()['createdAt'] as Timestamp).toDate(),
                    isRead: doc.data()['isRead'] ?? false,
                    specialistPhotoUrl: doc.data()['specialistPhotoUrl'],
                  ),
                )
                .toList(),
          );

  /// Получить похожих специалистов
  Future<List<SpecialistRecommendation>> getSimilarSpecialists(
    String specialistId,
  ) async {
    try {
      // Это заглушка - в реальном приложении здесь была бы логика рекомендаций
      return [];
    } catch (e) {
      throw Exception('Ошибка получения похожих специалистов: $e');
    }
  }

  /// Отписаться от специалиста
  Future<void> unsubscribeFromSpecialist(
    String userId,
    String specialistId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.update({'isActive': false});
      }
    } catch (e) {
      throw Exception('Ошибка отписки от специалиста: $e');
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('subscription_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Подписаться на специалиста
  Future<void> subscribeToSpecialist({
    required String userId,
    required String specialistId,
    required String specialistName,
    String? specialistPhotoUrl,
  }) async {
    try {
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'specialistPhotoUrl': specialistPhotoUrl,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка подписки на специалиста: $e');
    }
  }

  /// Получить подписку пользователя на специалиста
  Future<Subscription?> getUserSubscription(
    String userId,
    String specialistId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Subscription.fromDocument(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения подписки пользователя: $e');
    }
  }
}
