import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist.dart';

/// Сервис для создания тестовых данных в dev/debug режиме
class DevSeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Проверка, доступен ли сидинг (только в debug режиме)
  bool get isSeedingAvailable => kDebugMode;

  /// Создание полного набора тестовых данных
  Future<void> seedTestData() async {
    if (!isSeedingAvailable) {
      throw Exception('Сидинг доступен только в debug режиме');
    }

    try {
      // Проверяем, не были ли уже созданы тестовые данные
      final existingData = await _checkExistingTestData();
      if (existingData) {
        debugPrint('Тестовые данные уже существуют. Пропускаем сидинг.');
        return;
      }

      debugPrint('Начинаем создание тестовых данных...');

      // Создаем специалистов
      final specialistIds = await _createTestSpecialists();
      debugPrint('Создано ${specialistIds.length} специалистов');

      // Создаем посты
      await _createTestPosts(specialistIds);
      debugPrint('Созданы тестовые посты');

      // Создаем сторис
      await _createTestStories(specialistIds);
      debugPrint('Созданы тестовые сторис');

      // Создаем отзывы
      await _createTestReviews(specialistIds);
      debugPrint('Созданы тестовые отзывы');

      // Создаем бронирования
      await _createTestBookings(specialistIds);
      debugPrint('Созданы тестовые бронирования');

      // Добавляем метку о создании тестовых данных
      await _markDataAsSeeded();

      debugPrint('✅ Тестовые данные успешно созданы!');
    } catch (e) {
      debugPrint('❌ Ошибка создания тестовых данных: $e');
      rethrow;
    }
  }

  /// Проверка существования тестовых данных
  Future<bool> _checkExistingTestData() async {
    final seededDoc = await _firestore.collection('system').doc('seeded_data').get();

    return seededDoc.exists && seededDoc.data()?['seededAt'] != null;
  }

  /// Отметка о создании тестовых данных
  Future<void> _markDataAsSeeded() async {
    await _firestore.collection('system').doc('seeded_data').set({
      'seededAt': Timestamp.fromDate(DateTime.now()),
      'seededBy': _auth.currentUser?.uid ?? 'system',
      'version': '1.0',
    });
  }

  /// Создание тестовых специалистов
  Future<List<String>> _createTestSpecialists() async {
    final specialists = [
      _createPhotographer(),
      _createVideographer(),
      _createDJ(),
      _createHost(),
      _createDecorator(),
      _createMusician(),
      _createCaterer(),
      _createAnimator(),
      _createFlorist(),
      _createMakeupArtist(),
    ];

    final specialistIds = <String>[];
    final batch = _firestore.batch();

    for (final specialist in specialists) {
      final docRef = _firestore.collection('specialists').doc(specialist.id);
      batch.set(docRef, specialist.toMap());
      specialistIds.add(specialist.id);
    }

    await batch.commit();
    return specialistIds;
  }

  /// Создание фотографа
  Specialist _createPhotographer() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_photographer_1',
      userId: 'test_user_photographer',
      name: 'Анна Фотограф',
      description:
          'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
      bio: 'Люблю создавать красивые моменты и запечатлевать эмоции. Работаю в Москве и области.',
      category: SpecialistCategory.photographer,
      experienceLevel: ExperienceLevel.intermediate,
      yearsOfExperience: 5,
      hourlyRate: 3000,
      price: 3000,
      location: 'Москва',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.8,
      reviewCount: 127,
      createdAt: now.subtract(const Duration(days: 365)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (999) 123-45-67',
        'Email': 'anna.photographer@example.com',
        'Instagram': '@anna_photographer',
        'VK': 'vk.com/anna_photographer',
      },
      servicesWithPrices: const {
        'Свадебная фотосессия': 50000.0,
        'Портретная фотосессия': 15000.0,
        'Семейная фотосессия': 20000.0,
        'Корпоративная съемка': 25000.0,
        'Love Story': 12000.0,
      },
    );
  }

  /// Создание видеографа
  Specialist _createVideographer() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_videographer_1',
      userId: 'test_user_videographer',
      name: 'Максим Видеограф',
      description:
          'Креативный видеограф и монтажер. Создаю запоминающиеся видео для любых событий.',
      bio:
          '5 лет в индустрии видео. Работаю с современным оборудованием и программным обеспечением.',
      category: SpecialistCategory.videographer,
      experienceLevel: ExperienceLevel.advanced,
      yearsOfExperience: 5,
      hourlyRate: 4000,
      price: 4000,
      location: 'Санкт-Петербург',
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.9,
      reviewCount: 89,
      createdAt: now.subtract(const Duration(days: 200)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (812) 555-12-34',
        'Email': 'max.videographer@example.com',
        'Instagram': '@max_videographer',
        'Telegram': '@max_video',
      },
      servicesWithPrices: const {
        'Свадебное видео': 80000.0,
        'Корпоративное видео': 60000.0,
        'Промо-ролик': 40000.0,
        'Монтаж видео': 15000.0,
        'Аэросъемка': 25000.0,
      },
    );
  }

  /// Создание DJ
  Specialist _createDJ() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_dj_1',
      userId: 'test_user_dj',
      name: 'DJ Алексей',
      description:
          'Профессиональный DJ с 8-летним опытом. Специализируюсь на свадьбах и корпоративных мероприятиях.',
      bio: 'Создаю атмосферу праздника с помощью качественной музыки и современного оборудования.',
      category: SpecialistCategory.dj,
      experienceLevel: ExperienceLevel.advanced,
      yearsOfExperience: 8,
      hourlyRate: 5000,
      price: 5000,
      location: 'Москва',
      imageUrl:
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.7,
      reviewCount: 156,
      createdAt: now.subtract(const Duration(days: 500)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 123-45-67',
        'Email': 'dj.alexey@example.com',
        'Instagram': '@dj_alexey',
        'VK': 'vk.com/dj_alexey',
      },
      servicesWithPrices: const {
        'Свадебный DJ': 40000.0,
        'Корпоративный DJ': 35000.0,
        'День рождения': 25000.0,
        'Клубный вечер': 30000.0,
        'Аренда оборудования': 15000.0,
      },
    );
  }

  /// Создание ведущего
  Specialist _createHost() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_host_1',
      userId: 'test_user_host',
      name: 'Ведущий Дмитрий',
      description:
          'Опытный ведущий мероприятий. Специализируюсь на свадьбах, корпоративах и детских праздниках.',
      bio:
          'Создаю незабываемые моменты и веселье для всех гостей. Индивидуальный подход к каждому мероприятию.',
      category: SpecialistCategory.host,
      experienceLevel: ExperienceLevel.expert,
      yearsOfExperience: 10,
      hourlyRate: 6000,
      price: 6000,
      location: 'Москва',
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.9,
      reviewCount: 203,
      createdAt: now.subtract(const Duration(days: 800)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 987-65-43',
        'Email': 'host.dmitry@example.com',
        'Instagram': '@host_dmitry',
        'VK': 'vk.com/host_dmitry',
      },
      servicesWithPrices: const {
        'Свадебный ведущий': 60000.0,
        'Корпоративный ведущий': 50000.0,
        'Детский праздник': 30000.0,
        'День рождения': 40000.0,
        'Консультация': 5000.0,
      },
    );
  }

  /// Создание декоратора
  Specialist _createDecorator() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_decorator_1',
      userId: 'test_user_decorator',
      name: 'Елена Декоратор',
      description:
          'Креативный декоратор с 6-летним опытом. Создаю уникальные интерьеры для любых мероприятий.',
      bio:
          'Превращаю обычные пространства в волшебные места. Работаю с любыми стилями и бюджетами.',
      category: SpecialistCategory.decorator,
      experienceLevel: ExperienceLevel.intermediate,
      yearsOfExperience: 6,
      hourlyRate: 2500,
      price: 2500,
      location: 'Москва',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.6,
      reviewCount: 94,
      createdAt: now.subtract(const Duration(days: 300)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 111-22-33',
        'Email': 'elena.decorator@example.com',
        'Instagram': '@elena_decorator',
      },
      servicesWithPrices: const {
        'Свадебное оформление': 80000.0,
        'Корпоративное оформление': 60000.0,
        'Детский праздник': 30000.0,
        'День рождения': 40000.0,
        'Консультация': 3000.0,
      },
    );
  }

  /// Создание музыканта
  Specialist _createMusician() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_musician_1',
      userId: 'test_user_musician',
      name: 'Ансамбль "Мелодия"',
      description:
          'Профессиональный музыкальный ансамбль. Играем на свадьбах, корпоративах и частных мероприятиях.',
      bio:
          'Классическая и современная музыка. Живое исполнение создает особую атмосферу праздника.',
      category: SpecialistCategory.musician,
      experienceLevel: ExperienceLevel.advanced,
      yearsOfExperience: 12,
      hourlyRate: 8000,
      price: 8000,
      location: 'Москва',
      imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
      isVerified: true,
      rating: 4.8,
      reviewCount: 167,
      createdAt: now.subtract(const Duration(days: 600)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 444-55-66',
        'Email': 'melody.ensemble@example.com',
        'Instagram': '@melody_ensemble',
      },
      servicesWithPrices: const {
        'Свадебная музыка': 100000.0,
        'Корпоративная музыка': 80000.0,
        'День рождения': 60000.0,
        'Романтический ужин': 40000.0,
        'Концерт': 120000.0,
      },
    );
  }

  /// Создание кейтеринга
  Specialist _createCaterer() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_caterer_1',
      userId: 'test_user_caterer',
      name: 'Кейтеринг "Вкус"',
      description: 'Профессиональный кейтеринг для любых мероприятий. Качественная еда и сервис.',
      bio:
          'Готовим вкусную еду и обеспечиваем отличный сервис. Работаем с любыми диетическими требованиями.',
      category: SpecialistCategory.caterer,
      experienceLevel: ExperienceLevel.expert,
      yearsOfExperience: 15,
      hourlyRate: 2000,
      price: 2000,
      location: 'Москва',
      imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=400&fit=crop',
      isVerified: true,
      rating: 4.9,
      reviewCount: 234,
      createdAt: now.subtract(const Duration(days: 1000)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 777-88-99',
        'Email': 'catering.vkus@example.com',
        'Instagram': '@catering_vkus',
      },
      servicesWithPrices: const {
        'Свадебный банкет': 150000.0,
        'Корпоративный обед': 80000.0,
        'Фуршет': 60000.0,
        'День рождения': 100000.0,
        'Кофе-брейк': 30000.0,
      },
    );
  }

  /// Создание аниматора
  Specialist _createAnimator() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_animator_1',
      userId: 'test_user_animator',
      name: 'Аниматор Мария',
      description: 'Опытный аниматор для детских праздников. Создаю веселье и радость для детей.',
      bio:
          'Специализируюсь на детских праздниках. Игры, конкурсы, шоу-программы для любого возраста.',
      category: SpecialistCategory.animator,
      experienceLevel: ExperienceLevel.intermediate,
      yearsOfExperience: 4,
      hourlyRate: 2000,
      price: 2000,
      location: 'Москва',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.7,
      reviewCount: 78,
      createdAt: now.subtract(const Duration(days: 150)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 333-44-55',
        'Email': 'animator.maria@example.com',
        'Instagram': '@animator_maria',
      },
      servicesWithPrices: const {
        'Детский день рождения': 25000.0,
        'Новогодний праздник': 30000.0,
        'Выпускной': 35000.0,
        'Летний лагерь': 20000.0,
        'Семейный праздник': 20000.0,
      },
    );
  }

  /// Создание флориста
  Specialist _createFlorist() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_florist_1',
      userId: 'test_user_florist',
      name: 'Флорист Ольга',
      description: 'Профессиональный флорист. Создаю красивые букеты и цветочные композиции.',
      bio: 'Свежие цветы, креативные композиции, индивидуальный подход к каждому заказу.',
      category: SpecialistCategory.florist,
      experienceLevel: ExperienceLevel.intermediate,
      yearsOfExperience: 7,
      hourlyRate: 1500,
      price: 1500,
      location: 'Москва',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.8,
      reviewCount: 112,
      createdAt: now.subtract(const Duration(days: 400)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 222-33-44',
        'Email': 'florist.olga@example.com',
        'Instagram': '@florist_olga',
      },
      servicesWithPrices: const {
        'Свадебный букет': 15000.0,
        'Цветочное оформление': 50000.0,
        'Букет на день рождения': 5000.0,
        'Корпоративные цветы': 20000.0,
        'Консультация': 2000.0,
      },
    );
  }

  /// Создание визажиста
  Specialist _createMakeupArtist() {
    final now = DateTime.now();
    return Specialist(
      id: 'test_makeup_1',
      userId: 'test_user_makeup',
      name: 'Визажист Катя',
      description: 'Профессиональный визажист. Создаю идеальный образ для любого мероприятия.',
      bio:
          'Специализируюсь на свадебном макияже и макияже для фотосессий. Работаю с любыми типами кожи.',
      category: SpecialistCategory.makeup,
      experienceLevel: ExperienceLevel.advanced,
      yearsOfExperience: 8,
      hourlyRate: 3000,
      price: 3000,
      location: 'Москва',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
      isVerified: true,
      rating: 4.9,
      reviewCount: 145,
      createdAt: now.subtract(const Duration(days: 350)),
      updatedAt: now,
      contacts: const {
        'Телефон': '+7 (495) 666-77-88',
        'Email': 'makeup.kate@example.com',
        'Instagram': '@makeup_kate',
      },
      servicesWithPrices: const {
        'Свадебный макияж': 15000.0,
        'Макияж для фотосессии': 8000.0,
        'Вечерний макияж': 6000.0,
        'Дневной макияж': 4000.0,
        'Консультация': 2000.0,
      },
    );
  }

  /// Создание тестовых постов
  Future<void> _createTestPosts(List<String> specialistIds) async {
    final posts = [
      {
        'specialistId': specialistIds[0], // Фотограф
        'text':
            'Прекрасная свадебная церемония в загородном доме! 🌸✨\n\nСпасибо Ане и Дмитрию за доверие. Было очень волнительно запечатлеть этот особенный день! 💕\n\n#свадьба #фотограф #москва #свадебнаяфотография',
        'mediaUrls': [
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&h=800&fit=crop',
          'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=800&h=800&fit=crop',
          'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=800&h=800&fit=crop',
        ],
      },
      {
        'specialistId': specialistIds[1], // Видеограф
        'text':
            'Новый свадебный фильм готов! 🎥💕\n\nЭмоции, слезы радости, первый танец - все это теперь навсегда запечатлено в видео! ✨\n\n#свадьба #видеограф #свадебноевидео #эмоции',
        'mediaUrls': [
          'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=800&h=800&fit=crop',
        ],
      },
      {
        'specialistId': specialistIds[2], // DJ
        'text':
            'Отличная вечеринка вчера! 🎧🎉\n\nТанцпол был полон всю ночь! Спасибо всем за энергию и позитив! 🕺💃\n\n#dj #вечеринка #музыка #танцы',
        'mediaUrls': [
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=800&fit=crop',
        ],
      },
    ];

    final batch = _firestore.batch();

    for (var i = 0; i < posts.length; i++) {
      final postData = posts[i];
      final postId = 'test_post_${i + 1}';
      final docRef = _firestore.collection('posts').doc(postId);

      batch.set(docRef, {
        'id': postId,
        'specialistId': postData['specialistId'],
        'text': postData['text'],
        'mediaUrls': postData['mediaUrls'],
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i))),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'createdBy': 'dev_seed_service',
          'isTestData': true,
        },
      });
    }

    await batch.commit();
  }

  /// Создание тестовых сторис
  Future<void> _createTestStories(List<String> specialistIds) async {
    final stories = [
      {
        'specialistId': specialistIds[0], // Фотограф
        'mediaUrl':
            'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=600&fit=crop',
        'text': 'За кулисами свадебной съемки ✨',
      },
      {
        'specialistId': specialistIds[1], // Видеограф
        'mediaUrl':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop&crop=face',
        'text': 'Новая студия в центре Москвы! 📸',
      },
      {
        'specialistId': specialistIds[2], // DJ
        'mediaUrl':
            'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=600&fit=crop',
        'text': 'Готовлюсь к вечернему сету 🎧',
      },
    ];

    final batch = _firestore.batch();

    for (var i = 0; i < stories.length; i++) {
      final storyData = stories[i];
      final storyId = 'test_story_${i + 1}';
      final docRef = _firestore.collection('stories').doc(storyId);

      batch.set(docRef, {
        'id': storyId,
        'specialistId': storyData['specialistId'],
        'mediaUrl': storyData['mediaUrl'],
        'text': storyData['text'],
        'views': 0,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: i))),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        'metadata': {
          'createdBy': 'dev_seed_service',
          'isTestData': true,
        },
      });
    }

    await batch.commit();
  }

  /// Создание тестовых отзывов
  Future<void> _createTestReviews(List<String> specialistIds) async {
    final reviews = [
      {
        'specialistId': specialistIds[0], // Фотограф
        'customerName': 'Анна и Дмитрий',
        'rating': 5,
        'text':
            'Анна - потрясающий фотограф! Снимки получились просто волшебными. Очень рекомендую!',
      },
      {
        'specialistId': specialistIds[1], // Видеограф
        'customerName': 'Мария',
        'rating': 5,
        'text':
            'Максим создал невероятное свадебное видео! Каждый раз пересматриваем с удовольствием.',
      },
      {
        'specialistId': specialistIds[2], // DJ
        'customerName': 'Александр',
        'rating': 4,
        'text': 'Отличный DJ! Музыка была на высоте, все гости танцевали до утра.',
      },
    ];

    final batch = _firestore.batch();

    for (var i = 0; i < reviews.length; i++) {
      final reviewData = reviews[i];
      final reviewId = 'test_review_${i + 1}';
      final docRef = _firestore.collection('reviews').doc(reviewId);

      batch.set(docRef, {
        'id': reviewId,
        'specialistId': reviewData['specialistId'],
        'customerName': reviewData['customerName'],
        'rating': reviewData['rating'],
        'text': reviewData['text'],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i + 1))),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'createdBy': 'dev_seed_service',
          'isTestData': true,
        },
      });
    }

    await batch.commit();
  }

  /// Создание тестовых бронирований
  Future<void> _createTestBookings(List<String> specialistIds) async {
    final bookings = [
      {
        'specialistId': specialistIds[0], // Фотограф
        'customerName': 'Елена Петрова',
        'service': 'Свадебная фотосессия',
        'date': DateTime.now().add(const Duration(days: 30)),
        'status': 'confirmed',
      },
      {
        'specialistId': specialistIds[1], // Видеограф
        'customerName': 'Иван Сидоров',
        'service': 'Свадебное видео',
        'date': DateTime.now().add(const Duration(days: 45)),
        'status': 'pending',
      },
      {
        'specialistId': specialistIds[2], // DJ
        'customerName': 'Ольга Козлова',
        'service': 'Свадебный DJ',
        'date': DateTime.now().add(const Duration(days: 60)),
        'status': 'confirmed',
      },
    ];

    final batch = _firestore.batch();

    for (var i = 0; i < bookings.length; i++) {
      final bookingData = bookings[i];
      final bookingId = 'test_booking_${i + 1}';
      final docRef = _firestore.collection('bookings').doc(bookingId);

      batch.set(docRef, {
        'id': bookingId,
        'specialistId': bookingData['specialistId'],
        'customerName': bookingData['customerName'],
        'service': bookingData['service'],
        'date': Timestamp.fromDate(bookingData['date']! as DateTime),
        'status': bookingData['status'],
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: i + 2))),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'createdBy': 'dev_seed_service',
          'isTestData': true,
        },
      });
    }

    await batch.commit();
  }

  /// Очистка всех тестовых данных
  Future<void> clearTestData() async {
    if (!isSeedingAvailable) {
      throw Exception('Очистка доступна только в debug режиме');
    }

    try {
      debugPrint('Начинаем очистку тестовых данных...');

      // Удаляем тестовых специалистов
      final specialistsQuery = await _firestore
          .collection('specialists')
          .where('userId', isGreaterThanOrEqualTo: 'test_user_')
          .get();

      final batch = _firestore.batch();
      for (final doc in specialistsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем тестовые посты
      final postsQuery =
          await _firestore.collection('posts').where('metadata.isTestData', isEqualTo: true).get();

      for (final doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем тестовые сторис
      final storiesQuery = await _firestore
          .collection('stories')
          .where('metadata.isTestData', isEqualTo: true)
          .get();

      for (final doc in storiesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем тестовые отзывы
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('metadata.isTestData', isEqualTo: true)
          .get();

      for (final doc in reviewsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем тестовые бронирования
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('metadata.isTestData', isEqualTo: true)
          .get();

      for (final doc in bookingsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем метку о создании тестовых данных
      await _firestore.collection('system').doc('seeded_data').delete();

      await batch.commit();
      debugPrint('✅ Тестовые данные успешно очищены!');
    } catch (e) {
      debugPrint('❌ Ошибка очистки тестовых данных: $e');
      rethrow;
    }
  }
}
