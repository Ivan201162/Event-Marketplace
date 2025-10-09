import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/discount_notification.dart';
import 'fcm_service.dart';

/// Сервис для работы с уведомлениями о скидках
class DiscountNotificationService {
  static const String _collection = 'discount_notifications';
  static const String _usersCollection = 'users';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  /// Создать уведомление о скидке
  Future<DiscountNotification> createDiscountNotification(
      CreateDiscountNotification data) async {
    if (!data.isValid) {
      throw Exception('Неверные данные: ${data.validationErrors.join(', ')}');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    // Получить данные специалиста
    final specialistDoc = await _firestore
        .collection(_usersCollection)
        .doc(data.specialistId)
        .get();

    if (!specialistDoc.exists) {
      throw Exception('Специалист не найден');
    }

    final specialistData = specialistDoc.data()!;
    final specialist = AppUser.fromMap(specialistData);

    // Получить данные клиента
    final customerDoc = await _firestore
        .collection(_usersCollection)
        .doc(data.customerId)
        .get();

    if (!customerDoc.exists) {
      throw Exception('Клиент не найден');
    }

    final customerData = customerDoc.data()!;
    final customer = AppUser.fromMap(customerData);

    // Создать уведомление
    final notification = DiscountNotification(
      id: '', // Будет установлен Firestore
      customerId: data.customerId,
      specialistId: data.specialistId,
      bookingId: data.bookingId,
      originalPrice: data.originalPrice,
      newPrice: data.newPrice,
      discountPercent: data.discountPercent,
      message: data.message,
      createdAt: DateTime.now(),
      specialistName: specialist.displayName,
      specialistAvatar: specialist.photoURL,
      customerName: customer.displayName,
      customerAvatar: customer.photoURL,
      metadata: data.metadata,
    );

    // Сохранить в Firestore
    final docRef =
        await _firestore.collection(_collection).add(notification.toMap());

    // Обновить ID
    final createdNotification = notification.copyWith(id: docRef.id);

    // Отправить push-уведомление клиенту
    await _fcmService.sendDiscountNotification(
      customerId: data.customerId,
      specialistName: specialist.displayName,
      discountPercent: data.discountPercent,
      newPrice: data.newPrice,
    );

    return createdNotification;
  }

  /// Получить уведомления клиента
  Future<List<DiscountNotification>> getCustomerNotifications(
      String customerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(DiscountNotification.fromDocument).toList();
  }

  /// Получить непрочитанные уведомления клиента
  Future<List<DiscountNotification>> getUnreadCustomerNotifications(
      String customerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(DiscountNotification.fromDocument).toList();
  }

  /// Получить уведомление по ID
  Future<DiscountNotification?> getNotification(String notificationId) async {
    final doc =
        await _firestore.collection(_collection).doc(notificationId).get();
    if (!doc.exists) return null;
    return DiscountNotification.fromDocument(doc);
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final notification = await getNotification(notificationId);
    if (notification == null) {
      throw Exception('Уведомление не найдено');
    }

    if (notification.customerId != currentUser.uid) {
      throw Exception(
          'Только получатель может отмечать уведомления как прочитанные');
    }

    await _firestore.collection(_collection).doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Отметить все уведомления клиента как прочитанные
  Future<void> markAllAsRead(String customerId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    if (customerId != currentUser.uid) {
      throw Exception(
          'Только владелец может отмечать уведомления как прочитанные');
    }

    final unreadNotifications =
        await getUnreadCustomerNotifications(customerId);

    final batch = _firestore.batch();
    for (final notification in unreadNotifications) {
      final docRef = _firestore.collection(_collection).doc(notification.id);
      batch.update(docRef, {
        'isRead': true,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final notification = await getNotification(notificationId);
    if (notification == null) {
      throw Exception('Уведомление не найдено');
    }

    if (notification.customerId != currentUser.uid) {
      throw Exception('Только получатель может удалять уведомления');
    }

    await _firestore.collection(_collection).doc(notificationId).delete();
  }

  /// Получить количество непрочитанных уведомлений
  Future<int> getUnreadCount(String customerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  /// Получить статистику уведомлений клиента
  Future<Map<String, int>> getCustomerStats(String customerId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: customerId)
        .get();

    var total = 0;
    var unread = 0;
    double totalSavings = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      total++;

      if (data['isRead'] != true) {
        unread++;
      }

      final originalPrice = (data['originalPrice'] as num).toDouble();
      final newPrice = (data['newPrice'] as num).toDouble();
      totalSavings += originalPrice - newPrice;
    }

    return {
      'total': total,
      'unread': unread,
      'read': total - unread,
      'totalSavings': totalSavings.round(),
    };
  }

  /// Подписаться на изменения уведомлений клиента
  Stream<List<DiscountNotification>> watchCustomerNotifications(
          String customerId) =>
      _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(DiscountNotification.fromDocument).toList(),
          );

  /// Подписаться на непрочитанные уведомления клиента
  Stream<List<DiscountNotification>> watchUnreadCustomerNotifications(
          String customerId) =>
      _firestore
          .collection(_collection)
          .where('customerId', isEqualTo: customerId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(DiscountNotification.fromDocument).toList(),
          );

  /// Подписаться на количество непрочитанных уведомлений
  Stream<int> watchUnreadCount(String customerId) => _firestore
      .collection(_collection)
      .where('customerId', isEqualTo: customerId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}
