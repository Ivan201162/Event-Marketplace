import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Скрипт для добавления тестовых данных в Firestore
/// Запуск: dart run tool/firestore_test_data_seeder.dart
void main() async {
  print('🚀 Инициализация Firebase...');
  
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  
  print('📝 Начинаем добавление тестовых данных...');
  
  try {
    // ЭТАП 1: Тестовые пользователи
    await _createTestUsers(firestore);
    
    // ЭТАП 2: Посты в ленте
    await _createFeedPosts(firestore);
    
    // ЭТАП 3: Заявки
    await _createOrders(firestore);
    
    // ЭТАП 4: Чаты и сообщения
    await _createChats(firestore);
    
    // ЭТАП 5: Идеи
    await _createIdeas(firestore);
    
    print('✅ Все тестовые данные успешно добавлены!');
    
  } catch (e) {
    print('❌ Ошибка при добавлении данных: $e');
  }
  
  exit(0);
}

/// Создание тестовых пользователей
Future<void> _createTestUsers(FirebaseFirestore firestore) async {
  print('👥 Создание тестовых пользователей...');
  
  final users = [
    {
      'uid': 'user_1',
      'name': 'Александр Иванов',
      'city': 'Москва',
      'avatarUrl': 'https://i.pravatar.cc/150?img=1',
      'role': 'specialist',
      'email': 'alex.ivanov@example.com',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'uid': 'user_2',
      'name': 'Мария Смирнова',
      'city': 'Санкт-Петербург',
      'avatarUrl': 'https://i.pravatar.cc/150?img=2',
      'role': 'customer',
      'email': 'maria.smirnova@example.com',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'uid': 'user_3',
      'name': 'Игорь Кузнецов',
      'city': 'Казань',
      'avatarUrl': 'https://i.pravatar.cc/150?img=3',
      'role': 'specialist',
      'email': 'igor.kuznetsov@example.com',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'uid': 'user_4',
      'name': 'Анна Сергеева',
      'city': 'Новосибирск',
      'avatarUrl': 'https://i.pravatar.cc/150?img=4',
      'role': 'customer',
      'email': 'anna.sergeeva@example.com',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'uid': 'user_5',
      'name': 'Дмитрий Орлов',
      'city': 'Екатеринбург',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
      'role': 'specialist',
      'email': 'dmitry.orlov@example.com',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  ];
  
  for (final user in users) {
    await firestore.collection('users').doc(user['uid'] as String).set(user);
    print('  ✅ Пользователь ${user['name']} создан');
  }
}

/// Создание постов в ленте
Future<void> _createFeedPosts(FirebaseFirestore firestore) async {
  print('📢 Создание постов в ленте...');
  
  final posts = [
    {
      'id': 'feed_1',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=1',
      'text': 'Поделился кадром с последнего мероприятия 🎤',
      'likesCount': 25,
      'commentsCount': 6,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_2',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/300?random=2',
      'text': 'Новая фотозона для свадеб готова! 🌸',
      'likesCount': 18,
      'commentsCount': 4,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_3',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/300?random=3',
      'text': 'Отличный день для фотосессии на природе 📸',
      'likesCount': 32,
      'commentsCount': 8,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_4',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=4',
      'text': 'Свадебная церемония в стиле винтаж 💍',
      'likesCount': 41,
      'commentsCount': 12,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_5',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/300?random=5',
      'text': 'Детский праздник с аниматорами 🎈',
      'likesCount': 15,
      'commentsCount': 3,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_6',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/300?random=6',
      'text': 'Корпоративное мероприятие прошло на ура! 🎉',
      'likesCount': 28,
      'commentsCount': 7,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_7',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=7',
      'text': 'Новый реквизит для фотосессий 📷',
      'likesCount': 22,
      'commentsCount': 5,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_8',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/300?random=8',
      'text': 'День рождения в стиле пиратской вечеринки 🏴‍☠️',
      'likesCount': 19,
      'commentsCount': 4,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_9',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/300?random=9',
      'text': 'Семейная фотосессия в парке 👨‍👩‍👧‍👦',
      'likesCount': 35,
      'commentsCount': 9,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'feed_10',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=10',
      'text': 'Выпускной вечер в школе 🎓',
      'likesCount': 27,
      'commentsCount': 6,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];
  
  for (final post in posts) {
    await firestore.collection('feed').doc(post['id'] as String).set(post);
    print('  ✅ Пост ${post['id']} создан');
  }
}

/// Создание заявок
Future<void> _createOrders(FirebaseFirestore firestore) async {
  print('📝 Создание заявок...');
  
  final orders = [
    {
      'id': 'order_1',
      'customerId': 'user_2',
      'specialistId': 'user_1',
      'title': 'Свадьба 14 октября',
      'description': 'Нужен ведущий с юмором и диджей на свадьбу на 40 человек.',
      'status': 'pending',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'order_2',
      'customerId': 'user_4',
      'specialistId': 'user_3',
      'title': 'Детский день рождения',
      'description': 'Организация праздника для 8-летнего ребенка. Нужны аниматоры и фотограф.',
      'status': 'accepted',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'order_3',
      'customerId': 'user_2',
      'specialistId': 'user_5',
      'title': 'Корпоративное мероприятие',
      'description': 'Новогодний корпоратив на 50 сотрудников. Нужен ведущий и музыкальное сопровождение.',
      'status': 'completed',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'order_4',
      'customerId': 'user_4',
      'specialistId': 'user_1',
      'title': 'Фотосессия для пары',
      'description': 'Романтическая фотосессия в парке. Нужен профессиональный фотограф.',
      'status': 'pending',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'order_5',
      'customerId': 'user_2',
      'specialistId': 'user_3',
      'title': 'Выпускной вечер',
      'description': 'Организация выпускного для 11 класса. Нужен ведущий и диджей.',
      'status': 'accepted',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'order_6',
      'customerId': 'user_4',
      'specialistId': 'user_5',
      'title': 'Семейная фотосессия',
      'description': 'Фотосессия семьи из 4 человек. Нужен фотограф с опытом работы с детьми.',
      'status': 'completed',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'order_7',
      'customerId': 'user_2',
      'specialistId': 'user_1',
      'title': 'Юбилей бабушки',
      'description': 'Празднование 70-летия. Нужен ведущий и музыкальное сопровождение.',
      'status': 'canceled',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'order_8',
      'customerId': 'user_4',
      'specialistId': 'user_3',
      'title': 'День рождения ребенка',
      'description': 'Праздник для 5-летней девочки. Нужны аниматоры в костюмах принцесс.',
      'status': 'pending',
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];
  
  for (final order in orders) {
    await firestore.collection('orders').doc(order['id'] as String).set(order);
    print('  ✅ Заявка ${order['id']} создана');
  }
}

/// Создание чатов и сообщений
Future<void> _createChats(FirebaseFirestore firestore) async {
  print('💬 Создание чатов и сообщений...');
  
  final chats = [
    {
      'id': 'chat_1',
      'members': ['user_1', 'user_2'],
      'lastMessage': 'Добрый день! Уточните дату?',
      'isTest': true,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'chat_2',
      'members': ['user_3', 'user_4'],
      'lastMessage': 'Спасибо за отличную работу!',
      'isTest': true,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'chat_3',
      'members': ['user_5', 'user_2'],
      'lastMessage': 'Когда можем встретиться?',
      'isTest': true,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'chat_4',
      'members': ['user_1', 'user_4'],
      'lastMessage': 'Фото готовы, отправляю ссылку',
      'isTest': true,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'chat_5',
      'members': ['user_3', 'user_2'],
      'lastMessage': 'До встречи завтра!',
      'isTest': true,
      'updatedAt': FieldValue.serverTimestamp(),
    },
  ];
  
  // Создаем чаты
  for (final chat in chats) {
    await firestore.collection('chats').doc(chat['id'] as String).set(chat);
    print('  ✅ Чат ${chat['id']} создан');
    
    // Создаем сообщения для каждого чата
    final chatId = chat['id'] as String;
    final members = chat['members'] as List<String>;
    
    final messages = [
      {
        'id': 'msg_${chatId}_1',
        'senderId': members[0],
        'text': 'Здравствуйте, рад знакомству 👋',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'msg_${chatId}_2',
        'senderId': members[1],
        'text': 'Привет! Спасибо за отклик',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'msg_${chatId}_3',
        'senderId': members[0],
        'text': 'Расскажите подробнее о мероприятии',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'msg_${chatId}_4',
        'senderId': members[1],
        'text': 'Конечно! Это будет свадьба на 40 человек',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'msg_${chatId}_5',
        'senderId': members[0],
        'text': 'Отлично! Когда планируете?',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    
    for (final message in messages) {
      await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message['id'] as String)
          .set(message);
    }
    print('    ✅ 5 сообщений добавлено в чат $chatId');
  }
}

/// Создание идей
Future<void> _createIdeas(FirebaseFirestore firestore) async {
  print('💡 Создание идей...');
  
  final ideas = [
    {
      'id': 'idea_1',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/400?random=21',
      'title': 'Необычная фотозона 🌸',
      'description': 'Отличная идея для летних свадеб. Используйте живые цветы и натуральные материалы.',
      'likesCount': 12,
      'commentsCount': 3,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'idea_2',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/400?random=22',
      'title': 'Винтажная свадебная церемония 💍',
      'description': 'Создайте атмосферу прошлого века с помощью ретро-реквизита и классической музыки.',
      'likesCount': 28,
      'commentsCount': 7,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'idea_3',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/400?random=23',
      'title': 'Пикник на природе 🧺',
      'description': 'Организуйте романтический пикник с красивой сервировкой и природным декором.',
      'likesCount': 19,
      'commentsCount': 5,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'idea_4',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/400?random=24',
      'title': 'Детский праздник в стиле пиратов 🏴‍☠️',
      'description': 'Создайте незабываемое приключение для детей с костюмами и тематическими играми.',
      'likesCount': 15,
      'commentsCount': 4,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'idea_5',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/400?random=25',
      'title': 'Семейная фотосессия в парке 👨‍👩‍👧‍👦',
      'description': 'Запечатлейте счастливые моменты семьи на фоне красивой природы.',
      'likesCount': 24,
      'commentsCount': 6,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'idea_6',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/400?random=26',
      'title': 'Корпоратив в стиле 80-х 🕺',
      'description': 'Вернитесь в эпоху диско с яркими костюмами и зажигательной музыкой.',
      'likesCount': 21,
      'commentsCount': 8,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'idea_7',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/400?random=27',
      'title': 'Романтический ужин при свечах 🕯️',
      'description': 'Создайте интимную атмосферу с красивой сервировкой и мягким освещением.',
      'likesCount': 17,
      'commentsCount': 3,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'idea_8',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/400?random=28',
      'title': 'Выпускной в стиле Гарри Поттера 🧙‍♂️',
      'description': 'Окунитесь в мир магии с тематическими декорациями и костюмами.',
      'likesCount': 31,
      'commentsCount': 9,
      'isTest': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];
  
  for (final idea in ideas) {
    await firestore.collection('ideas').doc(idea['id'] as String).set(idea);
    print('  ✅ Идея ${idea['id']} создана');
  }
}

