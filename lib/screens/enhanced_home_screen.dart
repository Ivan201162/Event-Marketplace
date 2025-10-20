import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
import '../providers/auth_providers.dart';
import '../providers/search_providers.dart';
import '../repositories/chats_repository.dart';
import '../widgets/enhanced_filters_dialog.dart';

class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  ConsumerState<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'Все';

  late AnimationController _profileAnimationController;
  late Animation<double> _profileOpacityAnimation;
  late Animation<double> _profileScaleAnimation;

  bool _showProfileBanner = true;
  Map<String, dynamic> _currentFilters = {};

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Все', 'icon': '🎯', 'color': Colors.blue},
    {'name': 'Свадьбы', 'icon': '💒', 'color': Colors.pink},
    {'name': 'Корпоративы', 'icon': '🏢', 'color': Colors.blue},
    {'name': 'Дни рождения', 'icon': '🎂', 'color': Colors.orange},
    {'name': 'Детские праздники', 'icon': '🎈', 'color': Colors.purple},
    {'name': 'Выпускные', 'icon': '🎓', 'color': Colors.green},
    {'name': 'Фотографы', 'icon': '📸', 'color': Colors.indigo},
    {'name': 'Видеографы', 'icon': '🎬', 'color': Colors.red},
    {'name': 'DJ', 'icon': '🎵', 'color': Colors.purple},
    {'name': 'Ведущие', 'icon': '🎤', 'color': Colors.teal},
    {'name': 'Декораторы', 'icon': '🎨', 'color': Colors.amber},
    {'name': 'Аниматоры', 'icon': '🎭', 'color': Colors.cyan},
    {'name': 'Организатор мероприятий', 'icon': '🎪', 'color': Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
    _profileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _profileOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.easeInOut,
    ));

    _profileScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.easeInOut,
    ));

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _profileAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    const threshold = 100.0;

    if (currentOffset > threshold && _showProfileBanner) {
      setState(() {
        _showProfileBanner = false;
      });
      _profileAnimationController.forward();
    } else if (currentOffset <= threshold && !_showProfileBanner) {
      setState(() {
        _showProfileBanner = true;
      });
      _profileAnimationController.reverse();
    }
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedFiltersDialog(
        initialFilters: _currentFilters,
        onApplyFilters: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          // Применяем фильтры к поиску
          _applyFiltersToSearch();
        },
      ),
    );
  }

  void _applyFiltersToSearch() {
    // Создаем URL с параметрами фильтров
    final queryParams = <String, String>{};

    if (_searchController.text.isNotEmpty) {
      queryParams['q'] = _searchController.text;
    }

    _currentFilters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryParams[key] = value.toString();
      }
    });

    final queryString =
        queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    context.push('/search?$queryString');
  }

  /// Генерирует случайное количество подписчиков для демонстрации
  int _getRandomFollowers() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return 50 + (random % 500); // От 50 до 549 подписчиков
  }

  /// Получает отображаемое имя фильтра
  String _getFilterDisplayName(String key) {
    switch (key) {
      case 'city':
        return 'Город';
      case 'category':
        return 'Категория';
      case 'minPrice':
        return 'Цена от';
      case 'maxPrice':
        return 'Цена до';
      case 'specialistType':
        return 'Тип';
      default:
        return key;
    }
  }

  /// Удаляет фильтр
  void _removeFilter(String key) {
    setState(() {
      _currentFilters.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Обновление данных
            await Future.delayed(const Duration(seconds: 1));
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Плашка пользователя
              SliverToBoxAdapter(
                child: currentUserAsync.when(
                  data: _buildUserProfileCard,
                  loading: () => _buildUserProfileCard(null),
                  error: (_, __) => _buildUserProfileCard(null),
                ),
              ),

              // Поиск специалистов
              SliverToBoxAdapter(
                child: _buildSearchSection(),
              ),

              // Категории специалистов
              SliverToBoxAdapter(
                child: _buildCategoriesSection(),
              ),

              // Карусель лучших специалистов недели
              SliverToBoxAdapter(
                child: _buildBestSpecialistsCarousel(),
              ),

              // Лучшие специалисты по городу
              SliverToBoxAdapter(
                child: _buildCitySpecialistsCarousel(),
              ),

              // Блок "Интересное"
              SliverToBoxAdapter(
                child: _buildInterestingSection(),
              ),

              // Быстрые действия
              SliverToBoxAdapter(
                child: _buildQuickActionsSection(),
              ),

              // Дополнительный отступ внизу для предотвращения overflow
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Плашка пользователя с аватаром, именем и городом
  Widget _buildUserProfileCard(user) => AnimatedBuilder(
        animation: _profileAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _profileScaleAnimation.value,
            child: Opacity(
              opacity: _profileOpacityAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Аватар пользователя
                    GestureDetector(
                      onTap: () {
                        if (user != null) {
                          context.push('/profile/me');
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 31,
                          backgroundColor: Colors.white,
                          child: user?.photoURL?.isNotEmpty == true
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.photoURL!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.person,
                                        size: 35,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.email ?? 'Войдите в аккаунт',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  user?.city?.trim().isNotEmpty == true
                                      ? user!.city!
                                      : 'Город не указан',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 1,
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Статус и подписчики
                          Row(
                            children: [
                              // Статус онлайн/офлайн
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Онлайн',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Количество подписчиков
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_getRandomFollowers()} подписчиков',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Кнопка редактирования профиля
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Редактировать профиль',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  /// Строка поиска специалистов
  Widget _buildSearchSection() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Найти специалиста',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    // Индикатор активных фильтров
                    if (_currentFilters.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentFilters.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: _showFiltersDialog,
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Фильтры',
                      style: IconButton.styleFrom(
                        backgroundColor: _currentFilters.isNotEmpty
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        foregroundColor: _currentFilters.isNotEmpty
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Найти специалиста…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                        tooltip: 'Очистить',
                      ),
                    IconButton(
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          context.push('/search?q=${Uri.encodeComponent(_searchController.text)}');
                        }
                      },
                      icon: const Icon(Icons.search),
                      tooltip: 'Поиск',
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  context.push('/search?q=${Uri.encodeComponent(query)}');
                }
              },
            ),
            // Отображение активных фильтров
            if (_currentFilters.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentFilters.length,
                  itemBuilder: (context, index) {
                    final entry = _currentFilters.entries.elementAt(index);
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getFilterDisplayName(entry.key)}: ${entry.value}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeFilter(entry.key),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );

  /// Категории специалистов
  Widget _buildCategoriesSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Категории',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category['name'] == _selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'] as String;
                      });
                      // Переход к отфильтрованным специалистам
                      context.push(
                          '/search?category=${Uri.encodeComponent(category['name'] as String)}');
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (category['color'] as Color).withValues(alpha: 0.2)
                            : (category['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (category['color'] as Color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category['icon'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? (category['color'] as Color) : Colors.grey[700],
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

  /// Карусель лучших специалистов недели
  Widget _buildBestSpecialistsCarousel() {
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return specialistsAsync.when(
      data: (specialists) {
        // Берем топ-5 специалистов по рейтингу
        final topSpecialists = specialists..sort((a, b) => b.rating.compareTo(a.rating));
        final top5 = topSpecialists.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Лучшие специалисты недели',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('Все'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: top5.length,
                itemBuilder: (context, index) {
                  final specialist = top5[index];
                  return _SpecialistCard(specialist: specialist);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Ошибка загрузки специалистов')),
    );
  }

  /// Лучшие специалисты по городу
  Widget _buildCitySpecialistsCarousel() {
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return specialistsAsync.when(
      data: (specialists) {
        // Фильтруем специалистов по городу пользователя
        final currentUser = ref.read(currentUserProvider).value;
        final userCity = currentUser?.city?.trim();

        List<Specialist> citySpecialists = specialists;
        if (userCity != null && userCity.isNotEmpty) {
          citySpecialists = specialists
              .where((s) => s.city.toLowerCase().contains(userCity.toLowerCase()) == true)
              .toList();
        }

        // Берем топ-5 специалистов по рейтингу в городе
        citySpecialists.sort((a, b) => b.rating.compareTo(a.rating));
        final top5City = citySpecialists.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userCity != null && userCity.isNotEmpty
                        ? 'Лучшие специалисты в $userCity'
                        : 'Лучшие специалисты по городу',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push('/search?city=${Uri.encodeComponent(userCity ?? '')}'),
                    child: const Text('Все'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (top5City.isEmpty)
              // Заглушка если нет данных
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Пока нет специалистов\nв вашем городе',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Попробуйте изменить город\nв настройках профиля',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: top5City.length,
                  itemBuilder: (context, index) {
                    final specialist = top5City[index];
                    return _SpecialistCard(specialist: specialist);
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Ошибка загрузки специалистов')),
    );
  }

  /// Блок "Интересное"
  Widget _buildInterestingSection() => Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Интересное',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InterestingCard(
                    title: 'Самые популярные категории недели',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                    onTap: () => context.push('/search?sort=popular'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InterestingCard(
                    title: 'Новые специалисты',
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: () => context.push('/search?sort=newest'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InterestingCard(
              title: 'Специалисты рядом',
              icon: Icons.location_on,
              color: Colors.blue,
              onTap: () => context.push('/search?nearby=true'),
            ),
          ],
        ),
      );

  /// Быстрые действия
  Widget _buildQuickActionsSection() => Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые действия',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.event,
                    title: 'Создать заявку',
                    onTap: () => context.push('/requests/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.photo_library,
                    title: 'Мои идеи',
                    onTap: () => context.push('/ideas'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// Карточка специалиста с интерактивными кнопками
class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({required this.specialist});
  final Specialist specialist;

  @override
  Widget build(BuildContext context) => Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/specialist/${specialist.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар специалиста
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: specialist.avatar != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(specialist.avatar!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: specialist.avatar == null
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
                child: specialist.avatar == null
                    ? const Center(
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
              // Информация о специалисте
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialist.category.displayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            specialist.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${specialist.price}₸',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Интерактивные кнопки
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _openChat(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Связаться',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _openBooking(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Забронировать',
                                style: TextStyle(fontSize: 10),
                              ),
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

  /// Открыть чат с специалистом
  Future<void> _openChat(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо войти в аккаунт')),
        );
        return;
      }

      final chatsRepository = ChatsRepository();
      final chatId = await chatsRepository.findOrCreateChat(
        currentUser.uid,
        specialist.id,
      );

      if (chatId != null) {
        context.push('/chat/$chatId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания чата')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  /// Открыть форму бронирования
  void _openBooking(BuildContext context) {
    context.push('/booking/${specialist.id}');
  }
}

/// Карточка интересного контента
class _InterestingCard extends StatelessWidget {
  const _InterestingCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
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
}
