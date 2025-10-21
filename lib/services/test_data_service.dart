import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../utils/storage_guard.dart';

/// Сервис для создания и управления тестовыми данными в Firestore
class TestDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = getStorage();

  // Константы для батчевых операций
  static const int _batchSize = 500;

  // Тестовые категории
  final List<Map<String, dynamic>> _testCategories = [
    {
      'id': 'category_1',
      'name': 'Ведущие',
      'displayName': 'Ведущие',
      'description': 'Профессиональные ведущие для свадеб, корпоративов и праздников',
      'icon': '🎤',
      'color': '#FF6B6B',
      'subcategories': ['Свадебный ведущий', 'Корпоративный ведущий', 'Детский ведущий'],
      'isActive': true,
      'sortOrder': 1,
    },
    {
      'id': 'category_2',
      'name': 'Фотографы',
      'displayName': 'Фотографы',
      'description': 'Профессиональная фотосъемка для любых мероприятий',
      'icon': '📸',
      'color': '#4ECDC4',
      'subcategories': ['Свадебная фотосъемка', 'Портретная фотосъемка', 'Студийная фотосъемка'],
      'isActive': true,
      'sortOrder': 2,
    },
    {
      'id': 'category_3',
      'name': 'Флористы',
      'displayName': 'Флористы',
      'description': 'Цветочные композиции и декорации для мероприятий',
      'icon': '🌸',
      'color': '#45B7D1',
      'subcategories': ['Свадебная флористика', 'Корпоративная флористика', 'Праздничная флористика'],
      'isActive': true,
      'sortOrder': 3,
    },
    {
      'id': 'category_4',
      'name': 'Музыканты',
      'displayName': 'Музыканты',
      'description': 'Живая музыка для ваших мероприятий',
      'icon': '🎵',
      'color': '#96CEB4',
      'subcategories': ['Свадебная музыка', 'Корпоративная музыка', 'Детская музыка'],
      'isActive': true,
      'sortOrder': 4,
    },
    {
      'id': 'category_5',
      'name': 'Декораторы',
      'displayName': 'Декораторы',
      'description': 'Оформление и декорирование мероприятий',
      'icon': '🎨',
      'color': '#FFEAA7',
      'subcategories': ['Свадебное оформление', 'Корпоративное оформление', 'Детское оформление'],
      'isActive': true,
      'sortOrder': 5,
    },
  ];

  // Тестовые тарифы
  final List<Map<String, dynamic>> _testTariffs = [
    {
      'id': 'tariff_1',
      'name': 'Базовый',
      'description': 'Основные возможности для начинающих специалистов',
      'price': 0.0,
      'currency': 'RUB',
      'duration': 30,
      'features': ['Создание профиля', '5 заявок в месяц', 'Базовая поддержка'],
      'isActive': true,
      'isPopular': false,
      'sortOrder': 1,
    },
    {
      'id': 'tariff_2',
      'name': 'Профессиональный',
      'description': 'Расширенные возможности для опытных специалистов',
      'price': 2990.0,
      'currency': 'RUB',
      'duration': 30,
      'features': ['Неограниченные заявки', 'Приоритет в поиске', 'Расширенная аналитика', 'Премиум поддержка'],
      'isActive': true,
      'isPopular': true,
      'sortOrder': 2,
    },
    {
      'id': 'tariff_3',
      'name': 'Премиум',
      'description': 'Максимальные возможности для топ-специалистов',
      'price': 5990.0,
      'currency': 'RUB',
      'duration': 30,
      'features': ['Все возможности Профессионального', 'Персональный менеджер', 'VIP поддержка', 'Эксклюзивные возможности'],
      'isActive': true,
      'isPopular': false,
      'sortOrder': 3,
    },
  ];

  // Тестовые промоакции
  final List<Map<String, dynamic>> _testPromotions = [
    {
      'id': 'promo_1',
      'title': 'Скидка 20% на свадебную фотосъемку',
      'description':
          'Специальное предложение для молодоженов! Скидка 20% на полный пакет свадебной фотосъемки.',
      'discount': 20,
      'category': 'photographer',
      'specialistName': 'Анна Лебедева',
      'city': 'Санкт-Петербург',
      'endDate': '2024-12-31',
      'participants': 15,
      'isParticipating': false,
      'color': Colors.pink,
      'conditions':
          'Акция действует при заказе на сумму от 50 000 рублей. Не суммируется с другими скидками.',
      'image': 'https://picsum.photos/400/300?random=101',
    },
    {
      'id': 'promo_2',
      'title': 'Бесплатный DJ на корпоратив',
      'description':
          'При заказе ведущего на корпоратив - DJ в подарок! Создайте незабываемую атмосферу для вашего мероприятия.',
      'discount': 100,
      'category': 'dj',
      'specialistName': 'Дмитрий Козлов',
      'city': 'Москва',
      'endDate': '2024-11-30',
      'participants': 8,
      'isParticipating': false,
      'color': Colors.blue,
      'conditions':
          'Минимальный заказ ведущего - 40 000 рублей. Акция действует только в будние дни.',
      'image': 'https://picsum.photos/400/300?random=102',
    },
    {
      'id': 'promo_3',
      'title': 'Сезонная скидка на декорации',
      'description':
          'Осенняя скидка 30% на все виды декораций для мероприятий. Украсьте ваш праздник со скидкой!',
      'discount': 30,
      'category': 'decorator',
      'specialistName': 'Елена Петрова',
      'city': 'Москва',
      'endDate': '2024-10-31',
      'participants': 23,
      'isParticipating': true,
      'color': Colors.orange,
      'conditions':
          'Скидка распространяется на все виды декораций. Минимальный заказ - 20 000 рублей.',
      'image': 'https://picsum.photos/400/300?random=103',
    },
  ];

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
      'about': 'Декоратор с 6-летним опытом. Создаю уникальные интерьеры для любых мероприятий.',
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
      'about': 'Шеф-повар с 12-летним опытом. Организую кейтеринг для мероприятий любого масштаба.',
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
          'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_1',
          'senderName': 'Ольга Иванова',
          'content': 'Свадьба на 80 человек в загородном клубе. Нужен ведущий на 6 часов.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_1',
          'senderName': 'Алексей Смирнов',
          'content': 'Отлично! Мой тариф 30 000 ₽ за 6 часов. Включает сценарий, игры и конкурсы.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
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
          'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_2',
          'senderName': 'Игорь Петров',
          'content': '12 октября, в офисе на 50 человек.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_2',
          'senderName': 'Анна Лебедева',
          'content': 'Понятно! Мой тариф 25 000 ₽ за 4 часа съемки + обработка всех фото.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
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
          'content': 'Здравствуйте! 11 октября свободен. Расскажите о мероприятии.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_3',
          'senderName': 'Мария Сидорова',
          'content': 'Свадьба на 120 человек в ресторане. Нужно на 6 часов.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_3',
          'senderName': 'Дмитрий Козлов',
          'content': 'Отлично! Мой тариф 20 000 ₽ за 6 часов. Включает оборудование и музыку.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
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
          'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_4',
          'senderName': 'Александр Козлов',
          'content': '13 октября, в конференц-зале на 80 человек.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_4',
          'senderName': 'Елена Петрова',
          'content': 'Понятно! Мой тариф 35 000 ₽ за 4 часа съемки + монтаж ролика.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
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
          'timestamp': DateTime.now().subtract(const Duration(hours: 5, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_5',
          'senderName': 'Екатерина Морозова',
          'content': '14 октября, в загородном клубе. Нужно оформить зал и фотозону.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_5',
          'senderName': 'Михаил Волков',
          'content': 'Понятно! Мой тариф 15 000 ₽ за полное оформление в стиле прованс.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5, minutes: 15)),
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
          'content': 'Здравствуйте! С удовольствием помогу! Расскажите подробнее.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_6',
          'senderName': 'Дмитрий Соколов',
          'content': '15 октября, для 20 детей 5-7 лет. Тема: пиратская вечеринка.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_6',
          'senderName': 'Ольга Морозова',
          'content': 'Отлично! Мой тариф 40 000 ₽ за полную организацию пиратской вечеринки.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6, minutes: 15)),
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
          'timestamp': DateTime.now().subtract(const Duration(hours: 7, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_7',
          'senderName': 'Анна Федорова',
          'content': '16 октября, романтические баллады и джаз. 2 часа.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 7, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_7',
          'senderName': 'Сергей Новиков',
          'content': 'Понятно! Мой тариф 25 000 ₽ за 2 часа романтической музыки.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 7, minutes: 15)),
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
          'timestamp': DateTime.now().subtract(const Duration(hours: 8, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_8',
          'senderName': 'Игорь Лебедев',
          'content': '17 октября, белые и розовые розы, классический стиль.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_8',
          'senderName': 'Татьяна Соколова',
          'content': 'Отлично! Мой тариф 12 000 ₽ за полное цветочное оформление.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8, minutes: 15)),
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
          'content': 'Здравствуйте! Сколько человек и какие предпочтения по меню?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_9',
          'senderName': 'Наталья Козлова',
          'content': '18 октября, 100 человек, европейская кухня, фуршет.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_9',
          'senderName': 'Андрей Федоров',
          'content': 'Понятно! Мой тариф 50 000 ₽ за фуршет на 100 человек.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9, minutes: 15)),
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
          'timestamp': DateTime.now().subtract(const Duration(hours: 10, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_10',
          'senderName': 'Владимир Петров',
          'content': '19 октября, натуральный макияж для свадьбы.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 10, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_10',
          'senderName': 'Мария Кузнецова',
          'content': 'Отлично! Мой тариф 18 000 ₽ за свадебный макияж.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 10, minutes: 15)),
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
      'description': 'Свадьба на 80 человек в загородном клубе. Нужен ведущий на 6 часов.',
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
      'description': 'Корпоративное мероприятие в конференц-зале на 80 человек.',
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
      'description': 'Свадьба в загородном клубе. Нужно оформить зал и фотозону в стиле прованс.',
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
      'description': 'Детский день рождения для 20 детей 5-7 лет. Тема: пиратская вечеринка.',
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
      'description': 'Романтический ужин с живой музыкой. Романтические баллады и джаз на 2 часа.',
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
      'caption': 'Отличная свадьба вчера! 🎵 Музыка играла всю ночь, гости танцевали до утра!',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'likes': 31,
      'comments': 7,
    },
    {
      'authorId': 'specialist_4',
      'authorName': 'Елена Петрова',
      'authorAvatar': 'https://picsum.photos/200?random=4',
      'imageUrl': 'https://picsum.photos/400?random=33',
      'caption': 'Корпоративная видеосъемка 📹 Создаем крутой ролик для компании!',
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
      'likes': 19,
      'comments': 4,
    },
    {
      'authorId': 'specialist_5',
      'authorName': 'Михаил Волков',
      'authorAvatar': 'https://picsum.photos/200?random=5',
      'imageUrl': 'https://picsum.photos/400?random=34',
      'caption': 'Свадьба в стиле прованс 🌸 Французская романтика в каждом элементе!',
      'timestamp': DateTime.now().subtract(const Duration(days: 5)),
      'likes': 42,
      'comments': 9,
    },
    {
      'authorId': 'specialist_6',
      'authorName': 'Ольга Морозова',
      'authorAvatar': 'https://picsum.photos/200?random=6',
      'imageUrl': 'https://picsum.photos/400?random=35',
      'caption': 'Пиратская вечеринка для детей 🏴‍☠️ Дети были в восторге от приключений!',
      'timestamp': DateTime.now().subtract(const Duration(days: 6)),
      'likes': 28,
      'comments': 6,
    },
    {
      'authorId': 'specialist_7',
      'authorName': 'Сергей Новиков',
      'authorAvatar': 'https://picsum.photos/200?random=7',
      'imageUrl': 'https://picsum.photos/400?random=36',
      'caption': 'Романтический вечер 🎸 Джаз и баллады создали незабываемую атмосферу!',
      'timestamp': DateTime.now().subtract(const Duration(days: 7)),
      'likes': 35,
      'comments': 8,
    },
    {
      'authorId': 'specialist_8',
      'authorName': 'Татьяна Соколова',
      'authorAvatar': 'https://picsum.photos/200?random=8',
      'imageUrl': 'https://picsum.photos/400?random=37',
      'caption': 'Цветочное оформление свадьбы 🌹 Белые и розовые розы - классика жанра!',
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
      'caption': 'Свадебный макияж 💄 Натуральная красота - лучший выбор для невесты!',
      'timestamp': DateTime.now().subtract(const Duration(days: 10)),
      'likes': 29,
      'comments': 6,
    },
  ];

  /// Заполнить все тестовые данные
  Future<void> populateAll() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🚀 Начало заполнения тестовых данных...');

      // Проверяем, есть ли уже данные
      if (await hasTestData()) {
        debugPrint('⚠️ Тестовые данные уже существуют. Пропускаем создание.');
        return;
      }

      // Заполняем данные параллельно где возможно
      await Future.wait([_populateSpecialists(), _populateChats(), _populateBookings()]);

      await Future.wait([_populatePosts(), _populateIdeas(), _populateNotifications()]);

      await Future.wait([createTestPromotions(), _populateReviews()]);

      stopwatch.stop();
      debugPrint('✅ Тестовые данные успешно созданы за ${stopwatch.elapsedMilliseconds}ms');
    } on FirebaseException catch (e) {
      debugPrint('❌ Ошибка Firebase при заполнении данных: ${e.message}');
      rethrow;
    } on Exception catch (e) {
      debugPrint('❌ Общая ошибка при заполнении данных: $e');
      rethrow;
    }
  }

  /// Заполнить специалистов
  Future<void> _populateSpecialists() async {
    debugPrint('👥 Создание специалистов...');

    try {
      // Используем батчевые операции для лучшей производительности
      final batches = <WriteBatch>[];
      WriteBatch? currentBatch = _firestore.batch();
      var batchCount = 0;

      for (var i = 0; i < _testSpecialists.length; i++) {
        final specialist = _testSpecialists[i];
        final docRef = _firestore.collection('specialists').doc('specialist_${i + 1}');

        currentBatch!.set(docRef, {
          ...specialist,
          'id': 'specialist_${i + 1}',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        batchCount++;

        // Создаем новый батч каждые _batchSize операций
        if (batchCount >= _batchSize) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Добавляем последний батч если он не пустой
      if (batchCount > 0) {
        batches.add(currentBatch!);
      }

      // Выполняем все батчи
      for (final batch in batches) {
        await batch.commit();
      }

      debugPrint('✅ Создано ${_testSpecialists.length} специалистов');
    } on FirebaseException catch (e) {
      debugPrint('❌ Ошибка при создании специалистов: ${e.message}');
      rethrow;
    }
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
      final messages = chat['messages'] as List;
      for (var j = 0; j < messages.length; j++) {
        final message = messages[j];
        await _firestore.collection('chats').doc(chatId).collection('messages').add({
          'senderId': message['senderId'],
          'senderName': message['senderName'],
          'content': message['content'],
          'type': message['type'],
          'timestamp': message['timestamp'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    debugPrint('Добавлено ${_testChats.length} чатов');
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
    debugPrint('Добавлено ${_testBookings.length} заявок');
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
    debugPrint('Добавлено ${_testPosts.length} постов');
  }

  /// Получить список специалистов
  List<Map<String, dynamic>> getSpecialists() => _testSpecialists;

  /// Создать тестовых специалистов (для совместимости)
  Future<void> createTestSpecialists() async {
    await _populateSpecialists();
  }

  /// Заполнить идеи
  Future<void> _populateIdeas() async {
    final testIdeas = [
      {
        'title': 'Свадьба в стиле прованс',
        'description':
            'Романтическая свадьба с французским шармом. Лавандовые оттенки, винтажные детали и уютная атмосфера.',
        'imageUrl': 'https://picsum.photos/400?random=100',
        'authorId': 'specialist_5',
        'authorName': 'Михаил Волков',
        'authorAvatar': 'https://picsum.photos/200?random=5',
        'likeCount': 42,
        'commentCount': 8,
        'isLiked': false,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'title': 'Корпоратив в стиле 80-х',
        'description':
            'Яркий и энергичный корпоратив с неоновыми цветами, диско-музыкой и ретро-атмосферой.',
        'imageUrl': 'https://picsum.photos/400?random=101',
        'authorId': 'specialist_3',
        'authorName': 'Дмитрий Козлов',
        'authorAvatar': 'https://picsum.photos/200?random=3',
        'likeCount': 28,
        'commentCount': 5,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'title': 'Детская вечеринка "Пираты"',
        'description':
            'Приключенческая вечеринка для детей с поиском сокровищ, костюмами пиратов и морскими играми.',
        'imageUrl': 'https://picsum.photos/400?random=102',
        'authorId': 'specialist_6',
        'authorName': 'Ольга Морозова',
        'authorAvatar': 'https://picsum.photos/200?random=6',
        'likeCount': 35,
        'commentCount': 12,
        'isLiked': false,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'title': 'Фотосессия в закатном свете',
        'description':
            'Романтическая фотосессия на природе с мягким закатным освещением и естественными позами.',
        'imageUrl': 'https://picsum.photos/400?random=103',
        'authorId': 'specialist_2',
        'authorName': 'Анна Лебедева',
        'authorAvatar': 'https://picsum.photos/200?random=2',
        'likeCount': 56,
        'commentCount': 15,
        'isLiked': true,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
      },
      {
        'title': 'Свадебный макияж "Натуральная красота"',
        'description':
            'Деликатный макияж, подчеркивающий естественную красоту невесты. Светлые тона и нежные акценты.',
        'imageUrl': 'https://picsum.photos/400?random=104',
        'authorId': 'specialist_10',
        'authorName': 'Мария Кузнецова',
        'authorAvatar': 'https://picsum.photos/200?random=10',
        'likeCount': 31,
        'commentCount': 7,
        'isLiked': false,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'title': 'Кейтеринг "Французская кухня"',
        'description':
            'Изысканное меню с французскими деликатесами: фуа-гра, улитки, рататуй и классические десерты.',
        'imageUrl': 'https://picsum.photos/400?random=105',
        'authorId': 'specialist_9',
        'authorName': 'Андрей Федоров',
        'authorAvatar': 'https://picsum.photos/200?random=9',
        'likeCount': 48,
        'commentCount': 9,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 6)),
      },
      {
        'title': 'Цветочное оформление "Весенний сад"',
        'description':
            'Свежие весенние цветы: тюльпаны, нарциссы, гиацинты. Создаем атмосферу пробуждающейся природы.',
        'imageUrl': 'https://picsum.photos/400?random=106',
        'authorId': 'specialist_8',
        'authorName': 'Татьяна Соколова',
        'authorAvatar': 'https://picsum.photos/200?random=8',
        'likeCount': 39,
        'commentCount': 6,
        'isLiked': false,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
      },
      {
        'title': 'Живая музыка "Джаз и блюз"',
        'description':
            'Атмосферное выступление с джазовыми стандартами и блюзовыми импровизациями для особенного вечера.',
        'imageUrl': 'https://picsum.photos/400?random=107',
        'authorId': 'specialist_7',
        'authorName': 'Сергей Новиков',
        'authorAvatar': 'https://picsum.photos/200?random=7',
        'likeCount': 44,
        'commentCount': 11,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 8)),
      },
      {
        'title': 'Видеосъемка "Свадебный фильм"',
        'description':
            'Кинематографичная съемка свадьбы с красивыми планами, эмоциональными моментами и качественным монтажом.',
        'imageUrl': 'https://picsum.photos/400?random=108',
        'authorId': 'specialist_4',
        'authorName': 'Елена Петрова',
        'authorAvatar': 'https://picsum.photos/200?random=4',
        'likeCount': 52,
        'commentCount': 13,
        'isLiked': false,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 9)),
      },
      {
        'title': 'Ведущий "Интерактивная свадьба"',
        'description':
            'Современный подход к проведению свадьбы с интерактивными играми, квестами и вовлечением всех гостей.',
        'imageUrl': 'https://picsum.photos/400?random=109',
        'authorId': 'specialist_1',
        'authorName': 'Алексей Смирнов',
        'authorAvatar': 'https://picsum.photos/200?random=1',
        'likeCount': 37,
        'commentCount': 8,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      },
    ];

    for (var i = 0; i < testIdeas.length; i++) {
      final idea = testIdeas[i];
      await _firestore.collection('ideas').add({
        ...idea,
        'createdAt': idea['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${testIdeas.length} идей');
  }

  /// Заполнить уведомления
  Future<void> _populateNotifications() async {
    final testNotifications = [
      {
        'userId': 'current_user',
        'title': 'Новый лайк!',
        'body': 'Анна Лебедева поставила лайк вашему посту',
        'type': 'like',
        'data': 'post_1',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
      },
      {
        'userId': 'current_user',
        'title': 'Новый комментарий',
        'body': 'Дмитрий Козлов прокомментировал вашу идею',
        'type': 'comment',
        'data': 'idea_2',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
      },
      {
        'userId': 'current_user',
        'title': 'Новая подписка',
        'body': 'Михаил Волков подписался на вас',
        'type': 'follow',
        'data': 'specialist_5',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      },
      {
        'userId': 'current_user',
        'title': 'Новая заявка',
        'body': 'Поступила заявка на фотосъемку свадьбы',
        'type': 'request',
        'data': 'booking_1',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'userId': 'current_user',
        'title': 'Новое сообщение',
        'body': 'Елена Петрова: Спасибо за отличную работу!',
        'type': 'message',
        'data': 'chat_1',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      },
      {
        'userId': 'current_user',
        'title': 'Подтверждение заявки',
        'body': 'Ваша заявка на видеосъемку подтверждена',
        'type': 'booking',
        'data': 'booking_2',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'userId': 'current_user',
        'title': 'Системное уведомление',
        'body': 'Добро пожаловать в Event Marketplace!',
        'type': 'system',
        'data': null,
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'userId': 'current_user',
        'title': 'Новый лайк!',
        'body': 'Ольга Морозова поставила лайк вашей идее',
        'type': 'like',
        'data': 'idea_3',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      },
      {
        'userId': 'current_user',
        'title': 'Новый комментарий',
        'body': 'Сергей Новиков прокомментировал ваш пост',
        'type': 'comment',
        'data': 'post_2',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      },
      {
        'userId': 'current_user',
        'title': 'Новая подписка',
        'body': 'Татьяна Соколова подписался на вас',
        'type': 'follow',
        'data': 'specialist_8',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      },
    ];

    for (var i = 0; i < testNotifications.length; i++) {
      final notification = testNotifications[i];
      await _firestore.collection('notifications').add({
        ...notification,
        'createdAt': notification['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${testNotifications.length} уведомлений');
  }

  /// Создать тестовые акции
  Future<void> createTestPromotions() async {
    debugPrint('Создание тестовых акций...');

    final testPromotions = [
      {
        'title': 'Свадебный пакет -15%',
        'description':
            'Специальное предложение для свадебных мероприятий. Включает ведущего, фотографа и декорации.',
        'category': 'host',
        'discount': 15,
        'startDate': DateTime.now().subtract(const Duration(days: 5)),
        'endDate': DateTime.now().add(const Duration(days: 30)),
        'imageUrl': 'https://picsum.photos/400?random=101',
        'specialistId': 'specialist_1',
        'specialistName': 'Алексей Смирнов',
        'city': 'Москва',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Фотосессия -20%',
        'description': 'Скидка на все виды фотосессий. Студийная, выездная, свадебная фотография.',
        'category': 'photographer',
        'discount': 20,
        'startDate': DateTime.now().subtract(const Duration(days: 3)),
        'endDate': DateTime.now().add(const Duration(days: 20)),
        'imageUrl': 'https://picsum.photos/400?random=102',
        'specialistId': 'specialist_2',
        'specialistName': 'Анна Лебедева',
        'city': 'Санкт-Петербург',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Новогодние праздники -25%',
        'description': 'Сезонное предложение на новогодние корпоративы и частные вечеринки.',
        'category': 'seasonal',
        'discount': 25,
        'startDate': DateTime.now().subtract(const Duration(days: 1)),
        'endDate': DateTime.now().add(const Duration(days: 45)),
        'imageUrl': 'https://picsum.photos/400?random=103',
        'specialistId': 'specialist_3',
        'specialistName': 'Михаил Петров',
        'city': 'Москва',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'DJ-услуги -10%',
        'description':
            'Скидка на музыкальное сопровождение мероприятий. Современное оборудование и качественный звук.',
        'category': 'dj',
        'discount': 10,
        'startDate': DateTime.now(),
        'endDate': DateTime.now().add(const Duration(days: 15)),
        'imageUrl': 'https://picsum.photos/400?random=104',
        'specialistId': 'specialist_4',
        'specialistName': 'Дмитрий Козлов',
        'city': 'Санкт-Петербург',
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Подарок: бесплатная консультация',
        'description':
            'Бесплатная консультация по организации мероприятия. Поможем составить план и подобрать специалистов.',
        'category': 'gift',
        'discount': 0,
        'startDate': DateTime.now().subtract(const Duration(days: 2)),
        'endDate': DateTime.now().add(const Duration(days: 60)),
        'imageUrl': 'https://picsum.photos/400?random=105',
        'specialistId': 'specialist_5',
        'specialistName': 'Елена Волкова',
        'city': 'Москва',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Промокод WEDDING2024 -30%',
        'description':
            'Используйте промокод WEDDING2024 и получите максимальную скидку на свадебные услуги.',
        'category': 'promoCode',
        'discount': 30,
        'startDate': DateTime.now().subtract(const Duration(days: 7)),
        'endDate': DateTime.now().add(const Duration(days: 25)),
        'imageUrl': 'https://picsum.photos/400?random=106',
        'specialistId': 'specialist_6',
        'specialistName': 'Ольга Морозова',
        'city': 'Санкт-Петербург',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Декорации -18%',
        'description': 'Скидка на оформление залов и создание праздничной атмосферы.',
        'category': 'decorator',
        'discount': 18,
        'startDate': DateTime.now().subtract(const Duration(days: 4)),
        'endDate': DateTime.now().add(const Duration(days: 35)),
        'imageUrl': 'https://picsum.photos/400?random=107',
        'specialistId': 'specialist_7',
        'specialistName': 'Сергей Новиков',
        'city': 'Москва',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Кейтеринг -12%',
        'description': 'Специальные цены на организацию питания для ваших мероприятий.',
        'category': 'caterer',
        'discount': 12,
        'startDate': DateTime.now().subtract(const Duration(days: 6)),
        'endDate': DateTime.now().add(const Duration(days: 40)),
        'imageUrl': 'https://picsum.photos/400?random=108',
        'specialistId': 'specialist_8',
        'specialistName': 'Татьяна Соколова',
        'city': 'Санкт-Петербург',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 6)),
        'updatedAt': DateTime.now(),
      },
    ];

    for (var i = 0; i < testPromotions.length; i++) {
      final promotion = testPromotions[i];
      await _firestore.collection('promotions').add({
        ...promotion,
        'startDate': Timestamp.fromDate(promotion['startDate']! as DateTime),
        'endDate': Timestamp.fromDate(promotion['endDate']! as DateTime),
        'createdAt': Timestamp.fromDate(promotion['createdAt']! as DateTime),
        'updatedAt': Timestamp.fromDate(promotion['updatedAt']! as DateTime),
      });
    }
    debugPrint('Добавлено ${testPromotions.length} акций');
  }

  /// Очистить все тестовые данные
  Future<void> clearAllTestData() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🧹 Начало очистки тестовых данных...');

      // Удаляем все коллекции
      final collections = [
        'specialists',
        'chats',
        'bookings',
        'posts',
        'ideas',
        'notifications',
        'promotions',
        'reviews',
        'transactions',
        'premium_profiles',
        'subscriptions',
        'promoted_posts',
      ];

      var totalDeleted = 0;

      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).get();

          if (snapshot.docs.isNotEmpty) {
            // Используем батчевое удаление для лучшей производительности
            final batches = <WriteBatch>[];
            WriteBatch? currentBatch = _firestore.batch();
            var batchCount = 0;

            for (final doc in snapshot.docs) {
              currentBatch!.delete(doc.reference);
              batchCount++;

              if (batchCount >= _batchSize) {
                batches.add(currentBatch);
                currentBatch = _firestore.batch();
                batchCount = 0;
              }
            }

            if (batchCount > 0) {
              batches.add(currentBatch!);
            }

            for (final batch in batches) {
              await batch.commit();
            }

            totalDeleted += snapshot.docs.length;
            debugPrint('  ✅ Удалено ${snapshot.docs.length} документов из $collection');
          }
        } on FirebaseException catch (e) {
          debugPrint('  ⚠️ Ошибка при удалении из $collection: ${e.message}');
        }
      }

      stopwatch.stop();
      debugPrint(
        '✅ Очистка завершена. Удалено $totalDeleted документов за ${stopwatch.elapsedMilliseconds}ms',
      );
    } on Exception catch (e) {
      debugPrint('❌ Ошибка при удалении тестовых данных: $e');
      rethrow;
    }
  }

  /// Проверить, есть ли уже тестовые данные
  Future<bool> hasTestData() async {
    try {
      final specialistsSnapshot = await _firestore.collection('specialists').limit(1).get();
      return specialistsSnapshot.docs.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  /// Получить статистику тестовых данных
  Future<Map<String, int>> getTestDataStats() async {
    try {
      debugPrint('📊 Получение статистики тестовых данных...');

      final collections = [
        'specialists',
        'chats',
        'bookings',
        'posts',
        'ideas',
        'notifications',
        'promotions',
        'reviews',
      ];

      final stats = <String, int>{};

      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).get();
          stats[collection] = snapshot.docs.length;
        } on FirebaseException catch (e) {
          debugPrint('⚠️ Ошибка при получении статистики для $collection: ${e.message}');
          stats[collection] = 0;
        }
      }

      final total = stats.values.fold(0, (totalSum, count) => totalSum + count);
      stats['total'] = total;

      debugPrint('📊 Статистика тестовых данных: $stats');
      return stats;
    } on Exception catch (e) {
      debugPrint('❌ Ошибка при получении статистики: $e');
      return {};
    }
  }

  /// Заполнить отзывы
  Future<void> _populateReviews() async {
    final testReviews = [
      // Отзывы для специалиста 1 (Алексей Смирнов)
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_1',
        'customerName': 'Ольга Иванова',
        'rating': 5.0,
        'text':
            'Алексей - потрясающий ведущий! Наша свадьба прошла на высшем уровне. Он создал незабываемую атмосферу, все гости были в восторге. Очень рекомендую!',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'photos': ['https://picsum.photos/400?random=201', 'https://picsum.photos/400?random=202'],
        'likes': 12,
        'responses': [
          {
            'authorId': 'specialist_1',
            'authorName': 'Алексей Смирнов',
            'text': 'Спасибо большое за отзыв! Было очень приятно работать с вами!',
            'date': DateTime.now().subtract(const Duration(days: 4)),
          },
        ],
        'bookingId': 'booking_1',
        'eventTitle': 'Свадьба Ольги и Игоря',
        'customerAvatar': 'https://picsum.photos/200?random=301',
        'specialistName': 'Алексей Смирнов',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_2',
        'customerName': 'Мария Петрова',
        'rating': 4.5,
        'text':
            'Хороший ведущий, но немного затянул программу. В целом все прошло хорошо, гости остались довольны.',
        'date': DateTime.now().subtract(const Duration(days: 10)),
        'photos': ['https://picsum.photos/400?random=203'],
        'likes': 5,
        'responses': <String>[],
        'bookingId': 'booking_2',
        'eventTitle': 'Корпоратив IT-компании',
        'customerAvatar': 'https://picsum.photos/200?random=302',
        'specialistName': 'Алексей Смирнов',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_3',
        'customerName': 'Дмитрий Козлов',
        'rating': 5.0,
        'text':
            'Отличный ведущий! Профессиональный подход, интересная программа, все было на высоте. Рекомендую всем!',
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'photos': <String>[],
        'likes': 8,
        'responses': [
          {
            'authorId': 'specialist_1',
            'authorName': 'Алексей Смирнов',
            'text': 'Благодарю за отзыв! Рад, что мероприятие понравилось!',
            'date': DateTime.now().subtract(const Duration(days: 14)),
          },
        ],
        'bookingId': 'booking_3',
        'eventTitle': 'День рождения',
        'customerAvatar': 'https://picsum.photos/200?random=303',
        'specialistName': 'Алексей Смирнов',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_4',
        'customerName': 'Анна Сидорова',
        'rating': 4.0,
        'text':
            'Неплохой ведущий, но ожидала больше интерактива. В целом справился со своей задачей.',
        'date': DateTime.now().subtract(const Duration(days: 20)),
        'photos': ['https://picsum.photos/400?random=204', 'https://picsum.photos/400?random=205'],
        'likes': 3,
        'responses': <String>[],
        'bookingId': 'booking_4',
        'eventTitle': 'Юбилей',
        'customerAvatar': 'https://picsum.photos/200?random=304',
        'specialistName': 'Алексей Смирнов',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_5',
        'customerName': 'Сергей Волков',
        'rating': 5.0,
        'text':
            'Алексей - мастер своего дела! Создал незабываемую атмосферу на нашей свадьбе. Все гости до сих пор вспоминают этот день с улыбкой!',
        'date': DateTime.now().subtract(const Duration(days: 25)),
        'photos': ['https://picsum.photos/400?random=206'],
        'likes': 15,
        'responses': [
          {
            'authorId': 'specialist_1',
            'authorName': 'Алексей Смирнов',
            'text': 'Спасибо за теплые слова! Было очень приятно работать с вами!',
            'date': DateTime.now().subtract(const Duration(days: 24)),
          },
        ],
        'bookingId': 'booking_5',
        'eventTitle': 'Свадьба Сергея и Анны',
        'customerAvatar': 'https://picsum.photos/200?random=305',
        'specialistName': 'Алексей Смирнов',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },

      // Отзывы для специалиста 2 (Анна Лебедева)
      {
        'specialistId': 'specialist_2',
        'customerId': 'customer_6',
        'customerName': 'Елена Морозова',
        'rating': 5.0,
        'text':
            'Анна - талантливый фотограф! Снимки получились просто потрясающие. Очень внимательная к деталям, профессиональный подход.',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'photos': ['https://picsum.photos/400?random=207', 'https://picsum.photos/400?random=208'],
        'likes': 18,
        'responses': [
          {
            'authorId': 'specialist_2',
            'authorName': 'Анна Лебедева',
            'text': 'Спасибо за отзыв! Рада, что фото понравились!',
            'date': DateTime.now().subtract(const Duration(days: 2)),
          },
        ],
        'bookingId': 'booking_6',
        'eventTitle': 'Свадебная фотосессия',
        'customerAvatar': 'https://picsum.photos/200?random=306',
        'specialistName': 'Анна Лебедева',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_2',
        'customerId': 'customer_7',
        'customerName': 'Игорь Петров',
        'rating': 4.5,
        'text':
            'Хорошая работа, качественные фото. Единственное - немного затянула процесс съемки, но результат оправдал ожидания.',
        'date': DateTime.now().subtract(const Duration(days: 8)),
        'photos': ['https://picsum.photos/400?random=209'],
        'likes': 7,
        'responses': <String>[],
        'bookingId': 'booking_7',
        'eventTitle': 'Корпоративная фотосессия',
        'customerAvatar': 'https://picsum.photos/200?random=307',
        'specialistName': 'Анна Лебедева',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_2',
        'customerId': 'customer_8',
        'customerName': 'Татьяна Козлова',
        'rating': 5.0,
        'text':
            'Анна - профессионал высшего класса! Создала невероятные снимки нашей свадьбы. Каждый кадр - произведение искусства!',
        'date': DateTime.now().subtract(const Duration(days: 12)),
        'photos': ['https://picsum.photos/400?random=210', 'https://picsum.photos/400?random=211'],
        'likes': 22,
        'responses': [
          {
            'authorId': 'specialist_2',
            'authorName': 'Анна Лебедева',
            'text': 'Благодарю за такие теплые слова! Было очень приятно работать с вами!',
            'date': DateTime.now().subtract(const Duration(days: 11)),
          },
        ],
        'bookingId': 'booking_8',
        'eventTitle': 'Свадьба в стиле прованс',
        'customerAvatar': 'https://picsum.photos/200?random=308',
        'specialistName': 'Анна Лебедева',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },

      // Отзывы для специалиста 3 (Дмитрий Козлов)
      {
        'specialistId': 'specialist_3',
        'customerId': 'customer_9',
        'customerName': 'Александр Новиков',
        'rating': 4.0,
        'text':
            'Хороший DJ, но музыкальный вкус не совсем совпал с нашими предпочтениями. В целом справился с задачей.',
        'date': DateTime.now().subtract(const Duration(days: 6)),
        'photos': <String>[],
        'likes': 4,
        'responses': [
          {
            'authorId': 'specialist_3',
            'authorName': 'Дмитрий Козлов',
            'text': 'Спасибо за отзыв! Учту ваши пожелания на будущее.',
            'date': DateTime.now().subtract(const Duration(days: 5)),
          },
        ],
        'bookingId': 'booking_9',
        'eventTitle': 'День рождения',
        'customerAvatar': 'https://picsum.photos/200?random=309',
        'specialistName': 'Дмитрий Козлов',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_3',
        'customerId': 'customer_10',
        'customerName': 'Наталья Федорова',
        'rating': 5.0,
        'text':
            'Дмитрий - отличный DJ! Создал потрясающую атмосферу на нашей свадьбе. Все танцевали до утра!',
        'date': DateTime.now().subtract(const Duration(days: 14)),
        'photos': ['https://picsum.photos/400?random=212'],
        'likes': 11,
        'responses': [
          {
            'authorId': 'specialist_3',
            'authorName': 'Дмитрий Козлов',
            'text': 'Спасибо! Рад, что музыка понравилась всем!',
            'date': DateTime.now().subtract(const Duration(days: 13)),
          },
        ],
        'bookingId': 'booking_10',
        'eventTitle': 'Свадьба Натальи и Михаила',
        'customerAvatar': 'https://picsum.photos/200?random=310',
        'specialistName': 'Дмитрий Козлов',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
    ];

    for (var i = 0; i < testReviews.length; i++) {
      final review = testReviews[i];
      await _firestore.collection('reviews').add({
        ...review,
        'date': Timestamp.fromDate(review['date']! as DateTime),
        'responses': (review['responses']! as List<dynamic>)
            .map(
              (response) => {
                ...response as Map<String, dynamic>,
                'date': Timestamp.fromDate(response['date'] as DateTime),
              },
            )
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${testReviews.length} отзывов');
  }

  // Создание тестовых данных для монетизации
  Future<void> createMonetizationTestData() async {
    debugPrint('Создание тестовых данных монетизации...');

    await _createTestTransactions();
    await _createTestPremiumProfiles();
    await _createTestSubscriptions();
    await _createTestPromotedPosts();

    debugPrint('Тестовые данные монетизации созданы успешно!');
  }

  // Тестовые транзакции
  Future<void> _createTestTransactions() async {
    final testTransactions = [
      {
        'id': 'transaction_1',
        'userId': 'user_1',
        'type': 'promotion',
        'amount': 299.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 5)),
        'description': 'Продвижение профиля - 7_days',
        'targetUserId': null,
        'postId': null,
        'metadata': {'plan': '7_days'},
      },
      {
        'id': 'transaction_2',
        'userId': 'user_2',
        'type': 'subscription',
        'amount': 499.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 10)),
        'description': 'Подписка pro',
        'targetUserId': null,
        'postId': null,
        'metadata': {'plan': 'pro'},
      },
      {
        'id': 'transaction_3',
        'userId': 'demo_user_123',
        'type': 'donation',
        'amount': 500.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'description': 'Донат специалисту',
        'targetUserId': 'user_1',
        'postId': null,
        'metadata': {'message': 'Спасибо за отличную работу!'},
      },
      {
        'id': 'transaction_4',
        'userId': 'user_3',
        'type': 'boostPost',
        'amount': 999.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'description': 'Продвижение поста на 7 дней',
        'targetUserId': null,
        'postId': 'post_1',
        'metadata': {'days': 7},
      },
      {
        'id': 'transaction_5',
        'userId': 'user_4',
        'type': 'subscription',
        'amount': 999.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 15)),
        'description': 'Подписка elite',
        'targetUserId': null,
        'postId': null,
        'metadata': {'plan': 'elite'},
      },
    ];

    for (final transaction in testTransactions) {
      await _firestore.collection('transactions').doc(transaction['id']! as String).set({
        ...transaction,
        'timestamp': Timestamp.fromDate(transaction['timestamp']! as DateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${testTransactions.length} транзакций');
  }

  // Тестовые премиум-профили
  Future<void> _createTestPremiumProfiles() async {
    final testPremiumProfiles = [
      {
        'userId': 'user_1',
        'activeUntil': DateTime.now().add(const Duration(days: 2)),
        'type': 'highlight',
        'region': 'Москва',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'isActive': true,
      },
      {
        'userId': 'user_2',
        'activeUntil': DateTime.now().add(const Duration(days: 20)),
        'type': 'prioritySearch',
        'region': 'Санкт-Петербург',
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'isActive': true,
      },
    ];

    for (final profile in testPremiumProfiles) {
      await _firestore.collection('premiumProfiles').doc(profile['userId']! as String).set({
        ...profile,
        'activeUntil': Timestamp.fromDate(profile['activeUntil']! as DateTime),
        'createdAt': Timestamp.fromDate(profile['createdAt']! as DateTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${testPremiumProfiles.length} премиум-профилей');
  }

  // Тестовые подписки
  Future<void> _createTestSubscriptions() async {
    final testSubscriptions = [
      {
        'userId': 'user_2',
        'plan': 'pro',
        'startedAt': DateTime.now().subtract(const Duration(days: 10)),
        'expiresAt': DateTime.now().add(const Duration(days: 20)),
        'autoRenew': true,
        'isActive': true,
        'monthlyPrice': 499.0,
      },
      {
        'userId': 'user_4',
        'plan': 'elite',
        'startedAt': DateTime.now().subtract(const Duration(days: 15)),
        'expiresAt': DateTime.now().add(const Duration(days: 15)),
        'autoRenew': true,
        'isActive': true,
        'monthlyPrice': 999.0,
      },
    ];

    for (final subscription in testSubscriptions) {
      await _firestore.collection('subscriptions').doc(subscription['userId']! as String).set({
        ...subscription,
        'startedAt': Timestamp.fromDate(subscription['startedAt']! as DateTime),
        'expiresAt': Timestamp.fromDate(subscription['expiresAt']! as DateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${testSubscriptions.length} подписок');
  }

  // Тестовые продвигаемые посты
  Future<void> _createTestPromotedPosts() async {
    final testPromotedPosts = [
      {
        'postId': 'post_1',
        'userId': 'user_3',
        'startDate': DateTime.now().subtract(const Duration(days: 2)),
        'endDate': DateTime.now().add(const Duration(days: 5)),
        'priority': 1,
        'budget': 999.0,
        'isActive': true,
        'impressions': 1250,
        'clicks': 45,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'postId': 'post_2',
        'userId': 'user_1',
        'startDate': DateTime.now().subtract(const Duration(days: 1)),
        'endDate': DateTime.now().add(const Duration(days: 6)),
        'priority': 1,
        'budget': 499.0,
        'isActive': true,
        'impressions': 850,
        'clicks': 32,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    for (final post in testPromotedPosts) {
      await _firestore.collection('promotedPosts').doc(post['postId']! as String).set({
        ...post,
        'startDate': Timestamp.fromDate(post['startDate']! as DateTime),
        'endDate': Timestamp.fromDate(post['endDate']! as DateTime),
        'createdAt': Timestamp.fromDate(post['createdAt']! as DateTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${testPromotedPosts.length} продвигаемых постов');
  }

  // Создание тестовых пользователей с монетизацией
  Future<void> createMonetizationUsers() async {
    final monetizationUsers = [
      {
        'id': 'premium_user_1',
        'name': 'Елена Премиум',
        'email': 'elena.premium@example.com',
        'avatarUrl': 'https://picsum.photos/200?random=101',
        'subscription': 'pro',
        'premiumUntil': DateTime.now().add(const Duration(days: 25)),
        'totalEarnings': 15000.0,
        'donationCount': 12,
      },
      {
        'id': 'elite_user_1',
        'name': 'Максим Элит',
        'email': 'maxim.elite@example.com',
        'avatarUrl': 'https://picsum.photos/200?random=102',
        'subscription': 'elite',
        'premiumUntil': DateTime.now().add(const Duration(days: 15)),
        'totalEarnings': 25000.0,
        'donationCount': 8,
      },
      {
        'id': 'donor_user_1',
        'name': 'Анна Донатор',
        'email': 'anna.donor@example.com',
        'avatarUrl': 'https://picsum.photos/200?random=103',
        'subscription': 'standard',
        'totalDonations': 3500.0,
        'donationCount': 7,
      },
    ];

    for (final user in monetizationUsers) {
      await _firestore.collection('users').doc(user['id']! as String).set({
        ...user,
        'premiumUntil': user['premiumUntil'] != null
            ? Timestamp.fromDate(user['premiumUntil']! as DateTime)
            : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Добавлено ${monetizationUsers.length} пользователей с монетизацией');
  }

  /// Получить тестовые промоакции
  List<Map<String, dynamic>> getPromotions() => List.from(_testPromotions);

  // ===== МЕТОДЫ ДЛЯ РАБОТЫ С FIRESTORE =====

  /// Добавить тестовых пользователей в Firestore
  Future<void> addTestUsersToFirestore() async {
    debugPrint('👥 Добавление тестовых пользователей в Firestore...');

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
      await _firestore.collection('users').doc(user['uid']! as String).set(user);
      debugPrint('  ✅ Пользователь ${user['name']} добавлен');
    }
  }

  /// Добавить посты в ленту Firestore
  Future<void> addFeedPostsToFirestore() async {
    debugPrint('📢 Добавление постов в ленту Firestore...');

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
      await _firestore.collection('feed').doc(post['id']! as String).set(post);
      debugPrint('  ✅ Пост ${post['id']} добавлен');
    }
  }

  /// Добавить заявки в Firestore
  Future<void> addOrdersToFirestore() async {
    debugPrint('📝 Добавление заявок в Firestore...');

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
        'description':
            'Новогодний корпоратив на 50 сотрудников. Нужен ведущий и музыкальное сопровождение.',
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
      await _firestore.collection('orders').doc(order['id']! as String).set(order);
      debugPrint('  ✅ Заявка ${order['id']} добавлена');
    }
  }

  /// Добавить чаты и сообщения в Firestore
  Future<void> addChatsToFirestore() async {
    debugPrint('💬 Добавление чатов и сообщений в Firestore...');

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
      await _firestore.collection('chats').doc(chat['id']! as String).set(chat);
      debugPrint('  ✅ Чат ${chat['id']} добавлен');

      // Создаем сообщения для каждого чата
      final chatId = chat['id']! as String;
      final members = chat['members']! as List<String>;

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
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(message['id']! as String)
            .set(message);
      }
      debugPrint('    ✅ 5 сообщений добавлено в чат $chatId');
    }
  }

  /// Создать тестовые категории
  Future<void> createTestCategories() async {
    try {
      final batch = _firestore.batch();
      int count = 0;

      for (final category in _testCategories) {
        final docRef = _firestore.collection('categories').doc(category['id']);
        batch.set(docRef, {
          ...category,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        count++;
        if (count >= _batchSize) {
          await batch.commit();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      debugPrint('✅ Тестовые категории созданы успешно');
    } catch (e) {
      debugPrint('❌ Ошибка создания тестовых категорий: $e');
    }
  }

  /// Создать тестовые тарифы
  Future<void> createTestTariffs() async {
    try {
      final batch = _firestore.batch();
      int count = 0;

      for (final tariff in _testTariffs) {
        final docRef = _firestore.collection('tariffs').doc(tariff['id']);
        batch.set(docRef, {
          ...tariff,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        count++;
        if (count >= _batchSize) {
          await batch.commit();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      debugPrint('✅ Тестовые тарифы созданы успешно');
    } catch (e) {
      debugPrint('❌ Ошибка создания тестовых тарифов: $e');
    }
  }

  /// Создать тестовые посты
  Future<void> createTestPosts() async {
    try {
      final batch = _firestore.batch();
      int count = 0;

      for (final post in _testPosts) {
        final docRef = _firestore.collection('posts').doc(post['id']);
        batch.set(docRef, {
          ...post,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        count++;
        if (count >= _batchSize) {
          await batch.commit();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      debugPrint('✅ Тестовые посты созданы успешно');
    } catch (e) {
      debugPrint('❌ Ошибка создания тестовых постов: $e');
    }
  }

  /// Создать все тестовые данные
  Future<void> createAllTestData() async {
    try {
      debugPrint('🚀 Начинаем создание всех тестовых данных...');
      
      await createTestCategories();
      await createTestTariffs();
      await createTestSpecialists();
      await createTestPosts();
      await createTestIdeas();
      await createTestPromotions();
      
      debugPrint('✅ Все тестовые данные созданы успешно!');
    } catch (e) {
      debugPrint('❌ Ошибка создания тестовых данных: $e');
    }
  }

  /// Добавить идеи в Firestore
  Future<void> addIdeasToFirestore() async {
    debugPrint('💡 Добавление идей в Firestore...');

    final ideas = [
      {
        'id': 'idea_1',
        'authorId': 'user_3',
        'imageUrl': 'https://picsum.photos/400/400?random=21',
        'title': 'Необычная фотозона 🌸',
        'description':
            'Отличная идея для летних свадеб. Используйте живые цветы и натуральные материалы.',
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
        'description':
            'Создайте атмосферу прошлого века с помощью ретро-реквизита и классической музыки.',
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
        'description':
            'Организуйте романтический пикник с красивой сервировкой и природным декором.',
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
        'description':
            'Создайте незабываемое приключение для детей с костюмами и тематическими играми.',
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
      await _firestore.collection('ideas').doc(idea['id']! as String).set(idea);
      debugPrint('  ✅ Идея ${idea['id']} добавлена');
    }
  }

  /// Добавить все тестовые данные в Firestore
  Future<void> addAllTestDataToFirestore() async {
    debugPrint('🚀 Начинаем добавление всех тестовых данных в Firestore...');

    try {
      await addTestUsersToFirestore();
      await addFeedPostsToFirestore();
      await addOrdersToFirestore();
      await addChatsToFirestore();
      await addIdeasToFirestore();

      debugPrint('✅ Все тестовые данные успешно добавлены в Firestore!');
    } catch (e) {
      debugPrint('❌ Ошибка при добавлении данных: $e');
      rethrow;
    }
  }

  /// Очистить все тестовые данные из Firestore
  Future<void> clearTestDataFromFirestore() async {
    debugPrint('🧹 Очистка тестовых данных из Firestore...');

    try {
      // Удаляем тестовые данные из всех коллекций
      final collections = ['users', 'feed', 'orders', 'chats', 'ideas'];

      for (final collection in collections) {
        final querySnapshot = await _firestore
            .collection(collection)
            .where('isTest', isEqualTo: true)
            .get();

        for (final doc in querySnapshot.docs) {
          if (collection == 'chats') {
            // Для чатов удаляем также сообщения
            final messagesSnapshot = await doc.reference.collection('messages').get();

            for (final messageDoc in messagesSnapshot.docs) {
              await messageDoc.reference.delete();
            }
          }
          await doc.reference.delete();
        }

        debugPrint('  ✅ Тестовые данные удалены из коллекции $collection');
      }

      debugPrint('✅ Все тестовые данные очищены из Firestore!');
    } catch (e) {
      debugPrint('❌ Ошибка при очистке данных: $e');
      rethrow;
    }
  }
}
