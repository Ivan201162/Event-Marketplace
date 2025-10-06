import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TestDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Тестовые специалисты
  final List<Map<String, dynamic>> _testSpecialists = [
    {
      'id': 'specialist_1',
      'userId': 'user_1',
      'name': 'Алексей Смирнов',
      'category': 'host',
      'city': 'Москва',
      'rating': 4.8,
      'priceRange': 'от 30 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=1',
      'description':
          'Опыт более 7 лет. Веду свадьбы и корпоративы с душой. Создаю незабываемую атмосферу для вашего праздника.',
      'about':
          'Опыт более 7 лет. Веду свадьбы и корпоративы с душой. Создаю незабываемую атмосферу для вашего праздника.',
      'availableDates': ['2025-10-10', '2025-10-17', '2025-10-24'],
      'portfolioImages': [
        'https://picsum.photos/400?random=11',
        'https://picsum.photos/400?random=12',
        'https://picsum.photos/400?random=13',
      ],
      'phone': '+7 (999) 123-45-67',
      'email': 'alexey.smirnov@example.com',
      'hourlyRate': 30000.0,
      'price': 30000.0,
      'yearsOfExperience': 7,
      'experienceLevel': 'intermediate',
      'reviewCount': 45,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 365)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_2',
      'userId': 'user_2',
      'name': 'Анна Лебедева',
      'category': 'photographer',
      'city': 'Санкт-Петербург',
      'rating': 4.9,
      'priceRange': 'от 25 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=2',
      'description':
          'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
      'about':
          'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
      'availableDates': ['2025-10-12', '2025-10-19', '2025-10-26'],
      'portfolioImages': [
        'https://picsum.photos/400?random=21',
        'https://picsum.photos/400?random=22',
        'https://picsum.photos/400?random=23',
      ],
      'phone': '+7 (999) 234-56-78',
      'email': 'anna.lebedeva@example.com',
      'hourlyRate': 25000.0,
      'price': 25000.0,
      'yearsOfExperience': 5,
      'experienceLevel': 'intermediate',
      'reviewCount': 32,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 200)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_3',
      'userId': 'user_3',
      'name': 'Дмитрий Козлов',
      'category': 'dj',
      'city': 'Москва',
      'rating': 4.7,
      'priceRange': 'от 20 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=3',
      'description':
          'DJ с 8-летним стажем. Играю на свадьбах, корпоративах и частных вечеринках. Современное оборудование.',
      'about':
          'DJ с 8-летним стажем. Играю на свадьбах, корпоративах и частных вечеринках. Современное оборудование.',
      'availableDates': ['2025-10-11', '2025-10-18', '2025-10-25'],
      'portfolioImages': [
        'https://picsum.photos/400?random=31',
        'https://picsum.photos/400?random=32',
        'https://picsum.photos/400?random=33',
      ],
      'phone': '+7 (999) 345-67-89',
      'email': 'dmitry.kozlov@example.com',
      'hourlyRate': 20000.0,
      'price': 20000.0,
      'yearsOfExperience': 8,
      'experienceLevel': 'advanced',
      'reviewCount': 28,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 300)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_4',
      'userId': 'user_4',
      'name': 'Елена Петрова',
      'category': 'videographer',
      'city': 'Москва',
      'rating': 4.6,
      'priceRange': 'от 35 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=4',
      'description':
          'Видеограф с профессиональным оборудованием. Создаю красивые свадебные фильмы и корпоративные ролики.',
      'about':
          'Видеограф с профессиональным оборудованием. Создаю красивые свадебные фильмы и корпоративные ролики.',
      'availableDates': ['2025-10-13', '2025-10-20', '2025-10-27'],
      'portfolioImages': [
        'https://picsum.photos/400?random=41',
        'https://picsum.photos/400?random=42',
        'https://picsum.photos/400?random=43',
      ],
      'phone': '+7 (999) 456-78-90',
      'email': 'elena.petrova@example.com',
      'hourlyRate': 35000.0,
      'price': 35000.0,
      'yearsOfExperience': 6,
      'experienceLevel': 'intermediate',
      'reviewCount': 24,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 180)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_5',
      'userId': 'user_5',
      'name': 'Михаил Волков',
      'category': 'decorator',
      'city': 'Санкт-Петербург',
      'rating': 4.8,
      'priceRange': 'от 15 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=5',
      'description':
          'Декоратор с 6-летним опытом. Создаю уникальные интерьеры для любых мероприятий.',
      'about':
          'Декоратор с 6-летним опытом. Создаю уникальные интерьеры для любых мероприятий.',
      'availableDates': ['2025-10-14', '2025-10-21', '2025-10-28'],
      'portfolioImages': [
        'https://picsum.photos/400?random=51',
        'https://picsum.photos/400?random=52',
        'https://picsum.photos/400?random=53',
      ],
      'phone': '+7 (999) 567-89-01',
      'email': 'mikhail.volkov@example.com',
      'hourlyRate': 15000.0,
      'price': 15000.0,
      'yearsOfExperience': 6,
      'experienceLevel': 'intermediate',
      'reviewCount': 36,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 220)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_6',
      'userId': 'user_6',
      'name': 'Ольга Морозова',
      'category': 'host',
      'city': 'Москва',
      'rating': 4.9,
      'priceRange': 'от 40 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=6',
      'description':
          'Event-менеджер с 10-летним опытом. Организую мероприятия любой сложности от А до Я.',
      'about':
          'Event-менеджер с 10-летним опытом. Организую мероприятия любой сложности от А до Я.',
      'availableDates': ['2025-10-15', '2025-10-22', '2025-10-29'],
      'portfolioImages': [
        'https://picsum.photos/400?random=61',
        'https://picsum.photos/400?random=62',
        'https://picsum.photos/400?random=63',
      ],
      'phone': '+7 (999) 678-90-12',
      'email': 'olga.morozova@example.com',
      'hourlyRate': 40000.0,
      'price': 40000.0,
      'yearsOfExperience': 10,
      'experienceLevel': 'expert',
      'reviewCount': 52,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 400)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_7',
      'userId': 'user_7',
      'name': 'Сергей Новиков',
      'category': 'musician',
      'city': 'Москва',
      'rating': 4.7,
      'priceRange': 'от 25 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=7',
      'description':
          'Гитарист и вокалист. Играю на свадьбах и корпоративах. Репертуар от классики до современной музыки.',
      'about':
          'Гитарист и вокалист. Играю на свадьбах и корпоративах. Репертуар от классики до современной музыки.',
      'availableDates': ['2025-10-16', '2025-10-23', '2025-10-30'],
      'portfolioImages': [
        'https://picsum.photos/400?random=71',
        'https://picsum.photos/400?random=72',
        'https://picsum.photos/400?random=73',
      ],
      'phone': '+7 (999) 789-01-23',
      'email': 'sergey.novikov@example.com',
      'hourlyRate': 25000.0,
      'price': 25000.0,
      'yearsOfExperience': 9,
      'experienceLevel': 'advanced',
      'reviewCount': 31,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 350)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_8',
      'userId': 'user_8',
      'name': 'Татьяна Соколова',
      'category': 'florist',
      'city': 'Санкт-Петербург',
      'rating': 4.8,
      'priceRange': 'от 12 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=8',
      'description':
          'Флорист-декоратор с 4-летним опытом. Создаю уникальные цветочные композиции для любых событий.',
      'about':
          'Флорист-декоратор с 4-летним опытом. Создаю уникальные цветочные композиции для любых событий.',
      'availableDates': ['2025-10-17', '2025-10-24', '2025-10-31'],
      'portfolioImages': [
        'https://picsum.photos/400?random=81',
        'https://picsum.photos/400?random=82',
        'https://picsum.photos/400?random=83',
      ],
      'phone': '+7 (999) 890-12-34',
      'email': 'tatyana.sokolova@example.com',
      'hourlyRate': 12000.0,
      'price': 12000.0,
      'yearsOfExperience': 4,
      'experienceLevel': 'intermediate',
      'reviewCount': 19,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 150)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_9',
      'userId': 'user_9',
      'name': 'Андрей Федоров',
      'category': 'caterer',
      'city': 'Москва',
      'rating': 4.6,
      'priceRange': 'от 50 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=9',
      'description':
          'Шеф-повар с 12-летним опытом. Организую кейтеринг для мероприятий любого масштаба.',
      'about':
          'Шеф-повар с 12-летним опытом. Организую кейтеринг для мероприятий любого масштаба.',
      'availableDates': ['2025-10-18', '2025-10-25', '2025-11-01'],
      'portfolioImages': [
        'https://picsum.photos/400?random=91',
        'https://picsum.photos/400?random=92',
        'https://picsum.photos/400?random=93',
      ],
      'phone': '+7 (999) 901-23-45',
      'email': 'andrey.fedorov@example.com',
      'hourlyRate': 50000.0,
      'price': 50000.0,
      'yearsOfExperience': 12,
      'experienceLevel': 'expert',
      'reviewCount': 67,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 500)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_10',
      'userId': 'user_10',
      'name': 'Мария Кузнецова',
      'category': 'makeup',
      'city': 'Москва',
      'rating': 4.9,
      'priceRange': 'от 18 000 ₽',
      'avatarUrl': 'https://picsum.photos/200?random=10',
      'description':
          'Визажист и стилист с 6-летним опытом. Специализируюсь на свадебных образах и макияже.',
      'about':
          'Визажист и стилист с 6-летним опытом. Специализируюсь на свадебных образах и макияже.',
      'availableDates': ['2025-10-19', '2025-10-26', '2025-11-02'],
      'portfolioImages': [
        'https://picsum.photos/400?random=101',
        'https://picsum.photos/400?random=102',
        'https://picsum.photos/400?random=103',
      ],
      'phone': '+7 (999) 012-34-56',
      'email': 'maria.kuznetsova@example.com',
      'hourlyRate': 18000.0,
      'price': 18000.0,
      'yearsOfExperience': 6,
      'experienceLevel': 'intermediate',
      'reviewCount': 43,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 250)),
      'updatedAt': DateTime.now(),
    },
  ];

  // Тестовые чаты
  final List<Map<String, dynamic>> _testChats = [
    {
      'specialistId': 'specialist_1',
      'specialistName': 'Алексей Смирнов',
      'customerId': 'customer_1',
      'customerName': 'Ольга Иванова',
      'messages': [
        {
          'senderId': 'customer_1',
          'senderName': 'Ольга Иванова',
          'content': 'Здравствуйте! Интересует свадьба 10 октября?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_1',
          'senderName': 'Алексей Смирнов',
          'content':
              'Добро пожаловать! Да, 10 октября свободен. Расскажите подробнее о мероприятии.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_1',
          'senderName': 'Ольга Иванова',
          'content':
              'Свадьба на 80 человек в загородном клубе. Нужен ведущий на 6 часов.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_1',
          'senderName': 'Алексей Смирнов',
          'content':
              'Отлично! Мой тариф 30 000 ₽ за 6 часов. Включает сценарий, игры и конкурсы.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
          'type': 'text',
        },
        {
          'senderId': 'customer_1',
          'senderName': 'Ольга Иванова',
          'content': 'Подходит! Можем встретиться для обсуждения деталей?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_2',
      'specialistName': 'Анна Лебедева',
      'customerId': 'customer_2',
      'customerName': 'Игорь Петров',
      'messages': [
        {
          'senderId': 'customer_2',
          'senderName': 'Игорь Петров',
          'content': 'Привет! Нужна фотосессия для корпоратива.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_2',
          'senderName': 'Анна Лебедева',
          'content': 'Здравствуйте! Когда планируется мероприятие?',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_2',
          'senderName': 'Игорь Петров',
          'content': '12 октября, в офисе на 50 человек.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_2',
          'senderName': 'Анна Лебедева',
          'content':
              'Понятно! Мой тариф 25 000 ₽ за 4 часа съемки + обработка всех фото.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_3',
      'specialistName': 'Дмитрий Козлов',
      'customerId': 'customer_3',
      'customerName': 'Мария Сидорова',
      'messages': [
        {
          'senderId': 'customer_3',
          'senderName': 'Мария Сидорова',
          'content': 'Привет! Нужен DJ на свадьбу 11 октября.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_3',
          'senderName': 'Дмитрий Козлов',
          'content':
              'Здравствуйте! 11 октября свободен. Расскажите о мероприятии.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_3',
          'senderName': 'Мария Сидорова',
          'content': 'Свадьба на 120 человек в ресторане. Нужно на 6 часов.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_3',
          'senderName': 'Дмитрий Козлов',
          'content':
              'Отлично! Мой тариф 20 000 ₽ за 6 часов. Включает оборудование и музыку.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_4',
      'specialistName': 'Елена Петрова',
      'customerId': 'customer_4',
      'customerName': 'Александр Козлов',
      'messages': [
        {
          'senderId': 'customer_4',
          'senderName': 'Александр Козлов',
          'content': 'Добрый день! Нужна видеосъемка корпоратива.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_4',
          'senderName': 'Елена Петрова',
          'content': 'Здравствуйте! Когда планируется мероприятие?',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 4, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_4',
          'senderName': 'Александр Козлов',
          'content': '13 октября, в конференц-зале на 80 человек.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_4',
          'senderName': 'Елена Петрова',
          'content':
              'Понятно! Мой тариф 35 000 ₽ за 4 часа съемки + монтаж ролика.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_5',
      'specialistName': 'Михаил Волков',
      'customerId': 'customer_5',
      'customerName': 'Екатерина Морозова',
      'messages': [
        {
          'senderId': 'customer_5',
          'senderName': 'Екатерина Морозова',
          'content': 'Привет! Нужно оформить свадьбу в стиле прованс.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_5',
          'senderName': 'Михаил Волков',
          'content': 'Здравствуйте! Отличный выбор стиля! Когда мероприятие?',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 5, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_5',
          'senderName': 'Екатерина Морозова',
          'content':
              '14 октября, в загородном клубе. Нужно оформить зал и фотозону.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_5',
          'senderName': 'Михаил Волков',
          'content':
              'Понятно! Мой тариф 15 000 ₽ за полное оформление в стиле прованс.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 5, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_6',
      'specialistName': 'Ольга Морозова',
      'customerId': 'customer_6',
      'customerName': 'Дмитрий Соколов',
      'messages': [
        {
          'senderId': 'customer_6',
          'senderName': 'Дмитрий Соколов',
          'content': 'Добрый день! Нужна организация детского дня рождения.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 7)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_6',
          'senderName': 'Ольга Морозова',
          'content':
              'Здравствуйте! С удовольствием помогу! Расскажите подробнее.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 6, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_6',
          'senderName': 'Дмитрий Соколов',
          'content':
              '15 октября, для 20 детей 5-7 лет. Тема: пиратская вечеринка.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 6, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_6',
          'senderName': 'Ольга Морозова',
          'content':
              'Отлично! Мой тариф 40 000 ₽ за полную организацию пиратской вечеринки.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 6, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_7',
      'specialistName': 'Сергей Новиков',
      'customerId': 'customer_7',
      'customerName': 'Анна Федорова',
      'messages': [
        {
          'senderId': 'customer_7',
          'senderName': 'Анна Федорова',
          'content': 'Привет! Нужен музыкант на романтический ужин.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_7',
          'senderName': 'Сергей Новиков',
          'content': 'Здравствуйте! Какой репертуар предпочитаете?',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 7, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_7',
          'senderName': 'Анна Федорова',
          'content': '16 октября, романтические баллады и джаз. 2 часа.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 7, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_7',
          'senderName': 'Сергей Новиков',
          'content':
              'Понятно! Мой тариф 25 000 ₽ за 2 часа романтической музыки.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 7, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_8',
      'specialistName': 'Татьяна Соколова',
      'customerId': 'customer_8',
      'customerName': 'Игорь Лебедев',
      'messages': [
        {
          'senderId': 'customer_8',
          'senderName': 'Игорь Лебедев',
          'content': 'Добрый день! Нужны цветы для свадебной церемонии.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_8',
          'senderName': 'Татьяна Соколова',
          'content': 'Здравствуйте! Какой стиль и цветовая гамма?',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 8, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_8',
          'senderName': 'Игорь Лебедев',
          'content': '17 октября, белые и розовые розы, классический стиль.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 8, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_8',
          'senderName': 'Татьяна Соколова',
          'content':
              'Отлично! Мой тариф 12 000 ₽ за полное цветочное оформление.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 8, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_9',
      'specialistName': 'Андрей Федоров',
      'customerId': 'customer_9',
      'customerName': 'Наталья Козлова',
      'messages': [
        {
          'senderId': 'customer_9',
          'senderName': 'Наталья Козлова',
          'content': 'Привет! Нужен кейтеринг для корпоратива.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 10)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_9',
          'senderName': 'Андрей Федоров',
          'content':
              'Здравствуйте! Сколько человек и какие предпочтения по меню?',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 9, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_9',
          'senderName': 'Наталья Козлова',
          'content': '18 октября, 100 человек, европейская кухня, фуршет.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 9, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_9',
          'senderName': 'Андрей Федоров',
          'content': 'Понятно! Мой тариф 50 000 ₽ за фуршет на 100 человек.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 9, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_10',
      'specialistName': 'Мария Кузнецова',
      'customerId': 'customer_10',
      'customerName': 'Владимир Петров',
      'messages': [
        {
          'senderId': 'customer_10',
          'senderName': 'Владимир Петров',
          'content': 'Добрый день! Нужен макияж для невесты.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 11)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_10',
          'senderName': 'Мария Кузнецова',
          'content': 'Здравствуйте! Какой стиль макияжа предпочитаете?',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 10, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_10',
          'senderName': 'Владимир Петров',
          'content': '19 октября, натуральный макияж для свадьбы.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 10, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_10',
          'senderName': 'Мария Кузнецова',
          'content': 'Отлично! Мой тариф 18 000 ₽ за свадебный макияж.',
          'timestamp':
              DateTime.now().subtract(const Duration(hours: 10, minutes: 15)),
          'type': 'text',
        },
      ],
    },
  ];

  // Тестовые заявки
  final List<Map<String, dynamic>> _testBookings = [
    {
      'eventName': 'Свадьба Ольги и Игоря',
      'date': '2025-10-15',
      'budget': 80000,
      'specialistId': 'specialist_1',
      'specialistName': 'Алексей Смирнов',
      'customerId': 'customer_1',
      'customerName': 'Ольга Иванова',
      'status': 'Ожидает подтверждения',
      'description':
          'Свадьба на 80 человек в загородном клубе. Нужен ведущий на 6 часов.',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'eventName': 'Корпоратив IT-компании',
      'date': '2025-10-12',
      'budget': 50000,
      'specialistId': 'specialist_2',
      'specialistName': 'Анна Лебедева',
      'customerId': 'customer_2',
      'customerName': 'Игорь Петров',
      'status': 'Подтверждено',
      'description': 'Корпоративное мероприятие в офисе на 50 человек.',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'eventName': 'Свадьба Марии и Дмитрия',
      'date': '2025-10-11',
      'budget': 60000,
      'specialistId': 'specialist_3',
      'specialistName': 'Дмитрий Козлов',
      'customerId': 'customer_3',
      'customerName': 'Мария Сидорова',
      'status': 'Подтверждено',
      'description': 'Свадьба на 120 человек в ресторане. Нужен DJ на 6 часов.',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'eventName': 'Корпоратив IT-компании',
      'date': '2025-10-13',
      'budget': 70000,
      'specialistId': 'specialist_4',
      'specialistName': 'Елена Петрова',
      'customerId': 'customer_4',
      'customerName': 'Александр Козлов',
      'status': 'Ожидает подтверждения',
      'description':
          'Корпоративное мероприятие в конференц-зале на 80 человек.',
      'createdAt': DateTime.now().subtract(const Duration(days: 4)),
    },
    {
      'eventName': 'Свадьба в стиле прованс',
      'date': '2025-10-14',
      'budget': 45000,
      'specialistId': 'specialist_5',
      'specialistName': 'Михаил Волков',
      'customerId': 'customer_5',
      'customerName': 'Екатерина Морозова',
      'status': 'Подтверждено',
      'description':
          'Свадьба в загородном клубе. Нужно оформить зал и фотозону в стиле прованс.',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'eventName': 'Пиратская вечеринка',
      'date': '2025-10-15',
      'budget': 80000,
      'specialistId': 'specialist_6',
      'specialistName': 'Ольга Морозова',
      'customerId': 'customer_6',
      'customerName': 'Дмитрий Соколов',
      'status': 'Ожидает подтверждения',
      'description':
          'Детский день рождения для 20 детей 5-7 лет. Тема: пиратская вечеринка.',
      'createdAt': DateTime.now().subtract(const Duration(days: 6)),
    },
    {
      'eventName': 'Романтический ужин',
      'date': '2025-10-16',
      'budget': 50000,
      'specialistId': 'specialist_7',
      'specialistName': 'Сергей Новиков',
      'customerId': 'customer_7',
      'customerName': 'Анна Федорова',
      'status': 'Подтверждено',
      'description':
          'Романтический ужин с живой музыкой. Романтические баллады и джаз на 2 часа.',
      'createdAt': DateTime.now().subtract(const Duration(days: 7)),
    },
    {
      'eventName': 'Свадебная церемония',
      'date': '2025-10-17',
      'budget': 30000,
      'specialistId': 'specialist_8',
      'specialistName': 'Татьяна Соколова',
      'customerId': 'customer_8',
      'customerName': 'Игорь Лебедев',
      'status': 'Ожидает подтверждения',
      'description':
          'Цветочное оформление свадебной церемонии. Белые и розовые розы, классический стиль.',
      'createdAt': DateTime.now().subtract(const Duration(days: 8)),
    },
    {
      'eventName': 'Корпоративный фуршет',
      'date': '2025-10-18',
      'budget': 100000,
      'specialistId': 'specialist_9',
      'specialistName': 'Андрей Федоров',
      'customerId': 'customer_9',
      'customerName': 'Наталья Козлова',
      'status': 'Подтверждено',
      'description': 'Корпоративный фуршет на 100 человек. Европейская кухня.',
      'createdAt': DateTime.now().subtract(const Duration(days: 9)),
    },
    {
      'eventName': 'Свадебный макияж',
      'date': '2025-10-19',
      'budget': 36000,
      'specialistId': 'specialist_10',
      'specialistName': 'Мария Кузнецова',
      'customerId': 'customer_10',
      'customerName': 'Владимир Петров',
      'status': 'Ожидает подтверждения',
      'description': 'Свадебный макияж для невесты. Натуральный стиль.',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
    },
  ];

  // Тестовые посты
  final List<Map<String, dynamic>> _testPosts = [
    {
      'authorId': 'specialist_2',
      'authorName': 'Анна Лебедева',
      'authorAvatar': 'https://picsum.photos/200?random=2',
      'imageUrl': 'https://picsum.photos/400?random=30',
      'caption': 'Праздник на берегу моря 🌊 Фотосессия для молодоженов в Сочи',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'likes': 24,
      'comments': 5,
    },
    {
      'authorId': 'specialist_1',
      'authorName': 'Алексей Смирнов',
      'authorAvatar': 'https://picsum.photos/200?random=1',
      'imageUrl': 'https://picsum.photos/400?random=31',
      'caption': 'Свадьба в стиле "Великий Гэтсби" ✨ Незабываемый вечер!',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'likes': 18,
      'comments': 3,
    },
    {
      'authorId': 'specialist_3',
      'authorName': 'Дмитрий Козлов',
      'authorAvatar': 'https://picsum.photos/200?random=3',
      'imageUrl': 'https://picsum.photos/400?random=32',
      'caption':
          'Отличная свадьба вчера! 🎵 Музыка играла всю ночь, гости танцевали до утра!',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'likes': 31,
      'comments': 7,
    },
    {
      'authorId': 'specialist_4',
      'authorName': 'Елена Петрова',
      'authorAvatar': 'https://picsum.photos/200?random=4',
      'imageUrl': 'https://picsum.photos/400?random=33',
      'caption':
          'Корпоративная видеосъемка 📹 Создаем крутой ролик для компании!',
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
      'likes': 19,
      'comments': 4,
    },
    {
      'authorId': 'specialist_5',
      'authorName': 'Михаил Волков',
      'authorAvatar': 'https://picsum.photos/200?random=5',
      'imageUrl': 'https://picsum.photos/400?random=34',
      'caption':
          'Свадьба в стиле прованс 🌸 Французская романтика в каждом элементе!',
      'timestamp': DateTime.now().subtract(const Duration(days: 5)),
      'likes': 42,
      'comments': 9,
    },
    {
      'authorId': 'specialist_6',
      'authorName': 'Ольга Морозова',
      'authorAvatar': 'https://picsum.photos/200?random=6',
      'imageUrl': 'https://picsum.photos/400?random=35',
      'caption':
          'Пиратская вечеринка для детей 🏴‍☠️ Дети были в восторге от приключений!',
      'timestamp': DateTime.now().subtract(const Duration(days: 6)),
      'likes': 28,
      'comments': 6,
    },
    {
      'authorId': 'specialist_7',
      'authorName': 'Сергей Новиков',
      'authorAvatar': 'https://picsum.photos/200?random=7',
      'imageUrl': 'https://picsum.photos/400?random=36',
      'caption':
          'Романтический вечер 🎸 Джаз и баллады создали незабываемую атмосферу!',
      'timestamp': DateTime.now().subtract(const Duration(days: 7)),
      'likes': 35,
      'comments': 8,
    },
    {
      'authorId': 'specialist_8',
      'authorName': 'Татьяна Соколова',
      'authorAvatar': 'https://picsum.photos/200?random=8',
      'imageUrl': 'https://picsum.photos/400?random=37',
      'caption':
          'Цветочное оформление свадьбы 🌹 Белые и розовые розы - классика жанра!',
      'timestamp': DateTime.now().subtract(const Duration(days: 8)),
      'likes': 26,
      'comments': 5,
    },
    {
      'authorId': 'specialist_9',
      'authorName': 'Андрей Федоров',
      'authorAvatar': 'https://picsum.photos/200?random=9',
      'imageUrl': 'https://picsum.photos/400?random=38',
      'caption': 'Корпоративный фуршет 🍽️ Европейская кухня на высшем уровне!',
      'timestamp': DateTime.now().subtract(const Duration(days: 9)),
      'likes': 33,
      'comments': 7,
    },
    {
      'authorId': 'specialist_10',
      'authorName': 'Мария Кузнецова',
      'authorAvatar': 'https://picsum.photos/200?random=10',
      'imageUrl': 'https://picsum.photos/400?random=39',
      'caption':
          'Свадебный макияж 💄 Натуральная красота - лучший выбор для невесты!',
      'timestamp': DateTime.now().subtract(const Duration(days: 10)),
      'likes': 29,
      'comments': 6,
    },
  ];

  /// Заполнить все тестовые данные
  Future<void> populateAll() async {
    try {
      print('Начинаем заполнение тестовых данных...');

      await _populateSpecialists();
      await _populateChats();
      await _populateBookings();
      await _populatePosts();

      print('Тестовые данные успешно добавлены!');
    } catch (e) {
      print('Ошибка при заполнении тестовых данных: $e');
    }
  }

  /// Заполнить специалистов
  Future<void> _populateSpecialists() async {
    for (var i = 0; i < _testSpecialists.length; i++) {
      final specialist = _testSpecialists[i];
      await _firestore
          .collection('specialists')
          .doc('specialist_${i + 1}')
          .set({
        ...specialist,
        'id': 'specialist_${i + 1}',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    print('Добавлено ${_testSpecialists.length} специалистов');
  }

  /// Заполнить чаты
  Future<void> _populateChats() async {
    for (var i = 0; i < _testChats.length; i++) {
      final chat = _testChats[i];
      final chatId = 'chat_${i + 1}';

      // Создаем чат
      await _firestore.collection('chats').doc(chatId).set({
        'id': chatId,
        'specialistId': chat['specialistId'],
        'specialistName': chat['specialistName'],
        'customerId': chat['customerId'],
        'customerName': chat['customerName'],
        'lastMessage': chat['messages'].last['content'],
        'lastMessageAt': chat['messages'].last['timestamp'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Добавляем сообщения
      for (var j = 0; j < chat['messages'].length; j++) {
        final message = chat['messages'][j];
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': message['senderId'],
          'senderName': message['senderName'],
          'content': message['content'],
          'type': message['type'],
          'timestamp': message['timestamp'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    print('Добавлено ${_testChats.length} чатов');
  }

  /// Заполнить заявки
  Future<void> _populateBookings() async {
    for (var i = 0; i < _testBookings.length; i++) {
      final booking = _testBookings[i];
      await _firestore.collection('bookings').add({
        ...booking,
        'createdAt': booking['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    print('Добавлено ${_testBookings.length} заявок');
  }

  /// Заполнить посты
  Future<void> _populatePosts() async {
    for (var i = 0; i < _testPosts.length; i++) {
      final post = _testPosts[i];
      await _firestore.collection('posts').add({
        ...post,
        'createdAt': post['timestamp'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    print('Добавлено ${_testPosts.length} постов');
  }

  /// Получить список специалистов
  List<Map<String, dynamic>> getSpecialists() => _testSpecialists;

  /// Создать тестовых специалистов (для совместимости)
  Future<void> createTestSpecialists() async {
    await _populateSpecialists();
  }

  /// Очистить все тестовые данные
  Future<void> clearAllTestData() async {
    try {
      // Удаляем все коллекции
      final collections = ['specialists', 'chats', 'bookings', 'posts'];
      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
      print('Все тестовые данные удалены');
    } catch (e) {
      print('Ошибка при удалении тестовых данных: $e');
    }
  }

  /// Проверить, есть ли уже тестовые данные
  Future<bool> hasTestData() async {
    try {
      final specialistsSnapshot =
          await _firestore.collection('specialists').limit(1).get();
      return specialistsSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
