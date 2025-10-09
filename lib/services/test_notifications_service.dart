import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для создания тестовых уведомлений
class TestNotificationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создать тестовые уведомления для текущего пользователя
  static Future<void> createTestNotificationsForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await createTestNotifications(user.uid);
  }

  /// Создать тестовые уведомления для пользователя
  static Future<void> createTestNotifications(String userId) async {
    try {
      // Проверяем, есть ли уже уведомления
      final existingNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      if (existingNotifications.docs.isNotEmpty) {
        print('Тестовые уведомления уже существуют для пользователя $userId');
        return;
      }

      final testNotifications = [
        {
          'userId': userId,
          'title': 'Новое сообщение',
          'body': 'У вас новое сообщение от специалиста Анны Лебедевой',
          'type': 'message',
          'data': {
            'chatId': 'chat_1',
            'senderId': 'specialist_2',
            'senderName': 'Анна Лебедева',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Заявка подтверждена',
          'body': 'Ваша заявка на фотосессию подтверждена специалистом',
          'type': 'booking',
          'data': {
            'bookingId': 'booking_1',
            'specialistId': 'specialist_2',
            'specialistName': 'Анна Лебедева',
            'service': 'Фотосессия',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Новый отзыв',
          'body': 'Кто-то оставил отзыв о вашей работе - "Отличная организация!"',
          'type': 'review',
          'data': {
            'reviewId': 'review_1',
            'rating': 5,
            'comment': 'Отличная организация!',
          },
          'isRead': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Системное уведомление',
          'body': 'Приложение обновлено до версии 1.0.0. Добавлены новые функции!',
          'type': 'system',
          'data': {
            'version': '1.0.0',
            'features': ['Настройки', 'Уведомления', 'Темы'],
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Напоминание о встрече',
          'body': 'Через 2 часа у вас встреча с фотографом',
          'type': 'system',
          'data': {
            'reminderType': 'meeting',
            'time': '14:00',
            'specialist': 'Анна Лебедева',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Новое сообщение',
          'body': 'Алексей Смирнов: "Готов обсудить детали вашего мероприятия"',
          'type': 'message',
          'data': {
            'chatId': 'chat_2',
            'senderId': 'specialist_1',
            'senderName': 'Алексей Смирнов',
            'messagePreview': 'Готов обсудить детали вашего мероприятия',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      for (final notification in testNotifications) {
        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification);
      }
      await batch.commit();

      print('Создано ${testNotifications.length} тестовых уведомлений для пользователя $userId');
    } catch (e) {
      print('Ошибка создания тестовых уведомлений: $e');
    }
  }

  /// Создать тестовые уведомления для всех пользователей
  static Future<void> createTestNotificationsForAllUsers() async {
    try {
      // Получаем всех пользователей
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        await createTestNotifications(userId);
      }
      
      print('Созданы тестовые уведомления для ${usersSnapshot.docs.length} пользователей');
    } catch (e) {
      print('Ошибка создания тестовых уведомлений для всех пользователей: $e');
    }
  }

  /// Очистить все тестовые уведомления
  static Future<void> clearAllTestNotifications() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore.collection('notifications').get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Очищены все тестовые уведомления');
    } catch (e) {
      print('Ошибка очистки тестовых уведомлений: $e');
    }
  }

  /// Очистить тестовые уведомления для конкретного пользователя
  static Future<void> clearTestNotificationsForUser(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Очищены тестовые уведомления для пользователя $userId');
    } catch (e) {
      print('Ошибка очистки тестовых уведомлений для пользователя: $e');
    }
  }
}
