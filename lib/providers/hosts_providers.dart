import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/host_profile.dart';
import 'package:event_marketplace_app/models/smart_specialist.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/providers/real_hosts_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Фильтры для поиска ведущих
class HostFilters {
  const HostFilters({
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

  HostFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxRating,
    String? city,
    DateTime? availableDate,
    String? searchQuery,
  }) =>
      HostFilters(
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
    return other is HostFilters &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating &&
        other.maxRating == maxRating &&
        other.city == city &&
        other.availableDate == availableDate &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(minPrice, maxPrice, minRating, maxRating,
      city, availableDate, searchQuery,);
}

/// Провайдер фильтров для ведущих
final hostFiltersProvider =
    StateProvider<HostFilters>((ref) => const HostFilters());

/// Провайдер для загрузки всех ведущих с фильтрами
final hostsProvider = FutureProvider.family<List<Specialist>, HostFilters>(
  (ref, filters) async {
    if (FeatureFlags.useRealHosts) {
      return ref
          .read(RealHostsProviders.hostsWithFiltersProvider(filters).future);
    }
    return _loadHostsWithFilters(filters);
  },
);

/// Провайдер для пагинированной загрузки ведущих (мигрирован с StateNotifierProvider)
final paginatedHostsProvider =
    NotifierProvider<PaginatedHostsNotifier, AsyncValue<List<Specialist>>>(
  PaginatedHostsNotifier.new,
);

/// Провайдер для получения mock-данных ведущих (для тестирования) (мигрирован с StateNotifierProvider)
final mockPaginatedHostsProvider =
    NotifierProvider<MockPaginatedHostsNotifier, AsyncValue<List<Specialist>>>(
  MockPaginatedHostsNotifier.new,
);

/// Провайдер для получения уникальных городов ведущих
final hostCitiesProvider = FutureProvider<List<String>>((ref) async {
  // TODO(developer): Заменить на реальные данные из Firebase
  // Пока используем mock-данные
  final mockHosts = _generateMockHosts();
  final cities = mockHosts.map((host) => host.city).toSet().toList();
  cities.sort();
  return cities;
});

/// Провайдер для получения ценового диапазона всех ведущих
final hostPriceRangeProvider = FutureProvider<Map<String, double>>((ref) async {
  // TODO(developer): Заменить на реальные данные из Firebase
  // Пока используем mock-данные
  final mockHosts = _generateMockHosts();
  var minPrice = double.infinity;
  double maxPrice = 0;

  for (final host in mockHosts) {
    final priceRange = host.priceRange;
    if (priceRange != null) {
      if (priceRange.minPrice < minPrice) minPrice = priceRange.minPrice;
      if (priceRange.maxPrice > maxPrice) maxPrice = priceRange.maxPrice;
    }
  }

  return {'min': minPrice == double.infinity ? 0 : minPrice, 'max': maxPrice};
});

/// Загрузка ведущих с применением фильтров
Future<List<Specialist>> _loadHostsWithFilters(HostFilters filters) async {
  try {
    var query = FirebaseFirestore.instance
        .collection('specialists')
        .where('category', isEqualTo: 'Ведущие');

    // Фильтр по городу
    if (filters.city != null && filters.city!.isNotEmpty) {
      query = query.where('city', isEqualTo: filters.city);
    }

    // Фильтр по рейтингу
    if (filters.minRating != null) {
      query = query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
    }

    final querySnapshot = await query.get();
    final specialists = <Specialist>[];

    for (final doc in querySnapshot.docs) {
      try {
        final specialist = Specialist.fromFirestore(doc);

        // Применяем фильтры на клиенте (для сложных фильтров)
        if (_matchesFilters(specialist, filters)) {
          specialists.add(specialist);
        }
      } on Exception {
        // Пропускаем некорректные документы
        continue;
      }
    }

    // Сортируем по рейтингу (по убыванию)
    specialists.sort((a, b) => b.rating.compareTo(a.rating));

    return specialists;
  } catch (e) {
    throw Exception('Ошибка загрузки ведущих: $e');
  }
}

/// Проверка соответствия специалиста фильтрам
bool _matchesFilters(Specialist specialist, HostFilters filters) {
  // Фильтр по цене
  if (filters.minPrice != null || filters.maxPrice != null) {
    final priceRange = specialist.priceRange;
    if (priceRange != null) {
      if (filters.minPrice != null && priceRange.maxPrice < filters.minPrice!) {
        return false;
      }
      if (filters.maxPrice != null && priceRange.minPrice > filters.maxPrice!) {
        return false;
      }
    }
  }

  // Фильтр по рейтингу (уже применен в запросе, но проверяем еще раз)
  if (filters.maxRating != null && specialist.rating > filters.maxRating!) {
    return false;
  }

  // Фильтр по поисковому запросу
  if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
    final query = filters.searchQuery!.toLowerCase();
    final fullName =
        '${specialist.firstName} ${specialist.lastName}'.toLowerCase();
    final city = specialist.city.toLowerCase();

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

/// Notifier для пагинированной загрузки ведущих (мигрирован с StateNotifier)
class PaginatedHostsNotifier extends Notifier<AsyncValue<List<Specialist>>> {
  @override
  AsyncValue<List<Specialist>> build() {
    loadHosts();
    return const AsyncValue.loading();
  }

  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  HostFilters _currentFilters = const HostFilters();

  Future<void> loadHosts({bool refresh = false}) async {
    if (refresh) {
      _lastDocument = null;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      var query = FirebaseFirestore.instance
          .collection('specialists')
          .where('category', isEqualTo: 'Ведущие')
          .orderBy('rating', descending: true)
          .limit(_pageSize);

      // Применяем фильтры
      if (_currentFilters.city != null && _currentFilters.city!.isNotEmpty) {
        query = query.where('city', isEqualTo: _currentFilters.city);
      }

      if (_currentFilters.minRating != null) {
        query = query.where('rating',
            isGreaterThanOrEqualTo: _currentFilters.minRating,);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();
      final newSpecialists = <Specialist>[];

      for (final doc in querySnapshot.docs) {
        try {
          final specialist = Specialist.fromFirestore(doc);
          if (_matchesFilters(specialist, _currentFilters)) {
            newSpecialists.add(specialist);
          }
        } on Exception {
          continue;
        }
      }

      _lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      _hasMore = querySnapshot.docs.length == _pageSize;

      final currentList = state.valueOrNull ?? <Specialist>[];
      final updatedList =
          refresh ? newSpecialists : [...currentList, ...newSpecialists];

      state = AsyncValue.data(updatedList);
    } on Exception catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> applyFilters(HostFilters filters) async {
    _currentFilters = filters;
    await loadHosts(refresh: true);
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await loadHosts();
    }
  }

  void clearFilters() {
    _currentFilters = const HostFilters();
    loadHosts(refresh: true);
  }
}

/// Провайдер для получения mock-данных ведущих (для тестирования)
final mockHostsProvider =
    Provider<List<Specialist>>((ref) => _generateMockHosts());

/// Генерация mock-данных для ведущих
List<Specialist> _generateMockHosts() {
  final cities = [
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Казань',
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
  ];

  return List.generate(15, (index) {
    final name = names[index % names.length];
    final city = cities[index % cities.length];
    final rating = 3.5 + (index % 15) * 0.1; // Рейтинг от 3.5 до 5.0
    final minPrice = 10000 + (index % 10) * 5000; // Цена от 10k до 60k
    final maxPrice = minPrice + 20000;

    return Specialist(
      id: 'host_${index + 1}',
      name: '${name.$1} ${name.$2}',
      city: city,
      category: SpecialistCategory.other,
      subcategories: const ['Свадьбы', 'Корпоративы', 'Дни рождения'],
      priceRangeString: '$minPrice-$maxPrice руб/час',
      rating: rating,
      totalReviews: 10 + (index % 50),
      description:
          'Профессиональный ведущий с ${5 + (index % 10)}-летним опытом работы. '
          'Специализируюсь на ${index % 2 == 0 ? 'свадебных церемониях' : 'корпоративных мероприятиях'}. '
          'Создаю незабываемую атмосферу для вашего праздника.',
      imageUrl:
          'https://images.unsplash.com/photo-${1500000000000 + index * 1000000}?w=400&h=400&fit=crop&crop=face',
      isVerified: index % 3 == 0,
      createdAt: DateTime.now().subtract(Duration(days: 365 - index * 10)),
      updatedAt: DateTime.now().subtract(Duration(days: index)),
    );
  });
}

/// Notifier для пагинированной загрузки mock-данных ведущих (мигрирован с StateNotifier)
class MockPaginatedHostsNotifier
    extends Notifier<AsyncValue<List<Specialist>>> {
  @override
  AsyncValue<List<Specialist>> build() {
    loadHosts();
    return const AsyncValue.loading();
  }

  static const int _pageSize = 6;
  int _currentPage = 0;
  bool _hasMore = true;
  HostFilters _currentFilters = const HostFilters();
  List<Specialist> _allHosts = [];

  Future<void> loadHosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      // Генерируем mock-данные только один раз
      if (_allHosts.isEmpty) {
        _allHosts = _generateMockHosts();
      }

      // Применяем фильтры
      final filteredHosts = _allHosts
          .where((host) => _matchesFilters(host, _currentFilters))
          .toList();

      // Пагинация
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, filteredHosts.length);

      if (startIndex >= filteredHosts.length) {
        _hasMore = false;
        return;
      }

      final newHosts = filteredHosts.sublist(startIndex, endIndex);
      _hasMore = endIndex < filteredHosts.length;
      _currentPage++;

      final currentList = state.valueOrNull ?? <Specialist>[];
      final updatedList = refresh ? newHosts : [...currentList, ...newHosts];

      state = AsyncValue.data(updatedList);
    } on Exception catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> applyFilters(HostFilters filters) async {
    _currentFilters = filters;
    await loadHosts(refresh: true);
  }

  Future<void> loadMore() async {
    if (_hasMore && !state.isLoading) {
      await loadHosts();
    }
  }

  void clearFilters() {
    _currentFilters = const HostFilters();
    loadHosts(refresh: true);
  }

  /// Проверка соответствия специалиста фильтрам
  bool _matchesFilters(Specialist specialist, HostFilters filters) {
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
      final city = specialist.city.toLowerCase();

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
