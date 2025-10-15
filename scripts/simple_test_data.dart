void main() {
  print('Тестовые данные для Firestore:');
  print('');

  print('=== ТЕСТОВЫЕ ЗАЯВКИ ===');
  print('Добавьте эти данные в коллекцию "bookings":');
  print('');

  final bookings = [
    {
      'customerId': 'user1',
      'specialistId': 'specialist1',
      'eventTitle': 'Свадьба в стиле "Великий Гэтсби"',
      'eventDate':
          DateTime.now().add(const Duration(days: 15)).toIso8601String(),
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
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'customerId': 'user2',
      'specialistId': 'specialist1',
      'eventTitle': 'Корпоратив IT-компании',
      'eventDate':
          DateTime.now().add(const Duration(days: 25)).toIso8601String(),
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
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    },
    {
      'customerId': 'user3',
      'specialistId': 'specialist2',
      'eventTitle': 'День рождения ребенка',
      'eventDate':
          DateTime.now().add(const Duration(days: 10)).toIso8601String(),
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
          DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'customerId': 'user1',
      'specialistId': 'specialist2',
      'eventTitle': 'Выпускной вечер',
      'eventDate':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
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
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'customerId': 'user4',
      'specialistId': 'specialist1',
      'eventTitle': 'Юбилей компании',
      'eventDate':
          DateTime.now().add(const Duration(days: 20)).toIso8601String(),
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
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  for (var i = 0; i < bookings.length; i++) {
    print('Заявка ${i + 1}:');
    print(bookings[i]);
    print('');
  }

  print('=== ТЕСТОВЫЕ ЧАТЫ ===');
  print('Добавьте эти данные в коллекцию "chats":');
  print('');

  final chats = [
    {
      'participants': ['user1', 'specialist1'],
      'participantNames': {
        'user1': 'Анна Петрова',
        'specialist1': 'Александр Иванов',
      },
      'lastMessageContent': 'Спасибо за организацию свадьбы!',
      'lastMessageTime': DateTime.now()
          .subtract(const Duration(minutes: 30))
          .toIso8601String(),
      'createdAt':
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'updatedAt': DateTime.now()
          .subtract(const Duration(minutes: 30))
          .toIso8601String(),
    },
    {
      'participants': ['user2', 'specialist1'],
      'participantNames': {
        'user2': 'Михаил Сидоров',
        'specialist1': 'Александр Иванов',
      },
      'lastMessageContent': 'Когда можем обсудить детали корпоратива?',
      'lastMessageTime':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'createdAt':
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'participants': ['user3', 'specialist2'],
      'participantNames': {
        'user3': 'Елена Козлова',
        'specialist2': 'Мария Смирнова',
      },
      'lastMessageContent': 'Какие аниматоры у вас есть?',
      'lastMessageTime':
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      'createdAt':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'participants': ['user1', 'specialist2'],
      'participantNames': {
        'user1': 'Анна Петрова',
        'specialist2': 'Мария Смирнова',
      },
      'lastMessageContent': 'Отлично, ждем вас в 18:00',
      'lastMessageTime': DateTime.now()
          .subtract(const Duration(minutes: 45))
          .toIso8601String(),
      'createdAt':
          DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      'updatedAt': DateTime.now()
          .subtract(const Duration(minutes: 45))
          .toIso8601String(),
    },
    {
      'participants': ['user4', 'specialist1'],
      'participantNames': {
        'user4': 'Дмитрий Волков',
        'specialist1': 'Александр Иванов',
      },
      'lastMessageContent': 'Спасибо за отличную организацию юбилея!',
      'lastMessageTime':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'createdAt':
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      'updatedAt':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  for (var i = 0; i < chats.length; i++) {
    print('Чат ${i + 1}:');
    print(chats[i]);
    print('');
  }

  print('=== ТЕСТОВЫЕ СООБЩЕНИЯ ===');
  print('Добавьте эти данные в подколлекцию "messages" для каждого чата:');
  print('');

  final messages = [
    {
      'senderId': 'user1',
      'senderName': 'Анна Петрова',
      'type': 'text',
      'content': 'Здравствуйте! Интересует организация свадьбы',
      'status': 'read',
      'timestamp': DateTime.now()
          .subtract(const Duration(days: 3, hours: 2))
          .toIso8601String(),
    },
    {
      'senderId': 'specialist1',
      'senderName': 'Александр Иванов',
      'type': 'text',
      'content': 'Добро пожаловать! Расскажите подробнее о ваших пожеланиях',
      'status': 'read',
      'timestamp': DateTime.now()
          .subtract(const Duration(days: 3, hours: 1))
          .toIso8601String(),
    },
    {
      'senderId': 'user1',
      'senderName': 'Анна Петрова',
      'type': 'text',
      'content': 'Хотим свадьбу в стиле "Великий Гэтсби" на 50 человек',
      'status': 'read',
      'timestamp':
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
    {
      'senderId': 'specialist1',
      'senderName': 'Александр Иванов',
      'type': 'text',
      'content': 'Отличная идея! У нас есть опыт организации таких мероприятий',
      'status': 'read',
      'timestamp': DateTime.now()
          .subtract(const Duration(days: 2, hours: 20))
          .toIso8601String(),
    },
    {
      'senderId': 'user1',
      'senderName': 'Анна Петрова',
      'type': 'text',
      'content': 'Спасибо за организацию свадьбы!',
      'status': 'read',
      'timestamp': DateTime.now()
          .subtract(const Duration(minutes: 30))
          .toIso8601String(),
    },
  ];

  for (var i = 0; i < messages.length; i++) {
    print('Сообщение ${i + 1}:');
    print(messages[i]);
    print('');
  }

  print('=== ИНСТРУКЦИИ ===');
  print('1. Откройте Firebase Console');
  print('2. Перейдите в Firestore Database');
  print(
    '3. Создайте коллекции "bookings", "chats" и добавьте документы с данными выше',
  );
  print('4. Для сообщений создайте подколлекцию "messages" в каждом чате');
  print(
    '5. Убедитесь, что пользователи user1, user2, user3, user4 и специалисты specialist1, specialist2 существуют в вашей системе аутентификации',
  );
}
