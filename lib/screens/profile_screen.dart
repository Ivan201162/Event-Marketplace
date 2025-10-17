import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/profile/profile_actions_widget.dart';
import '../widgets/profile/profile_header_widget.dart';
import '../widgets/profile/profile_stats_widget.dart';
import '../widgets/profile/profile_tabs_widget.dart';

/// Экран профиля пользователя
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.userId,
  });

  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = widget.userId == null || (currentUser.value?.id == widget.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? 'Мой профиль' : 'Профиль'),
        centerTitle: true,
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editProfile,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProfile,
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Пользователь не найден'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Обновление данных профиля
              ref.invalidate(currentUserProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Заголовок профиля
                  ProfileHeaderWidget(
                    user: user,
                    isCurrentUser: isCurrentUser,
                  ),

                  const SizedBox(height: 16),

                  // Статистика профиля
                  ProfileStatsWidget(
                    user: user,
                    isCurrentUser: isCurrentUser,
                  ),

                  const SizedBox(height: 16),

                  // Действия профиля
                  ProfileActionsWidget(
                    user: user,
                    isCurrentUser: isCurrentUser,
                  ),

                  const SizedBox(height: 16),

                  // Вкладки профиля
                  ProfileTabsWidget(
                    user: user,
                    isCurrentUser: isCurrentUser,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки профиля',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    context.push('/profile/edit');
  }

  void _shareProfile() {
    // TODO: Реализовать шаринг профиля
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция шаринга будет добавлена позже'),
      ),
    );
  }
}
