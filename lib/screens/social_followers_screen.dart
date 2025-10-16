import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/social_models.dart';
import '../services/supabase_service.dart';

class SocialFollowersScreen extends ConsumerStatefulWidget {
  final String username;

  const SocialFollowersScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<SocialFollowersScreen> createState() => _SocialFollowersScreenState();
}

class _SocialFollowersScreenState extends ConsumerState<SocialFollowersScreen> {
  List<Profile> _followers = [];
  bool _isLoading = true;
  String? _error;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Загружаем профиль пользователя
      final profile = await SupabaseService.getProfileByUsername(widget.username);
      if (profile == null) {
        setState(() {
          _error = 'Профиль не найден';
          _isLoading = false;
        });
        return;
      }

      // Загружаем подписчиков
      final followers = await SupabaseService.getFollowers(profile.id);

      setState(() {
        _profile = profile;
        _followers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подписчики ${_profile?.name ?? ''}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет подписчиков',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'У ${_profile?.name ?? 'пользователя'} пока нет подписчиков',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final follower = _followers[index];
          return _buildFollowerItem(follower);
        },
      ),
    );
  }

  Widget _buildFollowerItem(Profile follower) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: follower.avatarUrl != null
            ? CachedNetworkImageProvider(follower.avatarUrl!)
            : null,
        child: follower.avatarUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        follower.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${follower.username}'),
          if (follower.city != null)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  follower.city!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
      trailing: _buildFollowButton(follower),
      onTap: () {
        context.push('/profile/${follower.username}');
      },
    );
  }

  Widget _buildFollowButton(Profile follower) {
    final currentUser = SupabaseService.currentUser;
    final isOwnProfile = currentUser?.id == follower.id;

    if (isOwnProfile) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: SupabaseService.isFollowing(currentUser!.id, follower.id),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return ElevatedButton(
          onPressed: () => _toggleFollow(follower, isFollowing),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(80, 32),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(
            isFollowing ? 'Отписаться' : 'Подписаться',
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow(Profile follower, bool isFollowing) async {
    try {
      bool success;
      if (isFollowing) {
        success = await SupabaseService.unfollowUser(follower.id);
      } else {
        success = await SupabaseService.followUser(follower.id);
      }

      if (success) {
        setState(() {
          // Обновляем список, чтобы отразить изменения
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка обновления подписки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
}



