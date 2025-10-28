import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/story_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Улучшенный экран профиля с шапкой и вкладками
class ProfileScreenImproved extends ConsumerStatefulWidget {

  const ProfileScreenImproved({required this.userId, super.key});
  final String userId;

  @override
  ConsumerState<ProfileScreenImproved> createState() =>
      _ProfileScreenImprovedState();
}

class _ProfileScreenImprovedState extends ConsumerState<ProfileScreenImproved>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final StoryService _storyService = StoryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      case 'account_security':
        context.go('/account/security');
      case 'appearance':
        context.go('/appearance');
      case 'notifications':
        context.go('/notifications');
      case 'privacy':
        context.go('/privacy');
      case 'professional':
        context.go('/professional');
      case 'monetization':
        context.go('/monetization');
      case 'blocked':
        context.go('/blocked');
      case 'report':
        context.go('/report');
      case 'logout':
        _handleLogout(context);
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
              // TODO: Implement logout with AuthService
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
          child: Column(
            children: [
              // Верхняя панель
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/main');
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
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
                            leading:
                                Icon(Icons.security, color: Color(0xFF1E3A8A)),
                            title: Text('Аккаунт и безопасность'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'appearance',
                          child: ListTile(
                            leading:
                                Icon(Icons.palette, color: Color(0xFF1E3A8A)),
                            title: Text('Внешний вид'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'notifications',
                          child: ListTile(
                            leading: Icon(Icons.notifications,
                                color: Color(0xFF1E3A8A),),
                            title: Text('Уведомления'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'privacy',
                          child: ListTile(
                            leading: Icon(Icons.privacy_tip,
                                color: Color(0xFF1E3A8A),),
                            title: Text('Конфиденциальность'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'professional',
                          child: ListTile(
                            leading:
                                Icon(Icons.business, color: Color(0xFF1E3A8A)),
                            title: Text('Профессиональный аккаунт'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'monetization',
                          child: ListTile(
                            leading: Icon(Icons.attach_money,
                                color: Color(0xFF1E3A8A),),
                            title: Text('Монетизация'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'blocked',
                          child: ListTile(
                            leading:
                                Icon(Icons.block, color: Color(0xFF1E3A8A)),
                            title: Text('Заблокированные пользователи'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: ListTile(
                            leading: Icon(Icons.bug_report,
                                color: Color(0xFF1E3A8A),),
                            title: Text('Сообщить о проблеме'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: ListTile(
                            leading: Icon(Icons.logout, color: Colors.red),
                            title: Text('Выйти',
                                style: TextStyle(color: Colors.red),),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Шапка профиля
              _ProfileHeader(userId: widget.userId, isOwnProfile: isOwnProfile),

              // Сторис
              _StoriesSection(userId: widget.userId),

              // Контент (вкладки)
              Expanded(
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
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_on), text: 'Посты'),
                          Tab(
                              icon: Icon(Icons.photo_library_outlined),
                              text: 'Фото',),
                          Tab(icon: Icon(Icons.movie_outlined), text: 'Видео'),
                          Tab(icon: Icon(Icons.star_outline), text: 'Отзывы'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            _PlaceholderTab(label: 'Посты пока пусты'),
                            _PlaceholderTab(label: 'Фото пока пусты'),
                            _PlaceholderTab(label: 'Видео пока пусты'),
                            _PlaceholderTab(label: 'Отзывы пока пусты'),
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
}

class _ProfileHeader extends ConsumerWidget {

  const _ProfileHeader({required this.userId, required this.isOwnProfile});
  final String userId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final name =
            userData?['name'] ?? userData?['displayName'] ?? 'Пользователь';
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
        final followersCount = userData?['followersCount'] ?? 0;
        final followingCount = userData?['followingCount'] ?? 0;
        final postsCount = userData?['postsCount'] ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'avatar-$userId',
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 38,)
                          : null,
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
                                fullName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,),
                              ),
                            ),
                            if (isVerified)
                              const Icon(Icons.verified,
                                  color: Colors.blue, size: 20,),
                          ],
                        ),
                        if (isProAccount && proCategory.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2,),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              proCategory,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          city,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14,),
                        ),
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            bio,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14,),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Счетчики
              Row(
                children: [
                  _Counter(label: 'Посты', value: postsCount.toString()),
                  _Counter(
                      label: 'Подписчики', value: followersCount.toString(),),
                  _Counter(label: 'Подписки', value: followingCount.toString()),
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
                        onPressed: () {},
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Подписаться'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isProAccount) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
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
                    ],
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StoriesSection extends ConsumerWidget {

  const _StoriesSection({required this.userId});
  final String userId;

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
            itemCount: stories.length +
                (isOwnProfile ? 1 : 0), // +1 для кнопки добавления
            itemBuilder: (context, index) {
              if (isOwnProfile && index == 0) {
                // Кнопка добавления сторис для владельца
                return _AddStoryButton();
              }

              final storyIndex = isOwnProfile ? index - 1 : index;
              final story = stories[storyIndex];

              return _StoryItem(
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

class _StoryItem extends StatelessWidget {

  const _StoryItem({required this.story, required this.isViewed});
  final Story story;
  final bool isViewed;

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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
