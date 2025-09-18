import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../providers/specialist_providers.dart';
import '../providers/auth_providers.dart';

class SpecialistsScreen extends ConsumerStatefulWidget {
  const SpecialistsScreen({super.key});

  @override
  ConsumerState<SpecialistsScreen> createState() => _SpecialistsScreenState();
}

class _SpecialistsScreenState extends ConsumerState<SpecialistsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Фильтры
  SpecialistCategory? _selectedCategory;
  ExperienceLevel? _selectedExperience;
  double _minPrice = 0;
  double _maxPrice = 10000;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Специалисты'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все специалисты'),
            Tab(text: 'По категориям'),
            Tab(text: 'Рекомендуемые'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),

          // Контент
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllSpecialistsTab(),
                _buildCategoriesTab(),
                _buildRecommendedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск специалистов...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
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
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onSubmitted: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildAllSpecialistsTab() {
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return specialistsAsync.when(
      data: (specialists) {
        final filteredSpecialists = _filterSpecialists(specialists);
        return _buildSpecialistsList(filteredSpecialists);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки специалистов: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(allSpecialistsProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: SpecialistCategory.values.length,
      itemBuilder: (context, index) {
        final category = SpecialistCategory.values[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildRecommendedTab() {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Войдите в аккаунт, чтобы увидеть рекомендации'),
          ],
        ),
      );
    }

    // TODO: Реализовать рекомендации на основе истории заказов
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.recommend, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Рекомендации будут доступны после первых заказов'),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(SpecialistCategory category) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSpecialistsByCategory(category),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              category.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistsList(List<Specialist> specialists) {
    if (specialists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Специалисты не найдены'),
            SizedBox(height: 8),
            Text('Попробуйте изменить фильтры или поисковый запрос'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allSpecialistsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: specialists.length,
        itemBuilder: (context, index) {
          final specialist = specialists[index];
          return _buildSpecialistCard(specialist);
        },
      ),
    );
  }

  Widget _buildSpecialistCard(Specialist specialist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showSpecialistDetails(specialist),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  specialist.name.isNotEmpty
                      ? specialist.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          specialist.category.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            specialist.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (specialist.isVerified)
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialist.category.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialist.experienceLevel.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${specialist.reviewCount})',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          '${specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Specialist> _filterSpecialists(List<Specialist> specialists) {
    var filtered = specialists;

    // Поиск по тексту
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((specialist) {
        return specialist.name.toLowerCase().contains(searchLower) ||
            specialist.description?.toLowerCase().contains(searchLower) ==
                true ||
            specialist.category.displayName
                .toLowerCase()
                .contains(searchLower) ||
            specialist.subcategories
                .any((sub) => sub.toLowerCase().contains(searchLower));
      }).toList();
    }

    // Фильтры
    if (_selectedCategory != null) {
      filtered = filtered
          .where((specialist) => specialist.category == _selectedCategory)
          .toList();
    }
    if (_selectedExperience != null) {
      filtered = filtered
          .where(
              (specialist) => specialist.experienceLevel == _selectedExperience)
          .toList();
    }
    filtered = filtered.where((specialist) {
      return specialist.hourlyRate >= _minPrice &&
          specialist.hourlyRate <= _maxPrice;
    }).toList();

    return filtered;
  }

  void _showSpecialistsByCategory(SpecialistCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpecialistsByCategoryScreen(category: category),
      ),
    );
  }

  void _showSpecialistDetails(Specialist specialist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpecialistDetailsScreen(specialist: specialist),
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Категория
              DropdownButtonFormField<SpecialistCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: SpecialistCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.icon),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Уровень опыта
              DropdownButtonFormField<ExperienceLevel>(
                initialValue: _selectedExperience,
                decoration: const InputDecoration(labelText: 'Уровень опыта'),
                items: ExperienceLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExperience = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Ценовой диапазон
              Text(
                  'Цена: ${_minPrice.toStringAsFixed(0)} - ${_maxPrice.toStringAsFixed(0)} ₽/час'),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 10000,
                divisions: 100,
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedExperience = null;
                _minPrice = 0;
                _maxPrice = 10000;
              });
            },
            child: const Text('Сбросить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

/// Экран специалистов по категории
class SpecialistsByCategoryScreen extends ConsumerWidget {
  final SpecialistCategory category;

  const SpecialistsByCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialistsAsync = ref.watch(specialistsByCategoryProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.icon} ${category.displayName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: specialistsAsync.when(
        data: (specialists) {
          if (specialists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('В этой категории пока нет специалистов'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specialists.length,
            itemBuilder: (context, index) {
              final specialist = specialists[index];
              return _buildSpecialistCard(context, specialist);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialistCard(BuildContext context, Specialist specialist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  SpecialistDetailsScreen(specialist: specialist),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  specialist.name.isNotEmpty
                      ? specialist.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            specialist.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (specialist.isVerified)
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialist.experienceLevel.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${specialist.reviewCount})',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          '${specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Экран детальной информации о специалисте
class SpecialistDetailsScreen extends ConsumerWidget {
  final Specialist specialist;

  const SpecialistDetailsScreen({
    super.key,
    required this.specialist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(specialist.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Реализовать шаринг профиля
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            specialist.name.isNotEmpty
                                ? specialist.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    specialist.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (specialist.isVerified) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.verified,
                                        color: Colors.blue),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${specialist.category.icon} ${specialist.category.displayName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 20, color: Colors.amber[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    specialist.rating.toStringAsFixed(1),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${specialist.reviewCount} отзывов)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Описание
                    if (specialist.description != null) ...[
                      Text(
                        'О себе:',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        specialist.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Информация о ценах и опыте
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'Опыт',
                            '${specialist.yearsOfExperience} лет',
                            Icons.work,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'Цена',
                            '${specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
                            Icons.attach_money,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопка бронирования
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Реализовать бронирование
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Бронирование будет реализовано позже')),
                  );
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Забронировать'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
