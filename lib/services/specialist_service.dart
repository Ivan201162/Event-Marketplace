import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist.dart';
import 'calendar_service.dart';

/// Сервис для управления специалистами
class SpecialistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CalendarService _calendarService = CalendarService();

  /// Получить ленту специалиста
  Stream<List<Map<String, dynamic>>> getSpecialistFeed(String specialistId) =>
      _db
          .collection('specialist_posts')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  },
                )
                .toList(),
          );

  /// Получить специалиста по ID
  Future<Specialist?> getSpecialist(String specialistId) async {
    try {
      final doc = await _db.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения специалиста: $e');
      return null;
    }
  }

  /// Поток специалиста по ID
  Stream<Specialist?> getSpecialistStream(String specialistId) =>
      _db.collection('specialists').doc(specialistId).snapshots().map((doc) {
        if (doc.exists) {
          return Specialist.fromDocument(doc);
        }
        return null;
      });

  /// Получить специалиста по ID пользователя
  Future<Specialist?> getSpecialistByUserId(String userId) async {
    try {
      final querySnapshot = await _db
          .collection('specialists')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Specialist.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Ошибка получения специалиста по userId: $e');
      return null;
    }
  }

  /// Поток специалиста по ID пользователя
  Stream<Specialist?> getSpecialistByUserIdStream(String userId) => _db
          .collection('specialists')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .snapshots()
          .map((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          return Specialist.fromDocument(querySnapshot.docs.first);
        }
        return null;
      });

  /// Получить всех специалистов
  Future<List<Specialist>> getAllSpecialists({int limit = 50}) async {
    try {
      final querySnapshot = await _db
          .collection('specialists')
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения специалистов: $e');
      return [];
    }
  }

  /// Поток всех специалистов
  Stream<List<Specialist>> getAllSpecialistsStream({int limit = 50}) => _db
      .collection('specialists')
      .where('isAvailable', isEqualTo: true)
      .orderBy('rating', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (querySnapshot) =>
            querySnapshot.docs.map(Specialist.fromDocument).toList(),
      );

  /// Поиск специалистов с фильтрами
  Future<List<Specialist>> searchSpecialists(
    SpecialistFilters filters, {
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection('specialists');

      // Фильтр по доступности
      if (filters.isAvailable != null) {
        query = query.where('isAvailable', isEqualTo: filters.isAvailable);
      }

      // Фильтр по категории
      if (filters.category != null) {
        query = query.where('category', isEqualTo: filters.category!.name);
      }

      // Фильтр по верификации
      if (filters.isVerified != null) {
        query = query.where('isVerified', isEqualTo: filters.isVerified);
      }

      // Фильтр по минимальному рейтингу
      if (filters.minRating != null) {
        query =
            query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
      }

      // Фильтр по максимальной ставке
      if (filters.maxHourlyRate != null) {
        query = query.where(
          'hourlyRate',
          isLessThanOrEqualTo: filters.maxHourlyRate,
        );
      }

      // Сортировка
      switch (filters.sortBy) {
        case 'rating':
          query = query.orderBy('rating', descending: !filters.sortAscending);
          break;
        case 'price':
          query =
              query.orderBy('hourlyRate', descending: !filters.sortAscending);
          break;
        case 'experience':
          query = query.orderBy(
            'yearsOfExperience',
            descending: !filters.sortAscending,
          );
          break;
        case 'reviews':
          query =
              query.orderBy('reviewCount', descending: !filters.sortAscending);
          break;
        default:
          query = query.orderBy('rating', descending: true);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      var specialists =
          querySnapshot.docs.map(Specialist.fromDocument).toList();

      // Дополнительная фильтрация на клиенте
      specialists = _applyClientSideFilters(specialists, filters);

      return specialists;
    } catch (e) {
      print('Ошибка поиска специалистов: $e');
      return [];
    }
  }

  /// Поток поиска специалистов с фильтрами
  Stream<List<Specialist>> searchSpecialistsStream(
    SpecialistFilters filters, {
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('specialists');

    // Фильтр по доступности
    if (filters.isAvailable != null) {
      query = query.where('isAvailable', isEqualTo: filters.isAvailable);
    }

    // Фильтр по категории
    if (filters.category != null) {
      query = query.where('category', isEqualTo: filters.category!.name);
    }

    // Фильтр по верификации
    if (filters.isVerified != null) {
      query = query.where('isVerified', isEqualTo: filters.isVerified);
    }

    // Фильтр по минимальному рейтингу
    if (filters.minRating != null) {
      query = query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
    }

    // Фильтр по максимальной ставке
    if (filters.maxHourlyRate != null) {
      query =
          query.where('hourlyRate', isLessThanOrEqualTo: filters.maxHourlyRate);
    }

    // Сортировка
    switch (filters.sortBy) {
      case 'rating':
        query = query.orderBy('rating', descending: !filters.sortAscending);
        break;
      case 'price':
        query = query.orderBy('hourlyRate', descending: !filters.sortAscending);
        break;
      case 'experience':
        query = query.orderBy(
          'experienceYears',
          descending: !filters.sortAscending,
        );
        break;
      case 'reviews':
        query =
            query.orderBy('reviewCount', descending: !filters.sortAscending);
        break;
      default:
        query = query.orderBy('rating', descending: true);
    }

    query = query.limit(limit);

    return query.snapshots().map((querySnapshot) {
      var specialists =
          querySnapshot.docs.map(Specialist.fromDocument).toList();

      // Дополнительная фильтрация на клиенте
      specialists = _applyClientSideFilters(specialists, filters);

      return specialists;
    });
  }

  /// Применить фильтры на клиенте
  List<Specialist> _applyClientSideFilters(
    List<Specialist> specialists,
    SpecialistFilters filters,
  ) =>
      specialists.where((specialist) {
        // Поиск по тексту
        if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
          final query = filters.searchQuery!.toLowerCase();
          final matchesName = specialist.name.toLowerCase().contains(query);
          final matchesDescription =
              specialist.description?.toLowerCase().contains(query) ?? false;
          final matchesSubcategories = specialist.subcategories
              .any((sub) => sub.toLowerCase().contains(query));

          if (!matchesName && !matchesDescription && !matchesSubcategories) {
            return false;
          }
        }

        // Фильтр по подкатегориям
        if (filters.subcategories != null &&
            filters.subcategories!.isNotEmpty) {
          final hasMatchingSubcategory = specialist.subcategories
              .any((sub) => filters.subcategories!.contains(sub));
          if (!hasMatchingSubcategory) {
            return false;
          }
        }

        // Фильтр по минимальному уровню опыта
        if (filters.minExperienceLevel != null) {
          final experienceLevels = [
            ExperienceLevel.beginner,
            ExperienceLevel.intermediate,
            ExperienceLevel.advanced,
            ExperienceLevel.expert,
          ];
          final specialistLevelIndex =
              experienceLevels.indexOf(specialist.experienceLevel);
          final minLevelIndex =
              experienceLevels.indexOf(filters.minExperienceLevel!);

          if (specialistLevelIndex < minLevelIndex) {
            return false;
          }
        }

        // Фильтр по областям обслуживания
        if (filters.serviceAreas != null && filters.serviceAreas!.isNotEmpty) {
          final hasMatchingArea = specialist.serviceAreas
              .any((area) => filters.serviceAreas!.contains(area));
          if (!hasMatchingArea) {
            return false;
          }
        }

        // Фильтр по языкам
        if (filters.languages != null && filters.languages!.isNotEmpty) {
          final hasMatchingLanguage = specialist.languages
              .any((lang) => filters.languages!.contains(lang));
          if (!hasMatchingLanguage) {
            return false;
          }
        }

        // Фильтр по доступности на дату
        if (filters.availableDate != null) {
          if (!specialist.isAvailableOnDate(filters.availableDate!)) {
            return false;
          }
        }

        return true;
      }).toList();

  /// Получить специалистов по категории
  Future<List<Specialist>> getSpecialistsByCategory(
    SpecialistCategory category, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения специалистов по категории: $e');
      return [];
    }
  }

  /// Получить топ специалистов
  Future<List<Specialist>> getTopSpecialists({int limit = 10}) async {
    try {
      final querySnapshot = await _db
          .collection('specialists')
          .where('isAvailable', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения топ специалистов: $e');
      return [];
    }
  }

  /// Создать профиль специалиста
  Future<Specialist> createSpecialist({
    required String userId,
    required String name,
    required SpecialistCategory category,
    required double hourlyRate,
    String? description,
    List<String> subcategories = const [],
    ExperienceLevel experienceLevel = ExperienceLevel.beginner,
    int yearsOfExperience = 0,
    double? minBookingHours,
    double? maxBookingHours,
    List<String> serviceAreas = const [],
    List<String> languages = const [],
    List<String> equipment = const [],
    List<String> portfolio = const [],
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? businessInfo,
  }) async {
    try {
      final specialist = Specialist(
        id: _generateSpecialistId(),
        userId: userId,
        name: name,
        description: description,
        category: category,
        subcategories: subcategories,
        experienceLevel: experienceLevel,
        price: hourlyRate, // Добавляем обязательное поле price
        yearsOfExperience: yearsOfExperience,
        hourlyRate: hourlyRate,
        minBookingHours: minBookingHours,
        maxBookingHours: maxBookingHours,
        serviceAreas: serviceAreas,
        languages: languages,
        equipment: equipment,
        portfolio: portfolio,
        contactInfo: contactInfo,
        businessInfo: businessInfo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db
          .collection('specialists')
          .doc(specialist.id)
          .set(specialist.toMap());
      return specialist;
    } catch (e) {
      print('Ошибка создания специалиста: $e');
      throw Exception('Не удалось создать профиль специалиста: $e');
    }
  }

  /// Обновить профиль специалиста
  Future<void> updateSpecialist(
    String specialistId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _db.collection('specialists').doc(specialistId).update(updates);
    } catch (e) {
      print('Ошибка обновления специалиста: $e');
      throw Exception('Не удалось обновить профиль специалиста: $e');
    }
  }

  /// Обновить рейтинг специалиста
  Future<void> updateSpecialistRating(
    String specialistId,
    double newRating,
    int newReviewCount,
  ) async {
    try {
      await _db.collection('specialists').doc(specialistId).update({
        'rating': newRating,
        'reviewCount': newReviewCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка обновления рейтинга: $e');
      throw Exception('Не удалось обновить рейтинг: $e');
    }
  }

  /// Проверить доступность специалиста на дату
  Future<bool> isSpecialistAvailableOnDate(
    String specialistId,
    DateTime date,
  ) async {
    try {
      return await _calendarService.isDateAvailable(specialistId, date);
    } catch (e) {
      print('Ошибка проверки доступности: $e');
      return false;
    }
  }

  /// Проверить доступность специалиста на дату и время
  Future<bool> isSpecialistAvailableOnDateTime(
    String specialistId,
    DateTime dateTime,
  ) async {
    try {
      return await _calendarService.isDateTimeAvailable(specialistId, dateTime);
    } catch (e) {
      print('Ошибка проверки доступности на дату и время: $e');
      return false;
    }
  }

  /// Получить доступные временные слоты специалиста
  Future<List<DateTime>> getAvailableTimeSlots(
    String specialistId,
    DateTime date, {
    Duration slotDuration = const Duration(hours: 1),
  }) async {
    try {
      return await _calendarService.getAvailableTimeSlots(
        specialistId,
        date,
        slotDuration,
      );
    } catch (e) {
      print('Ошибка получения временных слотов: $e');
      return [];
    }
  }

  /// Добавить тестовые данные специалистов
  Future<void> addTestSpecialists() async {
    try {
      final testSpecialists = [
        {
          'userId': 'user_1',
          'name': 'Александр Петров',
          'description':
              'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
          'category': 'photographer',
          'subcategories': [
            'свадебная фотография',
            'портретная съемка',
            'корпоративные мероприятия',
          ],
          'experienceLevel': 'advanced',
          'yearsOfExperience': 5,
          'hourlyRate': 3000.0,
          'minBookingHours': 2.0,
          'maxBookingHours': 12.0,
          'serviceAreas': ['Москва', 'Московская область'],
          'languages': ['Русский', 'Английский'],
          'equipment': [
            'Canon EOS R5',
            'Canon 24-70mm f/2.8',
            'Студийное освещение',
          ],
          'portfolio': [
            'https://example.com/portfolio1',
            'https://example.com/portfolio2',
          ],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.8,
          'reviewCount': 47,
        },
        {
          'userId': 'user_2',
          'name': 'Мария Сидорова',
          'description':
              'Опытный DJ с обширной музыкальной коллекцией. Работаю на свадьбах, корпоративах и частных вечеринках.',
          'category': 'dj',
          'subcategories': [
            'свадебные торжества',
            'корпоративные мероприятия',
            'частные вечеринки',
          ],
          'experienceLevel': 'expert',
          'yearsOfExperience': 8,
          'hourlyRate': 2500.0,
          'minBookingHours': 3.0,
          'maxBookingHours': 8.0,
          'serviceAreas': ['Москва', 'Санкт-Петербург'],
          'languages': ['Русский', 'Английский', 'Французский'],
          'equipment': [
            'Pioneer DJM-900NXS2',
            'Pioneer CDJ-2000NXS2',
            'JBL EON615',
          ],
          'portfolio': ['https://example.com/dj-portfolio'],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.9,
          'reviewCount': 89,
        },
        {
          'userId': 'user_3',
          'name': 'Дмитрий Козлов',
          'description':
              'Ведущий мероприятий с харизмой и чувством юмора. Создаю незабываемую атмосферу на любом празднике.',
          'category': 'host',
          'subcategories': [
            'свадебные торжества',
            'дни рождения',
            'корпоративные мероприятия',
          ],
          'experienceLevel': 'advanced',
          'yearsOfExperience': 6,
          'hourlyRate': 4000.0,
          'minBookingHours': 2.0,
          'maxBookingHours': 6.0,
          'serviceAreas': ['Москва', 'Московская область', 'Калужская область'],
          'languages': ['Русский'],
          'equipment': ['Микрофон Shure SM58', 'Портативная колонка'],
          'portfolio': ['https://example.com/host-portfolio'],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.7,
          'reviewCount': 34,
        },
        {
          'userId': 'user_4',
          'name': 'Анна Волкова',
          'description':
              'Декоратор с художественным образованием. Создаю уникальные интерьеры для любых мероприятий.',
          'category': 'decorator',
          'subcategories': [
            'свадебное оформление',
            'корпоративные мероприятия',
            'детские праздники',
          ],
          'experienceLevel': 'intermediate',
          'yearsOfExperience': 3,
          'hourlyRate': 2000.0,
          'minBookingHours': 4.0,
          'maxBookingHours': 12.0,
          'serviceAreas': ['Москва'],
          'languages': ['Русский', 'Английский'],
          'equipment': ['Декоративные материалы', 'Осветительное оборудование'],
          'portfolio': ['https://example.com/decor-portfolio'],
          'isAvailable': true,
          'isVerified': false,
          'rating': 4.5,
          'reviewCount': 12,
        },
        {
          'userId': 'user_5',
          'name': 'Сергей Морозов',
          'description':
              'Видеограф с современным оборудованием. Создаю качественные видеоролики для любых мероприятий.',
          'category': 'videographer',
          'subcategories': [
            'свадебная видеосъемка',
            'корпоративные видео',
            'рекламные ролики',
          ],
          'experienceLevel': 'advanced',
          'yearsOfExperience': 4,
          'hourlyRate': 3500.0,
          'minBookingHours': 2.0,
          'maxBookingHours': 10.0,
          'serviceAreas': ['Москва', 'Московская область'],
          'languages': ['Русский'],
          'equipment': ['Sony FX6', 'Canon 24-70mm f/2.8', 'DJI Ronin 2'],
          'portfolio': ['https://example.com/video-portfolio'],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.6,
          'reviewCount': 28,
        },
      ];

      for (final specialistData in testSpecialists) {
        final specialist = Specialist(
          id: _generateSpecialistId(),
          userId: specialistData['userId']! as String,
          name: specialistData['name']! as String,
          description: specialistData['description'] as String?,
          price: (specialistData['hourlyRate'] as num).toDouble(), // Добавляем обязательное поле price
          category: SpecialistCategory.values
              .firstWhere((e) => e.name == specialistData['category']),
          subcategories:
              List<String>.from(specialistData['subcategories']! as List),
          experienceLevel: ExperienceLevel.values
              .firstWhere((e) => e.name == specialistData['experienceLevel']),
          yearsOfExperience: specialistData['yearsOfExperience']! as int,
          hourlyRate: (specialistData['hourlyRate']! as num).toDouble(),
          minBookingHours: specialistData['minBookingHours'] != null
              ? (specialistData['minBookingHours']! as num).toDouble()
              : null,
          maxBookingHours: specialistData['maxBookingHours'] != null
              ? (specialistData['maxBookingHours']! as num).toDouble()
              : null,
          serviceAreas:
              List<String>.from(specialistData['serviceAreas']! as List),
          languages: List<String>.from(specialistData['languages']! as List),
          equipment: List<String>.from(specialistData['equipment']! as List),
          portfolio: List<String>.from(specialistData['portfolio']! as List),
          isAvailable: specialistData['isAvailable']! as bool,
          isVerified: specialistData['isVerified']! as bool,
          rating: (specialistData['rating']! as num).toDouble(),
          reviewCount: specialistData['reviewCount']! as int,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _db
            .collection('specialists')
            .doc(specialist.id)
            .set(specialist.toMap());
      }

      print('Тестовые специалисты добавлены');
    } catch (e) {
      print('Ошибка добавления тестовых специалистов: $e');
    }
  }

  /// Генерация ID специалиста
  String _generateSpecialistId() =>
      'specialist_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
}
