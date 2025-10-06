import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../models/specialist.dart';
import '../providers/auth_providers.dart';
import '../services/test_data_service.dart';

/// Современный экран профиля в стиле Instagram
class ModernProfileScreen extends ConsumerStatefulWidget {
  const ModernProfileScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  final String userId;
  final bool isOwnProfile;

  @override
  ConsumerState<ModernProfileScreen> createState() =>
      _ModernProfileScreenState();
}

class _ModernProfileScreenState extends ConsumerState<ModernProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  final TestDataService _testDataService = TestDataService();

  bool _isFollowing = false;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _buildProfileContent(),
      );

  Widget _buildProfileContent() {
    // Получаем данные специалиста (в реальном приложении из API)
    final specialists = _testDataService.getSpecialists();
    final specialistData = specialists.first; // Используем первого для демо
    final specialist = Specialist.fromMap(specialistData);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(specialist),
        _buildProfileInfo(specialist),
        _buildStatsSection(specialist),
        _buildActionButtons(specialist),
        _buildBioSection(specialist),
        _buildTabBar(),
        _buildTabContent(specialist),
      ],
    );
  }

  Widget _buildSliverAppBar(Specialist specialist) => SliverAppBar(
        expandedHeight: 200,
        pinned: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: BrandColors.primaryGradient,
            ),
            child: Stack(
              children: [
                // Фоновое изображение (если есть)
                if (specialist.imageUrlValue != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: specialist.imageUrlValue!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.primaryColor.withOpacity(0.3),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: context.primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                // Градиентный оверлей
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showOptionsMenu,
          ),
        ],
      );

  Widget _buildProfileInfo(Specialist specialist) => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.surfaceColor,
                      width: 4,
                    ),
                    boxShadow: BrandColors.cardShadow,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: context.primaryColor,
                    backgroundImage: specialist.imageUrlValue != null
                        ? CachedNetworkImageProvider(specialist.imageUrlValue!)
                        : null,
                    child: specialist.imageUrlValue == null
                        ? Text(
                            specialist.name.isNotEmpty
                                ? specialist.name[0].toUpperCase()
                                : 'С',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.displayName,
                        style: context.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            specialist.category.displayName,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                          if (specialist.isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: context.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
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
                            specialist.rating.toStringAsFixed(1),
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${specialist.reviewsCount} отзывов)',
                            style: context.textTheme.bodySmall,
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

  Widget _buildStatsSection(Specialist specialist) => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest),
              boxShadow: BrandColors.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Заказы', '${specialist.reviewsCount * 2}'),
                _buildStatItem('Рейтинг', specialist.rating.toStringAsFixed(1)),
                _buildStatItem('Опыт', '${specialist.yearsOfExperience} лет'),
                _buildStatItem('Цена', '${specialist.price.toInt()}₽/ч'),
              ],
            ),
          ),
        ),
      );

  Widget _buildStatItem(String label, String value) => Column(
        children: [
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.bodySmall,
          ),
        ],
      );

  Widget _buildActionButtons(Specialist specialist) => SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO(developer): Открыть чат
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Написать'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO(developer): Забронировать
                    },
                    icon: const Icon(Icons.event_available),
                    label: const Text('Забронировать'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!widget.isOwnProfile)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _toggleFollow,
                      icon: Icon(
                        _isFollowing ? Icons.person_remove : Icons.person_add,
                        color: _isFollowing
                            ? BrandColors.error
                            : context.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildBioSection(Specialist specialist) {
    if (specialist.description == null || specialist.description!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Text(
                'О специалисте',
                style: context.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                specialist.description!,
                style: context.textTheme.bodyMedium,
              ),
              if (specialist.services.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Услуги:',
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specialist.services
                      .take(5)
                      .map(
                        (service) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            service,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() => SliverPersistentHeader(
        pinned: true,
        delegate: _TabBarDelegate(
          TabBar(
            controller: _tabController,
            indicatorColor: context.primaryColor,
            labelColor: context.primaryColor,
            unselectedLabelColor: context.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.grid_on), text: 'Работы'),
              Tab(icon: Icon(Icons.favorite), text: 'Избранное'),
              Tab(icon: Icon(Icons.star), text: 'Отзывы'),
            ],
          ),
        ),
      );

  Widget _buildTabContent(Specialist specialist) => SliverFillRemaining(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildWorksTab(),
            _buildFavoritesTab(),
            _buildReviewsTab(specialist),
          ],
        ),
      );

  Widget _buildWorksTab() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 12,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.image,
              color: context.textSecondary,
              size: 32,
            ),
          ),
        ),
      );

  Widget _buildFavoritesTab() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.favorite,
              color: Colors.red,
              size: 32,
            ),
          ),
        ),
      );

  Widget _buildReviewsTab(Specialist specialist) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: specialist.reviewsCount,
        itemBuilder: (context, index) => _buildReviewCard(index),
      );

  Widget _buildReviewCard(int index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHighest),
          boxShadow: BrandColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.primaryColor,
                  child: Text(
                    'U$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Пользователь $index',
                        style: context.textTheme.titleSmall,
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (starIndex) => Icon(
                            starIndex < 4 ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${index + 1} дн. назад',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Отличный специалист! Очень довольна результатом. '
              'Рекомендую всем, кто ищет качественные услуги.',
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      );

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFollowing ? 'Подписались' : 'Отписались',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                context.pop();
                // TODO(developer): Поделиться профилем
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Пожаловаться'),
              onTap: () {
                context.pop();
                // TODO(developer): Пожаловаться
              },
            ),
            if (widget.isOwnProfile)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать профиль'),
                onTap: () {
                  // Проверяем, авторизован ли пользователь
                  final currentUser = ref.read(currentUserProvider).value;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Для редактирования профиля войдите в систему.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  context.push('/edit-profile');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: tabBar,
      );

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
