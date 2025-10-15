import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для генерации тестовых данных
class TestDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Генерация всех тестовых данных
  static Future<void> generateAllTestData() async {
    try {
      debugPrint('🚀 Начинаем генерацию тестовых данных...');

      // Очистка существующих данных
      await _clearTestData();

      // Генерация пользователей и специалистов
      await _generateUsersAndSpecialists();

      // Генерация постов ленты
      await _generateFeedPosts();

      // Генерация идей
      await _generateIdeas();

      // Генерация уведомлений
      await _generateNotifications();

      // Генерация чатов
      await _generateChats();

      // Генерация заявок
      await _generateRequests();

      debugPrint('✅ Все тестовые данные успешно сгенерированы!');
    } on Exception catch (e) {
      debugPrint('❌ Ошибка генерации тестовых данных: $e');
    }
  }

  /// Очистка тестовых данных
  static Future<void> _clearTestData() async {
    final collections = [
      'users',
      'specialists',
      'feed',
      'ideas',
      'notifications',
      'chats',
      'requests',
    ];

    for (final collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        debugPrint('🧹 Очищена коллекция: $collection');
      } on Exception catch (e) {
        debugPrint('⚠️ Ошибка очистки коллекции $collection: $e');
      }
    }
  }

  /// Генерация пользователей и специалистов
  static Future<void> _generateUsersAndSpecialists() async {
    final users = [
      {
        'id': 'user_1',
        'name': 'Анна Петрова',
        'email': 'anna@example.com',
        'avatar': 'https://picsum.photos/200/200?random=1',
        'city': 'Москва',
        'isSpecialist': true,
        'category': 'Фотограф',
        'rating': 4.8,
        'pricePerHour': 2500,
        'description':
            'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
      },
      {
        'id': 'user_2',
        'name': 'Михаил Соколов',
        'email': 'mikhail@example.com',
        'avatar': 'https://picsum.photos/200/200?random=2',
        'city': 'Санкт-Петербург',
        'isSpecialist': true,
        'category': 'Видеограф',
        'rating': 4.9,
        'pricePerHour': 3000,
        'description':
            'Креативный видеограф, создаю незабываемые видео для любых событий.',
      },
      {
        'id': 'user_3',
        'name': 'Елена Козлова',
        'email': 'elena@example.com',
        'avatar': 'https://picsum.photos/200/200?random=3',
        'city': 'Москва',
        'isSpecialist': true,
        'category': 'Организатор',
        'rating': 4.7,
        'pricePerHour': 2000,
        'description':
            'Опытный организатор мероприятий. Помогу сделать ваше событие незабываемым!',
      },
      {
        'id': 'user_4',
        'name': 'Дмитрий Волков',
        'email': 'dmitry@example.com',
        'avatar': 'https://picsum.photos/200/200?random=4',
        'city': 'Новосибирск',
        'isSpecialist': true,
        'category': 'Диджей',
        'rating': 4.6,
        'pricePerHour': 1500,
        'description':
            'Профессиональный диджей с отличной музыкальной коллекцией и качественным оборудованием.',
      },
      {
        'id': 'user_5',
        'name': 'Ольга Морозова',
        'email': 'olga@example.com',
        'avatar': 'https://picsum.photos/200/200?random=5',
        'city': 'Екатеринбург',
        'isSpecialist': true,
        'category': 'Декоратор',
        'rating': 4.8,
        'pricePerHour': 1800,
        'description':
            'Талантливый декоратор, создаю уникальные интерьеры для ваших мероприятий.',
      },
    ];

    for (final userData in users) {
      await _firestore.collection('users').doc(userData['id']! as String).set({
        'name': userData['name'],
        'email': userData['email'],
        'avatar': userData['avatar'],
        'city': userData['city'],
        'isSpecialist': userData['isSpecialist'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (userData['isSpecialist'] == true) {
        await _firestore
            .collection('specialists')
            .doc(userData['id']! as String)
            .set({
          'name': userData['name'],
          'email': userData['email'],
          'imageUrl': userData['avatar'],
          'city': userData['city'],
          'category': userData['category'],
          'rating': userData['rating'],
          'pricePerHour': userData['pricePerHour'],
          'description': userData['description'],
          'isVerified': true,
          'reviewCount': 25,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    debugPrint('👥 Создано ${users.length} пользователей и специалистов');
  }

  /// Генерация постов ленты
  static Future<void> _generateFeedPosts() async {
    final posts = [
      {
        'authorId': 'user_1',
        'authorName': 'Анна Петрова',
        'authorAvatar': 'https://picsum.photos/200/200?random=1',
        'description':
            'Красивая свадебная фотосессия в парке 🌸 #свадьба #фотограф #любовь',
        'imageUrl': 'https://picsum.photos/400/400?random=10',
        'location': 'Москва',
        'likeCount': 45,
        'commentCount': 8,
      },
      {
        'authorId': 'user_2',
        'authorName': 'Михаил Соколов',
        'authorAvatar': 'https://picsum.photos/200/200?random=2',
        'description':
            'Новый клип готов! Спасибо за доверие 🎬 #видеограф #клип #творчество',
        'imageUrl': 'https://picsum.photos/400/400?random=11',
        'location': 'Санкт-Петербург',
        'likeCount': 32,
        'commentCount': 5,
      },
      {
        'authorId': 'user_3',
        'authorName': 'Елена Козлова',
        'authorAvatar': 'https://picsum.photos/200/200?random=3',
        'description':
            'Организовала корпоратив на 100 человек. Все прошло идеально! 🎉 #корпоратив #организатор',
        'imageUrl': 'https://picsum.photos/400/400?random=12',
        'location': 'Москва',
        'likeCount': 28,
        'commentCount': 3,
      },
      {
        'authorId': 'user_4',
        'authorName': 'Дмитрий Волков',
        'authorAvatar': 'https://picsum.photos/200/200?random=4',
        'description':
            'Отличная вечеринка! Музыка была на высоте 🎵 #диджей #вечеринка #музыка',
        'imageUrl': 'https://picsum.photos/400/400?random=13',
        'location': 'Новосибирск',
        'likeCount': 19,
        'commentCount': 2,
      },
      {
        'authorId': 'user_5',
        'authorName': 'Ольга Морозова',
        'authorAvatar': 'https://picsum.photos/200/200?random=5',
        'description':
            'Декор для детского дня рождения готов! 🎈 #декор #деньрождения #дети',
        'imageUrl': 'https://picsum.photos/400/400?random=14',
        'location': 'Екатеринбург',
        'likeCount': 36,
        'commentCount': 7,
      },
    ];

    for (final postData in posts) {
      await _firestore.collection('feed').add({
        'authorId': postData['authorId'],
        'authorName': postData['authorName'],
        'authorAvatar': postData['authorAvatar'],
        'description': postData['description'],
        'imageUrl': postData['imageUrl'],
        'location': postData['location'],
        'likeCount': postData['likeCount'],
        'commentCount': postData['commentCount'],
        'isLiked': false,
        'isSaved': false,
        'isFollowing': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('📱 Создано ${posts.length} постов в ленте');
  }

  /// Генерация идей
  static Future<void> _generateIdeas() async {
    final ideas = [
      {
        'title': 'Свадебная фотосессия в стиле ретро',
        'description':
            'Идея для создания атмосферных фотографий в винтажном стиле с использованием старинных автомобилей и костюмов.',
        'imageUrl': 'https://picsum.photos/300/400?random=20',
        'authorId': 'user_1',
        'authorName': 'Анна Петрова',
        'authorAvatar': 'https://picsum.photos/200/200?random=1',
        'likeCount': 15,
        'commentCount': 3,
      },
      {
        'title': 'Корпоратив в стиле 80-х',
        'description':
            'Организация тематического корпоратива с музыкой, костюмами и декором в стиле диско.',
        'imageUrl': 'https://picsum.photos/300/400?random=21',
        'authorId': 'user_3',
        'authorName': 'Елена Козлова',
        'authorAvatar': 'https://picsum.photos/200/200?random=3',
        'likeCount': 22,
        'commentCount': 5,
      },
      {
        'title': 'Детский день рождения с клоунами',
        'description':
            'Веселая программа с аниматорами, клоунами и конкурсами для детей от 5 до 10 лет.',
        'imageUrl': 'https://picsum.photos/300/400?random=22',
        'authorId': 'user_5',
        'authorName': 'Ольга Морозова',
        'authorAvatar': 'https://picsum.photos/200/200?random=5',
        'likeCount': 18,
        'commentCount': 4,
      },
      {
        'title': 'Видео-клип в стиле киберпанк',
        'description':
            'Создание футуристического видео с неоновыми эффектами и современной музыкой.',
        'imageUrl': 'https://picsum.photos/300/400?random=23',
        'authorId': 'user_2',
        'authorName': 'Михаил Соколов',
        'authorAvatar': 'https://picsum.photos/200/200?random=2',
        'likeCount': 31,
        'commentCount': 8,
      },
      {
        'title': 'Вечеринка под открытым небом',
        'description':
            'Организация летней вечеринки с живой музыкой, барбекю и танцами под звездами.',
        'imageUrl': 'https://picsum.photos/300/400?random=24',
        'authorId': 'user_4',
        'authorName': 'Дмитрий Волков',
        'authorAvatar': 'https://picsum.photos/200/200?random=4',
        'likeCount': 27,
        'commentCount': 6,
      },
    ];

    for (final ideaData in ideas) {
      await _firestore.collection('ideas').add({
        'title': ideaData['title'],
        'description': ideaData['description'],
        'imageUrl': ideaData['imageUrl'],
        'authorId': ideaData['authorId'],
        'authorName': ideaData['authorName'],
        'authorAvatar': ideaData['authorAvatar'],
        'likeCount': ideaData['likeCount'],
        'commentCount': ideaData['commentCount'],
        'isLiked': false,
        'isSaved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('💡 Создано ${ideas.length} идей');
  }

  /// Генерация уведомлений
  static Future<void> _generateNotifications() async {
    final notifications = [
      {
        'userId': 'user_1',
        'title': 'Новый лайк',
        'body': 'Анна Петрова поставила лайк вашему посту',
        'type': 'like',
        'data': 'post_1',
      },
      {
        'userId': 'user_2',
        'title': 'Новый комментарий',
        'body': 'Михаил Соколов прокомментировал вашу идею',
        'type': 'comment',
        'data': 'idea_1',
      },
      {
        'userId': 'user_3',
        'title': 'Новая подписка',
        'body': 'Елена Козлова подписалась на вас',
        'type': 'follow',
        'data': 'user_3',
      },
      {
        'userId': 'user_4',
        'title': 'Новая заявка',
        'body': 'У вас новая заявка на услуги диджея',
        'type': 'request',
        'data': 'request_1',
      },
      {
        'userId': 'user_5',
        'title': 'Новое сообщение',
        'body': 'Ольга Морозова написала вам сообщение',
        'type': 'message',
        'data': 'chat_1',
      },
    ];

    for (final notificationData in notifications) {
      await _firestore.collection('notifications').add({
        'userId': notificationData['userId'],
        'title': notificationData['title'],
        'body': notificationData['body'],
        'type': notificationData['type'],
        'data': notificationData['data'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('🔔 Создано ${notifications.length} уведомлений');
  }

  /// Генерация чатов
  static Future<void> _generateChats() async {
    final chats = [
      {
        'id': 'chat_1',
        'members': ['user_1', 'user_2'],
        'lastMessage': 'Привет! Когда можем встретиться?',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 2,
      },
      {
        'id': 'chat_2',
        'members': ['user_3', 'user_4'],
        'lastMessage': 'Спасибо за отличную работу!',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      },
    ];

    for (final chatData in chats) {
      await _firestore.collection('chats').doc(chatData['id']! as String).set({
        'members': chatData['members'],
        'lastMessage': chatData['lastMessage'],
        'lastMessageTime': chatData['lastMessageTime'],
        'unreadCount': chatData['unreadCount'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('💬 Создано ${chats.length} чатов');
  }

  /// Генерация заявок
  static Future<void> _generateRequests() async {
    final requests = [
      {
        'customerId': 'user_1',
        'specialistId': 'user_2',
        'title': 'Съемка корпоративного видео',
        'description': 'Нужно снять промо-ролик для компании',
        'status': 'pending',
        'price': 15000,
        'eventDate': FieldValue.serverTimestamp(),
      },
      {
        'customerId': 'user_3',
        'specialistId': 'user_4',
        'title': 'Диджей на свадьбу',
        'description': 'Ищем диджея на свадебное торжество',
        'status': 'accepted',
        'price': 8000,
        'eventDate': FieldValue.serverTimestamp(),
      },
    ];

    for (final requestData in requests) {
      await _firestore.collection('requests').add({
        'customerId': requestData['customerId'],
        'specialistId': requestData['specialistId'],
        'title': requestData['title'],
        'description': requestData['description'],
        'status': requestData['status'],
        'price': requestData['price'],
        'eventDate': requestData['eventDate'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('📋 Создано ${requests.length} заявок');
  }
}
