import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/firebase_auth_service.dart';

/// Генератор тестовых данных для чатов
class ChatTestDataGenerator {
  final ChatService _chatService = ChatService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать тестовые чаты и сообщения
  Future<void> generateTestChatData() async {
    try {
      print('Начинаем создание тестовых данных для чатов...');

      // Создаем тестовых пользователей
      const customerId = 'test_customer_001';
      const specialist1Id = 'test_specialist_001'; // Ведущий
      const specialist2Id = 'test_specialist_002'; // Фотограф

      // Создаем пользователей в Firestore
      await _createTestUsers(customerId, specialist1Id, specialist2Id);

      // Создаем чаты
      final chat1Id = await _createTestChat(customerId, specialist1Id, 'Ведущий');
      final chat2Id = await _createTestChat(customerId, specialist2Id, 'Фотограф');

      // Создаем сообщения для первого чата (с ведущим)
      await _createMessagesForChat1(chat1Id, customerId, specialist1Id);

      // Создаем сообщения для второго чата (с фотографом)
      await _createMessagesForChat2(chat2Id, customerId, specialist2Id);

      print('Тестовые данные для чатов успешно созданы!');
    } catch (e) {
      print('Ошибка создания тестовых данных: $e');
    }
  }

  /// Создать тестовых пользователей
  Future<void> _createTestUsers(
    String customerId,
    String specialist1Id,
    String specialist2Id,
  ) async {
    // Создаем заказчика
    await _firestore.collection('users').doc(customerId).set({
      'id': customerId,
      'email': 'customer@test.com',
      'displayName': 'Анна Петрова',
      'role': 'customer',
      'avatar': 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=AP',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Создаем ведущего
    await _firestore.collection('users').doc(specialist1Id).set({
      'id': specialist1Id,
      'email': 'host@test.com',
      'displayName': 'Михаил Ведущий',
      'role': 'specialist',
      'specialization': 'Ведущий',
      'avatar': 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=MV',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Создаем фотографа
    await _firestore.collection('users').doc(specialist2Id).set({
      'id': specialist2Id,
      'email': 'photographer@test.com',
      'displayName': 'Елена Фотограф',
      'role': 'specialist',
      'specialization': 'Фотограф',
      'avatar': 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=EF',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Создать тестовый чат
  Future<String> _createTestChat(
    String customerId,
    String specialistId,
    String specialistType,
  ) async {
    final chatData = {
      'participants': [customerId, specialistId],
      'participantNames': {
        customerId: 'Анна Петрова',
        specialistId: specialistType == 'Ведущий' ? 'Михаил Ведущий' : 'Елена Фотограф',
      },
      'participantAvatars': {
        customerId: 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=AP',
        specialistId: specialistType == 'Ведущий'
            ? 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=MV'
            : 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=EF',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isGroup': false,
    };

    final docRef = await _firestore.collection('chats').add(chatData);
    return docRef.id;
  }

  /// Создать сообщения для чата с ведущим
  Future<void> _createMessagesForChat1(
    String chatId,
    String customerId,
    String specialistId,
  ) async {
    final messages = [
      // Текстовые сообщения
      {
        'chatId': chatId,
        'senderId': customerId,
        'senderName': 'Анна Петрова',
        'senderAvatar': 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=AP',
        'type': 'text',
        'content': 'Здравствуйте! Меня интересует проведение свадьбы на 50 человек.',
        'status': 'read',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      {
        'chatId': chatId,
        'senderId': specialistId,
        'senderName': 'Михаил Ведущий',
        'senderAvatar': 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=MV',
        'type': 'text',
        'content':
            'Добро пожаловать! Буду рад помочь с организацией вашей свадьбы. Когда планируется мероприятие?',
        'status': 'read',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        ),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      {
        'chatId': chatId,
        'senderId': customerId,
        'senderName': 'Анна Петрова',
        'senderAvatar': 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=AP',
        'type': 'text',
        'content': 'Свадьба планируется на 15 июня. Хотелось бы обсудить программу и стоимость.',
        'status': 'read',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        ),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      // Фото
      {
        'chatId': chatId,
        'senderId': specialistId,
        'senderName': 'Михаил Ведущий',
        'senderAvatar': 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=MV',
        'type': 'image',
        'content': 'Примеры моих работ',
        'fileUrl': 'https://via.placeholder.com/400x300/4ECDC4/FFFFFF?text=Wedding+Photo',
        'fileName': 'wedding_example.jpg',
        'fileSize': 1024000,
        'status': 'read',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        ),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      // Видео
      {
        'chatId': chatId,
        'senderId': specialistId,
        'senderName': 'Михаил Ведущий',
        'senderAvatar': 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=MV',
        'type': 'video',
        'content': 'Видео с предыдущей свадьбы',
        'fileUrl': 'https://via.placeholder.com/400x300/FF6B6B/FFFFFF?text=Wedding+Video',
        'fileName': 'wedding_video.mp4',
        'fileSize': 15728640, // 15 MB
        'thumbnailUrl': 'https://via.placeholder.com/200x150/FF6B6B/FFFFFF?text=Video+Thumb',
        'status': 'read',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 45))),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
    ];

    // Добавляем сообщения в Firestore
    for (final messageData in messages) {
      await _firestore.collection('messages').add(messageData);
    }

    // Обновляем последнее сообщение в чате
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessageContent': 'Видео с предыдущей свадьбы',
      'lastMessageType': 'video',
      'lastMessageTime': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 45))),
      'lastMessageSenderId': specialistId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Создать сообщения для чата с фотографом
  Future<void> _createMessagesForChat2(
    String chatId,
    String customerId,
    String specialistId,
  ) async {
    final messages = [
      // Текстовые сообщения
      {
        'chatId': chatId,
        'senderId': customerId,
        'senderName': 'Анна Петрова',
        'senderAvatar': 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=AP',
        'type': 'text',
        'content': 'Привет! Нужен фотограф на свадьбу 15 июня.',
        'status': 'read',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      {
        'chatId': chatId,
        'senderId': specialistId,
        'senderName': 'Елена Фотограф',
        'senderAvatar': 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=EF',
        'type': 'text',
        'content':
            'Здравствуйте! С удовольствием помогу запечатлеть ваш особенный день. Расскажите подробнее о мероприятии.',
        'status': 'read',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        ),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      {
        'chatId': chatId,
        'senderId': customerId,
        'senderName': 'Анна Петрова',
        'senderAvatar': 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=AP',
        'type': 'text',
        'content':
            'Свадьба на 50 человек, церемония в 15:00, банкет до 23:00. Нужна полная съемка.',
        'status': 'read',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        ),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      // Фото
      {
        'chatId': chatId,
        'senderId': specialistId,
        'senderName': 'Елена Фотограф',
        'senderAvatar': 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=EF',
        'type': 'image',
        'content': 'Мое портфолио',
        'fileUrl': 'https://via.placeholder.com/400x300/45B7D1/FFFFFF?text=Portfolio+Photo',
        'fileName': 'portfolio.jpg',
        'fileSize': 2048000,
        'status': 'read',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
        ),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
      // Видео
      {
        'chatId': chatId,
        'senderId': specialistId,
        'senderName': 'Елена Фотограф',
        'senderAvatar': 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=EF',
        'type': 'video',
        'content': 'Свадебная съемка - пример',
        'fileUrl': 'https://via.placeholder.com/400x300/96CEB4/FFFFFF?text=Wedding+Shooting',
        'fileName': 'wedding_shooting.mp4',
        'fileSize': 25165824, // 24 MB
        'thumbnailUrl': 'https://via.placeholder.com/200x150/96CEB4/FFFFFF?text=Shooting+Thumb',
        'status': 'read',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
        'readBy': [customerId, specialistId],
        'isDeleted': false,
      },
    ];

    // Добавляем сообщения в Firestore
    for (final messageData in messages) {
      await _firestore.collection('messages').add(messageData);
    }

    // Обновляем последнее сообщение в чате
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessageContent': 'Свадебная съемка - пример',
      'lastMessageType': 'video',
      'lastMessageTime': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
      'lastMessageSenderId': specialistId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Очистить тестовые данные
  Future<void> clearTestData() async {
    try {
      print('Очищаем тестовые данные...');

      // Удаляем тестовые чаты
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: 'test_customer_001')
          .get();

      for (final doc in chatsSnapshot.docs) {
        // Удаляем сообщения чата
        final messagesSnapshot = await _firestore
            .collection('messages')
            .where('chatId', isEqualTo: doc.id)
            .get();

        for (final messageDoc in messagesSnapshot.docs) {
          await messageDoc.reference.delete();
        }

        // Удаляем чат
        await doc.reference.delete();
      }

      // Удаляем тестовых пользователей
      final testUserIds = ['test_customer_001', 'test_specialist_001', 'test_specialist_002'];
      for (final userId in testUserIds) {
        await _firestore.collection('users').doc(userId).delete();
      }

      print('Тестовые данные успешно очищены!');
    } catch (e) {
      print('Ошибка очистки тестовых данных: $e');
    }
  }

  /// Создать дополнительные тестовые сообщения
  Future<void> addMoreTestMessages(String chatId, String senderId, String senderName) async {
    final additionalMessages = [
      {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'type': 'text',
        'content': 'Это тестовое сообщение для проверки функциональности чата.',
        'status': 'sent',
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'readBy': [senderId],
        'isDeleted': false,
      },
      {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'type': 'text',
        'content': 'Можете ли вы отправить мне прайс-лист?',
        'status': 'sent',
        'timestamp': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 1))),
        'readBy': [senderId],
        'isDeleted': false,
      },
      {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'type': 'document',
        'content': 'Документ с требованиями',
        'fileUrl': 'https://via.placeholder.com/300x400/FFEAA7/000000?text=PDF+Document',
        'fileName': 'requirements.pdf',
        'fileSize': 512000,
        'status': 'sent',
        'timestamp': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 2))),
        'readBy': [senderId],
        'isDeleted': false,
      },
    ];

    for (final messageData in additionalMessages) {
      await _firestore.collection('messages').add(messageData);
    }
  }
}
