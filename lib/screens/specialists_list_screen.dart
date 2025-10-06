import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../models/specialist_categories.dart';
import '../widgets/specialist_card.dart';
import 'specialist_profile_screen.dart';

class SpecialistsListScreen extends ConsumerStatefulWidget {
  const SpecialistsListScreen({
    super.key,
    required this.category,
  });

  final SpecialistCategoryInfo category;

  @override
  ConsumerState<SpecialistsListScreen> createState() =>
      _SpecialistsListScreenState();
}

class _SpecialistsListScreenState extends ConsumerState<SpecialistsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем специалистов по категории
    final specialistsAsync =
        ref.watch(specialistsByCategoryProvider(widget.category.name));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              widget.category.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.category.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          _buildSearchBar(),

          // Фильтры
          if (_showFilters) _buildFiltersSection(),

          // Результаты
          Expanded(
            child: specialistsAsync.when(
              data: (specialists) {
                final filteredSpecialists = _filterSpecialists(specialists);

                if (filteredSpecialists.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                      specialistsByCategoryProvider(widget.category.name),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSpecialists.length,
                    itemBuilder: (context, index) {
                      final specialist = filteredSpecialists[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SpecialistCard(
                          specialist: specialist,
                          onTap: () => _navigateToSpecialistProfile(specialist),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Загрузка специалистов...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(
                          specialistsByCategoryProvider(
                            widget.category.name,
                          ),
                        );
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Построить поисковую строку
  Widget _buildSearchBar() => Container(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск в категории "${widget.category.name}"...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      );

  /// Построить секцию фильтров
  Widget _buildFiltersSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фильтры',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Фильтр по цене
            _buildPriceFilter(),

            const SizedBox(height: 16),

            // Фильтр по рейтингу
            _buildRatingFilter(),

            const SizedBox(height: 16),

            // Фильтр по опыту
            _buildExperienceFilter(),
          ],
        ),
      );

  /// Построить фильтр по цене
  Widget _buildPriceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цена за час',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'От',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'До',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      );

  /// Построить фильтр по рейтингу
  Widget _buildRatingFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Минимальный рейтинг',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                icon: Icon(
                  Icons.star,
                  color: index < 4 ? Colors.amber : Colors.grey[300],
                ),
                onPressed: () {
                  // TODO(developer): Реализовать фильтр по рейтингу
                },
              ),
            ),
          ),
        ],
      );

  /// Построить фильтр по опыту
  Widget _buildExperienceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Уровень опыта',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ExperienceLevel.values
                .map(
                  (level) => FilterChip(
                    label: Text(level.displayName),
                    onSelected: (selected) {
                      // TODO(developer): Реализовать фильтр по опыту
                    },
                  ),
                )
                .toList(),
          ),
        ],
      );

  /// Построить пустое состояние
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет специалистов по запросу',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить поисковый запрос',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Text('Очистить поиск'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.category.emoji,
            style: TextStyle(
              fontSize: 64,
              color: widget.category.color.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'В категории "${widget.category.name}" пока нет специалистов',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.category.description,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Вернуться к категориям'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.category.color,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Фильтровать специалистов
  List<Specialist> _filterSpecialists(List<Specialist> specialists) {
    if (_searchQuery.isEmpty) {
      return specialists;
    }

    final searchLower = _searchQuery.toLowerCase();
    return specialists
        .where(
          (specialist) =>
              specialist.name.toLowerCase().contains(searchLower) ||
                  specialist.description?.toLowerCase().contains(searchLower) ??
              false ||
                  specialist.category.displayName
                      .toLowerCase()
                      .contains(searchLower) ||
                  specialist.subcategories
                      .any((sub) => sub.toLowerCase().contains(searchLower)),
        )
        .toList();
  }

  /// Перейти к профилю специалиста
  void _navigateToSpecialistProfile(Specialist specialist) {
    Navigator.of(context).push(
      MaterialPageRoute<SpecialistProfileScreen>(
        builder: (context) =>
            SpecialistProfileScreen(specialistId: specialist.id),
      ),
    );
  }
}

/// Provider для получения специалистов по категории
final specialistsByCategoryProvider =
    FutureProvider.family<List<Specialist>, String>((ref, categoryName) async {
  // TODO(developer): Реализовать получение специалистов из Firebase по категории
  // Пока возвращаем тестовые данные
  await Future<void>.delayed(const Duration(seconds: 1));

  return _getTestSpecialistsForCategory(categoryName);
});

/// Получить тестовых специалистов для категории
List<Specialist> _getTestSpecialistsForCategory(String categoryName) {
  // Генерируем тестовых специалистов в зависимости от категории
  final specialists = <Specialist>[];

  switch (categoryName) {
    case 'photographers':
      specialists.addAll([
        Specialist(
          id: 'photo_1',
          userId: 'user_1',
          name: 'Анна Петрова',
          description:
              'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной съемке.',
          category: SpecialistCategory.photographer,
          experienceLevel: ExperienceLevel.expert,
          yearsOfExperience: 5,
          hourlyRate: 5000,
          price: 5000,
          rating: 4.8,
          reviewCount: 127,
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now(),
        ),
        Specialist(
          id: 'photo_2',
          userId: 'user_2',
          name: 'Михаил Соколов',
          description:
              'Креативный фотограф, работаю в стиле репортажной съемки. Опыт работы с корпоративными мероприятиями.',
          category: SpecialistCategory.photographer,
          experienceLevel: ExperienceLevel.advanced,
          yearsOfExperience: 3,
          hourlyRate: 4000,
          price: 4000,
          rating: 4.6,
          reviewCount: 89,
          createdAt: DateTime.now().subtract(const Duration(days: 200)),
          updatedAt: DateTime.now(),
        ),
      ]);
      break;

    case 'hosts':
      specialists.addAll([
        Specialist(
          id: 'host_1',
          userId: 'user_3',
          name: 'Дмитрий Ведущий',
          description:
              'Опытный ведущий мероприятий. Провожу свадьбы, корпоративы, дни рождения. Индивидуальный подход к каждому событию.',
          category: SpecialistCategory.host,
          experienceLevel: ExperienceLevel.expert,
          yearsOfExperience: 8,
          hourlyRate: 6000,
          price: 6000,
          rating: 4.9,
          reviewCount: 203,
          createdAt: DateTime.now().subtract(const Duration(days: 500)),
          updatedAt: DateTime.now(),
        ),
      ]);
      break;

    case 'djs':
      specialists.addAll([
        Specialist(
          id: 'dj_1',
          userId: 'user_4',
          name: 'DJ Максим',
          description:
              'Профессиональный диджей с собственным оборудованием. Специализируюсь на танцевальной музыке и электронике.',
          category: SpecialistCategory.dj,
          experienceLevel: ExperienceLevel.advanced,
          yearsOfExperience: 4,
          hourlyRate: 4500,
          price: 4500,
          rating: 4.7,
          reviewCount: 156,
          createdAt: DateTime.now().subtract(const Duration(days: 300)),
          updatedAt: DateTime.now(),
        ),
      ]);
      break;

    default:
      // Для остальных категорий возвращаем пустой список
      break;
  }

  return specialists;
}
