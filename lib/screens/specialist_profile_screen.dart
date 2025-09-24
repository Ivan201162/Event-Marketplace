import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../models/feed_post.dart';
import '../models/specialist.dart';
import '../models/story.dart';
import '../providers/feed_providers.dart';
import '../providers/story_providers.dart';
import '../providers/subscription_providers.dart';
import '../widgets/enhanced_page_transition.dart';
import '../widgets/responsive_layout.dart';
import 'booking_form_screen.dart';
import 'chat_screen.dart';
import 'reviews_screen.dart';

/// Экран профиля специалиста с функциями соцсети
class SpecialistProfileScreen extends ConsumerStatefulWidget {
  const SpecialistProfileScreen({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  ConsumerState<SpecialistProfileScreen> createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState
    extends ConsumerState<SpecialistProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
        largeDesktop: _buildLargeDesktopLayout(),
      );

  Widget _buildMobileLayout() => Scaffold(
        body: CustomScrollView(
          slivers: [
            // AppBar с профилем
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showProfileOptions,
                ),
              ],
            ),
            // Вкладки
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
                    Tab(icon: Icon(Icons.photo_library), text: 'Альбомы'),
                    Tab(icon: Icon(Icons.info), text: 'О себе'),
                    Tab(icon: Icon(Icons.rate_review), text: 'Отзывы'),
                  ],
                ),
              ),
            ),
            // Контент
            SliverFillRemaining(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                },
                children: [
                  _buildPostsTab(),
                  _buildAlbumsTab(),
                  _buildAboutTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTabletLayout() => Scaffold(
        body: ResponsiveContainer(
          child: Column(
            children: [
              // Заголовок профиля
              _buildProfileHeader(),
              // Вкладки
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
                  Tab(icon: Icon(Icons.photo_library), text: 'Альбомы'),
                  Tab(icon: Icon(Icons.info), text: 'О себе'),
                  Tab(icon: Icon(Icons.rate_review), text: 'Отзывы'),
                ],
              ),
              // Контент
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                  },
                  children: [
                    _buildPostsTab(),
                    _buildAlbumsTab(),
                    _buildAboutTab(),
                    _buildReviewsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDesktopLayout() => Scaffold(
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель с профилем
              SizedBox(
                width: 350,
                child: _buildProfileSidebar(),
              ),
              const SizedBox(width: 24),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    // Вкладки
                    TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
                        Tab(icon: Icon(Icons.photo_library), text: 'Альбомы'),
                        Tab(icon: Icon(Icons.info), text: 'О себе'),
                        Tab(icon: Icon(Icons.rate_review), text: 'Отзывы'),
                      ],
                    ),
                    // Контент
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          _tabController.animateTo(index);
                        },
                        children: [
                          _buildPostsTab(),
                          _buildAlbumsTab(),
                          _buildAboutTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout() => Scaffold(
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель с профилем
              SizedBox(
                width: 400,
                child: _buildProfileSidebar(),
              ),
              const SizedBox(width: 32),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    // Вкладки
                    TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
                        Tab(icon: Icon(Icons.photo_library), text: 'Альбомы'),
                        Tab(icon: Icon(Icons.info), text: 'О себе'),
                        Tab(icon: Icon(Icons.rate_review), text: 'Отзывы'),
                      ],
                    ),
                    // Контент
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          _tabController.animateTo(index);
                        },
                        children: [
                          _buildPostsTab(),
                          _buildAlbumsTab(),
                          _buildAboutTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Правая панель с дополнительной информацией
              SizedBox(
                width: 300,
                child: _buildInfoSidebar(),
              ),
            ],
          ),
        ),
      );

  Widget _buildProfileHeader() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60), // Отступ для AppBar
            // Аватар и основная информация
            Row(
              children: [
                const SizedBox(width: 16),
                // Аватар
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    image: const DecorationImage(
                      image: NetworkImage('https://via.placeholder.com/80'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Информация о специалисте
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ResponsiveText(
                        'Анна Петрова',
                        isTitle: true,
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const ResponsiveText(
                        'Фотограф',
                        isSubtitle: true,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      // Статистика
                      Row(
                        children: [
                          _buildStatItem('Посты', '24'),
                          const SizedBox(width: 16),
                          _buildStatItem('Подписчики', '1.2K'),
                          const SizedBox(width: 16),
                          _buildStatItem('Подписки', '156'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Кнопки действий
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _navigateToBooking,
                      icon: const Icon(Icons.book_online),
                      label: const Text('Забронировать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6200EE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _navigateToChat,
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        'Написать',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );

  Widget _buildProfileSidebar() => Column(
        children: [
          const SizedBox(height: 20),
          // Аватар
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              image: const DecorationImage(
                image: NetworkImage('https://via.placeholder.com/120'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Имя и профессия
          const ResponsiveText(
            'Анна Петрова',
            isTitle: true,
          ),
          const SizedBox(height: 4),
          const ResponsiveText(
            'Фотограф',
            isSubtitle: true,
          ),
          const SizedBox(height: 16),
          // Кнопки действий
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleSubscription,
              icon: const Icon(Icons.person_add),
              label: const Text('Подписаться'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sendMessage,
              icon: const Icon(Icons.message),
              label: const Text('Сообщение'),
            ),
          ),
          const SizedBox(height: 24),
          // Статистика
          _buildStatsCard(),
          const SizedBox(height: 24),
          // Информация о специалисте
          _buildAboutCard(),
        ],
      );

  Widget _buildStatsCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Статистика',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Посты', '24'),
            _buildStatRow('Подписчики', '1.2K'),
            _buildStatRow('Подписки', '156'),
            _buildStatRow('Лайки', '3.4K'),
          ],
        ),
      );

  Widget _buildAboutCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'О специалисте',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            const ResponsiveText(
              'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии.',
              isSubtitle: true,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Город', 'Москва'),
            _buildInfoRow('Опыт', '5 лет'),
            _buildInfoRow('Рейтинг', '4.9 ⭐'),
          ],
        ),
      );

  Widget _buildInfoSidebar() => Column(
        children: [
          const SizedBox(height: 20),
          _buildRecentActivityCard(),
          const SizedBox(height: 24),
          _buildTopPostsCard(),
        ],
      );

  Widget _buildRecentActivityCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Недавняя активность',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Добавил новый пост', '2 часа назад'),
            _buildActivityItem('Обновил портфолио', '1 день назад'),
            _buildActivityItem('Ответил на отзыв', '2 дня назад'),
          ],
        ),
      );

  Widget _buildTopPostsCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Популярные посты',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildTopPostItem('Свадебная фотосессия', '156 лайков'),
            _buildTopPostItem('Портретная съемка', '89 лайков'),
            _buildTopPostItem('Семейная фотосессия', '67 лайков'),
          ],
        ),
      );

  Widget _buildPostsTab() => Consumer(
        builder: (context, ref, child) {
          final postsAsync =
              ref.watch(specialistFeedProvider(widget.specialistId));

          return postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return _buildEmptyState(
                  'Нет постов',
                  'Специалист еще не опубликовал ни одного поста',
                );
              }

              return ResponsiveList(
                children: posts.map(_buildPostCard).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Ошибка загрузки постов: $error'),
            ),
          );
        },
      );

  Widget _buildAlbumsTab() => ResponsiveList(
        children: [
          _buildAlbumCard(
            'Свадебные фото',
            '24 фото',
            'https://via.placeholder.com/300x200',
          ),
          _buildAlbumCard(
            'Портреты',
            '18 фото',
            'https://via.placeholder.com/300x200',
          ),
          _buildAlbumCard(
            'Семейные фото',
            '32 фото',
            'https://via.placeholder.com/300x200',
          ),
          _buildAlbumCard(
            'Корпоративы',
            '15 фото',
            'https://via.placeholder.com/300x200',
          ),
        ],
      );

  Widget _buildAboutTab() => ResponsiveList(
        children: [
          _buildAboutSection(),
          _buildServicesSection(),
          _buildPortfolioSection(),
          _buildReviewsSection(),
        ],
      );

  Widget _buildReviewsTab() => ReviewsScreen(
        specialistId: widget.specialistId,
        canWriteReview: false, // Только просмотр отзывов в профиле
      );

  Widget _buildPostCard(FeedPost post) => AnimatedContent(
        delay: Duration(milliseconds: 100),
        type: AnimationType.slideUp,
        child: ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок поста
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      post.specialistPhotoUrl ??
                          'https://via.placeholder.com/40',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          post.specialistName,
                          isTitle: true,
                        ),
                        ResponsiveText(
                          _formatDate(post.createdAt),
                          isSubtitle: true,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPostOptions(post),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Текст поста
              if (post.content.isNotEmpty) ...[
                ResponsiveText(post.content),
                const SizedBox(height: 16),
              ],
              // Медиа
              if (post.mediaUrls.isNotEmpty) ...[
                _buildPostMedia(post),
                const SizedBox(height: 16),
              ],
              // Действия
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.isLikedBy('current_user')
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post.isLikedBy('current_user') ? Colors.red : null,
                    ),
                    onPressed: () => _toggleLike(post),
                  ),
                  Text('${post.likes}'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () => _showComments(post),
                  ),
                  Text('${post.comments}'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _sharePost(post),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildPostMedia(FeedPost post) {
    if (post.mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          post.mediaUrls.first,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return SizedBox(
        height: 200,
        child: PageView.builder(
          itemCount: post.mediaUrls.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.mediaUrls[index],
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAlbumCard(String title, String count, String coverImage) =>
      AnimatedContent(
        delay: Duration(milliseconds: 100),
        type: AnimationType.scale,
        child: ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  coverImage,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              ResponsiveText(
                title,
                isTitle: true,
              ),
              const SizedBox(height: 4),
              ResponsiveText(
                count,
                isSubtitle: true,
              ),
            ],
          ),
        ),
      );

  Widget _buildAboutSection() => const ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'О специалисте',
              isTitle: true,
            ),
            SizedBox(height: 16),
            ResponsiveText(
              'Профессиональный фотограф с 5-летним опытом. Специализируюсь на свадебной и портретной фотографии. Работаю в Москве и области.',
              isSubtitle: true,
            ),
          ],
        ),
      );

  Widget _buildServicesSection() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Услуги',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildServiceItem('Свадебная фотосъемка', 'от 15,000 ₽'),
            _buildServiceItem('Портретная съемка', 'от 8,000 ₽'),
            _buildServiceItem('Семейная фотосъемка', 'от 10,000 ₽'),
            _buildServiceItem('Корпоративная съемка', 'от 12,000 ₽'),
          ],
        ),
      );

  Widget _buildPortfolioSection() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Портфолио',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              crossAxisCount: 3,
              children: List.generate(9, _buildPortfolioItem),
            ),
          ],
        ),
      );

  Widget _buildReviewsSection() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Отзывы',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildReviewItem(
              'Мария Иванова',
              'Отличная работа! Очень довольна результатом.',
              '5.0',
            ),
            _buildReviewItem(
              'Алексей Петров',
              'Профессиональный подход, качественные фото.',
              '5.0',
            ),
            _buildReviewItem(
              'Елена Сидорова',
              'Рекомендую всем! Очень внимательный к деталям.',
              '5.0',
            ),
          ],
        ),
      );

  Widget _buildStatItem(String label, String value) => Column(
        children: [
          ResponsiveText(
            value,
            isTitle: true,
            style: const TextStyle(color: Colors.white),
          ),
          ResponsiveText(
            label,
            isSubtitle: true,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      );

  Widget _buildStatRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(label, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(label, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildActivityItem(String action, String time) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: ResponsiveText(action, isSubtitle: true),
            ),
            ResponsiveText(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildTopPostItem(String title, String likes) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.thumb_up, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: ResponsiveText(title, isSubtitle: true),
            ),
            ResponsiveText(
              likes,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildServiceItem(String service, String price) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(service, isSubtitle: true),
            ResponsiveText(
              price,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildPortfolioItem(int index) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          'https://via.placeholder.com/100x100?text=${index + 1}',
          width: double.infinity,
          height: 100,
          fit: BoxFit.cover,
        ),
      );

  Widget _buildReviewItem(String name, String review, String rating) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      NetworkImage('https://via.placeholder.com/32'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ResponsiveText(name, isTitle: true),
                ),
                ResponsiveText(
                  rating,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ResponsiveText(review, isSubtitle: true),
          ],
        ),
      );

  Widget _buildEmptyState(String title, String subtitle) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            ResponsiveText(
              title,
              isTitle: true,
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              subtitle,
              isSubtitle: true,
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _toggleSubscription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Подписка обновлена')),
    );
  }

  void _sendMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Открытие чата')),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль скопирован в буфер обмена')),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Пожаловаться'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Заблокировать'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(FeedPost post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Сохранить'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Пожаловаться'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike(FeedPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Лайк обновлен')),
    );
  }

  void _showComments(FeedPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Открытие комментариев')),
    );
  }

  void _sharePost(FeedPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пост скопирован в буфер обмена')),
    );
  }

  /// Навигация к экрану бронирования
  void _navigateToBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingFormScreen(
          specialistId: widget.specialistId,
        ),
      ),
    );
  }

  /// Навигация к чату
  void _navigateToChat() {
    // Создаем или находим чат с специалистом
    final chatId = 'chat_${widget.specialistId}_${DateTime.now().millisecondsSinceEpoch}';
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
        ),
      ),
    );
  }
}

/// Делегат для SliverTabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _tabBar,
      );

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
