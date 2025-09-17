import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/subscription.dart';

/// Сервис для работы с подписками на специалистов
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Подписаться на специалиста
  Future<Subscription> subscribeToSpecialist({
    required String userId,
    required String specialistId,
    required String specialistName,
    String? specialistPhotoUrl,
  }) async {
    if (!FeatureFlags.subscriptionsEnabled) {
      throw Exception('Подписки отключены');
    }

    try {
      // Проверяем, не подписан ли уже пользователь
      final existingSubscription = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingSubscription.docs.isNotEmpty) {
        throw Exception('Вы уже подписаны на этого специалиста');
      }

      final now = DateTime.now();

      final subscription = Subscription(
        id: '',
        userId: userId,
        specialistId: specialistId,
        specialistName: specialistName,
        specialistPhotoUrl: specialistPhotoUrl,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        metadata: {},
      );

      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toMap());

      return subscription.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка подписки на специалиста: $e');
    }
  }

  /// Отписаться от специалиста
  Future<void> unsubscribeFromSpecialist({
    required String userId,
    required String specialistId,
  }) async {
    try {
      final subscription = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (subscription.docs.isEmpty) {
        throw Exception('Вы не подписаны на этого специалиста');
      }

      await _firestore
          .collection('subscriptions')
          .doc(subscription.docs.first.id)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка отписки от специалиста: $e');
    }
  }

  /// Получить подписки пользователя
  Future<List<Subscription>> getUserSubscriptions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Subscription.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения подписок: $e');
    }
  }

  /// Получить подписчиков специалиста
  Future<List<Subscription>> getSpecialistSubscribers(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Subscription.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения подписчиков: $e');
    }
  }

  /// Проверить, подписан ли пользователь на специалиста
  Future<bool> isSubscribed({
    required String userId,
    required String specialistId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Получить количество подписчиков специалиста
  Future<int> getSpecialistSubscribersCount(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Создать уведомление для подписчиков
  Future<void> createNotificationForSubscribers({
    required String specialistId,
    required String specialistName,
    String? specialistPhotoUrl,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? postId,
    String? storyId,
  }) async {
    try {
      // Получаем всех подписчиков
      final subscribers = await getSpecialistSubscribers(specialistId);

      // Создаем уведомления для каждого подписчика
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final subscriber in subscribers) {
        final notification = SubscriptionNotification(
          id: '',
          userId: subscriber.userId,
          specialistId: specialistId,
          specialistName: specialistName,
          specialistPhotoUrl: specialistPhotoUrl,
          type: type,
          title: title,
          body: body,
          data: data ?? {},
          createdAt: now,
          isRead: false,
          postId: postId,
          storyId: storyId,
        );

        final docRef =
            _firestore.collection('subscription_notifications').doc();
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка создания уведомлений: $e');
    }
  }

  /// Получить уведомления пользователя
  Future<List<SubscriptionNotification>> getUserNotifications({
    required String userId,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection('subscription_notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('subscription_notifications')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => SubscriptionNotification.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения уведомлений: $e');
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('subscription_notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Ошибка отметки уведомления: $e');
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscription_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка отметки всех уведомлений: $e');
    }
  }

  /// Получить количество непрочитанных уведомлений
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscription_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('subscription_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления уведомления: $e');
    }
  }

  /// Очистить старые уведомления
  Future<void> cleanupOldNotifications({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _firestore
          .collection('subscription_notifications')
          .where('createdAt', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка очистки старых уведомлений: $e');
    }
  }
}
