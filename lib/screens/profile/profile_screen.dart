import 'package:event_marketplace_app/providers/profile_providers.dart';
import 'package:event_marketplace_app/screens/profile/edit_profile_screen.dart';
import 'package:event_marketplace_app/widgets/profile_content.dart';
import 'package:event_marketplace_app/widgets/profile_header.dart';
import 'package:event_marketplace_app/widgets/profile_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран профиля пользователя
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isOwnProfile = true; // TODO: Определить из контекста

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isOwnProfile) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editProfile,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showProfileMenu,
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Посты'),
            Tab(text: 'Идеи'),
            Tab(text: 'Заявки'),
          ],
        ),
      ),
      body: profileState.when(
        data: (profile) => Column(
          children: [
            // Заголовок профиля
            ProfileHeader(
              profile: profile,
              isOwnProfile: _isOwnProfile,
              onEditProfile: _editProfile,
              onFollow: _toggleFollow,
              onMessage: _sendMessage,
            ),

            // Статистика
            ProfileStats(profile: profile),

            // Контент
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ProfileContent(type: 'posts', userId: profile.id),
                  ProfileContent(type: 'ideas', userId: profile.id),
                  ProfileContent(type: 'requests', userId: profile.id),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки профиля: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).refreshProfile(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _toggleFollow() {
    ref.read(profileProvider.notifier).toggleFollow();
  }

  void _sendMessage() {
    // TODO: Открыть чат с пользователем
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Открытие чата...')),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
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
    );
  }
}
