import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../models/story.dart';
import '../providers/auth_providers.dart';
import '../services/post_service.dart';
import '../services/story_service.dart';
import '../services/test_data_service.dart';
import '../widgets/editable_image.dart';
import '../widgets/post_grid_widget.dart';
import '../widgets/story_circle_widget.dart';

/// Современный экран профиля в стиле Instagram
class ModernProfileScreen extends ConsumerStatefulWidget {
  const ModernProfileScreen({super.key, required this.userId, this.isOwnProfile = false});

  final String userId;
  final bool isOwnProfile;

  @override
  ConsumerState<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends ConsumerState<ModernProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  final TestDataService _testDataService = TestDataService();
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();

  bool _isFollowing = false;
  bool _isLoading = false;
  List<Post> _posts = [];
  List<Story> _stories = [];
  Map<String, dynamic>? _specialist;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Посты, Отзывы, Портфолио, Расписание
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем данные специалиста
      final specialists = _testDataService.getSpecialists();
      final specialistData = specialists.firstWhere(
        (s) => s['id'] == widget.userId,
        orElse: () => specialists.first,
      );
      _specialist = specialistData;

      // Загружаем посты
      _posts = await _postService.getPostsBySpecialist(widget.userId);

      // Загружаем сторисы
      _stories = await _storyService.getStoriesBySpecialist(widget.userId);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_specialist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Профиль'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Профиль не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text((_specialist!['name'] as String?) ?? 'Без имени'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: _showOptionsMenu)],
      ),
      body: _buildProfileContent(_specialist!),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> specialist) => FadeTransition(
    opacity: _fadeAnimation,
    child: CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildProfileHeader(specialist),
        _buildProfileInfo(specialist),
        _buildStatsSection(specialist),
        _buildActionButtons(specialist),
        _buildBioSection(specialist),
        _buildStoriesSection(),
        _buildTabBar(),
        _buildTabContent(specialist),
      ],
    ),
  );

  Widget _buildProfileHeader(Map<String, dynamic> specialist) => SliverToBoxAdapter(
    child: Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Фоновое изображение (если есть)
          if (specialist['coverImageUrl'] != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: specialist['coverImageUrl'] as String,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                errorWidget: (context, url, error) =>
                    Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
              ),
            ),
          // Градиентный оверлей
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
          // Кнопка редактирования (для владельца профиля)
          if (widget.isOwnProfile)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _editProfile,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildProfileInfo(Map<String, dynamic> specialist) => SliverToBoxAdapter(
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Аватар
            Hero(
              tag: 'profile_avatar_${specialist['id']}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                ),
                child: ClipOval(
                  child: widget.isOwnProfile
                      ? EditableImage(
                          imageUrl: specialist['imageUrl'] as String?,
                          onImageChanged: _updateProfileImage,
                          placeholder: Icons.person,
                        )
                      : CachedNetworkImage(
                          imageUrl: (specialist['imageUrl'] as String?) ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 50),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 50),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Информация о пользователе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialist['name'] as String,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (specialist['city'] != null)
                    Text(
                      specialist['city'] as String,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        (specialist['rating'] as num).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${specialist['reviewCount']} отзывов)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

  Widget _buildStatsSection(Map<String, dynamic> specialist) => SliverToBoxAdapter(
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Посты', _posts.length.toString()),
            _buildStatItem('Подписчики', '1.2K'),
            _buildStatItem('Подписки', '156'),
            _buildStatItem('Проекты', specialist['totalBookings']?.toString() ?? '0'),
          ],
        ),
      ),
    ),
  );

  Widget _buildStatItem(String label, String value) => Column(
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _buildActionButtons(Map<String, dynamic> specialist) => SliverToBoxAdapter(
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.isOwnProfile
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _addPost,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить пост'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openChat,
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
                      onPressed: _toggleFollow,
                      icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                      label: Text(_isFollowing ? 'Отписаться' : 'Подписаться'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _isFollowing ? Colors.red : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );

  Widget _buildBioSection(Map<String, dynamic> specialist) {
    if (specialist['description'] == null || (specialist['description'] as String).isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('О специалисте', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(
                specialist['description'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if ((specialist['services'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Услуги:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (specialist['services'] as List)
                      .take(5)
                      .map(
                        (service) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            service.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
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

  Widget _buildStoriesSection() {
    if (_stories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stories.length + (widget.isOwnProfile ? 1 : 0),
            itemBuilder: (context, index) {
              if (widget.isOwnProfile && index == _stories.length) {
                return _buildAddStoryButton();
              }
              return _buildStoryItem(_stories[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(Story story) => Container(
    width: 80,
    margin: const EdgeInsets.only(right: 12),
    child: Column(
      children: [
        StoryCircleWidget(story: story, onTap: () => _viewStory(story)),
        const SizedBox(height: 4),
        Text(
          story.title,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _buildAddStoryButton() => Container(
    width: 80,
    margin: const EdgeInsets.only(right: 12),
    child: Column(
      children: [
        GestureDetector(
          onTap: _addStory,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
            ),
            child: const Icon(Icons.add, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 4),
        const Text('Добавить', style: TextStyle(fontSize: 12)),
      ],
    ),
  );

  Widget _buildTabBar() => SliverPersistentHeader(
    pinned: true,
    delegate: _TabBarDelegate(
      TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).primaryColor,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        tabs: const [
          Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
          Tab(icon: Icon(Icons.star), text: 'Отзывы'),
          Tab(icon: Icon(Icons.work), text: 'Портфолио'),
          Tab(icon: Icon(Icons.calendar_today), text: 'Расписание'),
        ],
      ),
    ),
  );

  Widget _buildTabContent(Map<String, dynamic> specialist) => SliverFillRemaining(
    child: TabBarView(
      controller: _tabController,
      children: [
        _buildPostsTab(),
        _buildReviewsTab(specialist),
        _buildPortfolioTab(specialist),
        _buildScheduleTab(specialist),
      ],
    ),
  );

  Widget _buildPostsTab() => _posts.isEmpty
      ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_on, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Пока нет постов'),
            ],
          ),
        )
      : PostGridWidget(posts: _posts, onPostTap: _viewPost);

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
      child: const Center(child: Icon(Icons.favorite, color: Colors.red, size: 32)),
    ),
  );

  Widget _buildReviewsTab(Map<String, dynamic> specialist) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: (specialist['reviewsCount'] as int?) ?? 0,
    itemBuilder: (context, index) => _buildReviewCard(index),
  );

  Widget _buildReviewCard(int index) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                'U$index',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Пользователь $index', style: Theme.of(context).textTheme.titleSmall),
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
            Text('${index + 1} дн. назад', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Отличный специалист! Очень довольна результатом. '
          'Рекомендую всем, кто ищет качественные услуги.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );

  Widget _buildPortfolioTab(Map<String, dynamic> specialist) =>
      (specialist['portfolioImages'] as List).isEmpty
      ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Портфолио пусто'),
            ],
          ),
        )
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: (specialist['portfolioImages'] as List).length,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: CachedNetworkImage(
              imageUrl: (specialist['portfolioImages'] as List)[index].toString(),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.grey[300], child: const Icon(Icons.error)),
            ),
          ),
        );

  Widget _buildScheduleTab(Map<String, dynamic> specialist) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Расписание будет доступно в следующей версии'),
      ],
    ),
  );

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? 'Подписались' : 'Отписались'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _editProfile() {
    // TODO: Открыть экран редактирования профиля
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование профиля будет доступно в следующей версии')),
    );
  }

  void _addPost() {
    // TODO: Открыть экран создания поста
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание поста будет доступно в следующей версии')),
    );
  }

  void _addStory() {
    // TODO: Открыть экран создания сторис
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание сторис будет доступно в следующей версии')),
    );
  }

  void _openChat() {
    // TODO: Открыть чат с пользователем
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Открытие чата будет доступно в следующей версии')),
    );
  }

  void _viewPost(Post post) {
    // TODO: Открыть детали поста
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Просмотр поста будет доступен в следующей версии')),
    );
  }

  void _viewStory(Story story) {
    // TODO: Открыть просмотр сторис
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Просмотр сторис будет доступен в следующей версии')),
    );
  }

  void _updateProfileImage(String imageUrl) {
    // TODO: Обновить изображение профиля
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Обновление изображения будет доступно в следующей версии')),
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
                        content: Text('Для редактирования профиля войдите в систему.'),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
