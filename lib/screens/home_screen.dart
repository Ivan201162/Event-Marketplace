import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../models/specialist.dart';
import '../models/user.dart';
import '../providers/auth_providers.dart';
import '../providers/search_providers.dart';
import '../services/test_data_service.dart';
import '../widgets/modern_specialist_card.dart';

/// Современная главная страница
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  final TestDataService _testDataService = TestDataService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        automaticallyImplyLeading:
            false, // Не показываем стрелку в главной вкладке
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
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

  Widget _buildHomeContent(AppUser? user) => CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSearchSection(user),
          _buildSearchResults(),
          _buildQuickFilters(),
          _buildRecommendedSection(),
          _buildCategoriesSection(),
          _buildPopularSpecialists(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );

  Widget _buildSearchSection(AppUser? user) => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: BrandColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: BrandColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                user?.displayName?.isNotEmpty ?? false
                                    ? user!.displayName![0].toUpperCase()
                                    : 'Г',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.displayName ?? 'Гость',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          context.push('/notifications');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Найди специалиста для своего праздника 🎉',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '🔍 Найдите специалиста...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.8)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(Icons.clear, color: Colors.white),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    onChanged: (query) {
                      setState(() {});
                      ref.read(searchQueryProvider.notifier).state = query;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildQuickFilters() => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Популярные категории',
                      style: context.textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/search'),
                      child: const Text('Все категории'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Ведущие', Icons.mic),
                      const SizedBox(width: 8),
                      _buildFilterChip('Фотографы', Icons.camera_alt),
                      const SizedBox(width: 8),
                      _buildFilterChip('Диджеи', Icons.music_note),
                      const SizedBox(width: 8),
                      _buildFilterChip('Оформители', Icons.local_florist),
                      const SizedBox(width: 8),
                      _buildFilterChip('Кавер-группы', Icons.group),
                      const SizedBox(width: 8),
                      _buildFilterChip('Видеографы', Icons.videocam),
                      const SizedBox(width: 8),
                      _buildFilterChip('Аниматоры', Icons.child_care),
                      const SizedBox(width: 8),
                      _buildFilterChip('Кейтеринг', Icons.restaurant),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFilterChip(String label, IconData icon) => Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: BrandColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          onSelected: (selected) {
            context.push('/search?category=${Uri.encodeComponent(label)}');
          },
          backgroundColor: Colors.white,
          selectedColor: BrandColors.primaryLight,
          checkmarkColor: BrandColors.primary,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );

  Widget _buildSearchResults() => SliverToBoxAdapter(
        child: Consumer(
          builder: (context, ref, _) {
            final searchQuery = ref.watch(searchQueryProvider);

            // Используем тестовые данные для поиска
            final specialists = _testDataService.getSpecialists();
            final filteredSpecialists = specialists.where((specialist) {
              if (searchQuery.isEmpty) {
                return true; // Показываем всех специалистов, если поиск пустой
              }
              final query = searchQuery.toLowerCase();
              return (specialist['name'] as String)
                      .toLowerCase()
                      .contains(query) ||
                  (specialist['category'] as String)
                      .toLowerCase()
                      .contains(query) ||
                  (specialist['city'] as String)
                      .toLowerCase()
                      .contains(query) ||
                  (specialist['about'] as String).toLowerCase().contains(query);
            }).toList();

            if (filteredSpecialists.isEmpty) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Никого не найдено 😅',
                      style: context.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Попробуйте изменить поисковый запрос',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        searchQuery.isEmpty
                            ? 'Все специалисты (${filteredSpecialists.length})'
                            : 'Найдено специалистов: ${filteredSpecialists.length}',
                        style: context.textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/search'),
                        child: const Text('Все результаты'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...filteredSpecialists.take(5).map(
                      (specialistData) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              context.push(
                                  '/specialist/specialist_${filteredSpecialists.indexOf(specialistData) + 1}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        specialistData['avatarUrl'] as String),
                                    radius: 30,
                                    backgroundColor:
                                        BrandColors.primary.withOpacity(0.1),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          specialistData['name'] as String,
                                          style: context.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${specialistData['category'] as String} • ${specialistData['city'] as String}',
                                          style: context.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: BrandColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${specialistData['rating']}',
                                              style:
                                                  context.textTheme.bodySmall,
                                            ),
                                            const SizedBox(width: 16),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: BrandColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                specialistData['priceRange']
                                                    as String,
                                                style: context
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: BrandColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 16,
                                      color: BrandColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                if (filteredSpecialists.length > 5)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton(
                      onPressed: () => context.go('/search'),
                      child: Text(
                          'Показать все ${filteredSpecialists.length} результатов'),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  Widget _buildQuickActions() => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.search,
                    title: 'Найти специалиста',
                    subtitle: 'Поиск по категориям',
                    onTap: () => context.push('/search'),
                    color: BrandColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.add_task,
                    title: 'Создать заявку',
                    subtitle: 'Разместить задачу',
                    onTap: () {
                      context.push('/booking-form');
                    },
                    color: BrandColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHighest),
            boxShadow: BrandColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: context.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );

  Widget _buildRecommendedSection() => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Рекомендуем вам',
                      style: context.textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () => context.push('/search'),
                      child: const Text('Смотреть все'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) => Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildRecommendedCard(index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildRecommendedCard(int index) {
    final specialists = _testDataService.getSpecialists();
    final specialist = specialists[index % specialists.length];

    return GestureDetector(
      onTap: () {
        context.push('/specialist/specialist_${index + 1}');
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: context.primaryColor,
                    child: Text(
                      specialist['name'].toString().isNotEmpty
                          ? specialist['name'].toString()[0].toUpperCase()
                          : 'С',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specialist['name'] as String,
                      style: context.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialist['category'] as String,
                      style: context.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          specialist['rating'].toString(),
                          style: context.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '${specialist['price'].toInt()}₽/ч',
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.primaryColor,
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
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'icon': Icons.cake, 'name': 'Торты', 'color': BrandColors.primary},
      {
        'icon': Icons.music_note,
        'name': 'Музыка',
        'color': BrandColors.secondary
      },
      {'icon': Icons.photo_camera, 'name': 'Фото', 'color': BrandColors.accent},
      {
        'icon': Icons.local_florist,
        'name': 'Цветы',
        'color': BrandColors.success
      },
      {
        'icon': Icons.design_services,
        'name': 'Декор',
        'color': BrandColors.warning
      },
      {'icon': Icons.videocam, 'name': 'Видео', 'color': BrandColors.info},
    ];

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Популярные категории',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(
                    icon: category['icon']! as IconData,
                    name: category['name']! as String,
                    color: category['color']! as Color,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String name,
    required Color color,
  }) =>
      GestureDetector(
        onTap: () {
          context.push('/search?category=${Uri.encodeComponent(name)}');
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHighest),
            boxShadow: BrandColors.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: context.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildPopularSpecialists() => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Популярные специалисты',
                      style: context.textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () => context.push('/search'),
                      child: const Text('Смотреть все'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(5, (index) {
                  final specialists = _testDataService.getSpecialists();
                  final specialistData =
                      specialists[index % specialists.length];
                  final specialist = Specialist.fromMap(specialistData);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ModernSpecialistCard(
                      specialist: specialist,
                    ),
                  );
                }),
              ],
            ),
          ),
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
              color: BrandColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: context.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.invalidate(currentUserProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Доброе утро';
    } else if (hour < 18) {
      return 'Добрый день';
    } else {
      return 'Добрый вечер';
    }
  }
}
