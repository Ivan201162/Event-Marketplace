import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/core/micro_animations.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/specialist_providers.dart';
import 'package:event_marketplace_app/models/specialist_enhanced.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Упрощенный главный экран
class HomeScreenSimple extends ConsumerWidget {
  const HomeScreenSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile/edit'),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Пользователь не авторизован'),
            );
          }

          return SingleChildScrollView(
            padding: context.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Приветствие
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (user.photoURL != null)
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(user.photoURL!),
                        )
                      else
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          child: Text(
                            user.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name ?? 'Пользователь',
                              style: TextStyle(
                                fontSize: context.isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (user.username != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '@${user.username}',
                                style: TextStyle(
                                  fontSize: context.isSmallScreen ? 14 : 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Найдите идеального специалиста для вашего мероприятия',
                              style: TextStyle(
                                fontSize: context.isSmallScreen ? 12 : 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Быстрые действия
                Text(
                  'Быстрые действия',
                  style: TextStyle(
                    fontSize: context.isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                AppComponents.animatedGrid(
                  crossAxisCount: 2,
                  children: [
                    _ActionCard(
                      icon: Icons.assignment_outlined,
                      title: 'Создать заявку',
                      subtitle: 'Найти специалиста',
                      onTap: () => context.go('/create-request'),
                    ),
                    _ActionCard(
                      icon: Icons.lightbulb_outline,
                      title: 'Поделиться идеей',
                      subtitle: 'Вдохновить других',
                      onTap: () => context.go('/create-idea'),
                    ),
                    _ActionCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Чаты',
                      subtitle: 'Общение с заказчиками',
                      onTap: () => context.go('/chats'),
                    ),
                    _ActionCard(
                      icon: Icons.monetization_on_outlined,
                      title: 'Монетизация',
                      subtitle: 'Зарабатывайте больше',
                      onTap: () => context.go('/monetization'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Статистика
                Text(
                  'Ваша статистика',
                  style: TextStyle(
                    fontSize: context.isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                AppComponents.animatedList(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Заявки',
                            value: '0',
                            icon: Icons.assignment,
                            subtitle: 'Активных заявок',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Идеи',
                            value: '0',
                            icon: Icons.lightbulb,
                            subtitle: 'Опубликованных идей',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ТОП специалисты по России
                _buildTopSpecialistsSection(
                  context: context,
                  ref: ref,
                  title: 'Лучшие специалисты недели (Россия)',
                  isRussia: true,
                ),

                const SizedBox(height: 24),

                // ТОП специалисты по городу
                _buildTopSpecialistsSection(
                  context: context,
                  ref: ref,
                  title: 'Лучшие специалисты по вашему городу',
                  isRussia: false,
                  userCity: user.city,
                ),
              ],
            ),
          );
        },
        loading: () => AppComponents.loadingIndicator(
          message: 'Загрузка данных...',
        ),
        error: (error, stack) => AppComponents.emptyState(
          icon: Icons.error_outline,
          title: 'Ошибка загрузки',
          subtitle: error.toString(),
          action: AppComponents.animatedButton(
            text: 'Попробовать снова',
            onPressed: () => context.go('/login'),
            icon: Icons.refresh,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MicroAnimations.hoverCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            MicroAnimations.fadeInText(
              text: title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            MicroAnimations.fadeInText(
              text: subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
  });
  final String title;
  final String value;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MicroAnimations.scaleCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            MicroAnimations.fadeInText(
              text: value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            MicroAnimations.fadeInText(
              text: title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            MicroAnimations.fadeInText(
              text: subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {

  const _RecommendationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MicroAnimations.hoverCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MicroAnimations.fadeInText(
                    text: title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  MicroAnimations.fadeInText(
                    text: subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
