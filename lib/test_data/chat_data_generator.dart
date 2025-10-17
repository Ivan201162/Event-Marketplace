import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/specialist.dart';
import '../models/user.dart';

/// Генератор данных для чатов
class ChatDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Шаблоны сообщений для различных этапов общения
  static const List<String> greetingMessages = [
    'Здравствуйте! Интересует ваша услуга.',
    'Добрый день! Можете рассказать подробнее о ваших услугах?',
    'Привет! Видел ваше портфолио, очень понравилось.',
    'Здравствуйте! Ищу специалиста для мероприятия.',
    'Добрый день! Подходите ли вы для нашего события?',
  ];

  static const List<String> specialistResponses = [
    'Здравствуйте! Конечно, расскажу. Какое мероприятие планируете?',
    'Добрый день! Буду рад помочь. Когда планируется событие?',
    'Привет! Спасибо за интерес. Какие у вас пожелания?',
    'Здравствуйте! Давайте обсудим детали вашего мероприятия.',
    'Добрый день! Да, я специализируюсь на таких событиях.',
  ];

  static const List<String> detailQuestions = [
    'Сколько будет гостей?',
    'Какой у вас бюджет?',
    'Где планируется мероприятие?',
    'На сколько часов нужны услуги?',
    'Есть ли особые пожелания?',
    'Какая тематика мероприятия?',
  ];

  static const List<String> customerAnswers = [
    'Гостей будет около 50 человек.',
    'Бюджет примерно 100 000 рублей.',
    'Мероприятие в ресторане в центре города.',
    'Нужно на 6 часов.',
    'Хотим что-то в классическом стиле.',
    'Это свадебное торжество.',
  ];

  static const List<String> negotiationMessages = [
    'Это входит в стоимость?',
    'Можете сделать скидку?',
    'Когда можем встретиться для обсуждения?',
    'Нужна ли предоплата?',
    'Какие гарантии вы даете?',
  ];

  static const List<String> finalMessages = [
    'Отлично! Договорились.',
    'Спасибо, буду ждать от вас предложение.',
    'Хорошо, свяжемся для уточнения деталей.',
    'Пока думаем, спасибо за информацию.',
    'Забронируем ваши услуги!',
  ];

  /// Генерация чатов между заказчиками и специалистами
  Future<void> generateChats(
    List<AppUser> customers,
    List<Specialist> specialists,
    List<Booking> bookings,
  ) async {
    print('💬 Генерация чатов...');

    var chatCount = 0;

    // Создаем чаты для существующих бронирований
    for (final booking in bookings) {
      final customer = customers.firstWhere((c) => c.id == booking.customerId);
      final specialist = specialists.firstWhere((s) => s.id == booking.specialistId);

      await _createChatConversation(customer, specialist, booking);
      chatCount++;

      if (chatCount % 50 == 0) {
        print('✅ Создано чатов: $chatCount');
      }
    }

    // Создаем дополнительные чаты без бронирований (потенциальные клиенты)
    final additionalChats = _random.nextInt(200) + 100;
    for (var i = 0; i < additionalChats; i++) {
      final customer = customers[_random.nextInt(customers.length)];
      final specialist = specialists[_random.nextInt(specialists.length)];

      await _createChatConversation(customer, specialist, null);
      chatCount++;
    }

    print('✅ Генерация чатов завершена: $chatCount');
  }

  /// Создание беседы между заказчиком и специалистом
  Future<void> _createChatConversation(
    AppUser customer,
    Specialist specialist,
    Booking? booking,
  ) async {
    final chatId = 'chat_${customer.id}_${specialist.id}';
    final messageCount = _random.nextInt(10) + 5; // 5-15 сообщений
    final messages = <Map<String, dynamic>>[];

    // Создаем чат документ
    final chatData = {
      'id': chatId,
      'participants': [customer.id, specialist.id],
      'participantNames': {
        customer.id: customer.displayName ?? 'Заказчик',
        specialist.id: specialist.name,
      },
      'participantAvatars': {
        customer.id: customer.photoURL,
        specialist.id: specialist.profileImageUrl,
      },
      'lastMessage': '',
      'lastMessageTime': null,
      'unreadCount': {
        customer.id: 0,
        specialist.id: 0,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'bookingId': booking?.id,
      'specialistCategory': specialist.category.name,
    };

    // Генерируем сообщения
    var messageTime = _generateRandomDate();
    var isCustomerTurn = true;

    for (var i = 0; i < messageCount; i++) {
      final message = _generateMessage(i, isCustomerTurn, booking != null);

      messages.add({
        'id': 'msg_${chatId}_$i',
        'chatId': chatId,
        'senderId': isCustomerTurn ? customer.id : specialist.id,
        'senderName': isCustomerTurn ? (customer.displayName ?? 'Заказчик') : specialist.name,
        'text': message,
        'timestamp': Timestamp.fromDate(messageTime),
        'isRead': true,
        'type': 'text',
        'attachments': <String>[],
      });

      // Обновляем время для следующего сообщения
      messageTime = messageTime.add(
        Duration(
          minutes: _random.nextInt(60) + 5, // 5-65 минут между сообщениями
        ),
      );

      isCustomerTurn = !isCustomerTurn;
    }

    // Обновляем последнее сообщение в чате
    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      chatData['lastMessage'] = lastMessage['text'];
      chatData['lastMessageTime'] = lastMessage['timestamp'];
    }

    try {
      // Сохраняем чат
      await _firestore.collection('chats').doc(chatId).set(chatData);

      // Сохраняем сообщения
      final batch = _firestore.batch();
      for (final message in messages) {
        final messageRef =
            _firestore.collection('chats').doc(chatId).collection('messages').doc(message['id']);
        batch.set(messageRef, message);
      }
      await batch.commit();
    } catch (e) {
      print('❌ Ошибка создания чата $chatId: $e');
    }
  }

  /// Генерация сообщения в зависимости от номера и контекста
  String _generateMessage(
    int messageIndex,
    bool isFromCustomer,
    bool hasBooking,
  ) {
    if (messageIndex == 0) {
      // Первое сообщение - приветствие от заказчика
      return greetingMessages[_random.nextInt(greetingMessages.length)];
    }

    if (messageIndex == 1) {
      // Ответ специалиста
      return specialistResponses[_random.nextInt(specialistResponses.length)];
    }

    if (messageIndex < 4) {
      // Уточнение деталей
      if (isFromCustomer) {
        return customerAnswers[_random.nextInt(customerAnswers.length)];
      } else {
        return detailQuestions[_random.nextInt(detailQuestions.length)];
      }
    }

    if (messageIndex < 8) {
      // Переговоры
      if (isFromCustomer) {
        return negotiationMessages[_random.nextInt(negotiationMessages.length)];
      } else {
        return _generateSpecialistNegotiationResponse();
      }
    }

    // Завершающие сообщения
    if (hasBooking) {
      if (isFromCustomer) {
        return finalMessages[_random.nextInt(finalMessages.length)];
      } else {
        return 'Отлично! Жду вас в назначенное время. Всё будет на высшем уровне!';
      }
    } else {
      if (isFromCustomer) {
        return 'Спасибо за информацию, подумаем.';
      } else {
        return 'Обращайтесь, если будут вопросы!';
      }
    }
  }

  String _generateSpecialistNegotiationResponse() {
    final responses = [
      'Да, это входит в базовую стоимость.',
      'Могу предложить небольшую скидку постоянным клиентам.',
      'Можем встретиться в любое удобное время.',
      'Обычно беру предоплату 30%.',
      'Гарантирую качество и соблюдение сроков.',
      'Покажу вам примеры моих работ.',
      'Обсудим все детали при встрече.',
      'Могу подготовить несколько вариантов.',
    ];
    return responses[_random.nextInt(responses.length)];
  }

  DateTime _generateRandomDate() {
    final now = DateTime.now();
    final daysAgo = _random.nextInt(30) + 1;
    return now.subtract(Duration(days: daysAgo));
  }

  /// Генерация системных уведомлений
  Future<void> generateNotifications(
    List<AppUser> customers,
    List<Specialist> specialists,
    List<Booking> bookings,
  ) async {
    print('🔔 Генерация уведомлений...');

    var notificationCount = 0;

    for (final booking in bookings) {
      // Уведомления для заказчика
      await _createNotification(
        userId: booking.customerId,
        title: 'Бронирование подтверждено',
        body: 'Ваше бронирование на ${booking.eventTitle} подтверждено',
        type: 'booking_confirmed',
        relatedId: booking.id,
      );

      // Уведомления для специалиста
      final specialist = specialists.firstWhere((s) => s.id == booking.specialistId);
      await _createNotification(
        userId: specialist.userId,
        title: 'Новое бронирование',
        body: 'У вас новое бронирование на ${booking.eventTitle}',
        type: 'new_booking',
        relatedId: booking.id,
      );

      notificationCount += 2;

      if (notificationCount % 100 == 0) {
        print('✅ Создано уведомлений: $notificationCount');
      }
    }

    print('✅ Генерация уведомлений завершена: $notificationCount');
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final notificationData = {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': _random.nextBool(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      print('❌ Ошибка создания уведомления: $e');
    }
  }
}
