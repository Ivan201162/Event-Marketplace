import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Простой скрипт для добавления тестовых данных в Firestore
/// Запуск: dart tool/simple_add_test_data.dart
Future<void> main() async {
  print('🚀 Инициализация Firebase...');

  // Инициализация Firebase
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  print('📝 Добавление тестовых данных...');

  try {
    // 1. Добавляем тестовых пользователей
    print('👥 Добавление тестовых пользователей...');
    await _addTestUsers(firestore);

    // 2. Добавляем посты в ленту
    print('📢 Добавление постов в ленту...');
    await _addFeedPosts(firestore);

    // 3. Добавляем заявки
    print('📝 Добавление заявок...');
    await _addOrders(firestore);

    // 4. Добавляем чаты с сообщениями
    print('💬 Добавление чатов...');
    await _addChats(firestore);

    // 5. Добавляем идеи
    print('💡 Добавление идей...');
    await _addIdeas(firestore);

    print('✅ Все тестовые данные успешно добавлены!');
  } catch (e) {
    print('❌ Ошибка при добавлении тестовых данных: $e');
    exit(1);
  }

  exit(0);
}

/// Добавление тестовых пользователей
Future<void> _addTestUsers(FirebaseFirestore firestore) async {
  final users = [
    {
      'uid': 'user_1',
      'name': 'Анна Лебедева',
      'city': 'Санкт-Петербург',
      'avatarUrl': 'https://picsum.photos/200/200?random=1',
      'role': 'specialist',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'uid': 'user_2',
      'name': 'Дмитрий Козлов',
      'city': 'Москва',
      'avatarUrl': 'https://picsum.photos/200/200?random=2',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'uid': 'user_3',
      'name': 'Елена Петрова',
      'city': 'Москва',
      'avatarUrl': 'https://picsum.photos/200/200?random=3',
      'role': 'specialist',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'uid': 'user_4',
      'name': 'Михаил Соколов',
      'city': 'Казань',
      'avatarUrl': 'https://picsum.photos/200/200?random=4',
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'uid': 'user_5',
      'name': 'Ольга Волкова',
      'city': 'Екатеринбург',
      'avatarUrl': 'https://picsum.photos/200/200?random=5',
      'role': 'specialist',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
  ];

  for (final user in users) {
    await firestore.collection('users').doc(user['uid']! as String).set(user);
  }

  print('✅ Добавлено ${users.length} тестовых пользователей');
}

/// Добавление постов в ленту
Future<void> _addFeedPosts(FirebaseFirestore firestore) async {
  final posts = [
    {
      'id': 'feed_1',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=1',
      'text': 'Праздник удался 🎉 Отличная свадьба в Санкт-Петербурге!',
      'likesCount': 25,
      'commentsCount': 5,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_2',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/300?random=2',
      'text': 'Корпоратив в офисе - звук и свет на высоте! 🎵',
      'likesCount': 18,
      'commentsCount': 3,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_3',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/300?random=3',
      'text': 'Детский день рождения - море радости и улыбок! 🎈',
      'likesCount': 32,
      'commentsCount': 8,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_4',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=4',
      'text': 'Фотосессия в парке - золотая осень во всей красе 🍂',
      'likesCount': 41,
      'commentsCount': 12,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_5',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/300?random=5',
      'text': 'Выпускной вечер - незабываемые моменты! 🎓',
      'likesCount': 28,
      'commentsCount': 6,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_6',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/300?random=6',
      'text': 'Новогодний корпоратив - праздник удался! 🎄',
      'likesCount': 35,
      'commentsCount': 9,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_7',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=7',
      'text': 'Свадебная церемония на природе - романтика! 💕',
      'likesCount': 47,
      'commentsCount': 15,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_8',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/300?random=8',
      'text': 'День рождения в ресторане - атмосфера праздника! 🎂',
      'likesCount': 22,
      'commentsCount': 4,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_9',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/300?random=9',
      'text': 'Тематическая вечеринка - все в костюмах! 🎭',
      'likesCount': 38,
      'commentsCount': 11,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'feed_10',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/300?random=10',
      'text': 'Фотосессия в студии - профессиональные кадры! 📸',
      'likesCount': 29,
      'commentsCount': 7,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
  ];

  for (final post in posts) {
    await firestore.collection('feed').doc(post['id']! as String).set(post);
  }

  print('✅ Добавлено ${posts.length} постов в ленту');
}

/// Добавление заявок
Future<void> _addOrders(FirebaseFirestore firestore) async {
  final orders = [
    {
      'id': 'order_1',
      'customerId': 'user_2',
      'specialistId': 'user_1',
      'title': 'Свадьба 14 октября',
      'description':
          'Нужен ведущий и диджей на 40 человек. Свадьба в загородном клубе.',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'order_2',
      'customerId': 'user_4',
      'specialistId': 'user_3',
      'title': 'Корпоратив 20 ноября',
      'description':
          'Организация корпоративного мероприятия на 60 сотрудников.',
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'order_3',
      'customerId': 'user_2',
      'specialistId': 'user_5',
      'title': 'Детский день рождения',
      'description': 'Праздник для ребенка 8 лет. Нужны аниматоры и украшения.',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'order_4',
      'customerId': 'user_4',
      'specialistId': 'user_1',
      'title': 'Фотосессия в парке',
      'description': 'Семейная фотосессия в осеннем парке. Нужен фотограф.',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'order_5',
      'customerId': 'user_2',
      'specialistId': 'user_3',
      'title': 'Выпускной вечер',
      'description':
          'Организация выпускного для 11 класса. Нужен ведущий и музыка.',
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'order_6',
      'customerId': 'user_4',
      'specialistId': 'user_5',
      'title': 'Новогодний корпоратив',
      'description':
          'Празднование Нового года в офисе. Нужны украшения и ведущий.',
      'status': 'canceled',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'order_7',
      'customerId': 'user_2',
      'specialistId': 'user_1',
      'title': 'Свадебная церемония',
      'description': 'Романтическая церемония на природе. Нужен фотограф.',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'order_8',
      'customerId': 'user_4',
      'specialistId': 'user_3',
      'title': 'День рождения в ресторане',
      'description':
          'Празднование 30-летия. Нужен ведущий и музыкальное сопровождение.',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
  ];

  for (final order in orders) {
    await firestore.collection('orders').doc(order['id']! as String).set(order);
  }

  print('✅ Добавлено ${orders.length} заявок');
}

/// Добавление чатов с сообщениями
Future<void> _addChats(FirebaseFirestore firestore) async {
  final chats = [
    {
      'id': 'chat_1',
      'members': ['user_1', 'user_2'],
      'lastMessage': 'Здравствуйте, уточните детали мероприятия?',
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'chat_2',
      'members': ['user_3', 'user_4'],
      'lastMessage': 'Спасибо за отличную организацию!',
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'chat_3',
      'members': ['user_5', 'user_2'],
      'lastMessage': 'Когда можем встретиться для обсуждения?',
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'chat_4',
      'members': ['user_1', 'user_4'],
      'lastMessage': 'Фотосессия прошла отлично!',
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'chat_5',
      'members': ['user_3', 'user_2'],
      'lastMessage': 'До встречи завтра в 15:00',
      'updatedAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
  ];

  for (final chat in chats) {
    await firestore.collection('chats').doc(chat['id']! as String).set(chat);

    // Добавляем сообщения в каждый чат
    final messages = [
      {
        'id': 'msg_1',
        'senderId': chat['members'][0],
        'text': 'Добрый день! Рад знакомству 👋',
        'createdAt': FieldValue.serverTimestamp(),
        'isTest': true,
      },
      {
        'id': 'msg_2',
        'senderId': chat['members'][1],
        'text': 'Привет! Спасибо за быстрый ответ',
        'createdAt': FieldValue.serverTimestamp(),
        'isTest': true,
      },
      {
        'id': 'msg_3',
        'senderId': chat['members'][0],
        'text': 'Расскажите подробнее о вашем мероприятии',
        'createdAt': FieldValue.serverTimestamp(),
        'isTest': true,
      },
      {
        'id': 'msg_4',
        'senderId': chat['members'][1],
        'text': 'Это будет свадьба на 50 человек',
        'createdAt': FieldValue.serverTimestamp(),
        'isTest': true,
      },
      {
        'id': 'msg_5',
        'senderId': chat['members'][0],
        'text': 'Отлично! Могу предложить несколько вариантов',
        'createdAt': FieldValue.serverTimestamp(),
        'isTest': true,
      },
    ];

    for (final message in messages) {
      await firestore
          .collection('chats')
          .doc(chat['id']! as String)
          .collection('messages')
          .doc(message['id'] as String)
          .set(message);
    }
  }

  print('✅ Добавлено ${chats.length} чатов с сообщениями');
}

/// Добавление идей
Future<void> _addIdeas(FirebaseFirestore firestore) async {
  final ideas = [
    {
      'id': 'idea_1',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/400?random=21',
      'title': 'Фотозона в цветах',
      'description':
          'Отличный вариант для летнего мероприятия 🌸 Создайте атмосферу романтики с помощью живых цветов.',
      'likesCount': 12,
      'commentsCount': 4,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'idea_2',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/400?random=22',
      'title': 'Свадебная арка из веток',
      'description':
          'Эко-стиль в тренде! Арка из натуральных веток создаст неповторимую атмосферу 🌿',
      'likesCount': 28,
      'commentsCount': 8,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'idea_3',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/400?random=23',
      'title': 'Детский квест-праздник',
      'description':
          'Интерактивный день рождения с поиском сокровищ! Дети будут в восторге 🏴‍☠️',
      'likesCount': 35,
      'commentsCount': 12,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'idea_4',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/400?random=24',
      'title': 'Корпоратив в стиле 80-х',
      'description': 'Ретро-вечеринка с диско-музыкой и яркими костюмами! 🕺💃',
      'likesCount': 19,
      'commentsCount': 6,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'idea_5',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/400?random=25',
      'title': 'Фотосессия в тумане',
      'description':
          'Мистическая атмосфера для необычных кадров. Туман создает магический эффект 🌫️',
      'likesCount': 42,
      'commentsCount': 15,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'idea_6',
      'authorId': 'user_5',
      'imageUrl': 'https://picsum.photos/400/400?random=26',
      'title': 'Пикник на природе',
      'description':
          'Семейный отдых с играми и барбекю. Идеально для теплых дней 🍖',
      'likesCount': 24,
      'commentsCount': 7,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'idea_7',
      'authorId': 'user_3',
      'imageUrl': 'https://picsum.photos/400/400?random=27',
      'title': 'Новогодняя магия',
      'description':
          'Волшебная атмосфера с огнями и снегом. Создайте настоящую зимнюю сказку ❄️',
      'likesCount': 31,
      'commentsCount': 9,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
    {
      'id': 'idea_8',
      'authorId': 'user_1',
      'imageUrl': 'https://picsum.photos/400/400?random=28',
      'title': 'Студийная портретная съемка',
      'description':
          'Профессиональные портреты в студии. Идеально для деловых фото 📸',
      'likesCount': 16,
      'commentsCount': 3,
      'createdAt': FieldValue.serverTimestamp(),
      'isTest': true,
    },
  ];

  for (final idea in ideas) {
    await firestore.collection('ideas').doc(idea['id']! as String).set(idea);
  }

  print('✅ Добавлено ${ideas.length} идей');
}
