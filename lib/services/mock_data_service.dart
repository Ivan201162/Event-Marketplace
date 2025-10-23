import 'dart:math';

import '../models/price_range.dart';
import '../models/specialist.dart';
import '../models/specialist_categories.dart';
import '../models/specialist_filters_simple.dart';
import '../models/specialist_sorting.dart';

/// Сервис для работы с тестовыми данными специалистов
class MockDataService {
  static final Random _random = Random();

  /// Получить специалистов по категории
  static List<Specialist> getSpecialistsByCategory(String categoryId) {
    switch (categoryId) {
      case 'host':
        return _getHosts();
      case 'photographer':
        return _getPhotographers();
      case 'dj':
        return _getDJs();
      case 'animator':
        return _getAnimators();
      case 'videographer':
        return _getVideographers();
      case 'cover_band':
        return _getCoverBands();
      case 'musician':
        return _getMusicians();
      case 'dancer':
        return _getDancers();
      case 'content_creator':
        return _getContentCreators();
      case 'decorator':
        return _getDecorators();
      case 'florist':
        return _getFlorists();
      case 'catering':
        return _getCatering();
      case 'cleaning':
        return _getCleaning();
      case 'fire_show':
        return _getFireShows();
      case 'equipment_rental':
        return _getEquipmentRental();
      case 'costume_rental':
        return _getCostumeRental();
      case 'venue':
        return _getVenues();
      case 'event_organizer':
        return _getEventOrganizers();
      case 'photo_studio':
        return _getPhotoStudios();
      case 'teambuilding':
        return _getTeambuilding();
      default:
        return [];
    }
  }

  /// Получить всех специалистов
  static List<Specialist> getAllSpecialists() {
    final allSpecialists = <Specialist>[];
    for (final category in SpecialistCategoryInfo.all) {
      allSpecialists.addAll(getSpecialistsByCategory(category.id));
    }
    return allSpecialists;
  }

  /// Поиск специалистов по запросу
  static List<Specialist> searchSpecialists(String query,
      {String? categoryId}) {
    final specialists = categoryId != null
        ? getSpecialistsByCategory(categoryId)
        : getAllSpecialists();

    if (query.isEmpty) return specialists;

    final lowerQuery = query.toLowerCase();
    return specialists
        .where(
          (specialist) =>
              (specialist.firstName?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (specialist.lastName?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (specialist.description?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (specialist.city.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();
  }

  /// Получить отфильтрованных специалистов
  static List<Specialist> getFilteredSpecialists(
      {String? categoryId, SpecialistFilters? filters}) {
    final specialists = categoryId != null
        ? getSpecialistsByCategory(categoryId)
        : getAllSpecialists();

    if (filters == null || !filters.hasActiveFilters) {
      return specialists;
    }

    return specialists
        .where((specialist) => _matchesFilters(specialist, filters))
        .toList();
  }

  /// Получить отсортированных специалистов
  static List<Specialist> getSortedSpecialists({
    String? categoryId,
    SpecialistFilters? filters,
    SpecialistSorting? sorting,
  }) {
    // Сначала получаем отфильтрованных специалистов
    var specialists =
        getFilteredSpecialists(categoryId: categoryId, filters: filters);

    // Затем применяем сортировку
    if (sorting != null && sorting.isActive) {
      specialists =
          SpecialistSortingUtils.sortSpecialists(specialists, sorting);
    }

    return specialists;
  }

  /// Получить специалистов с сортировкой по типу
  static List<Specialist> getSortedSpecialistsByType({
    String? categoryId,
    SpecialistFilters? filters,
    String sortBy = 'none',
  }) {
    final sorting = SpecialistSortOption.fromValue(sortBy);
    return getSortedSpecialists(
      categoryId: categoryId,
      filters: filters,
      sorting: sorting != null ? SpecialistSorting(sortOption: sorting) : null,
    );
  }

  /// Проверка соответствия специалиста фильтрам
  static bool _matchesFilters(
      Specialist specialist, SpecialistFilters filters) {
    // Фильтр по цене
    if (filters.minPrice != null || filters.maxPrice != null) {
      final priceRange = specialist.priceRange;
      if (priceRange != null) {
        if (filters.minPrice != null &&
            priceRange.maxPrice < filters.minPrice!) {
          return false;
        }
        if (filters.maxPrice != null &&
            priceRange.minPrice > filters.maxPrice!) {
          return false;
        }
      } else {
        return false; // Если у специалиста нет цены, а фильтр по цене активен
      }
    }

    // Фильтр по рейтингу
    if (filters.minRating != null && specialist.rating < filters.minRating!) {
      return false;
    }
    if (filters.maxRating != null && specialist.rating > filters.maxRating!) {
      return false;
    }

    // Фильтр по городу
    if (filters.city != null && filters.city!.isNotEmpty) {
      if (specialist.city != filters.city) {
        return false;
      }
    }

    // Фильтр по поисковому запросу
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      final fullName =
          '${specialist.firstName} ${specialist.lastName}'.toLowerCase();
      final city = specialist.city.toLowerCase() ?? '';
      final description = specialist.description?.toLowerCase() ?? '';

      if (!fullName.contains(query) &&
          !city.contains(query) &&
          !description.contains(query)) {
        return false;
      }
    }

    // Фильтр по подкатегориям
    if (filters.subcategories.isNotEmpty) {
      final hasMatchingSubcategory = filters.subcategories.any(
        (subcategory) => specialist.subcategories.contains(subcategory),
      );
      if (!hasMatchingSubcategory) {
        return false;
      }
    }

    // Фильтр по верификации
    if (filters.isVerified != null) {
      if (specialist.isVerified != filters.isVerified) {
        return false;
      }
    }

    // Фильтр по доступности
    if (filters.isAvailable != null) {
      if (specialist.isAvailable != filters.isAvailable) {
        return false;
      }
    }

    // Фильтр по доступной дате
    if (filters.availableDate != null) {
      if (!isSpecialistAvailable(specialist.id, filters.availableDate!)) {
        return false;
      }
    }

    return true;
  }

  /// Получить доступные даты для специалиста
  static List<DateTime> getAvailableDates(String specialistId) {
    // TODO(developer): Реализовать получение реальных доступных дат
    // Пока возвращаем мок-данные
    final now = DateTime.now();
    final availableDates = <DateTime>[];

    for (var i = 1; i <= 30; i++) {
      final date = now.add(Duration(days: i));
      // Исключаем выходные для демонстрации
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        availableDates.add(date);
      }
    }

    return availableDates;
  }

  /// Проверить доступность специалиста на дату
  static bool isSpecialistAvailable(String specialistId, DateTime date) {
    // Проверяем, что дата не в прошлом
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }

    // Проверяем, что дата не слишком далеко в будущем (максимум 3 месяца)
    if (date.isAfter(DateTime.now().add(const Duration(days: 90)))) {
      return false;
    }

    // Исключаем выходные дни
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }

    // Используем детерминированную логику на основе ID специалиста и даты
    // для более предсказуемого поведения в тестах
    final hash = (specialistId.hashCode + date.millisecondsSinceEpoch) % 7;
    return hash != 0; // 6 из 7 дней доступны
  }

  /// Ведущие
  static List<Specialist> _getHosts() => [
        _createSpecialist(
          id: 'host_1',
          firstName: 'Алексей',
          lastName: 'Смирнов',
          category: 'Ведущие',
          description:
              'Профессиональный ведущий с 8-летним опытом. Специализируюсь на свадебных церемониях и корпоративных мероприятиях. Создаю незабываемую атмосферу для вашего праздника.',
          priceRange: const PriceRange(minPrice: 15000, maxPrice: 35000),
          rating: 4.8,
          totalReviews: 127,
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'host_2',
          firstName: 'Анна',
          lastName: 'Петрова',
          category: 'Ведущие',
          description:
              'Опытная ведущая мероприятий. Провожу детские праздники, дни рождения и корпоративы. Индивидуальный подход к каждому клиенту.',
          priceRange: const PriceRange(minPrice: 12000, maxPrice: 28000),
          rating: 4.6,
          totalReviews: 89,
          imageUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'host_3',
          firstName: 'Михаил',
          lastName: 'Козлов',
          category: 'Ведущие',
          description:
              'Ведущий с 12-летним стажем. Работаю в различных жанрах: от официальных корпоративов до веселых свадеб. Гарантирую качество и профессионализм.',
          priceRange: const PriceRange(minPrice: 18000, maxPrice: 40000),
          rating: 4.9,
          totalReviews: 156,
          imageUrl:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'host_4',
          firstName: 'Елена',
          lastName: 'Волкова',
          category: 'Ведущие',
          description:
              'Креативная ведущая с актерским образованием. Создаю уникальные сценарии для ваших мероприятий. Специализируюсь на тематических вечеринках.',
          priceRange: const PriceRange(minPrice: 14000, maxPrice: 32000),
          rating: 4.7,
          totalReviews: 98,
          imageUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'host_5',
          firstName: 'Дмитрий',
          lastName: 'Новиков',
          category: 'Ведущие',
          description:
              'Молодой и энергичный ведущий. Специализируюсь на современных мероприятиях: тимбилдингах, промо-акциях, молодежных вечеринках.',
          priceRange: const PriceRange(minPrice: 10000, maxPrice: 25000),
          rating: 4.5,
          totalReviews: 67,
          imageUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Фотографы
  static List<Specialist> _getPhotographers() => [
        _createSpecialist(
          id: 'photo_1',
          firstName: 'Сергей',
          lastName: 'Павлов',
          category: 'Фотографы',
          description:
              'Профессиональный свадебный фотограф с 10-летним опытом. Создаю романтичные и естественные кадры. Работаю в стиле lifestyle и fine art.',
          priceRange: const PriceRange(minPrice: 25000, maxPrice: 60000),
          rating: 4.9,
          totalReviews: 203,
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'photo_2',
          firstName: 'Мария',
          lastName: 'Кузнецова',
          category: 'Фотографы',
          description:
              'Портретный и семейный фотограф. Специализируюсь на детской и семейной фотографии. Создаю теплые и душевные кадры.',
          priceRange: const PriceRange(minPrice: 15000, maxPrice: 35000),
          rating: 4.8,
          totalReviews: 145,
          imageUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'photo_3',
          firstName: 'Андрей',
          lastName: 'Лебедев',
          category: 'Фотографы',
          description:
              'Корпоративный и событийный фотограф. Снимаю конференции, презентации, корпоративы. Быстрая обработка и качественный результат.',
          priceRange: const PriceRange(minPrice: 20000, maxPrice: 45000),
          rating: 4.7,
          totalReviews: 112,
          imageUrl:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'photo_4',
          firstName: 'Ольга',
          lastName: 'Морозова',
          category: 'Фотографы',
          description:
              'Фэшн и beauty фотограф. Создаю стильные и современные образы. Работаю с моделями, блогерами, брендами одежды.',
          priceRange: const PriceRange(minPrice: 18000, maxPrice: 40000),
          rating: 4.6,
          totalReviews: 89,
          imageUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'photo_5',
          firstName: 'Игорь',
          lastName: 'Новиков',
          category: 'Фотографы',
          description:
              'Студийный и предметный фотограф. Специализируюсь на коммерческой фотографии: каталоги, реклама, интернет-магазины.',
          priceRange: const PriceRange(minPrice: 12000, maxPrice: 30000),
          rating: 4.5,
          totalReviews: 76,
          imageUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Диджеи
  static List<Specialist> _getDJs() => [
        _createSpecialist(
          id: 'dj_1',
          firstName: 'Александр',
          lastName: 'Попов',
          category: 'Диджеи',
          description:
              'Профессиональный диджей с 15-летним опытом. Работаю в клубах и на частных мероприятиях. Широкий музыкальный репертуар.',
          priceRange: const PriceRange(minPrice: 15000, maxPrice: 40000),
          rating: 4.8,
          totalReviews: 134,
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'dj_2',
          firstName: 'Екатерина',
          lastName: 'Васильева',
          category: 'Диджеи',
          description:
              'Женский диджей, специализируюсь на свадебных мероприятиях и корпоративах. Создаю атмосферу под настроение гостей.',
          priceRange: const PriceRange(minPrice: 12000, maxPrice: 30000),
          rating: 4.7,
          totalReviews: 98,
          imageUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'dj_3',
          firstName: 'Максим',
          lastName: 'Соколов',
          category: 'Диджеи',
          description:
              'Молодой диджей, играю современную музыку. Специализируюсь на молодежных вечеринках и клубных мероприятиях.',
          priceRange: const PriceRange(minPrice: 8000, maxPrice: 25000),
          rating: 4.5,
          totalReviews: 67,
          imageUrl:
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Аниматоры
  static List<Specialist> _getAnimators() => [
        _createSpecialist(
          id: 'anim_1',
          firstName: 'Татьяна',
          lastName: 'Соколова',
          category: 'Аниматоры',
          description:
              'Детский аниматор с педагогическим образованием. Провожу веселые программы для детей от 3 до 12 лет. Костюмы и реквизит включены.',
          priceRange: const PriceRange(minPrice: 5000, maxPrice: 15000),
          rating: 4.9,
          totalReviews: 156,
          imageUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'anim_2',
          firstName: 'Владимир',
          lastName: 'Петров',
          category: 'Аниматоры',
          description:
              'Аниматор для взрослых мероприятий. Провожу корпоративы, тимбилдинги, вечеринки. Интерактивные игры и конкурсы.',
          priceRange: const PriceRange(minPrice: 8000, maxPrice: 20000),
          rating: 4.7,
          totalReviews: 89,
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'anim_3',
          firstName: 'Людмила',
          lastName: 'Волкова',
          category: 'Аниматоры',
          description:
              'Универсальный аниматор. Работаю с детьми и взрослыми. Тематические программы, квесты, мастер-классы.',
          priceRange: const PriceRange(minPrice: 6000, maxPrice: 18000),
          rating: 4.6,
          totalReviews: 112,
          imageUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Видеографы
  static List<Specialist> _getVideographers() => [
        _createSpecialist(
          id: 'video_1',
          firstName: 'Николай',
          lastName: 'Смирнов',
          category: 'Видеографы',
          description:
              'Свадебный видеограф с 8-летним опытом. Создаю романтичные фильмы о вашем дне. Полный цикл: съемка, монтаж, цветокоррекция.',
          priceRange: const PriceRange(minPrice: 30000, maxPrice: 80000),
          rating: 4.9,
          totalReviews: 178,
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'video_2',
          firstName: 'Светлана',
          lastName: 'Морозова',
          category: 'Видеографы',
          description:
              'Корпоративный видеограф. Снимаю презентации, конференции, рекламные ролики. Быстрая обработка и современный стиль.',
          priceRange: const PriceRange(minPrice: 25000, maxPrice: 60000),
          rating: 4.8,
          totalReviews: 134,
          imageUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Кавер-группы
  static List<Specialist> _getCoverBands() => [
        _createSpecialist(
          id: 'band_1',
          firstName: 'Группа',
          lastName: '"Ретро-Хит"',
          category: 'Кавер-группы',
          description:
              'Кавер-группа, исполняющая хиты 80-90х годов. Полный состав: вокал, гитара, бас, барабаны, клавиши. Идеально для корпоративов.',
          priceRange: const PriceRange(minPrice: 40000, maxPrice: 80000),
          rating: 4.8,
          totalReviews: 89,
          imageUrl:
              'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
        ),
        _createSpecialist(
          id: 'band_2',
          firstName: 'Группа',
          lastName: '"Современные Хиты"',
          category: 'Кавер-группы',
          description:
              'Молодая кавер-группа, исполняющая современные хиты. Энергичные выступления, интерактив с публикой.',
          priceRange: const PriceRange(minPrice: 30000, maxPrice: 60000),
          rating: 4.6,
          totalReviews: 67,
          imageUrl:
              'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&h=400&fit=crop',
        ),
      ];

  /// Музыканты
  static List<Specialist> _getMusicians() => [
        _createSpecialist(
          id: 'music_1',
          firstName: 'Анна',
          lastName: 'Скрипка',
          category: 'Музыканты',
          description:
              'Скрипачка с консерваторским образованием. Играю классику, джаз, современную музыку. Идеально для торжественных мероприятий.',
          priceRange: const PriceRange(minPrice: 15000, maxPrice: 35000),
          rating: 4.9,
          totalReviews: 123,
          imageUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        ),
        _createSpecialist(
          id: 'music_2',
          firstName: 'Дмитрий',
          lastName: 'Пианино',
          category: 'Музыканты',
          description:
              'Пианист, лауреат международных конкурсов. Создаю атмосферу для свадеб, корпоративов, частных вечеров.',
          priceRange: const PriceRange(minPrice: 20000, maxPrice: 45000),
          rating: 4.8,
          totalReviews: 98,
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Танцоры
  static List<Specialist> _getDancers() => [
        _createSpecialist(
          id: 'dance_1',
          firstName: 'Ансамбль',
          lastName: '"Ритм"',
          category: 'Танцоры',
          description:
              'Танцевальный ансамбль из 6 человек. Исполняем латиноамериканские танцы, современную хореографию, народные танцы.',
          priceRange: const PriceRange(minPrice: 25000, maxPrice: 50000),
          rating: 4.7,
          totalReviews: 76,
          imageUrl:
              'https://images.unsplash.com/photo-1508700929628-666bc8bd84ea?w=400&h=400&fit=crop',
        ),
      ];

  /// Контент-мейкеры
  static List<Specialist> _getContentCreators() => [
        _createSpecialist(
          id: 'content_1',
          firstName: 'Максим',
          lastName: 'Блогер',
          category: 'Контент-мейкеры',
          description:
              'SMM-менеджер и контент-мейкер. Создаю контент для соцсетей, веду блоги, делаю репортажи с мероприятий.',
          priceRange: const PriceRange(minPrice: 10000, maxPrice: 25000),
          rating: 4.5,
          totalReviews: 45,
          imageUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Декораторы
  static List<Specialist> _getDecorators() => [
        _createSpecialist(
          id: 'decor_1',
          firstName: 'Елена',
          lastName: 'Декоратор',
          category: 'Оформители/Декораторы',
          description:
              'Декоратор с художественным образованием. Создаю уникальные декорации для свадеб, корпоративов, детских праздников.',
          priceRange: const PriceRange(minPrice: 20000, maxPrice: 50000),
          rating: 4.8,
          totalReviews: 112,
          imageUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Флористы
  static List<Specialist> _getFlorists() => [
        _createSpecialist(
          id: 'florist_1',
          firstName: 'Ольга',
          lastName: 'Цветы',
          category: 'Флористы',
          description:
              'Флорист с 10-летним опытом. Создаю букеты, цветочные композиции, оформляю залы живыми цветами.',
          priceRange: const PriceRange(minPrice: 8000, maxPrice: 25000),
          rating: 4.7,
          totalReviews: 89,
          imageUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
        ),
      ];

  /// Кейтеринг
  static List<Specialist> _getCatering() => [
        _createSpecialist(
          id: 'catering_1',
          firstName: 'Сервис',
          lastName: '"Вкусно и Сытно"',
          category: 'Кейтеринг',
          description:
              'Кейтеринговая служба. Организуем питание на любых мероприятиях: от фуршетов до банкетов. Собственная кухня и команда поваров.',
          priceRange: const PriceRange(minPrice: 500, maxPrice: 2000),
          rating: 4.6,
          totalReviews: 156,
          imageUrl:
              'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=400&fit=crop',
        ),
      ];

  /// Клининг
  static List<Specialist> _getCleaning() => [
        _createSpecialist(
          id: 'clean_1',
          firstName: 'Служба',
          lastName: '"Чистота Про"',
          category: 'Клининг',
          description:
              'Клининговая служба. Убираем до и после мероприятий. Быстро, качественно, с использованием профессионального оборудования.',
          priceRange: const PriceRange(minPrice: 3000, maxPrice: 15000),
          rating: 4.5,
          totalReviews: 78,
          imageUrl:
              'https://images.unsplash.com/photo-1581578731548-c6a0c3f2f6c5?w=400&h=400&fit=crop',
        ),
      ];

  /// Фаер-шоу
  static List<Specialist> _getFireShows() => [
        _createSpecialist(
          id: 'fire_1',
          firstName: 'Группа',
          lastName: '"Огненный Шоу"',
          category: 'Фаер-шоу/Световые шоу/Салюты',
          description:
              'Профессиональное фаер-шоу. Огненные представления, световые шоу, салюты. Безопасность и зрелищность гарантированы.',
          priceRange: const PriceRange(minPrice: 30000, maxPrice: 80000),
          rating: 4.9,
          totalReviews: 134,
          imageUrl:
              'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=400&fit=crop',
        ),
      ];

  /// Аренда оборудования
  static List<Specialist> _getEquipmentRental() => [
        _createSpecialist(
          id: 'equip_1',
          firstName: 'Сервис',
          lastName: '"Звук и Свет"',
          category: 'Аренда оборудования',
          description:
              'Аренда звукового и светового оборудования. Микрофоны, колонки, микшеры, прожекторы, световые эффекты. Доставка и настройка.',
          priceRange: const PriceRange(minPrice: 5000, maxPrice: 25000),
          rating: 4.7,
          totalReviews: 98,
          imageUrl:
              'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
        ),
      ];

  /// Аренда костюмов
  static List<Specialist> _getCostumeRental() => [
        _createSpecialist(
          id: 'costume_1',
          firstName: 'Салон',
          lastName: '"Элегант"',
          category: 'Аренда платьев/Костюмов',
          description:
              'Аренда вечерних платьев, костюмов, аксессуаров. Большой выбор размеров и стилей. Помощь в подборе образа.',
          priceRange: const PriceRange(minPrice: 2000, maxPrice: 10000),
          rating: 4.6,
          totalReviews: 67,
          imageUrl:
              'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=400&fit=crop',
        ),
      ];

  /// Площадки
  static List<Specialist> _getVenues() => [
        _createSpecialist(
          id: 'venue_1',
          firstName: 'Ресторан',
          lastName: '"Гранд Холл"',
          category: 'Рестораны и площадки',
          description:
              'Престижный ресторан с банкетными залами. Вместимость до 200 человек. Полный сервис: кухня, обслуживание, декорации.',
          priceRange: const PriceRange(minPrice: 100000, maxPrice: 300000),
          rating: 4.8,
          totalReviews: 145,
          imageUrl:
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=400&fit=crop',
        ),
      ];

  /// Организаторы мероприятий
  static List<Specialist> _getEventOrganizers() => [
        _createSpecialist(
          id: 'org_1',
          firstName: 'Агентство',
          lastName: '"Праздник Про"',
          category: 'Организаторы мероприятий',
          description:
              'Полная организация мероприятий под ключ. От идеи до реализации. Свадьбы, корпоративы, детские праздники, конференции.',
          priceRange: const PriceRange(minPrice: 50000, maxPrice: 200000),
          rating: 4.9,
          totalReviews: 178,
          imageUrl:
              'https://images.unsplash.com/photo-1511578314322-379afb476865?w=400&h=400&fit=crop',
        ),
      ];

  /// Фотостудии
  static List<Specialist> _getPhotoStudios() => [
        _createSpecialist(
          id: 'studio_1',
          firstName: 'Студия',
          lastName: '"Свет и Тень"',
          category: 'Фотостудии',
          description:
              'Профессиональная фотостудия с современным оборудованием. Аренда для фотосессий, видеосъемки, интервью.',
          priceRange: const PriceRange(minPrice: 3000, maxPrice: 15000),
          rating: 4.7,
          totalReviews: 89,
          imageUrl:
              'https://images.unsplash.com/photo-1606983340126-99ab4feaa64a?w=400&h=400&fit=crop',
        ),
      ];

  /// Тимбилдинг
  static List<Specialist> _getTeambuilding() => [
        _createSpecialist(
          id: 'team_1',
          firstName: 'Агентство',
          lastName: '"Команда+"',
          category: 'Тимбилдинг агентства',
          description:
              'Организация тимбилдингов и корпоративных мероприятий. Квесты, игры, тренинги на сплочение команды.',
          priceRange: const PriceRange(minPrice: 25000, maxPrice: 80000),
          rating: 4.8,
          totalReviews: 112,
          imageUrl:
              'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400&h=400&fit=crop',
        ),
      ];

  /// Создание специалиста с базовыми данными
  static Specialist _createSpecialist({
    required String id,
    required String firstName,
    required String lastName,
    required String category,
    required String description,
    required PriceRange priceRange,
    required double rating,
    required int totalReviews,
    required String imageUrl,
  }) {
    final cities = [
      'Москва',
      'Санкт-Петербург',
      'Новосибирск',
      'Екатеринбург',
      'Казань'
    ];
    final city = cities[_random.nextInt(cities.length)];

    return Specialist(
      id: id,
      userId: 'user_$id',
      name: '$firstName $lastName',
      firstName: firstName,
      lastName: lastName,
      email: '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com',
      phone:
          '+7 (999) ${_random.nextInt(900) + 100}-${_random.nextInt(90) + 10}-${_random.nextInt(90) + 10}',
      city: city,
      category: SpecialistCategory.values.firstWhere(
        (c) => c.name == category,
        orElse: () => SpecialistCategory.photographer,
      ),
      subcategories: _getSubcategoriesForCategory(category),
      experienceLevel: ExperienceLevel
          .values[_random.nextInt(ExperienceLevel.values.length)],
      yearsOfExperience: 1 + _random.nextInt(10),
      hourlyRate: priceRange.minPrice / 2,
      price: priceRange.minPrice,
      priceRange: priceRange,
      rating: rating,
      totalReviews: totalReviews,
      description: description,
      photoUrl: imageUrl,
      isVerified: _random.nextBool(),
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      updatedAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
    );
  }

  /// Получение подкатегорий для категории
  static List<String> _getSubcategoriesForCategory(String category) {
    switch (category) {
      case 'Ведущие':
        return ['Свадьбы', 'Корпоративы', 'Дни рождения'];
      case 'Фотографы':
        return ['Свадьбы', 'Портреты', 'События'];
      case 'Диджеи':
        return ['Свадьбы', 'Корпоративы', 'Клубы'];
      case 'Аниматоры':
        return ['Детские праздники', 'Корпоративы', 'Свадьбы'];
      case 'Видеографы':
        return ['Свадьбы', 'Корпоративы', 'Реклама'];
      case 'Кавер-группы':
        return ['Свадьбы', 'Корпоративы', 'Концерты'];
      case 'Музыканты':
        return ['Свадьбы', 'Корпоративы', 'Концерты'];
      case 'Танцоры':
        return ['Свадьбы', 'Корпоративы', 'Шоу'];
      case 'Контент-мейкеры':
        return ['SMM', 'Блоги', 'Репортажи'];
      case 'Оформители/Декораторы':
        return ['Свадьбы', 'Корпоративы', 'Дни рождения'];
      case 'Флористы':
        return ['Свадьбы', 'События', 'Букеты'];
      case 'Кейтеринг':
        return ['Фуршеты', 'Банкеты', 'Кофе-брейки'];
      case 'Клининг':
        return ['До мероприятия', 'После мероприятия', 'Генеральная уборка'];
      case 'Фаер-шоу/Световые шоу/Салюты':
        return ['Фаер-шоу', 'Световые шоу', 'Салюты'];
      case 'Аренда оборудования':
        return ['Звук', 'Свет', 'Сцена'];
      case 'Аренда платьев/Костюмов':
        return ['Вечерние платья', 'Костюмы', 'Аксессуары'];
      case 'Рестораны и площадки':
        return ['Банкетные залы', 'Рестораны', 'Террасы'];
      case 'Организаторы мероприятий':
        return ['Свадьбы', 'Корпоративы', 'Конференции'];
      case 'Фотостудии':
        return ['Фотосессии', 'Видеосъемка', 'Интервью'];
      case 'Тимбилдинг агентства':
        return ['Квесты', 'Игры', 'Тренинги'];
      default:
        return ['Услуги'];
    }
  }
}
