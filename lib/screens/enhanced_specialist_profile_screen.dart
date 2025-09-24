import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/specialist.dart';
import '../models/specialist_post.dart';
import '../models/specialist_story.dart';
import '../services/specialist_content_service.dart';
import '../widgets/specialist_profile_header.dart';
import '../widgets/specialist_stories_widget.dart';
import '../widgets/specialist_posts_widget.dart';
import '../widgets/specialist_stats_widget.dart';
import '../widgets/specialist_services_widget.dart';

/// Улучшенный экран профиля специалиста в стиле соцсетей
class EnhancedSpecialistProfileScreen extends ConsumerStatefulWidget {
  const EnhancedSpecialistProfileScreen({
    super.key,
    required this.specialistId,
    this.isOwnProfile = false,
  });

  final String specialistId;
  final bool isOwnProfile;

  @override
  ConsumerState<EnhancedSpecialistProfileScreen> createState() => _EnhancedSpecialistProfileScreenState();
}

class _EnhancedSpecialistProfileScreenState extends ConsumerState<EnhancedSpecialistProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Апп бар с градиентом
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Профиль специалиста',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (widget.isOwnProfile) ...[
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showSettings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _createPost,
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareProfile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showMoreOptions,
                  ),
                ],
              ],
            ),
            
            // Заголовок профиля
            SliverToBoxAdapter(
              child: SpecialistProfileHeader(
                specialistId: widget.specialistId,
                isOwnProfile: widget.isOwnProfile,
                onEditProfile: widget.isOwnProfile ? _editProfile : null,
                onContactSpecialist: widget.isOwnProfile ? null : _contactSpecialist,
              ),
            ),
            
            // Статистика
            SliverToBoxAdapter(
              child: SpecialistStatsWidget(
                specialistId: widget.specialistId,
              ),
            ),
            
            // Сторис
            SliverToBoxAdapter(
              child: SpecialistStoriesWidget(
                specialistId: widget.specialistId,
                isOwnProfile: widget.isOwnProfile,
                onAddStory: widget.isOwnProfile ? _addStory : null,
              ),
            ),
            
            // Табы
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
                    Tab(icon: Icon(Icons.work), text: 'Услуги'),
                    Tab(icon: Icon(Icons.analytics), text: 'Аналитика'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Посты
            SpecialistPostsWidget(
              specialistId: widget.specialistId,
              isOwnProfile: widget.isOwnProfile,
              onPostTap: _showPostDetails,
              onLikePost: _likePost,
              onCommentPost: _commentPost,
            ),
            
            // Услуги
            SpecialistServicesWidget(
              specialistId: widget.specialistId,
              isOwnProfile: widget.isOwnProfile,
              onEditService: widget.isOwnProfile ? _editService : null,
              onAddService: widget.isOwnProfile ? _addService : null,
              onBookService: widget.isOwnProfile ? null : _bookService,
            ),
            
            // Аналитика
            _buildAnalyticsTab(),
          ],
        ),
      ),
      
      // Плавающая кнопка для быстрых действий
      floatingActionButton: widget.isOwnProfile
          ? FloatingActionButton.extended(
              onPressed: _showQuickActions,
              icon: const Icon(Icons.add),
              label: const Text('Создать'),
            )
          : null,
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // График просмотров
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статистика просмотров',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('График просмотров (заглушка)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Топ посты
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Топ посты',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Список популярных постов (заглушка)'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Демография аудитории
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Демография аудитории',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Демографические данные (заглушка)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Редактировать профиль'),
            onTap: () {
              Navigator.pop(context);
              _editProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Уведомления'),
            onTap: () {
              Navigator.pop(context);
              _showNotificationSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Приватность'),
            onTap: () {
              Navigator.pop(context);
              _showPrivacySettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Помощь'),
            onTap: () {
              Navigator.pop(context);
              _showHelp();
            },
          ),
        ],
      ),
    );
  }

  void _createPost() {
    Navigator.pushNamed(context, '/create_post');
  }

  void _shareProfile() {
    // Логика шаринга профиля
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMoreOptionsBottomSheet(),
    );
  }

  Widget _buildMoreOptionsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Пожаловаться'),
            onTap: () {
              Navigator.pop(context);
              _reportProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Заблокировать'),
            onTap: () {
              Navigator.pop(context);
              _blockProfile();
            },
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    Navigator.pushNamed(context, '/edit_specialist_profile');
  }

  void _contactSpecialist() {
    Navigator.pushNamed(context, '/chat', arguments: widget.specialistId);
  }

  void _addStory() {
    Navigator.pushNamed(context, '/create_story');
  }

  void _showPostDetails(SpecialistPost post) {
    Navigator.pushNamed(context, '/post_details', arguments: post.id);
  }

  void _likePost(String postId) {
    // Логика лайка поста
  }

  void _commentPost(String postId) {
    Navigator.pushNamed(context, '/post_comments', arguments: postId);
  }

  void _editService(String serviceId) {
    Navigator.pushNamed(context, '/edit_service', arguments: serviceId);
  }

  void _addService() {
    Navigator.pushNamed(context, '/add_service');
  }

  void _bookService(String serviceId) {
    Navigator.pushNamed(context, '/book_service', arguments: serviceId);
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildQuickActionsBottomSheet(),
    );
  }

  Widget _buildQuickActionsBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.post_add),
            title: const Text('Создать пост'),
            onTap: () {
              Navigator.pop(context);
              _createPost();
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_call),
            title: const Text('Добавить сторис'),
            onTap: () {
              Navigator.pop(context);
              _addStory();
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Добавить услугу'),
            onTap: () {
              Navigator.pop(context);
              _addService();
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    // Логика настроек уведомлений
  }

  void _showPrivacySettings() {
    // Логика настроек приватности
  }

  void _showHelp() {
    // Логика помощи
  }

  void _reportProfile() {
    // Логика жалобы на профиль
  }

  void _blockProfile() {
    // Логика блокировки профиля
  }
}

/// Делегат для закрепленного таб бара
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
