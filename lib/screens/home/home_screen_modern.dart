import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_providers.dart';
import '../../providers/specialist_providers.dart';
import '../../providers/notification_providers.dart';
import '../../models/specialist_enhanced.dart';
import '../../widgets/animated_skeleton.dart';
import '../../services/navigation_service.dart';

/// Современная главная страница с поиском, фильтрами и ТОП специалистами
class HomeScreenModern extends ConsumerStatefulWidget {
  const HomeScreenModern({super.key});

  @override
  ConsumerState<HomeScreenModern> createState() => _HomeScreenModernState();
}

class _HomeScreenModernState extends ConsumerState<HomeScreenModern>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = '';
  bool _isSearchExpanded = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final userCity = ref.watch(userCityProvider);
    final currentFilters = ref.watch(currentSearchFiltersProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок с поиском
              _buildHeader(user, userCity),

              // Основной контент
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildContent(userCity, currentFilters),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок с поиском и уведомлениями
  Widget _buildHeader(AsyncValue user, AsyncValue<String?> userCity) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Верхняя панель с аватаром и уведомлениями
          Row(
            children: [
              // Аватар пользователя
              GestureDetector(
                onTap: () {
                  final userData = user.value;
                  final uid = userData?.uid ?? 'me';
                  NavigationService.safeGo(context, '/profile/$uid');
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.when(
                      data: (userData) => userData?.avatarUrl != null
                          ? Hero(
                              tag: 'avatar-${userData!.uid}',
                              child: CachedNetworkImage(
                                imageUrl: userData.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const ShimmerBox(
                                  width: 50,
                                  height: 50,
                                  borderRadius: 25,
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                      loading: () => const ShimmerBox(
                        width: 50,
                        height: 50,
                        borderRadius: 25,
                      ),
                      error: (_, __) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Приветствие
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    user.when(
                      data: (userData) => Text(
                        userData != null
                            ? '${_getGreetingByTime()}, ${_getUserDisplayName(userData)}!'
                            : '${_getGreetingByTime()}!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      loading: () => const Text(
                        'Добро пожаловать!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      error: (_, __) => const Text(
                        'Добро пожаловать!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    user.when(
                      data: (userData) => Text(
                        userData?.name ?? 'Пользователь',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const ShimmerBox(
                        width: 150,
                        height: 20,
                        borderRadius: 10,
                      ),
                      error: (_, __) => const Text(
                        'Пользователь',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Уведомления
              _buildNotificationsButton(user),
            ],
          ),

          const SizedBox(height: 20),

          // Поисковая строка
          _buildSearchBar(),

          // Категории
          if (!_isSearchExpanded) _buildCategoryFilters(),
        ],
      ),
    );
  }

  /// Поисковая строка
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onTap: () {
          setState(() {
            _isSearchExpanded = true;
          });
        },
        onSubmitted: (value) {
          _performSearch(value);
        },
        decoration: InputDecoration(
          hintText: 'Поиск специалистов...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
          suffixIcon: _isSearchExpanded
              ? IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFF1E3A8A)),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  /// Фильтры по категориям
  Widget _buildCategoryFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: SpecialistCategory.values.length,
        itemBuilder: (context, index) {
          final category = SpecialistCategory.values[index];
          final isSelected = _selectedCategory == category.name;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? '' : category.name;
                });
                _filterByCategory(category.name);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        color:
                            isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Основной контент
  Widget _buildContent(
      AsyncValue<String?> userCity, SearchFilters currentFilters) {
    return RefreshIndicator(
      onRefresh: () async {
        // Обновляем данные
        ref.invalidate(topSpecialistsByCityProvider);
        ref.invalidate(topSpecialistsByRussiaProvider);
        ref.invalidate(nearbySpecialistsProvider);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ТОП специалисты по городу
            _buildTopSpecialistsByCity(userCity),

            const SizedBox(height: 32),

            // ТОП специалисты по России
            _buildTopSpecialistsByRussia(),

            const SizedBox(height: 32),

            // Рядом с вами
            _buildNearbySpecialists(),

            const SizedBox(height: 32),

            // Быстрые действия
            _buildQuickActions(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// ТОП специалисты по городу
  Widget _buildTopSpecialistsByCity(AsyncValue<String?> userCity) {
    return userCity.when(
      data: (city) {
        if (city == null) {
          return _buildTopSpecialistsSection(
            title: '🏙️ ТОП специалисты',
            subtitle: 'Выберите город для просмотра',
            specialists: const [],
            isLoading: false,
          );
        }

        final specialistsAsync = ref.watch(topSpecialistsByCityProvider(city));
        return specialistsAsync.when(
          data: (specialists) => _buildTopSpecialistsSection(
            title: '🏙️ ТОП специалисты в $city',
            subtitle: specialists.isEmpty
                ? 'Пока нет лидеров в вашем городе'
                : 'Лучшие специалисты вашего города',
            specialists: specialists,
            isLoading: false,
          ),
          loading: () => _buildTopSpecialistsSection(
            title: '🏙️ ТОП специалисты в $city',
            subtitle: 'Загрузка...',
            specialists: const [],
            isLoading: true,
          ),
          error: (error, stack) => _buildTopSpecialistsSection(
            title: '🏙️ ТОП специалисты в $city',
            subtitle: 'Ошибка загрузки',
            specialists: const [],
            isLoading: false,
          ),
        );
      },
      loading: () => _buildTopSpecialistsSection(
        title: '🏙️ ТОП специалисты',
        subtitle: 'Загрузка...',
        specialists: const [],
        isLoading: true,
      ),
      error: (error, stack) => _buildTopSpecialistsSection(
        title: '🏙️ ТОП специалисты',
        subtitle: 'Ошибка определения города',
        specialists: const [],
        isLoading: false,
      ),
    );
  }

  /// ТОП специалисты по России
  Widget _buildTopSpecialistsByRussia() {
    final specialistsAsync = ref.watch(topSpecialistsByRussiaProvider);

    return specialistsAsync.when(
      data: (specialists) => _buildTopSpecialistsSection(
        title: '🇷🇺 ТОП специалисты России',
        subtitle: 'Лучшие специалисты страны',
        specialists: specialists,
        isLoading: false,
      ),
      loading: () => _buildTopSpecialistsSection(
        title: '🇷🇺 ТОП специалисты России',
        subtitle: 'Загрузка...',
        specialists: const [],
        isLoading: true,
      ),
      error: (error, stack) => _buildTopSpecialistsSection(
        title: '🇷🇺 ТОП специалисты России',
        subtitle: 'Ошибка загрузки',
        specialists: const [],
        isLoading: false,
      ),
    );
  }

  /// Секция ТОП специалистов
  Widget _buildTopSpecialistsSection({
    required String title,
    required String subtitle,
    required List<SpecialistEnhanced> specialists,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (specialists.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Переход к полному списку
                  NavigationService.safeGo(context, '/search');
                },
                child: const Text(
                  'Все',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          _buildLoadingCards()
        else if (specialists.isEmpty)
          _buildEmptyState()
        else
          _buildSpecialistsList(specialists),
      ],
    );
  }

  /// Карточки загрузки
  Widget _buildLoadingCards() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: const ShimmerBox(
              width: 280,
              height: 200,
              borderRadius: 16,
            ),
          );
        },
      ),
    );
  }

  /// Пустое состояние
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет специалистов',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Специалисты появятся здесь',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Список специалистов
  Widget _buildSpecialistsList(List<SpecialistEnhanced> specialists) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: specialists.length,
        itemBuilder: (context, index) {
          final specialist = specialists[index];
          return _buildSpecialistCard(specialist);
        },
      ),
    );
  }

  /// Карточка специалиста
  Widget _buildSpecialistCard(SpecialistEnhanced specialist) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          NavigationService.safeGo(context, '/profile/${specialist.id}');
        },
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E3A8A).withOpacity(0.8),
                      const Color(0xFF3B82F6).withOpacity(0.8),
                    ],
                  ),
                ),
                child: specialist.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: specialist.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
              ),

              // Информация
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя и специализация
                    Text(
                      specialist.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialist.specialization,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Рейтинг и заказы
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${specialist.successfulOrders} заказов',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Бейджи
                    if (specialist.badges.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: specialist.badges.take(2).map((badge) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(badge.color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${badge.emoji} ${badge.label}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(badge.color),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
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

  /// Рядом с вами
  Widget _buildNearbySpecialists() {
    final location = ref.watch(userLocationProvider);

    return location.when(
      data: (position) {
        if (position == null) {
          return _buildNearbySection(
            title: '🌍 Рядом с вами',
            subtitle:
                'Разрешите геолокацию для просмотра ближайших специалистов',
            specialists: const [],
            isLoading: false,
          );
        }

        final specialistsAsync = ref.watch(nearbySpecialistsProvider(position));
        return specialistsAsync.when(
          data: (specialists) => _buildNearbySection(
            title: '🌍 Рядом с вами',
            subtitle: specialists.isEmpty
                ? 'Поблизости нет специалистов'
                : 'Специалисты в радиусе 50 км',
            specialists: specialists,
            isLoading: false,
          ),
          loading: () => _buildNearbySection(
            title: '🌍 Рядом с вами',
            subtitle: 'Поиск ближайших специалистов...',
            specialists: const [],
            isLoading: true,
          ),
          error: (error, stack) => _buildNearbySection(
            title: '🌍 Рядом с вами',
            subtitle: 'Ошибка поиска',
            specialists: const [],
            isLoading: false,
          ),
        );
      },
      loading: () => _buildNearbySection(
        title: '🌍 Рядом с вами',
        subtitle: 'Определение местоположения...',
        specialists: const [],
        isLoading: true,
      ),
      error: (error, stack) => _buildNearbySection(
        title: '🌍 Рядом с вами',
        subtitle: 'Ошибка определения местоположения',
        specialists: const [],
        isLoading: false,
      ),
    );
  }

  /// Секция "Рядом с вами"
  Widget _buildNearbySection({
    required String title,
    required String subtitle,
    required List<SpecialistEnhanced> specialists,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          _buildLoadingCards()
        else if (specialists.isEmpty)
          _buildEmptyState()
        else
          _buildSpecialistsList(specialists),
      ],
    );
  }

  /// Быстрые действия
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Быстрые действия',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                title: 'Создать заявку',
                subtitle: 'Найти специалиста',
                color: const Color(0xFF1E3A8A),
                onTap: () {
                  NavigationService.safeGo(context, '/create-request');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.lightbulb_outline,
                title: 'Поделиться идеей',
                subtitle: 'Вдохновить других',
                color: const Color(0xFF10B981),
                onTap: () {
                  NavigationService.safeGo(context, '/ideas/create');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Кнопка уведомлений
  Widget _buildNotificationsButton(AsyncValue user) {
    return user.when(
      data: (userData) {
        if (userData == null) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () =>
                  NavigationService.safeGo(context, '/notifications'),
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        }

        return Consumer(
          builder: (context, ref, child) {
            final unreadCountAsync = ref
                .watch(NotificationProviders.unreadCountProvider(userData.uid));

            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () =>
                        NavigationService.safeGo(context, '/notifications'),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                unreadCountAsync.when(
                  data: (count) {
                    if (count > 0) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const IconButton(
          onPressed: null,
          icon: Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      error: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: () => NavigationService.safeGo(context, '/notifications'),
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Выполнить поиск
  void _performSearch(String query) {
    if (query.isEmpty) return;

    // Обновляем фильтры поиска
    final currentFilters = ref.read(currentSearchFiltersProvider);
    ref.read(currentSearchFiltersProvider.notifier).updateFilters(
          currentFilters.copyWith(
              // Здесь можно добавить поиск по имени/специализации
              ),
        );

    // Переходим к экрану поиска
    NavigationService.safeGo(context, '/search');
  }

  /// Фильтр по категории
  void _filterByCategory(String category) {
    final currentFilters = ref.read(currentSearchFiltersProvider);
    final categories = currentFilters.categories;

    List<String> newCategories;
    if (categories.contains(category)) {
      newCategories = categories.where((c) => c != category).toList();
    } else {
      newCategories = [...categories, category];
    }

    ref.read(currentSearchFiltersProvider.notifier).updateFilters(
          currentFilters.copyWith(categories: newCategories),
        );
  }

  /// Получить приветствие
  String _getGreetingByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Доброе утро';
    } else if (hour >= 12 && hour < 17) {
      return 'Добрый день';
    } else if (hour >= 17 && hour < 22) {
      return 'Добрый вечер';
    } else {
      return 'Доброй ночи';
    }
  }

  /// Получить имя пользователя
  String _getUserDisplayName(dynamic userData) {
    if (userData.displayName != null && userData.displayName!.isNotEmpty) {
      return userData.displayName!;
    }
    if (userData.name != null && userData.name!.isNotEmpty) {
      return userData.name!;
    }
    if (userData.email != null && userData.email!.isNotEmpty) {
      final email = userData.email!;
      final atIndex = email.indexOf('@');
      if (atIndex > 0) {
        return email.substring(0, atIndex);
      }
    }
    return 'Пользователь';
  }
}

/// Карточка быстрого действия
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
