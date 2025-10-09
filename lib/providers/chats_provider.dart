import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для чатов с тестовыми данными
final chatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  // Сначала пытаемся загрузить из Firestore
  try {
    await for (final snapshot in FirebaseFirestore.instance
        .collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()) {
      final chats = snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();

      // Если нет данных, добавляем тестовые
      if (chats.isEmpty) {
        yield _getTestChats();
      } else {
        yield chats;
      }
    }
  } on Exception {
    // В случае ошибки возвращаем тестовые данные
    yield _getTestChats();
  }
});

/// Тестовые данные для чатов
List<Map<String, dynamic>> _getTestChats() => [
      {
        'id': 'chat_1',
        'participants': ['customer_1', 'specialist_1'],
        'customerName': 'Иван Заказчик',
        'specialistName': 'Андрей Ведущий',
        'lastMessage': 'Спасибо за отличную работу!',
        'lastMessageAt': DateTime.now()
            .subtract(const Duration(minutes: 30))
            .toIso8601String(),
        'unreadCount': 0,
        'isActive': true,
        'messages': [
          {
            'id': 'msg_1',
            'senderId': 'customer_1',
            'senderName': 'Иван Заказчик',
            'text': 'Здравствуйте! Хочу заказать мероприятие',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_2',
            'senderId': 'specialist_1',
            'senderName': 'Андрей Ведущий',
            'text': 'Добрый день! Давайте обсудим детали.',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 1, minutes: 45))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_3',
            'senderId': 'customer_1',
            'senderName': 'Иван Заказчик',
            'text': 'Спасибо за отличную работу!',
            'timestamp': DateTime.now()
                .subtract(const Duration(minutes: 30))
                .toIso8601String(),
            'isRead': true,
          },
        ],
      },
      {
        'id': 'chat_2',
        'participants': ['customer_2', 'specialist_2'],
        'customerName': 'Мария Организатор',
        'specialistName': 'Елена Фотограф',
        'lastMessage': 'Когда сможете прислать фото?',
        'lastMessageAt':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'unreadCount': 1,
        'isActive': true,
        'messages': [
          {
            'id': 'msg_4',
            'senderId': 'customer_2',
            'senderName': 'Мария Организатор',
            'text': 'Здравствуйте! Нужна фотосъемка корпоратива',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_5',
            'senderId': 'specialist_2',
            'senderName': 'Елена Фотограф',
            'text': 'Конечно! Когда планируется мероприятие?',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 2, minutes: 30))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_6',
            'senderId': 'customer_2',
            'senderName': 'Мария Организатор',
            'text': 'Когда сможете прислать фото?',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'isRead': false,
          },
        ],
      },
      {
        'id': 'chat_3',
        'participants': ['customer_3', 'specialist_3'],
        'customerName': 'Алексей Клиент',
        'specialistName': 'Дмитрий Диджей',
        'lastMessage': 'Отлично, ждем вас!',
        'lastMessageAt':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'unreadCount': 0,
        'isActive': true,
        'messages': [
          {
            'id': 'msg_7',
            'senderId': 'customer_3',
            'senderName': 'Алексей Клиент',
            'text': 'Привет! Нужен диджей на день рождения',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 4))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_8',
            'senderId': 'specialist_3',
            'senderName': 'Дмитрий Диджей',
            'text': 'Привет! Расскажите подробнее о мероприятии',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 3, minutes: 30))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_9',
            'senderId': 'customer_3',
            'senderName': 'Алексей Клиент',
            'text': 'Отлично, ждем вас!',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'isRead': true,
          },
        ],
      },
      {
        'id': 'chat_4',
        'participants': ['customer_4', 'specialist_4'],
        'customerName': 'Ольга Заказчица',
        'specialistName': 'Сергей Декоратор',
        'lastMessage': 'Понятно, спасибо за информацию',
        'lastMessageAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'unreadCount': 0,
        'isActive': false,
        'messages': [
          {
            'id': 'msg_10',
            'senderId': 'customer_4',
            'senderName': 'Ольга Заказчица',
            'text': 'Здравствуйте! Нужно украсить зал для выпускного',
            'timestamp': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_11',
            'senderId': 'specialist_4',
            'senderName': 'Сергей Декоратор',
            'text': 'К сожалению, в этот день я занят',
            'timestamp': DateTime.now()
                .subtract(const Duration(days: 1, hours: 2))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_12',
            'senderId': 'customer_4',
            'senderName': 'Ольга Заказчица',
            'text': 'Понятно, спасибо за информацию',
            'timestamp': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'isRead': true,
          },
        ],
      },
      {
        'id': 'chat_5',
        'participants': ['customer_5', 'specialist_5'],
        'customerName': 'Николай Клиент',
        'specialistName': 'Анна Кейтеринг',
        'lastMessage': 'Договорились!',
        'lastMessageAt':
            DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'unreadCount': 0,
        'isActive': true,
        'messages': [
          {
            'id': 'msg_13',
            'senderId': 'customer_5',
            'senderName': 'Николай Клиент',
            'text': 'Добрый день! Нужен кейтеринг на семейный праздник',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_14',
            'senderId': 'specialist_5',
            'senderName': 'Анна Кейтеринг',
            'text': 'Здравствуйте! Какое меню предпочитаете?',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 4, minutes: 30))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': 'msg_15',
            'senderId': 'customer_5',
            'senderName': 'Николай Клиент',
            'text': 'Договорились!',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
            'isRead': true,
          },
        ],
      },
    ];
