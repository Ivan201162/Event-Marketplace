import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/core/micro_animations.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/specialist_providers.dart';
import 'package:event_marketplace_app/models/specialist_enhanced.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Упрощенный главный экран
class HomeScreenSimple extends ConsumerWidget {
  const HomeScreenSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("HOME_LOADED");
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
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
                      GestureDetector(
                        onTap: () => context.go('/profile/${user.uid}'),
                        child: user.photoURL != null && user.photoURL!.isNotEmpty
                            ? CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(user.photoURL!),
                                onBackgroundImageError: (_, __) {},
                              )
                            : CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty 
                                  ? (user.name ?? 'Пользователь')
                                  : '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim(),
                              style: TextStyle(
                                fontSize: context.isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (user.username != null && user.username!.isNotEmpty) ...[
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
                              user.city != null && user.city!.isNotEmpty
                                  ? user.city!
                                  : 'Город не выбран',
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('Создать заявку'),
                        onPressed: () {
                          debugLog("CREATE_REQUEST_OPENED");
                          context.go('/requests/create');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('Найти специалиста'),
                        onPressed: () {
                          context.go('/search');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Статистика удалена - не требуется на главной

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

  Widget _buildTopSpecialistsSection({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required bool isRussia,
    String? userCity,
  }) {
    final specialistsAsync = isRussia
        ? ref.watch(topSpecialistsByRussiaProvider)
        : ref.watch(topSpecialistsByCityProvider(userCity ?? 'Москва'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: context.isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/search');
              },
              child: const Text('Смотреть все'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        specialistsAsync.when(
          data: (specialists) {
            if (specialists.isEmpty) {
              return AppComponents.emptyState(
                icon: Icons.star_outline,
                title: 'Пока нет специалистов',
                subtitle: 'Специалисты появятся здесь после регистрации',
              );
            }
            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: specialists.length,
                itemBuilder: (context, index) {
                  final specialist = specialists[index];
                  return _SpecialistCard(specialist: specialist);
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          error: (error, stack) => AppComponents.emptyState(
            icon: Icons.error_outline,
            title: 'Ошибка загрузки',
            subtitle: error.toString(),
          ),
        ),
      ],
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

class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({required this.specialist});
  final SpecialistEnhanced specialist;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.go('/specialist/${specialist.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: specialist.avatarUrl != null
                    ? Image.network(
                        specialist.avatarUrl!,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.person, size: 40),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 40),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                specialist.name ?? 'Специалист',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${specialist.rating ?? 0.0}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
