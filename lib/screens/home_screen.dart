import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/search_providers.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../services/smart_search_service.dart';
import '../widgets/home_search_filters_widget.dart';
import '../widgets/popular_specialists_widget.dart';
import '../widgets/smart_search_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showFilters = false;
  Map<String, dynamic> _currentFilters = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Обработка выбора подсказки
  void _handleSuggestionTap(SearchSuggestion suggestion) {
    switch (suggestion.type) {
      case SuggestionType.specialist:
        // Переход к профилю специалиста
        final specialistId = suggestion.data['specialistId'];
        if (specialistId != null) {
          context.push('/specialist/$specialistId');
        }
        break;
      case SuggestionType.category:
        // Поиск по категории
        final category = suggestion.data['category'];
        if (category != null) {
          context.push('/search?category=${Uri.encodeComponent(category)}');
        }
        break;
      case SuggestionType.location:
        // Поиск по городу
        final city = suggestion.data['city'];
        if (city != null) {
          context.push('/search?city=${Uri.encodeComponent(city)}');
        }
        break;
      case SuggestionType.service:
        // Поиск по услуге
        final service = suggestion.data['service'];
        if (service != null) {
          ref.read(searchQueryProvider.notifier).state = service;
          context.push('/search');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Иконка акций
          IconButton(
            icon: const Icon(Icons.local_offer_outlined),
            onPressed: () => context.push('/promos'),
            tooltip: 'Акции и предложения',
          ),
          // Иконка уведомлений
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
          // Иконка настроек
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: _buildHomeContent,
        loading: _buildLoadingState,
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildHomeContent(user) => SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserProfileCard(user),
            const SizedBox(height: 16),
            _buildSearchSection(),
            const SizedBox(height: 20),
            _buildCategoriesSection(),
            const SizedBox(height: 20),
            const PopularSpecialistsWidget(),
            const SizedBox(height: 20),
            _buildFeaturedSpecialistsSection(),
            const SizedBox(height: 20),
            _buildQuickActionsSection(),
            const SizedBox(height: 20),
            _buildRecentBookingsSection(),
            const SizedBox(height: 20),
            _buildPopularCategoriesSection(),
            const SizedBox(height: 20),
          ],
        ),
      );

  Widget _buildUserProfileCard(user) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Аватар пользователя
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: user?.photoUrl?.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          user.photoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Информация о пользователе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Добро пожаловать!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Войдите в аккаунт',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user?.city?.trim().isNotEmpty == true
                            ? user!.city!
                            : 'Город не указан',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Кнопка профиля
            IconButton(
              onPressed: () => context.push('/profile'),
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      );

  Widget _buildLoadingState() => const Center(
        child: CircularProgressIndicator(),
      );

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(currentUserProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildSearchSection() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Найти специалиста',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _showFilters
                        ? Icons.filter_list
                        : Icons.filter_list_outlined,
                    color: _showFilters ? Theme.of(context).primaryColor : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  tooltip: 'Фильтры',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SmartSearchWidget(
              hintText: 'Поиск по имени, категории, городу...',
              onSearch: (query) {
                ref.read(searchQueryProvider.notifier).state = query;
                context.go('/search');
              },
              onSuggestionTap: (suggestion) {
                _handleSuggestionTap(suggestion);
              },
            ),
            if (_showFilters) ...[
              const SizedBox(height: 16),
              HomeSearchFiltersWidget(
                onFiltersChanged: (filters) {
                  setState(() {
                    _currentFilters = filters;
                  });
                },
              ),
            ],
          ],
        ),
      );

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Ведущие', 'icon': '🎤', 'color': Colors.blue},
      {'name': 'DJ', 'icon': '🎵', 'color': Colors.purple},
      {'name': 'Фотографы', 'icon': '📸', 'color': Colors.orange},
      {'name': 'Видеографы', 'icon': '🎬', 'color': Colors.red},
      {'name': 'Декораторы', 'icon': '🎨', 'color': Colors.green},
      {'name': 'Аниматоры', 'icon': '🎭', 'color': Colors.teal},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Категории',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    context.push(
                        '/search?category=${Uri.encodeComponent(category['name']! as String)}');
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: (category['color']! as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (category['color']! as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category['icon']! as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category['name']! as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSpecialistsSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Рекомендуемые специалисты',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  // Временные тестовые данные для специалистов
                  final specialist = {
                    'id': 'specialist_$index',
                    'name': 'Специалист ${index + 1}',
                    'category': 'Фотограф',
                    'city': 'Москва',
                    'rating': 4.5,
                    'price': '5000',
                    'avatarUrl':
                        'https://picsum.photos/100/100?random=${index + 100}',
                  };

                  return GestureDetector(
                    onTap: () {
                      context.push('/specialist/specialist_${index + 1}');
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                              ),
                              child: Center(
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  child: Text(
                                    (specialist['name'] as String?)
                                                ?.isNotEmpty ??
                                            false
                                        ? (specialist['name']! as String)[0]
                                            .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (specialist['name'] as String?) ??
                                        'Специалист',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (specialist['category'] as String?) ??
                                        'Специалист',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        ((specialist['rating'] as num?) ?? 0.0)
                                            .toStringAsFixed(1),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${((specialist['price'] as num?) ?? 0).toInt()}₽',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActionsSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые действия',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Найти специалиста',
                    Icons.search,
                    Colors.blue,
                    () => context.push('/search'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Создать заявку',
                    Icons.event_available,
                    Colors.green,
                    () => context.push('/booking-form'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildRecentBookingsSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Недавние заявки',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'У вас пока нет заявок',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Создайте первую заявку для поиска специалиста',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildPopularCategoriesSection() {
    final categories = [
      {'name': 'Свадьбы', 'count': 45},
      {'name': 'Дни рождения', 'count': 32},
      {'name': 'Корпоративы', 'count': 28},
      {'name': 'Детские праздники', 'count': 24},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Популярные категории',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => context.push('/search'),
                child: const Text('Все'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...categories.map(
            (category) => GestureDetector(
              onTap: () {
                context.push(
                    '/search?category=${Uri.encodeComponent(category['name']! as String)}');
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category['name']! as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '${category['count']} специалистов',
                      style: Theme.of(context).textTheme.bodySmall,
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
}
