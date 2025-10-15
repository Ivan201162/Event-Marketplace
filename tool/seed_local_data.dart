import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Утилита для заполнения локальных тестовых данных
class LocalDataSeeder {
  static const String _dataFileName = 'local_test_data.json';

  /// Основные тестовые данные
  static final Map<String, dynamic> _testData = {
    'currentUser': {
      'id': 'user_current',
      'name': 'Анна Петрова',
      'email': 'anna.petrova@example.com',
      'phone': '+7 (999) 123-45-67',
      'avatar':
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
      'city': 'Москва',
      'isVerified': true,
      'rating': 4.8,
      'completedOrders': 45,
      'joinedDate': '2023-01-15T10:00:00Z',
    },
    'specialists': [
      {
        'id': 'specialist_1',
        'userId': 'user_1',
        'name': 'Анна Лебедева',
        'category': 'Фотограф',
        'experienceLevel': 'Профессионал',
        'yearsOfExperience': 8,
        'hourlyRate': 5000,
        'price': 25000,
        'rating': 4.9,
        'reviewCount': 156,
        'avatar':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=400',
          'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400',
          'https://images.unsplash.com/photo-1465495976277-4387d4b0e4a6?w=400',
        ],
        'description':
            'Профессиональный фотограф с 8-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
        'location': 'Москва',
        'isAvailable': true,
        'specialties': ['Свадьбы', 'Портреты', 'Семейные фотосессии'],
        'isVerified': true,
        'isPromoted': true,
      },
      {
        'id': 'specialist_2',
        'userId': 'user_2',
        'name': 'Михаил Соколов',
        'category': 'Видеограф',
        'experienceLevel': 'Профессионал',
        'yearsOfExperience': 6,
        'hourlyRate': 8000,
        'price': 35000,
        'rating': 4.8,
        'reviewCount': 89,
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400',
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400',
        ],
        'description':
            'Создаю качественные видеоролики для любых мероприятий. Современное оборудование и креативный подход.',
        'location': 'Санкт-Петербург',
        'isAvailable': true,
        'specialties': ['Свадебные фильмы', 'Корпоративы', 'Промо-ролики'],
        'isVerified': true,
        'isPromoted': false,
      },
      {
        'id': 'specialist_3',
        'userId': 'user_3',
        'name': 'Елена Волкова',
        'category': 'Организатор мероприятий',
        'experienceLevel': 'Эксперт',
        'yearsOfExperience': 12,
        'hourlyRate': 10000,
        'price': 50000,
        'rating': 4.9,
        'reviewCount': 203,
        'avatar':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1519167758481-83f1426e0b3b?w=400',
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400',
        ],
        'description':
            'Полная организация мероприятий от идеи до реализации. Индивидуальный подход к каждому клиенту.',
        'location': 'Москва',
        'isAvailable': true,
        'specialties': ['Свадьбы', 'Дни рождения', 'Корпоративы'],
        'isVerified': true,
        'isPromoted': true,
      },
      {
        'id': 'specialist_4',
        'userId': 'user_4',
        'name': 'Дмитрий Козлов',
        'category': 'DJ',
        'experienceLevel': 'Профессионал',
        'yearsOfExperience': 10,
        'hourlyRate': 6000,
        'price': 30000,
        'rating': 4.7,
        'reviewCount': 127,
        'avatar':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1571266028243-e4733b0b5a0e?w=400',
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        ],
        'description':
            'Профессиональный DJ с большим опытом работы на различных мероприятиях. Современная аппаратура.',
        'location': 'Екатеринбург',
        'isAvailable': true,
        'specialties': ['Свадьбы', 'Корпоративы', 'Клубы'],
        'isVerified': true,
        'isPromoted': false,
      },
      {
        'id': 'specialist_5',
        'userId': 'user_5',
        'name': 'Ольга Морозова',
        'category': 'Флорист',
        'experienceLevel': 'Профессионал',
        'yearsOfExperience': 7,
        'hourlyRate': 4000,
        'price': 20000,
        'rating': 4.8,
        'reviewCount': 94,
        'avatar':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1563241527-3004b7be99c3?w=400',
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        ],
        'description':
            'Создаю уникальные цветочные композиции для любых событий. Свежие цветы и креативные решения.',
        'location': 'Новосибирск',
        'isAvailable': true,
        'specialties': [
          'Свадебные букеты',
          'Оформление залов',
          'Цветочные композиции',
        ],
        'isVerified': true,
        'isPromoted': false,
      },
      {
        'id': 'specialist_6',
        'userId': 'user_6',
        'name': 'Александр Иванов',
        'category': 'Ведущий',
        'experienceLevel': 'Профессионал',
        'yearsOfExperience': 9,
        'hourlyRate': 7000,
        'price': 40000,
        'rating': 4.9,
        'reviewCount': 178,
        'avatar':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400',
          'https://images.unsplash.com/photo-1519167758481-83f1426e0b3b?w=400',
        ],
        'description':
            'Опытный ведущий мероприятий. Создаю незабываемую атмосферу для вашего праздника.',
        'location': 'Москва',
        'isAvailable': true,
        'specialties': ['Свадьбы', 'Корпоративы', 'Дни рождения'],
        'isVerified': true,
        'isPromoted': true,
      },
      {
        'id': 'specialist_7',
        'userId': 'user_7',
        'name': 'Мария Смирнова',
        'category': 'Визажист',
        'experienceLevel': 'Профессионал',
        'yearsOfExperience': 5,
        'hourlyRate': 3000,
        'price': 15000,
        'rating': 4.8,
        'reviewCount': 112,
        'avatar':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400',
          'https://images.unsplash.com/photo-1465495976277-4387d4b0e4a6?w=400',
        ],
        'description':
            'Профессиональный визажист. Создаю идеальный образ для любого события.',
        'location': 'Санкт-Петербург',
        'isAvailable': true,
        'specialties': ['Свадебный макияж', 'Вечерний макияж', 'Фотосессии'],
        'isVerified': true,
        'isPromoted': false,
      },
      {
        'id': 'specialist_8',
        'userId': 'user_8',
        'name': 'Игорь Петров',
        'category': 'Декор',
        'experienceLevel': 'Профессионал',
        'yearsOfExperience': 6,
        'hourlyRate': 5000,
        'price': 25000,
        'rating': 4.7,
        'reviewCount': 89,
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'portfolio': [
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=400',
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400',
        ],
        'description':
            'Создаю уникальные декорации для мероприятий. Индивидуальный подход к каждому проекту.',
        'location': 'Москва',
        'isAvailable': true,
        'specialties': [
          'Свадебный декор',
          'Корпоративный декор',
          'Детские праздники',
        ],
        'isVerified': true,
        'isPromoted': false,
      },
    ],
    'events': [
      {
        'id': 'event_1',
        'title': 'Свадьба Анны и Михаила',
        'description':
            'Романтическая свадьба в стиле прованс с французским шармом',
        'date': '2024-06-15T18:00:00Z',
        'location': 'Москва, ул. Тверская, 15',
        'price': 150000,
        'organizerId': 'user_3',
        'organizerName': 'Елена Волкова',
        'category': 'Свадьба',
        'status': 'active',
        'maxParticipants': 100,
        'currentParticipants': 75,
        'image':
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=400',
        'tags': ['прованс', 'свадьба', 'романтика'],
      },
      {
        'id': 'event_2',
        'title': 'Корпоратив IT-компании',
        'description':
            'Новогодний корпоратив для сотрудников с развлекательной программой',
        'date': '2024-12-28T19:00:00Z',
        'location': 'Санкт-Петербург, Невский проспект, 28',
        'price': 200000,
        'organizerId': 'user_3',
        'organizerName': 'Елена Волкова',
        'category': 'Корпоратив',
        'status': 'active',
        'maxParticipants': 150,
        'currentParticipants': 120,
        'image':
            'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400',
        'tags': ['корпоратив', 'новый год', 'it'],
      },
      {
        'id': 'event_3',
        'title': 'День рождения Марии',
        'description':
            'Празднование 25-летия в кругу друзей с тематической вечеринкой',
        'date': '2024-05-20T20:00:00Z',
        'location': 'Москва, ул. Арбат, 10',
        'price': 50000,
        'organizerId': 'user_3',
        'organizerName': 'Елена Волкова',
        'category': 'День рождения',
        'status': 'active',
        'maxParticipants': 30,
        'currentParticipants': 25,
        'image':
            'https://images.unsplash.com/photo-1519167758481-83f1426e0b3b?w=400',
        'tags': ['день рождения', 'вечеринка', 'друзья'],
      },
      {
        'id': 'event_4',
        'title': 'Выпускной вечер',
        'description':
            'Торжественное мероприятие для выпускников с церемонией вручения дипломов',
        'date': '2024-07-10T17:00:00Z',
        'location': 'Екатеринбург, ул. Ленина, 5',
        'price': 100000,
        'organizerId': 'user_3',
        'organizerName': 'Елена Волкова',
        'category': 'Выпускной',
        'status': 'active',
        'maxParticipants': 200,
        'currentParticipants': 180,
        'image':
            'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400',
        'tags': ['выпускной', 'дипломы', 'торжество'],
      },
      {
        'id': 'event_5',
        'title': 'Детский праздник',
        'description':
            'Весёлый день рождения для ребёнка с аниматорами и конкурсами',
        'date': '2024-04-15T15:00:00Z',
        'location': 'Новосибирск, ул. Красный проспект, 20',
        'price': 30000,
        'organizerId': 'user_3',
        'organizerName': 'Елена Волкова',
        'category': 'Детский праздник',
        'status': 'active',
        'maxParticipants': 20,
        'currentParticipants': 15,
        'image':
            'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400',
        'tags': ['дети', 'аниматоры', 'конкурсы'],
      },
    ],
    'reviews': [
      {
        'id': 'review_1',
        'specialistId': 'specialist_1',
        'customerId': 'user_current',
        'customerName': 'Анна Петрова',
        'rating': 5,
        'text':
            'Анна - потрясающий фотограф! Снимки получились просто волшебными. Очень рекомендую!',
        'date': '2024-01-15T10:00:00Z',
        'serviceTags': ['Свадьба'],
        'eventType': 'Свадьба',
      },
      {
        'id': 'review_2',
        'specialistId': 'specialist_2',
        'customerId': 'user_9',
        'customerName': 'Александр Иванов',
        'rating': 5,
        'text':
            'Михаил создал невероятный свадебный фильм. Качество на высшем уровне!',
        'date': '2024-01-10T14:30:00Z',
        'serviceTags': ['Свадьба'],
        'eventType': 'Свадьба',
      },
      {
        'id': 'review_3',
        'specialistId': 'specialist_3',
        'customerId': 'user_10',
        'customerName': 'Мария Петрова',
        'rating': 4,
        'text':
            'Елена отлично организовала наш корпоратив. Всё прошло без сучка и задоринки.',
        'date': '2024-01-08T16:45:00Z',
        'serviceTags': ['Корпоратив'],
        'eventType': 'Корпоратив',
      },
      {
        'id': 'review_4',
        'specialistId': 'specialist_4',
        'customerId': 'user_11',
        'customerName': 'Дмитрий Козлов',
        'rating': 5,
        'text':
            'Дмитрий - настоящий профессионал! Музыка была отличная, все танцевали до утра.',
        'date': '2024-01-05T20:15:00Z',
        'serviceTags': ['Свадьба'],
        'eventType': 'Свадьба',
      },
      {
        'id': 'review_5',
        'specialistId': 'specialist_5',
        'customerId': 'user_12',
        'customerName': 'Анна Волкова',
        'rating': 5,
        'text':
            'Ольга создала потрясающие цветочные композиции. Букет был просто идеальным!',
        'date': '2024-01-03T12:20:00Z',
        'serviceTags': ['Свадьба'],
        'eventType': 'Свадьба',
      },
    ],
    'feedPosts': [
      {
        'id': 'post_1',
        'authorId': 'specialist_1',
        'content': 'Новая фотосессия в осеннем парке 🌿✨',
        'type': 'image',
        'createdAt': '2024-01-20T14:30:00Z',
        'media': [
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=400',
          'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400',
        ],
        'likesCount': 45,
        'commentsCount': 12,
        'sharesCount': 8,
        'tags': ['фотография', 'осень', 'портрет'],
      },
      {
        'id': 'post_2',
        'authorId': 'specialist_2',
        'content': 'Свадебный фильм готов! Посмотрите трейлер 🎬💕',
        'type': 'video',
        'createdAt': '2024-01-19T16:45:00Z',
        'media': [
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400',
        ],
        'likesCount': 78,
        'commentsCount': 23,
        'sharesCount': 15,
        'tags': ['видео', 'свадьба', 'фильм'],
      },
      {
        'id': 'post_3',
        'authorId': 'specialist_3',
        'content':
            'Организовала потрясающий корпоратив! Все остались довольны 🎉',
        'type': 'image',
        'createdAt': '2024-01-18T11:20:00Z',
        'media': [
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400',
          'https://images.unsplash.com/photo-1519167758481-83f1426e0b3b?w=400',
        ],
        'likesCount': 32,
        'commentsCount': 8,
        'sharesCount': 5,
        'tags': ['корпоратив', 'организация', 'мероприятие'],
      },
      {
        'id': 'post_4',
        'authorId': 'specialist_4',
        'content': 'Новый микс для свадебной церемонии 🎵💒',
        'type': 'audio',
        'createdAt': '2024-01-17T19:15:00Z',
        'media': <String>[],
        'likesCount': 56,
        'commentsCount': 18,
        'sharesCount': 12,
        'tags': ['музыка', 'свадьба', 'микс'],
      },
      {
        'id': 'post_5',
        'authorId': 'specialist_5',
        'content': 'Весенние букеты уже готовы! 🌸🌺',
        'type': 'image',
        'createdAt': '2024-01-16T09:30:00Z',
        'media': [
          'https://images.unsplash.com/photo-1563241527-3004b7be99c3?w=400',
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        ],
        'likesCount': 67,
        'commentsCount': 15,
        'sharesCount': 9,
        'tags': ['цветы', 'весна', 'букеты'],
      },
    ],
    'ideas': [
      {
        'id': 'idea_1',
        'authorId': 'user_current',
        'title': 'Свадьба в стиле прованс',
        'description':
            'Романтическая свадьба с французским шармом. Пастельные тона, лаванда и винтажные детали.',
        'type': 'wedding',
        'createdAt': '2024-01-15T10:00:00Z',
        'media': [
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=400',
          'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400',
        ],
        'likesCount': 67,
        'commentsCount': 15,
        'sharesCount': 12,
        'tags': ['прованс', 'свадьба', 'романтика'],
        'budget': 200000,
        'location': 'Москва',
      },
      {
        'id': 'idea_2',
        'authorId': 'user_13',
        'title': 'Корпоратив в стиле 80-х',
        'description':
            'Ретро-вечеринка с музыкой 80-х, неоновыми цветами и диско-атмосферой.',
        'type': 'corporate',
        'createdAt': '2024-01-14T15:30:00Z',
        'media': [
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400',
        ],
        'likesCount': 43,
        'commentsCount': 8,
        'sharesCount': 6,
        'tags': ['80-е', 'корпоратив', 'ретро'],
        'budget': 150000,
        'location': 'Санкт-Петербург',
      },
      {
        'id': 'idea_3',
        'authorId': 'user_14',
        'title': 'Детский день рождения в стиле принцесс',
        'description':
            'Волшебная вечеринка для маленьких принцесс с замком, коронами и магией.',
        'type': 'birthday',
        'createdAt': '2024-01-13T12:45:00Z',
        'media': [
          'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400',
          'https://images.unsplash.com/photo-1465495976277-4387d4b0e4a6?w=400',
        ],
        'likesCount': 89,
        'commentsCount': 22,
        'sharesCount': 18,
        'tags': ['принцессы', 'дети', 'волшебство'],
        'budget': 50000,
        'location': 'Москва',
      },
      {
        'id': 'idea_4',
        'authorId': 'user_15',
        'title': 'Свадьба в стиле бохо',
        'description':
            'Свободная и романтичная свадьба в стиле бохо с натуральными материалами.',
        'type': 'wedding',
        'createdAt': '2024-01-12T16:20:00Z',
        'media': [
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=400',
        ],
        'likesCount': 54,
        'commentsCount': 11,
        'sharesCount': 7,
        'tags': ['бохо', 'свадьба', 'натуральность'],
        'budget': 180000,
        'location': 'Екатеринбург',
      },
      {
        'id': 'idea_5',
        'authorId': 'user_16',
        'title': 'Корпоратив в стиле Гарри Поттера',
        'description':
            'Магический корпоратив с элементами вселенной Гарри Поттера.',
        'type': 'corporate',
        'createdAt': '2024-01-11T14:10:00Z',
        'media': [
          'https://images.unsplash.com/photo-1519167758481-83f1426e0b3b?w=400',
        ],
        'likesCount': 76,
        'commentsCount': 19,
        'sharesCount': 14,
        'tags': ['гарри поттер', 'магия', 'корпоратив'],
        'budget': 120000,
        'location': 'Новосибирск',
      },
    ],
    'chats': [
      {
        'id': 'chat_1',
        'participants': ['user_current', 'specialist_1'],
        'lastMessage': {
          'text': 'Спасибо за отличную работу!',
          'senderId': 'user_current',
          'timestamp': '2024-01-20T15:30:00Z',
        },
        'unreadCount': 0,
        'specialistName': 'Анна Лебедева',
        'specialistAvatar':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
      },
      {
        'id': 'chat_2',
        'participants': ['user_current', 'specialist_3'],
        'lastMessage': {
          'text': 'Когда можем обсудить детали?',
          'senderId': 'specialist_3',
          'timestamp': '2024-01-19T11:45:00Z',
        },
        'unreadCount': 1,
        'specialistName': 'Елена Волкова',
        'specialistAvatar':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      },
      {
        'id': 'chat_3',
        'participants': ['user_current', 'specialist_4'],
        'lastMessage': {
          'text': 'Отлично, жду вашего ответа!',
          'senderId': 'specialist_4',
          'timestamp': '2024-01-18T16:20:00Z',
        },
        'unreadCount': 0,
        'specialistName': 'Дмитрий Козлов',
        'specialistAvatar':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      },
      {
        'id': 'chat_4',
        'participants': ['user_current', 'specialist_5'],
        'lastMessage': {
          'text': 'Букет будет готов к пятнице',
          'senderId': 'specialist_5',
          'timestamp': '2024-01-17T09:15:00Z',
        },
        'unreadCount': 2,
        'specialistName': 'Ольга Морозова',
        'specialistAvatar':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      },
      {
        'id': 'chat_5',
        'participants': ['user_current', 'specialist_6'],
        'lastMessage': {
          'text': 'Спасибо за заказ!',
          'senderId': 'user_current',
          'timestamp': '2024-01-16T14:30:00Z',
        },
        'unreadCount': 0,
        'specialistName': 'Александр Иванов',
        'specialistAvatar':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      },
    ],
    'orders': [
      {
        'id': 'order_1',
        'customerId': 'user_current',
        'specialistId': 'specialist_1',
        'title': 'Свадебная фотосъёмка',
        'description': 'Полный пакет свадебной фотосъёмки',
        'status': 'completed',
        'price': 25000,
        'createdAt': '2024-01-10T10:00:00Z',
        'completedAt': '2024-01-15T18:00:00Z',
        'rating': 5,
        'review': 'Отличная работа!',
      },
      {
        'id': 'order_2',
        'customerId': 'user_current',
        'specialistId': 'specialist_3',
        'title': 'Организация корпоратива',
        'description': 'Новогодний корпоратив на 50 человек',
        'status': 'in_progress',
        'price': 50000,
        'createdAt': '2024-01-12T14:30:00Z',
        'eventDate': '2024-12-28T19:00:00Z',
      },
      {
        'id': 'order_3',
        'customerId': 'user_current',
        'specialistId': 'specialist_4',
        'title': 'DJ на свадьбу',
        'description': 'Музыкальное сопровождение свадебного торжества',
        'status': 'pending',
        'price': 30000,
        'createdAt': '2024-01-14T16:45:00Z',
        'eventDate': '2024-06-15T18:00:00Z',
      },
      {
        'id': 'order_4',
        'customerId': 'user_current',
        'specialistId': 'specialist_5',
        'title': 'Свадебный букет',
        'description': 'Букет невесты в стиле прованс',
        'status': 'pending',
        'price': 20000,
        'createdAt': '2024-01-16T11:20:00Z',
        'eventDate': '2024-06-15T16:00:00Z',
      },
      {
        'id': 'order_5',
        'customerId': 'user_17',
        'specialistId': 'user_current',
        'title': 'Фотосессия для портфолио',
        'description': 'Профессиональная фотосессия для портфолио модели',
        'status': 'pending',
        'price': 15000,
        'createdAt': '2024-01-18T13:15:00Z',
        'eventDate': '2024-02-15T14:00:00Z',
      },
    ],
  };

  /// Сохраняет тестовые данные в локальный файл
  static Future<void> seedLocalData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dataFileName');

      final jsonString = jsonEncode(_testData);
      await file.writeAsString(jsonString);

      debugPrint('✅ Локальные тестовые данные сохранены: ${file.path}');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения локальных данных: $e');
    }
  }

  /// Загружает тестовые данные из локального файла
  static Future<Map<String, dynamic>?> loadLocalData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dataFileName');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint('✅ Локальные тестовые данные загружены');
        return data;
      } else {
        debugPrint('⚠️ Файл локальных данных не найден');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки локальных данных: $e');
      return null;
    }
  }

  /// Проверяет наличие локальных данных
  static Future<bool> hasLocalData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dataFileName');
      return await file.exists();
    } catch (e) {
      debugPrint('❌ Ошибка проверки локальных данных: $e');
      return false;
    }
  }

  /// Очищает локальные данные
  static Future<void> clearLocalData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_dataFileName');

      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ Локальные тестовые данные очищены');
      }
    } catch (e) {
      debugPrint('❌ Ошибка очистки локальных данных: $e');
    }
  }
}
