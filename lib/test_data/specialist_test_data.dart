import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/models/price_range.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/services/specialist_service.dart';

class SpecialistTestData {
  static final SpecialistService _specialistService = SpecialistService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать тестовых специалистов
  static Future<void> createTestSpecialists() async {
    try {
      final specialists = _generateTestSpecialists();

      for (final specialist in specialists) {
        await _specialistService.createSpecialist(specialist);
        print('Создан специалист: ${specialist.name}');
      }

      print('Создано ${specialists.length} тестовых специалистов');
    } catch (e) {
      print('Ошибка создания тестовых специалистов: $e');
    }
  }

  /// Сгенерировать тестовых специалистов
  static List<Specialist> _generateTestSpecialists() {
    final now = DateTime.now();

    return [
      // Фотографы
      Specialist(
        id: 'photographer_1',
        userId: 'user_1',
        name: 'Анна Петрова',
        description:
            'Профессиональный фотограф с 8-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.expert,
        yearsOfExperience: 8,
        hourlyRate: 5000,
        price: 5000,
        rating: 4.8,
        reviewCount: 127,
        city: 'Москва',
        location: 'Москва, Центральный округ',
        services: const [
          'Свадебная фотосъемка',
          'Портретная фотосъемка',
          'Семейная фотосъемка',
          'Корпоративная фотосъемка',
        ],
        equipment: const [
          'Canon EOS R5',
          'Canon EF 24-70mm f/2.8L',
          'Canon EF 85mm f/1.4L',
          'Студийное освещение',
        ],
        languages: const ['Русский', 'Английский'],
        isVerified: true,
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 3000, maxPrice: 8000),
        avgPriceByService: const {
          'Свадебная фотосъемка': 15000,
          'Портретная фотосъемка': 5000,
          'Семейная фотосъемка': 8000,
          'Корпоративная фотосъемка': 12000,
        },
        availableDates: [
          now.add(const Duration(days: 1)),
          now.add(const Duration(days: 2)),
          now.add(const Duration(days: 3)),
          now.add(const Duration(days: 5)),
          now.add(const Duration(days: 7)),
          now.add(const Duration(days: 10)),
        ],
        busyDates: [
          now.add(const Duration(days: 4)),
          now.add(const Duration(days: 6)),
          now.add(const Duration(days: 8)),
        ],
      ),

      Specialist(
        id: 'photographer_2',
        userId: 'user_2',
        name: 'Михаил Соколов',
        description:
            'Фотограф-документалист, работаю в жанре репортажной и событийной фотографии.',
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 5,
        hourlyRate: 3500,
        price: 3500,
        rating: 4.6,
        reviewCount: 89,
        city: 'Санкт-Петербург',
        location: 'Санкт-Петербург, Центральный район',
        services: const [
          'Репортажная фотосъемка',
          'Событийная фотосъемка',
          'Уличная фотография',
        ],
        equipment: const [
          'Sony A7R IV',
          'Sony FE 24-70mm f/2.8 GM',
          'Sony FE 70-200mm f/2.8 GM',
        ],
        isVerified: true,
        isOnline: false,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 2500, maxPrice: 5000),
        availableDates: [
          now.add(const Duration(days: 2)),
          now.add(const Duration(days: 4)),
          now.add(const Duration(days: 6)),
          now.add(const Duration(days: 9)),
          now.add(const Duration(days: 11)),
        ],
        busyDates: [
          now.add(const Duration(days: 1)),
          now.add(const Duration(days: 3)),
          now.add(const Duration(days: 5)),
        ],
      ),

      // Видеографы
      Specialist(
        id: 'videographer_1',
        userId: 'user_3',
        name: 'Елена Волкова',
        description:
            'Видеограф и монтажер. Создаю качественные видеоролики для любых мероприятий.',
        category: SpecialistCategory.videographer,
        experienceLevel: ExperienceLevel.expert,
        yearsOfExperience: 10,
        hourlyRate: 6000,
        price: 6000,
        rating: 4.9,
        reviewCount: 156,
        city: 'Москва',
        location: 'Москва, Северный округ',
        services: const [
          'Свадебная видеосъемка',
          'Корпоративные видео',
          'Промо-ролики',
          'Монтаж видео',
        ],
        equipment: const [
          'Sony FX6',
          'Canon C70',
          'DJI Ronin 4D',
          'Профессиональное освещение',
        ],
        languages: const ['Русский', 'Английский', 'Французский'],
        isVerified: true,
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 4000, maxPrice: 10000),
        availableDates: [
          now.add(const Duration(days: 1)),
          now.add(const Duration(days: 3)),
          now.add(const Duration(days: 5)),
          now.add(const Duration(days: 7)),
          now.add(const Duration(days: 9)),
          now.add(const Duration(days: 12)),
        ],
        busyDates: [
          now.add(const Duration(days: 2)),
          now.add(const Duration(days: 4)),
          now.add(const Duration(days: 6)),
        ],
      ),

      // DJ
      Specialist(
        id: 'dj_1',
        userId: 'user_4',
        name: 'Алексей Козлов',
        description:
            'DJ с 12-летним опытом. Специализируюсь на свадьбах, корпоративах и частных вечеринках.',
        category: SpecialistCategory.dj,
        experienceLevel: ExperienceLevel.expert,
        yearsOfExperience: 12,
        hourlyRate: 4000,
        price: 4000,
        rating: 4.7,
        reviewCount: 203,
        city: 'Москва',
        location: 'Москва, Восточный округ',
        services: const [
          'Свадебные вечеринки',
          'Корпоративные мероприятия',
          'Частные вечеринки',
          'Клубные выступления',
        ],
        equipment: const [
          'Pioneer DJM-900NXS2',
          'Pioneer CDJ-2000NXS2',
          'JBL EON615',
          'Профессиональная звуковая система',
        ],
        languages: const ['Русский', 'Английский'],
        isVerified: true,
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 3000, maxPrice: 6000),
      ),

      // Ведущий
      Specialist(
        id: 'host_1',
        userId: 'user_5',
        name: 'Дмитрий Морозов',
        description:
            'Профессиональный ведущий мероприятий. Провожу свадьбы, корпоративы, дни рождения.',
        category: SpecialistCategory.host,
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 7,
        hourlyRate: 4500,
        price: 4500,
        rating: 4.8,
        reviewCount: 134,
        city: 'Санкт-Петербург',
        location: 'Санкт-Петербург, Василеостровский район',
        services: const [
          'Свадебные церемонии',
          'Корпоративные мероприятия',
          'Дни рождения',
          'Юбилеи',
        ],
        equipment: const [
          'Микрофонная система',
          'Музыкальное оборудование',
          'Декорации',
        ],
        languages: const ['Русский', 'Английский'],
        isVerified: true,
        isOnline: false,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 3500, maxPrice: 7000),
      ),

      // Декоратор
      Specialist(
        id: 'decorator_1',
        userId: 'user_6',
        name: 'Мария Иванова',
        description:
            'Декоратор и флорист. Создаю уникальные декорации для любых мероприятий.',
        category: SpecialistCategory.decorator,
        experienceLevel: ExperienceLevel.expert,
        yearsOfExperience: 9,
        hourlyRate: 3000,
        price: 3000,
        rating: 4.9,
        reviewCount: 98,
        city: 'Москва',
        location: 'Москва, Южный округ',
        services: const [
          'Свадебные декорации',
          'Цветочные композиции',
          'Корпоративные мероприятия',
          'Частные вечеринки',
        ],
        equipment: const [
          'Цветы и растения',
          'Декоративные материалы',
          'Инструменты для флористики',
        ],
        isVerified: true,
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 35)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 2000, maxPrice: 5000),
      ),

      // Музыкант
      Specialist(
        id: 'musician_1',
        userId: 'user_7',
        name: 'Сергей Новиков',
        description:
            'Пианист и вокалист. Выступаю на свадьбах, корпоративах и частных мероприятиях.',
        category: SpecialistCategory.musician,
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 6,
        hourlyRate: 5500,
        price: 5500,
        rating: 4.7,
        reviewCount: 76,
        city: 'Москва',
        location: 'Москва, Западный округ',
        services: const [
          'Живая музыка',
          'Вокальные выступления',
          'Аккомпанемент',
          'Музыкальное оформление',
        ],
        equipment: const [
          'Цифровое пианино',
          'Микрофонная система',
          'Звуковое оборудование',
        ],
        languages: const ['Русский', 'Английский'],
        isVerified: true,
        isOnline: false,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 4000, maxPrice: 8000),
      ),

      // Кейтеринг
      Specialist(
        id: 'caterer_1',
        userId: 'user_8',
        name: 'ООО "Вкусные решения"',
        description:
            'Кейтеринговая компания. Организуем питание для любых мероприятий.',
        category: SpecialistCategory.caterer,
        experienceLevel: ExperienceLevel.expert,
        yearsOfExperience: 15,
        hourlyRate: 2000,
        price: 2000,
        rating: 4.8,
        reviewCount: 245,
        city: 'Москва',
        location: 'Москва, Северо-Восточный округ',
        services: const [
          'Свадебные банкеты',
          'Корпоративные мероприятия',
          'Фуршеты',
          'Детские праздники',
        ],
        equipment: const [
          'Кухонное оборудование',
          'Посуда',
          'Сервировочные принадлежности',
        ],
        languages: const ['Русский', 'Английский'],
        isVerified: true,
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 1500, maxPrice: 3000),
      ),

      // Аниматор
      Specialist(
        id: 'animator_1',
        userId: 'user_9',
        name: 'Анна Смирнова',
        description:
            'Детский аниматор и ведущая. Провожу детские праздники и развлекательные программы.',
        category: SpecialistCategory.animator,
        experienceLevel: ExperienceLevel.intermediate,
        yearsOfExperience: 4,
        hourlyRate: 2500,
        price: 2500,
        rating: 4.6,
        reviewCount: 67,
        city: 'Санкт-Петербург',
        location: 'Санкт-Петербург, Приморский район',
        services: const [
          'Детские праздники',
          'Анимационные программы',
          'Мастер-классы',
          'Игровые программы',
        ],
        equipment: const [
          'Костюмы персонажей',
          'Реквизит для игр',
          'Музыкальное оборудование',
        ],
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 2000, maxPrice: 4000),
      ),

      // Флорист
      Specialist(
        id: 'florist_1',
        userId: 'user_10',
        name: 'Екатерина Лебедева',
        description:
            'Флорист с художественным образованием. Создаю уникальные цветочные композиции.',
        category: SpecialistCategory.florist,
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 6,
        hourlyRate: 2800,
        price: 2800,
        rating: 4.7,
        reviewCount: 89,
        city: 'Москва',
        location: 'Москва, Юго-Западный округ',
        services: const [
          'Свадебные букеты',
          'Цветочные композиции',
          'Декорации из цветов',
          'Корпоративные заказы',
        ],
        equipment: const [
          'Свежие цветы',
          'Флористические инструменты',
          'Декоративные материалы',
        ],
        languages: const ['Русский', 'Французский'],
        isVerified: true,
        isOnline: false,
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 2000, maxPrice: 4500),
      ),

      // Дополнительные специалисты для разнообразия
      Specialist(
        id: 'photographer_3',
        userId: 'user_11',
        name: 'Игорь Федоров',
        description:
            'Фотограф-портретист. Специализируюсь на студийной и уличной портретной съемке.',
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.intermediate,
        yearsOfExperience: 3,
        hourlyRate: 2500,
        price: 2500,
        rating: 4.3,
        reviewCount: 45,
        city: 'Казань',
        location: 'Казань, Центр',
        services: const [
          'Портретная фотосъемка',
          'Студийная съемка',
          'Уличная фотография',
        ],
        equipment: const [
          'Canon EOS 6D',
          'Canon EF 50mm f/1.4',
          'Студийное освещение',
        ],
        languages: const ['Русский', 'Татарский'],
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 1500, maxPrice: 3500),
      ),

      Specialist(
        id: 'dj_2',
        userId: 'user_12',
        name: 'Максим Петров',
        description:
            'DJ и звукорежиссер. Работаю в различных жанрах электронной музыки.',
        category: SpecialistCategory.dj,
        experienceLevel: ExperienceLevel.intermediate,
        yearsOfExperience: 4,
        hourlyRate: 3000,
        price: 3000,
        rating: 4.4,
        reviewCount: 52,
        city: 'Екатеринбург',
        location: 'Екатеринбург, Центр',
        services: const [
          'Клубные выступления',
          'Частные вечеринки',
          'Корпоративные мероприятия',
        ],
        equipment: const [
          'Pioneer DDJ-1000',
          'JBL EON615',
          'Профессиональные наушники',
        ],
        isOnline: false,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 2000, maxPrice: 4000),
      ),

      Specialist(
        id: 'host_2',
        userId: 'user_13',
        name: 'Наталья Козлова',
        description:
            'Ведущая мероприятий и тамада. Создаю незабываемые праздники.',
        category: SpecialistCategory.host,
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 8,
        hourlyRate: 4000,
        price: 4000,
        rating: 4.8,
        reviewCount: 112,
        city: 'Новосибирск',
        location: 'Новосибирск, Центральный район',
        services: const [
          'Свадебные церемонии',
          'Дни рождения',
          'Юбилеи',
          'Корпоративы',
        ],
        equipment: const [
          'Микрофонная система',
          'Музыкальное оборудование',
          'Игровой реквизит',
        ],
        isVerified: true,
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now,
        priceRange: const PriceRange(minPrice: 3000, maxPrice: 6000),
      ),
    ];
  }

  /// Очистить все тестовые данные
  static Future<void> clearTestData() async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection('specialists').get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Тестовые данные специалистов очищены');
    } catch (e) {
      print('Ошибка очистки тестовых данных: $e');
    }
  }

  /// Получить статистику тестовых данных
  static Future<Map<String, dynamic>> getTestDataStats() async {
    try {
      final specialists = await _specialistService.getAllSpecialists();

      final stats = <String, dynamic>{
        'totalCount': specialists.length,
        'categories': <String, int>{},
        'cities': <String, int>{},
        'averageRating': 0.0,
        'averagePrice': 0.0,
        'verifiedCount': 0,
        'onlineCount': 0,
      };

      if (specialists.isNotEmpty) {
        double totalRating = 0;
        double totalPrice = 0;

        for (final specialist in specialists) {
          // Категории
          final category = specialist.category.displayName;
          stats['categories'][category] =
              (stats['categories'][category] ?? 0) + 1;

          // Города
          final city = specialist.city ?? 'Не указан';
          stats['cities'][city] = (stats['cities'][city] ?? 0) + 1;

          // Рейтинг и цена
          totalRating += specialist.rating;
          totalPrice += specialist.price;

          // Верификация и онлайн статус
          if (specialist.isVerified) stats['verifiedCount']++;
          if (specialist.isOnline ?? false) stats['onlineCount']++;
        }

        stats['averageRating'] = totalRating / specialists.length;
        stats['averagePrice'] = totalPrice / specialists.length;
      }

      return stats;
    } catch (e) {
      print('Ошибка получения статистики: $e');
      return {};
    }
  }
}
