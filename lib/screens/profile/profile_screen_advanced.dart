import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/story.dart';
import '../../providers/auth_providers.dart';
import '../../services/story_service.dart';

/// Продвинутый экран профиля с социальными функциями
class ProfileScreenAdvanced extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreenAdvanced({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreenAdvanced> createState() => _ProfileScreenAdvancedState();
}

class _ProfileScreenAdvancedState extends ConsumerState<ProfileScreenAdvanced>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final StoryService _storyService = StoryService();
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit_profile':
        context.go('/profile/edit');
        break;
      case 'account_security':
        context.go('/account/security');
        break;
      case 'appearance':
        context.go('/appearance');
        break;
      case 'notifications':
        context.go('/notifications');
        break;
      case 'privacy':
        context.go('/privacy');
        break;
      case 'professional':
        context.go('/professional');
        break;
      case 'monetization':
        context.go('/monetization');
        break;
      case 'blocked':
        context.go('/blocked');
        break;
      case 'report':
        context.go('/report');
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider);
    final isOwnProfile = currentUser.value?.uid == widget.userId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Верхняя панель
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/main');
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit_profile',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                          title: Text('Редактировать профиль'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'account_security',
                        child: ListTile(
                          leading: Icon(Icons.security, color: Color(0xFF1E3A8A)),
                          title: Text('Аккаунт и безопасность'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'appearance',
                        child: ListTile(
                          leading: Icon(Icons.palette, color: Color(0xFF1E3A8A)),
                          title: Text('Внешний вид'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'notifications',
                        child: ListTile(
                          leading: Icon(Icons.notifications, color: Color(0xFF1E3A8A)),
                          title: Text('Уведомления'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'privacy',
                        child: ListTile(
                          leading: Icon(Icons.privacy_tip, color: Color(0xFF1E3A8A)),
                          title: Text('Конфиденциальность'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'professional',
                        child: ListTile(
                          leading: Icon(Icons.business, color: Color(0xFF1E3A8A)),
                          title: Text('Профессиональный аккаунт'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'monetization',
                        child: ListTile(
                          leading: Icon(Icons.attach_money, color: Color(0xFF1E3A8A)),
                          title: Text('Монетизация'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'blocked',
                        child: ListTile(
                          leading: Icon(Icons.block, color: Color(0xFF1E3A8A)),
                          title: Text('Заблокированные пользователи'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: ListTile(
                          leading: Icon(Icons.bug_report, color: Color(0xFF1E3A8A)),
                          title: Text('Сообщить о проблеме'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text('Выйти', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Шапка профиля с обложкой
              SliverToBoxAdapter(
                child: _ProfileHeaderAdvanced(
                  userId: widget.userId,
                  isOwnProfile: isOwnProfile,
                  onFollowToggle: () => _toggleFollow(),
                  isFollowing: _isFollowing,
                ),
              ),

              // Сторис
              SliverToBoxAdapter(
                child: _StoriesSectionAdvanced(userId: widget.userId),
              ),

              // Контент (вкладки)
              SliverFillRemaining(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF1E3A8A),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF1E3A8A),
                        isScrollable: true,
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
                          Tab(icon: Icon(Icons.photo_library_outlined), text: 'Фото'),
                          Tab(icon: Icon(Icons.movie_outlined), text: 'Видео'),
                          Tab(icon: Icon(Icons.star_outline), text: 'Отзывы'),
                          Tab(icon: Icon(Icons.analytics_outlined), text: 'Аналитика'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            _PostsTab(),
                            _PhotosTab(),
                            _VideosTab(),
                            _ReviewsTab(),
                            _AnalyticsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    // TODO: Implement follow/unfollow logic
  }
}

class _ProfileHeaderAdvanced extends ConsumerWidget {
  final String userId;
  final bool isOwnProfile;
  final VoidCallback onFollowToggle;
  final bool isFollowing;

  const _ProfileHeaderAdvanced({
    required this.userId,
    required this.isOwnProfile,
    required this.onFollowToggle,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? userData?['displayName'] ?? 'Пользователь';
        final firstName = userData?['firstName'] ?? '';
        final lastName = userData?['lastName'] ?? '';
        final fullName = firstName.isNotEmpty && lastName.isNotEmpty 
            ? '$firstName $lastName' 
            : name;
        final city = userData?['city'] ?? 'Город не указан';
        final bio = userData?['bio'] ?? '';
        final isProAccount = userData?['isProAccount'] ?? false;
        final proCategory = userData?['proCategory'] ?? '';
        final isVerified = userData?['isVerified'] ?? false;
        final avatarUrl = userData?['avatarUrl'] ?? userData?['photoURL'];
        final coverUrl = userData?['coverUrl'];
        final followersCount = userData?['followersCount'] ?? 0;
        final followingCount = userData?['followingCount'] ?? 0;
        final postsCount = userData?['postsCount'] ?? 0;
        final rating = userData?['rating'] ?? 0.0;
        final isOnline = userData?['isOnline'] ?? false;
        final lastSeen = userData?['lastSeen'];

        return Column(
          children: [
            // Обложка профиля
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: coverUrl == null
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Аватар поверх обложки
                  Positioned(
                    bottom: -40,
                    left: 16,
                    child: Hero(
                      tag: 'avatar-$userId',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person, color: Colors.grey, size: 50)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  // Онлайн статус
                  if (isOnline)
                    Positioned(
                      bottom: 10,
                      left: 70,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // Информация о пользователе
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isVerified)
                                  const Icon(Icons.verified, color: Colors.blue, size: 24),
                              ],
                            ),
                            if (isProAccount && proCategory.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Text(
                                  proCategory,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  city,
                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                if (isOnline) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Онлайн',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (bio.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                bio,
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (rating > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Статистика
                  Row(
                    children: [
                      _StatItem(label: 'Посты', value: postsCount.toString()),
                      _StatItem(label: 'Подписчики', value: followersCount.toString()),
                      _StatItem(label: 'Подписки', value: followingCount.toString()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Кнопки действий
                  if (isOwnProfile) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/profile/edit'),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Редактировать'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.share, color: Colors.white),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onFollowToggle,
                            icon: Icon(
                              isFollowing ? Icons.person_remove : Icons.person_add_alt_1,
                              size: 18,
                            ),
                            label: Text(isFollowing ? 'Отписаться' : 'Подписаться'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.grey : Colors.white,
                              foregroundColor: isFollowing ? Colors.white : const Color(0xFF1E3A8A),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to chat
                            },
                            icon: const Icon(Icons.message, size: 18),
                            label: const Text('Написать'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.share, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoriesSectionAdvanced extends ConsumerWidget {
  final String userId;

  const _StoriesSectionAdvanced({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider);
    final isOwnProfile = currentUser.value?.uid == userId;
    final storyService = StoryService();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<List<Story>>(
        stream: storyService.getUserStories(userId),
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length + (isOwnProfile ? 1 : 0),
            itemBuilder: (context, index) {
              if (isOwnProfile && index == 0) {
                return _AddStoryButton();
              }

              final storyIndex = isOwnProfile ? index - 1 : index;
              final story = stories[storyIndex];

              return _StoryItemAdvanced(
                story: story,
                isViewed: story.hasViewed(currentUser.value?.uid ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Navigate to create story
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ваша история',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StoryItemAdvanced extends StatelessWidget {
  final Story story;
  final bool isViewed;

  const _StoryItemAdvanced({required this.story, required this.isViewed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Navigate to story viewer
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isViewed ? Colors.white54 : Colors.white,
                  width: 2,
                ),
                gradient: isViewed
                    ? null
                    : const LinearGradient(
                        colors: [Colors.purple, Colors.orange, Colors.red],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: story.content != null && story.type == StoryType.image
                      ? Image.network(
                          story.content!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, color: Colors.grey);
                          },
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'История',
            style: TextStyle(
              color: isViewed ? Colors.white54 : Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Placeholder tabs
class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Посты пока пусты', style: TextStyle(color: Colors.grey)),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Фото пока пусты', style: TextStyle(color: Colors.grey)),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Видео пока пусты', style: TextStyle(color: Colors.grey)),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Отзывы пока пусты', style: TextStyle(color: Colors.grey)),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Аналитика пока пуста', style: TextStyle(color: Colors.grey)),
    );
  }
}
