import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../models/app_user.dart'; // Conflict with user.dart
import '../providers/auth_providers.dart';
import '../widgets/error/error_state_widget.dart';
import '../widgets/loading/loading_state_widget.dart';
import '../widgets/profile/profile_actions_widget.dart';
import '../widgets/profile/profile_header_widget.dart';
import '../widgets/profile/profile_stats_widget.dart';
import '../widgets/profile/profile_tabs_widget.dart';
import '../widgets/chat/start_chat_button.dart';

/// Экран профиля пользователя
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = widget.userId == null || (currentUser.value?.uid == widget.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? 'Мой профиль' : 'Профиль'),
        centerTitle: true,
        actions: [
          if (isCurrentUser) 
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editProfile,
              tooltip: 'Редактировать профиль',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProfile,
            tooltip: 'Поделиться профилем',
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
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
                  ProfileHeaderWidget(user: user as dynamic, isCurrentUser: isCurrentUser),

                  const SizedBox(height: 16),

                  // Статистика профиля
                  ProfileStatsWidget(user: user as dynamic, isCurrentUser: isCurrentUser),

                  const SizedBox(height: 16),

                  // Действия профиля
                  ProfileActionsWidget(user: user as dynamic, isCurrentUser: isCurrentUser),

                  // Кнопка "Написать сообщение" для других пользователей
                  if (!isCurrentUser) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StartChatButton(
                        userId: widget.userId!,
                        userName: user.name,
                        userAvatar: user.avatarUrl,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Вкладки профиля
                  ProfileTabsWidget(user: user as dynamic, isCurrentUser: isCurrentUser),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingStateWidget(
          message: 'Загрузка профиля...',
        ),
        error: (error, stack) => ErrorStateWidget(
          error: error.toString(),
          onRetry: () {
            ref.invalidate(currentUserProvider);
          },
          title: 'Ошибка загрузки профиля',
        ),
      ),
    );
  }

  void _editProfile() {
    context.push('/profile/edit');
  }

  void _shareProfile() {
    // TODO: Реализовать шаринг профиля
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Функция шаринга будет добавлена позже')));
  }
}
