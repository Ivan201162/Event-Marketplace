import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/core/micro_animations.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/specialist_providers.dart';
import 'package:event_marketplace_app/models/specialist_enhanced.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/providers/city_specialists_paged_provider.dart';
import 'package:event_marketplace_app/widgets/user_name_display.dart';
import 'package:event_marketplace_app/screens/home/city_specialists_list_widget.dart';
import 'package:event_marketplace_app/constants/specialist_roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Упрощенный главный экран
class HomeScreenSimple extends ConsumerWidget {
  const HomeScreenSimple({super.key});

  Future<List<Map<String, dynamic>>> _getUserRoles(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final roles = (data['roles'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return roles;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("HOME_LOADED");
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Выход'),
              content: const Text('Вы действительно хотите выйти из приложения?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Выход'),
                ),
              ],
            ),
          );
          if (shouldExit == true && context.mounted) {
            // Закрываем приложение
          }
        }
      },
      child: Scaffold(
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

          return RefreshIndicator(
            onRefresh: () async {
              try {
                ref.invalidate(topSpecialistsByRussiaProvider);
                ref.invalidate(topSpecialistsByCityProvider(user.city ?? 'Москва'));
                await Future.delayed(const Duration(milliseconds: 500));
                debugLog("REFRESH_OK:home");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Обновлено'), duration: Duration(seconds: 1)),
                  );
                }
              } catch (e) {
                debugLog("REFRESH_ERR:home:$e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка обновления: $e')),
                  );
                }
              }
            },
            child: SingleChildScrollView(
            padding: context.screenPadding,
              physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Приветствие
                Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      debugLog("HOME_BANNER_RENDERED");
                    });
                    return GestureDetector(
                      onTap: () => context.push('/profile/me'),
                      child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                        user.photoURL != null && user.photoURL!.isNotEmpty
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty 
                                    ? (user.email ?? user.name ?? 'Пользователь')
                                    : '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim(),
                              style: TextStyle(
                                fontSize: context.isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            // Роли специалиста
                            if (user.isSpecialist == true) ...[
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: _getUserRoles(user.uid),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                    final roles = snapshot.data!;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                                      child: Wrap(
                                        spacing: 8,
                                        children: roles.map((role) {
                                          final roleId = role['id'] as String? ?? '';
                                          final roleLabel = role['label'] as String? ?? '';
                                          return Text(
                                            '${SpecialistRoles.getIcon(roleId)} $roleLabel',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                                user.city != null && user.city!.isNotEmpty
                                    ? user.city!
                                    : 'Город не указан',
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
                    );
                  },
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
                          debugLog("REQUEST_CREATE_OPENED");
                          context.push('/requests/create');
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
                          context.push('/search');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Карусель "Лучшие специалисты недели — Россия"
                _buildTopSpecialistsSection(
                  context: context,
                  ref: ref,
                  title: 'Лучшие специалисты недели — Россия',
                  isRussia: true,
                ),

                const SizedBox(height: 24),

                // Карусель "Лучшие специалисты недели — {город}"
                if (user.city != null && user.city!.isNotEmpty)
                _buildTopSpecialistsSection(
                  context: context,
                  ref: ref,
                    title: 'Лучшие специалисты недели — ${user.city}',
                  isRussia: false,
                  userCity: user.city,
                ),

              ],
            ),
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
      ),
    );
  }

  Widget _buildNoCityCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Город не указан',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Укажите город в профиле, чтобы видеть специалистов вашего города',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_location),
              label: const Text('Указать'),
              onPressed: () => context.push('/profile/edit#city'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySpecialistsSection(BuildContext context, WidgetRef ref, String city) {
    return CitySpecialistsList(city: city);
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
                context.push('/search');
              },
              child: const Text('Смотреть все'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        specialistsAsync.when(
          data: (specialists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isRussia) {
                debugLog("HOME_TOP_RU_COUNT:${specialists.length}");
              } else {
                debugLog("HOME_TOP_CITY_COUNT:${specialists.length}");
              }
            });
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

class _ModernSpecialistCard extends StatelessWidget {
  const _ModernSpecialistCard({
    required this.specialist,
    required this.onTap,
    super.key,
  });
  final SpecialistEnhanced specialist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: specialist.avatarUrl != null
                    ? NetworkImage(specialist.avatarUrl!)
                    : null,
                child: specialist.avatarUrl == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specialist.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (specialist.categories.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: specialist.categories.take(2).map((cat) {
                          return Chip(
                            label: Text(
                              cat,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${specialist.reviews.length} отзывов)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (specialist.bio != null && specialist.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        specialist.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
          context.push('/profile/${specialist.id}');
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
                specialist.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (specialist.categories.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  specialist.categories.first,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    specialist.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                specialist.city,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (specialist.minPrice > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'от ${specialist.minPrice.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
