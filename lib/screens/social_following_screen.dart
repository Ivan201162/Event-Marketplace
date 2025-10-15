import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/social_models.dart';
import '../services/supabase_service.dart';

class SocialFollowingScreen extends ConsumerStatefulWidget {
  final String username;

  const SocialFollowingScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<SocialFollowingScreen> createState() => _SocialFollowingScreenState();
}

class _SocialFollowingScreenState extends ConsumerState<SocialFollowingScreen> {
  List<Profile> _following = [];
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

      // Загружаем подписки
      final following = await SupabaseService.getFollowing(profile.id);

      setState(() {
        _profile = profile;
        _following = following;
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
        title: Text('Подписки ${_profile?.name ?? ''}'),
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

    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 64,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет подписок',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${_profile?.name ?? 'Пользователь'} пока ни на кого не подписан',
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
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final following = _following[index];
          return _buildFollowingItem(following);
        },
      ),
    );
  }

  Widget _buildFollowingItem(Profile following) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: following.avatarUrl != null
            ? CachedNetworkImageProvider(following.avatarUrl!)
            : null,
        child: following.avatarUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        following.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${following.username}'),
          if (following.city != null)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  following.city!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
      trailing: _buildUnfollowButton(following),
      onTap: () {
        context.push('/profile/${following.username}');
      },
    );
  }

  Widget _buildUnfollowButton(Profile following) {
    final currentUser = SupabaseService.currentUser;
    final isOwnProfile = currentUser?.id == following.id;

    if (isOwnProfile) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: SupabaseService.isFollowing(currentUser!.id, following.id),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        if (!isFollowing) {
          return const SizedBox.shrink();
        }

        return ElevatedButton(
          onPressed: () => _unfollow(following),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(80, 32),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade200),
          ),
          child: const Text(
            'Отписаться',
            style: TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }

  Future<void> _unfollow(Profile following) async {
    try {
      final success = await SupabaseService.unfollowUser(following.id);
      
      if (success) {
        setState(() {
          _following.removeWhere((user) => user.id == following.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Вы отписались от ${following.name}'),
            action: SnackBarAction(
              label: 'Отменить',
              onPressed: () => _refollow(following),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка отписки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _refollow(Profile following) async {
    try {
      final success = await SupabaseService.followUser(following.id);
      
      if (success) {
        setState(() {
          _following.add(following);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
}

