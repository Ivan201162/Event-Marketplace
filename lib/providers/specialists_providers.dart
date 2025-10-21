import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/common_types.dart';
import '../models/price_range.dart';
import '../models/specialist.dart';
import '../services/mock_data_service.dart';

/// Категории специалистов
enum SpecialistCategory {
  host('Ведущие', 'host', '🎤'),
  dj('Диджеи', 'dj', '🎧'),
  photographer('Фотографы', 'photographer', '📸'),
  animator('Аниматоры', 'animator', '🎭'),
  videographer('Видеографы', 'videographer', '🎬'),
  decorator('Декораторы', 'decorator', '🎨'),
  musician('Музыканты', 'musician', '🎵'),
  makeup('Визажисты', 'makeup', '💄');

  const SpecialistCategory(this.displayName, this.value, this.emoji);

  final String displayName;
  final String value;
  final String emoji;

  static SpecialistCategory? fromValue(String value) {
    for (final category in SpecialistCategory.values) {
      if (category.value == value) {
        return category;
      }
    }
    return null;
  }
}

/// Фильтры для поиска специалистов
class SpecialistFilters {
  const SpecialistFilters({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxRating,
    this.city,
    this.availableDate,
    this.searchQuery,
  });
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final double? maxRating;
  final String? city;
  final DateTime? availableDate;
  final String? searchQuery;

  SpecialistFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxRating,
    String? city,
    DateTime? availableDate,
    String? searchQuery,
  }) =>
      SpecialistFilters(
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minRating: minRating ?? this.minRating,
        maxRating: maxRating ?? this.maxRating,
        city: city ?? this.city,
        availableDate: availableDate ?? this.availableDate,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      maxRating != null ||
      city != null ||
      availableDate != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistFilters &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating &&
        other.maxRating == maxRating &&
        other.city == city &&
        other.availableDate == availableDate &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(
        minPrice,
        maxPrice,
        minRating,
        maxRating,
        city,
        availableDate,
        searchQuery,
      );
}

/// Провайдер фильтров для специалистов
final specialistFiltersProvider =
    StateProvider<SpecialistFilters>((ref) => const SpecialistFilters());

/// Провайдер для загрузки специалистов по категории с фильтрами
final specialistsProvider = FutureProvider.family<List<Specialist>, String>(
  (ref, category) async => MockDataService.getSpecialistsByCategory(category),
);

/// Провайдер для пагинированной загрузки специалистов (мигрирован с StateNotifierProvider)
final paginatedSpecialistsProvider =
    NotifierProvider.family<PaginatedSpecialistsNotifier, AsyncValue<List<Specialist>>, String>(
        () => PaginatedSpecialistsNotifier());

/// Провайдер для получения уникальных городов специалистов по категории
final specialistCitiesProvider = FutureProvider.family<List<String>, String>((ref, category) async {
  final specialists = MockDataService.getSpecialistsByCategory(category);
  final cities = specialists
      .map((specialist) => specialist.city)
      .where((city) => city != null)
      .cast<String>()
      .toSet()
      .toList();
  cities.sort();
  return cities;
});

/// Провайдер для получения ценового диапазона специалистов по категории
final specialistPriceRangeProvider =
    FutureProvider.family<Map<String, double>, String>((ref, category) async {
  final specialists = MockDataService.getSpecialistsByCategory(category);
  var minPrice = double.infinity;
  double maxPrice = 0;

  for (final specialist in specialists) {
    final price = specialist.pricePerHour;
    if (price < minPrice) minPrice = price;
    if (price > maxPrice) maxPrice = price;
  }

  return {
    'min': minPrice == double.infinity ? 0 : minPrice,
    'max': maxPrice,
  };
});

/// Провайдер для поиска специалистов
final searchSpecialistsProvider = FutureProvider.family<List<Specialist>, String>(
  (ref, query) async => MockDataService.searchSpecialists(query),
);

/// Загрузка специалистов по категории с применением фильтров
Future<List<Specialist>> _loadSpecialistsByCategory(String category) async {
  try {
    final query =
        FirebaseFirestore.instance.collection('specialists').where('category', isEqualTo: category);

    final querySnapshot = await query.get();
    final specialists = <Specialist>[];

    for (final doc in querySnapshot.docs) {
      try {
        final specialist = Specialist.fromDocument(doc);
        specialists.add(specialist);
      } on Exception {
        // Пропускаем некорректные документы
        continue;
      }
    }

    // Сортируем по рейтингу (по убыванию)
    specialists.sort((a, b) => b.rating.compareTo(a.rating));

    return specialists;
  } catch (e) {
    throw Exception('Ошибка загрузки специалистов: $e');
  }
}

/// Notifier для пагинированной загрузки специалистов (мигрирован с StateNotifier)
class PaginatedSpecialistsNotifier extends FamilyNotifier<AsyncValue<List<Specialist>>, String> {
  @override
  AsyncValue<List<Specialist>> build(String category) {
    loadSpecialists();
    return const AsyncValue.loading();
  }

  static const int _pageSize = 8;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  SpecialistFilters _currentFilters = const SpecialistFilters();
  List<Specialist> _allSpecialists = [];

  Future<void> loadSpecialists({bool refresh = false}) async {
    if (refresh) {
      _lastDocument = null;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      // Загружаем mock-данные только один раз
      if (_allSpecialists.isEmpty) {
        _allSpecialists = MockDataService.getSpecialistsByCategory(category);
      }

      // Применяем фильтры
      final filteredSpecialists = _allSpecialists
          .where((specialist) => _matchesFilters(specialist, _currentFilters))
          .toList();

      // Пагинация
      final startIndex = (_lastDocument != null ? _getCurrentPage() : 0) * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, filteredSpecialists.length);

      if (startIndex >= filteredSpecialists.length) {
        _hasMore = false;
        return;
      }

      final newSpecialists = filteredSpecialists.sublist(startIndex, endIndex);
      _hasMore = endIndex < filteredSpecialists.length;

      _lastDocument ??= _createMockDocument();

      final currentList = state.valueOrNull ?? <Specialist>[];
      final updatedList = refresh ? newSpecialists : [...currentList, ...newSpecialists];

      state = AsyncValue.data(updatedList);
    } on Exception catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  int _getCurrentPage() {
    final currentList = state.valueOrNull ?? <Specialist>[];
    return (currentList.length / _pageSize).floor();
  }

  DocumentSnapshot _createMockDocument() {
    // Создаем mock DocumentSnapshot для пагинации
    return MockDocumentSnapshot();
  }

  Future<void> applyFilters(SpecialistFilters filters) async {
    _currentFilters = filters;
    await loadSpecialists(refresh: true);
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await loadSpecialists();
    }
  }

  void clearFilters() {
    _currentFilters = const SpecialistFilters();
    loadSpecialists(refresh: true);
  }

  /// Проверка соответствия специалиста фильтрам
  bool _matchesFilters(Specialist specialist, SpecialistFilters filters) {
    // Фильтр по цене
    if (filters.minPrice != null || filters.maxPrice != null) {
      final price = specialist.pricePerHour;
      if (filters.minPrice != null && price < filters.minPrice!) {
        return false;
      }
      if (filters.maxPrice != null && price > filters.maxPrice!) {
        return false;
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
      final fullName = specialist.name.toLowerCase();
      final city = specialist.city.toLowerCase() ?? '';

      if (!fullName.contains(query) && !city.contains(query)) {
        return false;
      }
    }

    // Фильтр по доступной дате
    if (filters.availableDate != null) {
      // TODO(developer): Реализовать проверку доступности даты
      // Пока что возвращаем true для всех
    }

    return true;
  }
}

/// Mock DocumentSnapshot для пагинации
class MockDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  String get id => 'mock_doc';

  @override
  Map<String, dynamic>? data() => {'id': 'mock_doc'};

  @override
  dynamic get(Object field) => null;

  @override
  dynamic operator [](Object field) => null;

  @override
  bool get exists => true;

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}

/// Генерация mock-данных для специалистов по категории
List<Specialist> _generateMockSpecialistsForCategory(String category) {
  final categoryEnum = SpecialistCategory.fromValue(category);
  if (categoryEnum == null) return [];

  final cities = [
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Казань',
    'Нижний Новгород',
  ];
  final names = [
    ('Алексей', 'Смирнов'),
    ('Анна', 'Петрова'),
    ('Михаил', 'Козлов'),
    ('Елена', 'Волкова'),
    ('Дмитрий', 'Новиков'),
    ('Ольга', 'Морозова'),
    ('Сергей', 'Павлов'),
    ('Татьяна', 'Соколова'),
    ('Андрей', 'Лебедев'),
    ('Наталья', 'Козлова'),
    ('Игорь', 'Новиков'),
    ('Светлана', 'Морозова'),
    ('Владимир', 'Петров'),
    ('Людмила', 'Волкова'),
    ('Николай', 'Смирнов'),
    ('Мария', 'Кузнецова'),
    ('Александр', 'Попов'),
    ('Екатерина', 'Васильева'),
    ('Максим', 'Соколов'),
    ('Юлия', 'Михайлова'),
  ];

  // Количество специалистов в зависимости от категории
  final count = _getSpecialistCountForCategory(categoryEnum);

  return List.generate(count, (index) {
    final name = names[index % names.length];
    final city = cities[index % cities.length];
    final rating = 3.0 + (index % 20) * 0.1; // Рейтинг от 3.0 до 5.0
    final priceRange = _getPriceRangeForCategory(categoryEnum, index);
    final subcategories = _getSubcategoriesForCategory(categoryEnum);

    return Specialist(
      id: '${category}_${index + 1}',
      userId: 'user_${index + 1}',
      name: '${name.$1} ${name.$2}',
      specialization: _getSpecializationForCategory(categoryEnum),
      city: city,
      rating: rating,
      pricePerHour: priceRange.minPrice.toInt(),
      category: _getSpecialistCategoryFromString(categoryEnum.displayName),
      experienceLevel: ExperienceLevel.values[index % ExperienceLevel.values.length],
      yearsOfExperience: 1 + (index % 10),
      description: _getDescriptionForCategory(categoryEnum, index),
      avatarUrl:
          'https://images.unsplash.com/photo-${1500000000000 + index * 1000000}?w=400&h=400&fit=crop&crop=face',
      isVerified: index % 4 == 0,
      createdAt: DateTime.now().subtract(Duration(days: 365 - index * 5)),
      updatedAt: DateTime.now().subtract(Duration(days: index)),
    );
  });
}

/// Преобразование строки в SpecialistCategory
SpecialistCategory _getSpecialistCategoryFromString(String categoryName) {
  switch (categoryName) {
    case 'Ведущие':
      return SpecialistCategory.host;
    case 'Диджеи':
      return SpecialistCategory.dj;
    case 'Фотографы':
      return SpecialistCategory.photographer;
    case 'Аниматоры':
      return SpecialistCategory.animator;
    case 'Видеографы':
      return SpecialistCategory.videographer;
    case 'Декораторы':
      return SpecialistCategory.decorator;
    case 'Музыканты':
      return SpecialistCategory.musician;
    case 'Визажисты':
      return SpecialistCategory.makeup;
    default:
      return SpecialistCategory.host;
  }
}

/// Получение количества специалистов для категории
int _getSpecialistCountForCategory(SpecialistCategory category) {
  switch (category) {
    case SpecialistCategory.host:
      return 15;
    case SpecialistCategory.dj:
      return 12;
    case SpecialistCategory.photographer:
      return 20;
    case SpecialistCategory.animator:
      return 10;
    case SpecialistCategory.videographer:
      return 8;
    case SpecialistCategory.decorator:
      return 6;
    case SpecialistCategory.musician:
      return 14;
    case SpecialistCategory.makeup:
      return 9;
  }
}

/// Получение ценового диапазона для категории
PriceRange _getPriceRangeForCategory(SpecialistCategory category, int index) {
  switch (category) {
    case SpecialistCategory.host:
      final minPrice = 10000 + (index % 10) * 5000;
      return PriceRange(
        minPrice: minPrice.toDouble(),
        maxPrice: (minPrice + 20000).toDouble(),
      );
    case SpecialistCategory.dj:
      final minPrice = 8000 + (index % 8) * 3000;
      return PriceRange(
        min: minPrice.toDouble(),
        max: (minPrice + 15000).toDouble(),
      );
    case SpecialistCategory.photographer:
      final minPrice = 15000 + (index % 12) * 4000;
      return PriceRange(
        min: minPrice.toDouble(),
        max: (minPrice + 25000).toDouble(),
      );
    case SpecialistCategory.animator:
      final minPrice = 5000 + (index % 6) * 2000;
      return PriceRange(
        minPrice: minPrice.toDouble(),
        maxPrice: (minPrice + 10000).toDouble(),
      );
    case SpecialistCategory.videographer:
      final minPrice = 20000 + (index % 8) * 5000;
      return PriceRange(
        minPrice: minPrice.toDouble(),
        maxPrice: (minPrice + 30000).toDouble(),
      );
    case SpecialistCategory.decorator:
      final minPrice = 12000 + (index % 5) * 4000;
      return PriceRange(
        minPrice: minPrice.toDouble(),
        maxPrice: (minPrice + 18000).toDouble(),
      );
    case SpecialistCategory.musician:
      final minPrice = 6000 + (index % 7) * 2000;
      return PriceRange(
        minPrice: minPrice.toDouble(),
        maxPrice: (minPrice + 12000).toDouble(),
      );
    case SpecialistCategory.makeup:
      final minPrice = 3000 + (index % 6) * 1500;
      return PriceRange(
        minPrice: minPrice.toDouble(),
        maxPrice: (minPrice + 8000).toDouble(),
      );
  }
}

/// Получение подкатегорий для категории
List<String> _getSubcategoriesForCategory(SpecialistCategory category) {
  switch (category) {
    case SpecialistCategory.host:
      return ['Свадьбы', 'Корпоративы', 'Дни рождения'];
    case SpecialistCategory.dj:
      return ['Свадьбы', 'Корпоративы', 'Клубы'];
    case SpecialistCategory.photographer:
      return ['Свадьбы', 'Портреты', 'События'];
    case SpecialistCategory.animator:
      return ['Детские праздники', 'Корпоративы', 'Свадьбы'];
    case SpecialistCategory.videographer:
      return ['Свадьбы', 'Корпоративы', 'Реклама'];
    case SpecialistCategory.decorator:
      return ['Свадьбы', 'Корпоративы', 'Дни рождения'];
    case SpecialistCategory.musician:
      return ['Свадьбы', 'Корпоративы', 'Концерты'];
    case SpecialistCategory.makeup:
      return ['Свадьбы', 'События', 'Фотосессии'];
  }
}

/// Получение описания для категории
String _getDescriptionForCategory(SpecialistCategory category, int index) {
  final experience = 3 + (index % 10);

  switch (category) {
    case SpecialistCategory.host:
      return 'Профессиональный ведущий с $experience-летним опытом работы. Специализируюсь на свадебных церемониях и корпоративных мероприятиях. Создаю незабываемую атмосферу для вашего праздника.';
    case SpecialistCategory.dj:
      return 'Опытный диджей с $experience-летним стажем. Работаю в различных жанрах музыки. Обеспечиваю качественное звуковое сопровождение вашего мероприятия.';
    case SpecialistCategory.photographer:
      return 'Профессиональный фотограф с $experience-летним опытом. Специализируюсь на свадебной и портретной фотографии. Создаю красивые и запоминающиеся кадры.';
    case SpecialistCategory.animator:
      return 'Креативный аниматор с $experience-летним опытом работы с детьми. Провожу веселые и интересные программы для детских праздников.';
    case SpecialistCategory.videographer:
      return 'Опытный видеограф с $experience-летним стажем. Создаю качественные видеоролики для свадеб, корпоративов и рекламных проектов.';
    case SpecialistCategory.decorator:
      return 'Талантливый декоратор с $experience-летним опытом. Создаю уникальные декорации для различных мероприятий. Превращаю ваши идеи в реальность.';
    case SpecialistCategory.musician:
      return 'Профессиональный музыкант с $experience-летним опытом выступлений. Играю на различных инструментах и создаю атмосферу для вашего события.';
    case SpecialistCategory.makeup:
      return 'Опытный визажист с $experience-летним стажем. Специализируюсь на свадебном и вечернем макияже. Подчеркиваю вашу естественную красоту.';
  }
}

/// Получить специализацию для категории
String _getSpecializationForCategory(SpecialistCategory category) {
  switch (category) {
    case SpecialistCategory.host:
      return 'Ведущий мероприятий';
    case SpecialistCategory.photographer:
      return 'Фотограф';
    case SpecialistCategory.dj:
      return 'Диск-жокей';
    case SpecialistCategory.musician:
      return 'Музыкант';
    case SpecialistCategory.decorator:
      return 'Декоратор';
    case SpecialistCategory.florist:
      return 'Флорист';
    case SpecialistCategory.animator:
      return 'Аниматор';
    case SpecialistCategory.makeup:
      return 'Визажист';
    default:
      return 'Специалист';
  }
}
