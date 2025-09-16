import 'package:flutter/foundation.dart';
import '../models/specialist.dart';
import '../models/event.dart';

/// Расширенный сервис поиска
class AdvancedSearchService {
  static final AdvancedSearchService _instance =
      AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  /// Поиск специалистов с расширенными фильтрами
  Future<List<Specialist>> searchSpecialists({
    String? query,
    SpecialistCategory? category,
    String? city,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    SearchSortType sortType = SearchSortType.rating,
    int limit = 20,
  }) async {
    try {
      // TODO: Реальная реализация поиска в Firestore
      // Пока что возвращаем mock данные
      debugPrint('Searching specialists with query: $query');
      debugPrint('Category: $category, City: $city');
      debugPrint('Price range: $minPrice - $maxPrice');
      debugPrint('Min rating: $minRating, Sort: $sortType');

      await Future.delayed(const Duration(milliseconds: 500));

      // Mock данные для демонстрации
      final mockSpecialists = _getMockSpecialists();

      // Применяем фильтры
      var filteredSpecialists = mockSpecialists.where((specialist) {
        // Фильтр по запросу
        if (query != null && query.isNotEmpty) {
          final searchQuery = query.toLowerCase();
          if (!specialist.name.toLowerCase().contains(searchQuery) &&
              !specialist.description.toLowerCase().contains(searchQuery)) {
            return false;
          }
        }

        // Фильтр по категории
        if (category != null && specialist.category != category) {
          return false;
        }

        // Фильтр по городу
        if (city != null && city.isNotEmpty) {
          if (!specialist.location.toLowerCase().contains(city.toLowerCase())) {
            return false;
          }
        }

        // Фильтр по цене
        if (minPrice != null && specialist.hourlyRate < minPrice) {
          return false;
        }
        if (maxPrice != null && specialist.hourlyRate > maxPrice) {
          return false;
        }

        // Фильтр по рейтингу
        if (minRating != null && specialist.rating < minRating) {
          return false;
        }

        return true;
      }).toList();

      // Сортируем результаты
      filteredSpecialists = _sortSpecialists(filteredSpecialists, sortType);

      // Ограничиваем количество результатов
      if (filteredSpecialists.length > limit) {
        filteredSpecialists = filteredSpecialists.take(limit).toList();
      }

      return filteredSpecialists;
    } catch (e) {
      debugPrint('Error searching specialists: $e');
      return [];
    }
  }

  /// Поиск событий с расширенными фильтрами
  Future<List<Event>> searchEvents({
    String? query,
    String? category,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    double? minPrice,
    double? maxPrice,
    SearchSortType sortType = SearchSortType.date,
    int limit = 20,
  }) async {
    try {
      // TODO: Реальная реализация поиска в Firestore
      debugPrint('Searching events with query: $query');
      debugPrint('Category: $category, City: $city');
      debugPrint('Date range: $startDate - $endDate');
      debugPrint('Price range: $minPrice - $maxPrice');

      await Future.delayed(const Duration(milliseconds: 500));

      // Mock данные для демонстрации
      final mockEvents = _getMockEvents();

      // Применяем фильтры
      var filteredEvents = mockEvents.where((event) {
        // Фильтр по запросу
        if (query != null && query.isNotEmpty) {
          final searchQuery = query.toLowerCase();
          if (!event.title.toLowerCase().contains(searchQuery) &&
              !event.description.toLowerCase().contains(searchQuery)) {
            return false;
          }
        }

        // Фильтр по категории
        if (category != null && category.isNotEmpty) {
          if (!event.category.toLowerCase().contains(category.toLowerCase())) {
            return false;
          }
        }

        // Фильтр по дате
        if (startDate != null && event.startDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && event.startDate.isAfter(endDate)) {
          return false;
        }

        // Фильтр по цене
        if (minPrice != null && event.price < minPrice) {
          return false;
        }
        if (maxPrice != null && event.price > maxPrice) {
          return false;
        }

        return true;
      }).toList();

      // Сортируем результаты
      filteredEvents = _sortEvents(filteredEvents, sortType);

      // Ограничиваем количество результатов
      if (filteredEvents.length > limit) {
        filteredEvents = filteredEvents.take(limit).toList();
      }

      return filteredEvents;
    } catch (e) {
      debugPrint('Error searching events: $e');
      return [];
    }
  }

  /// Сортировка специалистов
  List<Specialist> _sortSpecialists(
      List<Specialist> specialists, SearchSortType sortType) {
    switch (sortType) {
      case SearchSortType.rating:
        specialists.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SearchSortType.price:
        specialists.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
        break;
      case SearchSortType.name:
        specialists.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SearchSortType.newest:
        specialists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SearchSortType.reviews:
        specialists.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
        break;
      default:
        specialists.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return specialists;
  }

  /// Сортировка событий
  List<Event> _sortEvents(List<Event> events, SearchSortType sortType) {
    switch (sortType) {
      case SearchSortType.date:
        events.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case SearchSortType.price:
        events.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SearchSortType.name:
        events.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SearchSortType.newest:
        events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SearchSortType.rating:
        // Для событий используем количество участников как "рейтинг"
        events.sort(
            (a, b) => b.currentParticipants.compareTo(a.currentParticipants));
        break;
      default:
        events.sort((a, b) => a.startDate.compareTo(b.startDate));
    }
    return events;
  }

  /// Получить популярные поисковые запросы
  Future<List<String>> getPopularQueries() async {
    // TODO: Реальная реализация из аналитики
    return [
      'фотограф',
      'видеограф',
      'диджей',
      'декоратор',
      'свадьба',
      'день рождения',
      'корпоратив',
      'детский праздник',
    ];
  }

  /// Получить рекомендуемые категории
  Future<List<SpecialistCategory>> getRecommendedCategories() async {
    // TODO: Реальная реализация на основе пользовательских предпочтений
    return [
      SpecialistCategory.photographer,
      SpecialistCategory.videographer,
      SpecialistCategory.dj,
      SpecialistCategory.decorator,
      SpecialistCategory.animator,
    ];
  }

  /// Mock данные специалистов
  List<Specialist> _getMockSpecialists() {
    return [
      Specialist(
        id: '1',
        name: 'Анна Петрова',
        description: 'Профессиональный фотограф с 5-летним опытом',
        category: SpecialistCategory.photographer,
        location: 'Москва',
        hourlyRate: 5000.0,
        rating: 4.8,
        reviewsCount: 127,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      Specialist(
        id: '2',
        name: 'Михаил Сидоров',
        description: 'Видеограф, специализирующийся на свадебных съемках',
        category: SpecialistCategory.videographer,
        location: 'Санкт-Петербург',
        hourlyRate: 8000.0,
        rating: 4.9,
        reviewsCount: 89,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
      ),
      Specialist(
        id: '3',
        name: 'Елена Козлова',
        description: 'Диджей с большим опытом работы на мероприятиях',
        category: SpecialistCategory.dj,
        location: 'Москва',
        hourlyRate: 3000.0,
        rating: 4.7,
        reviewsCount: 156,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Mock данные событий
  List<Event> _getMockEvents() {
    return [
      Event(
        id: '1',
        title: 'Свадебная фотосессия в парке',
        description: 'Романтическая фотосессия на природе',
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 7, hours: 3)),
        location: 'Парк Сокольники, Москва',
        maxParticipants: 2,
        currentParticipants: 0,
        price: 15000.0,
        organizerId: '1',
        organizerName: 'Анна Петрова',
        category: 'Фотосессия',
        tags: const ['свадьба', 'фотосессия', 'парк'],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      Event(
        id: '2',
        title: 'Детский день рождения',
        description: 'Веселый праздник с аниматором',
        startDate: DateTime.now().add(const Duration(days: 14)),
        endDate: DateTime.now().add(const Duration(days: 14, hours: 4)),
        location: 'Детский центр, Москва',
        maxParticipants: 15,
        currentParticipants: 8,
        price: 25000.0,
        organizerId: '2',
        organizerName: 'Михаил Сидоров',
        category: 'Детский праздник',
        tags: const ['дети', 'день рождения', 'аниматор'],
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

/// Типы сортировки для поиска
enum SearchSortType {
  rating,
  price,
  name,
  newest,
  reviews,
  date,
}
