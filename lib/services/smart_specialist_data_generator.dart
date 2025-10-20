import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/smart_specialist.dart';
import '../models/specialist.dart';

/// Генератор тестовых данных для умного поиска
class SmartSpecialistDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// Сгенерировать и сохранить тестовых специалистов
  Future<void> generateTestSpecialists({int count = 20}) async {
    try {
      final specialists = <SmartSpecialist>[];

      // Категории для генерации
      final categories = [
        SpecialistCategory.host,
        SpecialistCategory.photographer,
        SpecialistCategory.dj,
        SpecialistCategory.musician,
        SpecialistCategory.decorator,
        SpecialistCategory.florist,
        SpecialistCategory.animator,
        SpecialistCategory.makeup,
        SpecialistCategory.hairstylist,
        SpecialistCategory.caterer,
      ];

      // Города
      final cities = [
        'Москва',
        'Санкт-Петербург',
        'Екатеринбург',
        'Новосибирск',
        'Казань',
        'Нижний Новгород',
        'Челябинск',
        'Самара',
        'Омск',
        'Ростов-на-Дону',
      ];

      // Стили
      final allStyles = [
        'классика',
        'современный',
        'юмор',
        'интерактив',
        'романтичный',
        'официальный',
        'креативный',
        'элегантный',
        'веселый',
        'стильный',
      ];

      // Имена
      final firstNames = [
        'Андрей',
        'Александр',
        'Дмитрий',
        'Максим',
        'Сергей',
        'Анна',
        'Елена',
        'Ольга',
        'Татьяна',
        'Наталья',
        'Иван',
        'Михаил',
        'Владимир',
        'Алексей',
        'Николай',
        'Мария',
        'Светлана',
        'Юлия',
        'Ирина',
        'Екатерина',
      ];

      final lastNames = [
        'Иванов',
        'Петров',
        'Сидоров',
        'Козлов',
        'Новиков',
        'Морозов',
        'Петухов',
        'Волков',
        'Соловьев',
        'Васильев',
        'Зайцев',
        'Павлов',
        'Семенов',
        'Голубев',
        'Виноградов',
        'Богданов',
        'Воробьев',
        'Федоров',
        'Михайлов',
        'Белов',
      ];

      for (var i = 0; i < count; i++) {
        final category = categories[_random.nextInt(categories.length)];
        final firstName = firstNames[_random.nextInt(firstNames.length)];
        final lastName = lastNames[_random.nextInt(lastNames.length)];
        final city = cities[_random.nextInt(cities.length)];

        // Генерируем стили для специалиста
        final specialistStyles = <String>[];
        final numStyles = _random.nextInt(3) + 1; // 1-3 стиля
        for (var j = 0; j < numStyles; j++) {
          final style = allStyles[_random.nextInt(allStyles.length)];
          if (!specialistStyles.contains(style)) {
            specialistStyles.add(style);
          }
        }

        // Генерируем цены в зависимости от категории
        final priceRange = _getPriceRangeForCategory(category);
        final price =
            priceRange['min'] + _random.nextDouble() * (priceRange['max'] - priceRange['min']);

        // Генерируем рейтинг
        final rating = 3.0 + _random.nextDouble() * 2.0; // 3.0-5.0

        // Генерируем опыт
        final experienceYears = _random.nextInt(15) + 1; // 1-15 лет

        // Генерируем количество отзывов
        final reviewCount = _random.nextInt(100) + 1; // 1-100 отзывов

        // Генерируем доступные даты
        final availableDates = <DateTime>[];
        final today = DateTime.now();
        for (var j = 0; j < 10; j++) {
          final date = today.add(Duration(days: _random.nextInt(90) + 1));
          availableDates.add(date);
        }

        // Генерируем занятые даты
        final busyDates = <DateTime>[];
        for (var j = 0; j < _random.nextInt(5); j++) {
          final date = today.add(Duration(days: _random.nextInt(30) + 1));
          busyDates.add(date);
        }

        final specialist = SmartSpecialist(
          id: 'specialist_${DateTime.now().millisecondsSinceEpoch}_$i',
          userId: 'user_${_random.nextInt(1000)}',
          name: '$firstName $lastName',
          description: _generateDescription(category, firstName),
          bio: _generateBio(category, firstName, experienceYears),
          category: category,
          categories: [category],
          subcategories: _generateSubcategories(category),
          experienceLevel: _getExperienceLevel(experienceYears),
          yearsOfExperience: experienceYears,
          hourlyRate: price / 8, // Предполагаем 8-часовой рабочий день
          price: price,
          priceFrom: price * 0.8,
          priceTo: price * 1.2,
          rating: rating,
          reviewCount: reviewCount,
          city: city,
          location: city,
          isAvailable: _random.nextBool(),
          isVerified: _random.nextDouble() > 0.3, // 70% верифицированы
          portfolioImages: _generatePortfolioImages(category),
          portfolioVideos: _generatePortfolioVideos(category),
          services: _generateServices(category),
          equipment: _generateEquipment(category),
          languages: _generateLanguages(),
          workingHours: _generateWorkingHours(),
          availableDates: availableDates,
          busyDates: busyDates,
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
          updatedAt: DateTime.now(),
          lastActiveAt: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
          // Новые поля для интеллектуального поиска
          styles: specialistStyles,
          keywords: _generateKeywords(category, city, specialistStyles),
          reputationScore: _calculateReputationScore(rating, reviewCount, experienceYears),
          searchTags: _generateSearchTags(category, city, specialistStyles),
          eventTypes: _generateEventTypes(category),
          specializations: _generateSpecializations(category),
          workingStyle: _generateWorkingStyle(category),
          personalityTraits: _generatePersonalityTraits(rating, experienceYears),
          availabilityPattern: _generateAvailabilityPattern(),
          clientPreferences: _generateClientPreferences(price),
          performanceMetrics: _generatePerformanceMetrics(rating, reviewCount),
          recommendationFactors: _generateRecommendationFactors(
            rating,
            reviewCount,
            experienceYears,
          ),
        );

        specialists.add(specialist);
      }

      // Сохраняем в Firestore
      final batch = _firestore.batch();
      for (final specialist in specialists) {
        final docRef = _firestore.collection('specialists').doc(specialist.id);
        batch.set(docRef, specialist.toMap());
      }

      await batch.commit();

      debugdebugPrint(
        '✅ Сгенерировано и сохранено ${specialists.length} тестовых специалистов',
      );
    } catch (e) {
      debugdebugPrint('❌ Ошибка генерации тестовых данных: $e');
    }
  }

  /// Получить диапазон цен для категории
  Map<String, double> _getPriceRangeForCategory(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.host:
        return {'min': 15000, 'max': 50000};
      case SpecialistCategory.photographer:
        return {'min': 10000, 'max': 40000};
      case SpecialistCategory.dj:
        return {'min': 8000, 'max': 30000};
      case SpecialistCategory.musician:
        return {'min': 12000, 'max': 35000};
      case SpecialistCategory.decorator:
        return {'min': 5000, 'max': 25000};
      case SpecialistCategory.florist:
        return {'min': 3000, 'max': 15000};
      case SpecialistCategory.animator:
        return {'min': 4000, 'max': 20000};
      case SpecialistCategory.makeup:
        return {'min': 2000, 'max': 12000};
      case SpecialistCategory.hairstylist:
        return {'min': 1500, 'max': 10000};
      case SpecialistCategory.caterer:
        return {'min': 8000, 'max': 30000};
      default:
        return {'min': 5000, 'max': 25000};
    }
  }

  /// Получить уровень опыта
  ExperienceLevel _getExperienceLevel(int years) {
    if (years < 2) return ExperienceLevel.beginner;
    if (years < 5) return ExperienceLevel.intermediate;
    if (years < 10) return ExperienceLevel.advanced;
    return ExperienceLevel.expert;
  }

  /// Сгенерировать описание
  String _generateDescription(SpecialistCategory category, String firstName) {
    final descriptions = {
      SpecialistCategory.host: [
        'Опытный ведущий с отличным чувством юмора',
        'Профессиональный ведущий мероприятий',
        'Креативный ведущий с индивидуальным подходом',
        'Ведущий с многолетним опытом работы',
      ],
      SpecialistCategory.photographer: [
        'Фотограф с художественным видением',
        'Профессиональный фотограф с современным стилем',
        'Креативный фотограф с индивидуальным подходом',
        'Фотограф с многолетним опытом',
      ],
      SpecialistCategory.dj: [
        'DJ с отличным музыкальным вкусом',
        'Профессиональный диджей с современным звуком',
        'DJ с многолетним опытом работы',
        'Креативный диджей с индивидуальным стилем',
      ],
    };

    final categoryDescriptions = descriptions[category] ?? ['Профессиональный специалист'];
    return categoryDescriptions[_random.nextInt(categoryDescriptions.length)];
  }

  /// Сгенерировать биографию
  String _generateBio(
    SpecialistCategory category,
    String firstName,
    int experienceYears,
  ) =>
      'Привет! Меня зовут $firstName, и я работаю в сфере ${category.displayName.toLowerCase()} уже $experienceYears лет. '
      'Люблю создавать незабываемые моменты для моих клиентов. '
      'Имею опыт работы с различными типами мероприятий и всегда нахожу индивидуальный подход к каждому клиенту.';

  /// Сгенерировать подкатегории
  List<String> _generateSubcategories(SpecialistCategory category) {
    final subcategories = {
      SpecialistCategory.host: ['свадьбы', 'корпоративы', 'дни рождения'],
      SpecialistCategory.photographer: [
        'свадебная съемка',
        'портретная съемка',
        'репортажная съемка',
      ],
      SpecialistCategory.dj: ['электронная музыка', 'поп-музыка', 'рок-музыка'],
      SpecialistCategory.musician: [
        'живая музыка',
        'каверы',
        'авторские композиции',
      ],
    };

    return subcategories[category] ?? ['услуги'];
  }

  /// Сгенерировать изображения портфолио
  List<String> _generatePortfolioImages(SpecialistCategory category) {
    final count = _random.nextInt(5) + 3; // 3-7 изображений
    final images = <String>[];

    for (var i = 0; i < count; i++) {
      images.add('https://picsum.photos/400/300?random=${_random.nextInt(1000)}');
    }

    return images;
  }

  /// Сгенерировать видео портфолио
  List<String> _generatePortfolioVideos(SpecialistCategory category) {
    if (_random.nextBool()) {
      return [
        'https://example.com/video1.mp4',
        'https://example.com/video2.mp4',
      ];
    }
    return [];
  }

  /// Сгенерировать услуги
  List<String> _generateServices(SpecialistCategory category) {
    final services = {
      SpecialistCategory.host: [
        'ведущий мероприятия',
        'развлекательная программа',
        'игры и конкурсы',
      ],
      SpecialistCategory.photographer: [
        'фотосъемка',
        'обработка фото',
        'печать фотографий',
      ],
      SpecialistCategory.dj: [
        'музыкальное сопровождение',
        'звуковое оборудование',
        'световое шоу',
      ],
      SpecialistCategory.musician: [
        'живое выступление',
        'музыкальное сопровождение',
        'интерактив с гостями',
      ],
    };

    return services[category] ?? ['услуги'];
  }

  /// Сгенерировать оборудование
  List<String> _generateEquipment(SpecialistCategory category) {
    final equipment = {
      SpecialistCategory.host: [
        'микрофон',
        'колонки',
        'музыкальное оборудование',
      ],
      SpecialistCategory.photographer: [
        'профессиональная камера',
        'объективы',
        'освещение',
      ],
      SpecialistCategory.dj: ['DJ-пульт', 'колонки', 'микрофоны'],
      SpecialistCategory.musician: [
        'музыкальные инструменты',
        'усилители',
        'микрофоны',
      ],
    };

    return equipment[category] ?? ['оборудование'];
  }

  /// Сгенерировать языки
  List<String> _generateLanguages() {
    final languages = ['Русский', 'Английский'];
    if (_random.nextBool()) {
      languages.add('Немецкий');
    }
    return languages;
  }

  /// Сгенерировать рабочие часы
  Map<String, String> _generateWorkingHours() => {
        'monday': '09:00-18:00',
        'tuesday': '09:00-18:00',
        'wednesday': '09:00-18:00',
        'thursday': '09:00-18:00',
        'friday': '09:00-18:00',
        'saturday': '10:00-16:00',
        'sunday': 'Выходной',
      };

  /// Сгенерировать ключевые слова
  List<String> _generateKeywords(
    SpecialistCategory category,
    String city,
    List<String> styles,
  ) {
    final keywords = <String>[];

    keywords.add(category.displayName.toLowerCase());
    keywords.add(city.toLowerCase());
    keywords.addAll(styles);

    // Добавляем дополнительные ключевые слова
    final additionalKeywords = [
      'профессиональный',
      'опытный',
      'качественный',
      'надежный',
    ];
    keywords.addAll(additionalKeywords);

    return keywords;
  }

  /// Вычислить балл репутации
  int _calculateReputationScore(
    double rating,
    int reviewCount,
    int experienceYears,
  ) {
    var score = 0;

    // Базовый балл за рейтинг
    score += (rating * 10).round();

    // Бонус за количество отзывов
    if (reviewCount > 10) score += 10;
    if (reviewCount > 50) score += 10;
    if (reviewCount > 100) score += 10;

    // Бонус за опыт
    if (experienceYears > 5) score += 10;
    if (experienceYears > 10) score += 10;

    return score.clamp(0, 100);
  }

  /// Сгенерировать теги для поиска
  List<String> _generateSearchTags(
    SpecialistCategory category,
    String city,
    List<String> styles,
  ) {
    final tags = <String>[];

    tags.add(category.displayName);
    tags.add(city);
    tags.addAll(styles);

    return tags;
  }

  /// Сгенерировать типы мероприятий
  List<String> _generateEventTypes(SpecialistCategory category) {
    final eventTypes = {
      SpecialistCategory.host: [
        'свадьба',
        'корпоратив',
        'день рождения',
        'юбилей',
      ],
      SpecialistCategory.photographer: [
        'свадьба',
        'фотосессия',
        'корпоратив',
        'день рождения',
      ],
      SpecialistCategory.dj: [
        'свадьба',
        'корпоратив',
        'день рождения',
        'вечеринка',
      ],
      SpecialistCategory.musician: [
        'свадьба',
        'корпоратив',
        'день рождения',
        'концерт',
      ],
    };

    return eventTypes[category] ?? ['мероприятие'];
  }

  /// Сгенерировать специализации
  List<String> _generateSpecializations(SpecialistCategory category) {
    final specializations = <String>[];

    specializations.add(category.displayName);

    if (_random.nextBool()) {
      specializations.add('опытный');
    }

    return specializations;
  }

  /// Сгенерировать стиль работы
  Map<String, dynamic> _generateWorkingStyle(SpecialistCategory category) => {
        'communication': _random.nextBool() ? 'отличная' : 'хорошая',
        'punctuality': 0.8 + _random.nextDouble() * 0.2,
        'flexibility': _random.nextBool() ? 'высокая' : 'средняя',
        'creativity': _random.nextBool() ? 'высокая' : 'средняя',
      };

  /// Сгенерировать черты характера
  List<String> _generatePersonalityTraits(double rating, int experienceYears) {
    final traits = <String>[];

    if (rating > 4.5) {
      traits.add('профессиональный');
    }
    if (experienceYears > 5) {
      traits.add('опытный');
    }
    if (_random.nextBool()) {
      traits.add('креативный');
    }
    if (_random.nextBool()) {
      traits.add('надежный');
    }

    return traits;
  }

  /// Сгенерировать паттерн доступности
  Map<String, dynamic> _generateAvailabilityPattern() => {
        'weekdays': true,
        'weekends': _random.nextBool(),
        'evenings': _random.nextBool(),
        'flexible': _random.nextBool(),
      };

  /// Сгенерировать предпочтения клиентов
  Map<String, dynamic> _generateClientPreferences(double price) {
    String budgetRange;
    if (price < 15000) {
      budgetRange = 'бюджетный';
    } else if (price < 30000) {
      budgetRange = 'средний';
    } else {
      budgetRange = 'премиум';
    }

    return {
      'budgetRange': budgetRange,
      'eventSize': _random.nextBool() ? 'любой' : 'малый-средний',
      'style': _random.nextBool() ? 'премиум' : 'стандартный',
    };
  }

  /// Сгенерировать метрики производительности
  Map<String, dynamic> _generatePerformanceMetrics(
    double rating,
    int reviewCount,
  ) =>
      {
        'responseTime': _random.nextBool() ? 'быстрый' : 'средний',
        'completionRate': 0.9 + _random.nextDouble() * 0.1,
        'cancellationRate': _random.nextDouble() * 0.1,
        'clientSatisfaction': rating,
      };

  /// Сгенерировать факторы рекомендаций
  Map<String, dynamic> _generateRecommendationFactors(
    double rating,
    int reviewCount,
    int experienceYears,
  ) =>
      {
        'popularity': reviewCount,
        'quality': rating,
        'experience': experienceYears,
        'availability': true,
        'verification': _random.nextBool(),
      };
}
