import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/social_models.dart';
import '../services/supabase_service.dart';

class SocialProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const SocialProfileScreen({super.key, required this.username});

  @override
  ConsumerState<SocialProfileScreen> createState() =>
      _SocialProfileScreenState();
}

class _SocialProfileScreenState extends ConsumerState<SocialProfileScreen> {
  Profile? _profile;
  FollowStats? _followStats;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isUpdatingFollow = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final profile =
          await SupabaseService.getProfileByUsername(widget.username);
      if (profile == null) {
        setState(() {
          _error = 'Профиль не найден';
          _isLoading = false;
        });
        return;
      }

      final currentUser = SupabaseService.currentUser;
      bool isFollowing = false;
      int followersCount = 0;
      int followingCount = 0;

      if (currentUser != null) {
        isFollowing =
            await SupabaseService.isFollowing(currentUser.id, profile.id);
        followersCount = await SupabaseService.getFollowersCount(profile.id);
        followingCount = await SupabaseService.getFollowingCount(profile.id);
      }

      setState(() {
        _profile = profile;
        _isFollowing = isFollowing;
        _followStats = FollowStats(
          followersCount: followersCount,
          followingCount: followingCount,
          isFollowing: isFollowing,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || _isUpdatingFollow) return;

    setState(() {
      _isUpdatingFollow = true;
    });

    try {
      bool success;
      if (_isFollowing) {
        success = await SupabaseService.unfollowUser(_profile!.id);
      } else {
        success = await SupabaseService.followUser(_profile!.id);
      }

      if (success) {
        setState(() {
          _isFollowing = !_isFollowing;
          _followStats = FollowStats(
            followersCount: _isFollowing
                ? _followStats!.followersCount + 1
                : _followStats!.followersCount - 1,
            followingCount: _followStats!.followingCount,
            isFollowing: _isFollowing,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isUpdatingFollow = false;
      });
    }
  }

  Future<void> _openChat() async {
    if (_profile == null) return;

    try {
      final chatId = await SupabaseService.getOrCreateChat(_profile!.id);
      if (chatId != null) {
        context.push('/chat/$chatId');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка создания чата')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Профиль не найден',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadProfile, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile!.name),
        actions: [
          // Кнопка редактирования (только для своего профиля)
          if (_isOwnProfile())
            IconButton(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
            ),
          IconButton(
            onPressed: () {
              // Поделиться профилем
              _shareProfile();
            },
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Заголовок профиля
            _buildProfileHeader(),

            // Статистика подписок
            _buildFollowStats(),

            // Био и навыки
            _buildBioSection(),

            // Кнопки действий
            _buildActionButtons(),

            // Дополнительная информация
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Аватар
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Theme.of(context).primaryColor, width: 3),
            ),
            child: ClipOval(
              child: _profile!.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _profile!.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        child: Icon(Icons.person,
                            color: Theme.of(context).primaryColor, size: 60),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        child: Icon(Icons.person,
                            color: Theme.of(context).primaryColor, size: 60),
                      ),
                    )
                  : Container(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: Icon(Icons.person,
                          color: Theme.of(context).primaryColor, size: 60),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Имя и username
          Text(
            _profile!.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '@${_profile!.username}',
            style: Theme.of(
              context,
            )
                .textTheme
                .bodyLarge
                ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Город
          if (_profile!.city != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(_profile!.city!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFollowStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Подписчики',
            _followStats?.followersCount.toString() ?? '0',
            () => context.push('/profile/${_profile!.username}/followers'),
          ),
          Container(
              width: 1, height: 40, color: Theme.of(context).dividerColor),
          _buildStatItem(
            'Подписки',
            _followStats?.followingCount.toString() ?? '0',
            () => context.push('/profile/${_profile!.username}/following'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            )
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
            Text(
              'О себе',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_profile!.bio!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          if (_profile!.skills.isNotEmpty) ...[
            Text(
              'Навыки',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profile!.skills.map((skill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final currentUser = SupabaseService.currentUser;
    final isOwnProfile = currentUser?.id == _profile!.id;

    if (isOwnProfile) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать профиль'),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isUpdatingFollow ? null : _toggleFollow,
              icon: _isUpdatingFollow
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
              label: Text(_isFollowing ? 'Отписаться' : 'Подписаться'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.message),
              label: const Text('Написать'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.calendar_today,
            'Дата регистрации',
            _formatDate(_profile!.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(Icons.update, 'Последнее обновление',
              _formatDate(_profile!.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon,
            size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} недель назад';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} месяцев назад';
    } else {
      return '${(difference.inDays / 365).floor()} лет назад';
    }
  }

  void _shareProfile() {
    // TODO: Реализовать функционал шаринга
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Функция шаринга будет добавлена позже')));
  }

  bool _isOwnProfile() {
    final currentUser = SupabaseService.currentUser;
    return currentUser != null &&
        _profile != null &&
        currentUser.id == _profile!.id;
  }

  void _editProfile() {
    context.push('/edit-profile', extra: _profile);
  }
}
