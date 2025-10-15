import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  debugPrint('Добавление тестовых данных в Firestore...');

  // Добавляем тестовые заявки
  await _addTestBookings(firestore);

  // Добавляем тестовые чаты
  await _addTestChats(firestore);

  // Добавляем тестовые сообщения
  await _addTestMessages(firestore);

  debugPrint('Тестовые данные успешно добавлены!');
}

Future<void> _addTestBookings(FirebaseFirestore firestore) async {
  debugPrint('Добавление тестовых заявок...');

  final testBookings = [
    {
      'customerId': 'user1',
      'specialistId': 'specialist1',
      'eventTitle': 'Свадьба в стиле "Великий Гэтсби"',
      'eventDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
      'totalPrice': 45000.0,
      'prepayment': 22500.0,
      'status': 'pending',
      'message': 'Организация свадьбы на 50 человек в стиле 20-х годов',
      'customerName': 'Анна Петрова',
      'customerPhone': '+7 (999) 123-45-67',
      'customerEmail': 'anna.petrova@email.com',
      'description':
          'Свадьба в стиле "Великий Гэтсби" с джазовой музыкой и винтажным декором',
      'participantsCount': 50,
      'address': 'Москва, ул. Тверская, 15',
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
    },
    {
      'customerId': 'user2',
      'specialistId': 'specialist1',
      'eventTitle': 'Корпоратив IT-компании',
      'eventDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 25))),
      'totalPrice': 35000.0,
      'prepayment': 17500.0,
      'status': 'confirmed',
      'message': 'Новогодний корпоратив для 30 сотрудников',
      'customerName': 'Михаил Сидоров',
      'customerPhone': '+7 (999) 234-56-78',
      'customerEmail': 'mikhail.sidorov@company.com',
      'description':
          'Новогодний корпоратив с развлекательной программой и банкетом',
      'participantsCount': 30,
      'address': 'Москва, ул. Арбат, 25',
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
    },
    {
      'customerId': 'user3',
      'specialistId': 'specialist2',
      'eventTitle': 'День рождения ребенка',
      'eventDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
      'totalPrice': 25000.0,
      'prepayment': 12500.0,
      'status': 'pending',
      'message': 'День рождения на 15 детей с аниматорами',
      'customerName': 'Елена Козлова',
      'customerPhone': '+7 (999) 345-67-89',
      'customerEmail': 'elena.kozlova@email.com',
      'description':
          'Детский день рождения с тематическими аниматорами и сладким столом',
      'participantsCount': 15,
      'address': 'Москва, ул. Ленина, 10',
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
    },
    {
      'customerId': 'user1',
      'specialistId': 'specialist2',
      'eventTitle': 'Выпускной вечер',
      'eventDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'totalPrice': 60000.0,
      'prepayment': 30000.0,
      'status': 'confirmed',
      'message': 'Выпускной вечер для 11 класса',
      'customerName': 'Анна Петрова',
      'customerPhone': '+7 (999) 123-45-67',
      'customerEmail': 'anna.petrova@email.com',
      'description':
          'Торжественный выпускной вечер с банкетом и развлекательной программой',
      'participantsCount': 25,
      'address': 'Москва, ул. Красная Площадь, 1',
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
    },
    {
      'customerId': 'user4',
      'specialistId': 'specialist1',
      'eventTitle': 'Юбилей компании',
      'eventDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 20))),
      'totalPrice': 80000.0,
      'prepayment': 40000.0,
      'status': 'completed',
      'message': '10-летний юбилей компании',
      'customerName': 'Дмитрий Волков',
      'customerPhone': '+7 (999) 456-78-90',
      'customerEmail': 'dmitry.volkov@company.com',
      'description': 'Торжественное мероприятие по случаю 10-летия компании',
      'participantsCount': 100,
      'address': 'Москва, ул. Садовое кольцо, 50',
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
  ];

  for (final booking in testBookings) {
    await firestore.collection('bookings').add(booking);
  }

  debugPrint('Добавлено ${testBookings.length} тестовых заявок');
}

Future<void> _addTestChats(FirebaseFirestore firestore) async {
  debugPrint('Добавление тестовых чатов...');

  final testChats = [
    {
      'participants': ['user1', 'specialist1'],
      'participantNames': {
        'user1': 'Анна Петрова',
        'specialist1': 'Александр Иванов',
      },
      'lastMessageContent': 'Спасибо за организацию свадьбы!',
      'lastMessageTime': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    },
    {
      'participants': ['user2', 'specialist1'],
      'participantNames': {
        'user2': 'Михаил Сидоров',
        'specialist1': 'Александр Иванов',
      },
      'lastMessageContent': 'Когда можем обсудить детали корпоратива?',
      'lastMessageTime':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
    },
    {
      'participants': ['user3', 'specialist2'],
      'participantNames': {
        'user3': 'Елена Козлова',
        'specialist2': 'Мария Смирнова',
      },
      'lastMessageContent': 'Какие аниматоры у вас есть?',
      'lastMessageTime':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
    },
    {
      'participants': ['user1', 'specialist2'],
      'participantNames': {
        'user1': 'Анна Петрова',
        'specialist2': 'Мария Смирнова',
      },
      'lastMessageContent': 'Отлично, ждем вас в 18:00',
      'lastMessageTime': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
      'updatedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    },
    {
      'participants': ['user4', 'specialist1'],
      'participantNames': {
        'user4': 'Дмитрий Волков',
        'specialist1': 'Александр Иванов',
      },
      'lastMessageContent': 'Спасибо за отличную организацию юбилея!',
      'lastMessageTime':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
      'updatedAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
  ];

  for (final chat in testChats) {
    await firestore.collection('chats').add(chat);
  }

  debugPrint('Добавлено ${testChats.length} тестовых чатов');
}

Future<void> _addTestMessages(FirebaseFirestore firestore) async {
  debugPrint('Добавление тестовых сообщений...');

  // Получаем ID чатов
  final chatsSnapshot = await firestore.collection('chats').get();
  final chatIds = chatsSnapshot.docs.map((doc) => doc.id).toList();

  if (chatIds.isEmpty) {
    debugPrint('Нет чатов для добавления сообщений');
    return;
  }

  final testMessages = [
    {
      'chatId': chatIds[0],
      'senderId': 'user1',
      'senderName': 'Анна Петрова',
      'type': 'text',
      'content': 'Здравствуйте! Интересует организация свадьбы',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      ),
    },
    {
      'chatId': chatIds[0],
      'senderId': 'specialist1',
      'senderName': 'Александр Иванов',
      'type': 'text',
      'content': 'Добро пожаловать! Расскажите подробнее о ваших пожеланиях',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      ),
    },
    {
      'chatId': chatIds[0],
      'senderId': 'user1',
      'senderName': 'Анна Петрова',
      'type': 'text',
      'content': 'Хотим свадьбу в стиле "Великий Гэтсби" на 50 человек',
      'status': 'read',
      'timestamp':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
    },
    {
      'chatId': chatIds[0],
      'senderId': 'specialist1',
      'senderName': 'Александр Иванов',
      'type': 'text',
      'content': 'Отличная идея! У нас есть опыт организации таких мероприятий',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2, hours: 20)),
      ),
    },
    {
      'chatId': chatIds[0],
      'senderId': 'user1',
      'senderName': 'Анна Петрова',
      'type': 'text',
      'content': 'Спасибо за организацию свадьбы!',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    },
    {
      'chatId': chatIds[1],
      'senderId': 'user2',
      'senderName': 'Михаил Сидоров',
      'type': 'text',
      'content': 'Здравствуйте! Нужна организация корпоратива',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
    },
    {
      'chatId': chatIds[1],
      'senderId': 'specialist1',
      'senderName': 'Александр Иванов',
      'type': 'text',
      'content': 'Привет! Расскажите о вашем корпоративе',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      ),
    },
    {
      'chatId': chatIds[1],
      'senderId': 'user2',
      'senderName': 'Михаил Сидоров',
      'type': 'text',
      'content': 'Новогодний корпоратив на 30 человек',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      ),
    },
    {
      'chatId': chatIds[1],
      'senderId': 'user2',
      'senderName': 'Михаил Сидоров',
      'type': 'text',
      'content': 'Когда можем обсудить детали корпоратива?',
      'status': 'read',
      'timestamp':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
    },
    {
      'chatId': chatIds[2],
      'senderId': 'user3',
      'senderName': 'Елена Козлова',
      'type': 'text',
      'content': 'Добрый день! Организуете детские праздники?',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
    },
    {
      'chatId': chatIds[2],
      'senderId': 'specialist2',
      'senderName': 'Мария Смирнова',
      'type': 'text',
      'content': 'Да, конечно! У нас большой опыт с детскими мероприятиями',
      'status': 'read',
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ),
    },
    {
      'chatId': chatIds[2],
      'senderId': 'user3',
      'senderName': 'Елена Козлова',
      'type': 'text',
      'content': 'Какие аниматоры у вас есть?',
      'status': 'read',
      'timestamp':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
    },
  ];

  for (final message in testMessages) {
    await firestore
        .collection('chats')
        .doc(message['chatId']! as String)
        .collection('messages')
        .add(message);
  }

  debugPrint('Добавлено ${testMessages.length} тестовых сообщений');
}
