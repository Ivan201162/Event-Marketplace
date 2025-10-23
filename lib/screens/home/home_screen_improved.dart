import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/real_specialists_providers.dart';
import '../../providers/real_categories_providers.dart';
import '../../providers/notification_providers.dart';
import '../../core/feature_flags.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../../services/user_cache_service.dart';
import '../../widgets/animated_skeleton.dart';

/// Улучшенный главный экран с shimmer-анимацией
class HomeScreenImproved extends ConsumerStatefulWidget {
  const HomeScreenImproved({super.key});

  @override
  ConsumerState<HomeScreenImproved> createState() => _HomeScreenImprovedState();
}

class _HomeScreenImprovedState extends ConsumerState<HomeScreenImproved>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Аватар пользователя
                    GestureDetector(
                      onTap: () {
                        final userData = user.value;
                        final uid = userData?.uid ?? 'me';
                        context.go('/profile/$uid');
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user.when(
                            data: (userData) => userData?.avatarUrl != null
                                ? Hero(
                                    tag: 'avatar-${userData!.uid}',
                                    child: Image.network(
                                      userData.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 30,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                            loading: () => const ShimmerBox(
                              width: 50,
                              height: 50,
                              borderRadius: 25,
                            ),
                            error: (_, __) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Приветствие
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          user.when(
                            data: (userData) => Text(
                              userData != null 
                                  ? '${_getGreetingByTime()}, ${_getUserDisplayName(userData)}!'
                                  : '${_getGreetingByTime()}!',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            loading: () => const Text(
                              'Добро пожаловать!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            error: (_, __) => const Text(
                              'Добро пожаловать!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          user.when(
                            data: (userData) => Text(
                              userData?.name ?? 'Пользователь',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const ShimmerBox(
                              width: 150,
                              height: 20,
                              borderRadius: 10,
                            ),
                            error: (_, __) => const Text(
                              'Пользователь',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Уведомления с индикатором
                    _buildNotificationsButton(),
                  ],
                ),
              ),
              
              // Основной контент
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Быстрые действия
                        const Text(
                          'Быстрые действия',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.add_circle_outline,
                                title: 'Создать заявку',
                                subtitle: 'Найти специалиста',
                                color: const Color(0xFF1E3A8A),
                                onTap: () {
                                  context.go('/create-request');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.lightbulb_outline,
                                title: 'Поделиться идеей',
                                subtitle: 'Вдохновить других',
                                color: const Color(0xFF10B981),
                                onTap: () {
                                  context.go('/create-idea');
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Статистика
                        const Text(
                          'Ваша статистика',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Заявки',
                                value: '12',
                                subtitle: 'Активных',
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Идеи',
                                value: '8',
                                subtitle: 'Опубликовано',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Чаты',
                                value: '5',
                                subtitle: 'Новых',
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Последние активности
                        const Text(
                          'Последние активности',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Placeholder для последних активностей
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.timeline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Пока нет активностей',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ваши действия будут отображаться здесь',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Получить приветствие в зависимости от времени суток
  String _getGreetingByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Доброе утро';
    } else if (hour >= 12 && hour < 17) {
      return 'Добрый день';
    } else if (hour >= 17 && hour < 22) {
      return 'Добрый вечер';
    } else {
      return 'Доброй ночи';
    }
  }

  /// Получить отображаемое имя пользователя с fallback
  String _getUserDisplayName(dynamic userData) {
    // Приоритет: displayName -> name -> email (до @) -> "Пользователь"
    if (userData.displayName != null && userData.displayName!.isNotEmpty) {
      return userData.displayName!;
    }
    if (userData.name != null && userData.name!.isNotEmpty) {
      return userData.name!;
    }
    if (userData.email != null && userData.email!.isNotEmpty) {
      final email = userData.email!;
      final atIndex = email.indexOf('@');
      if (atIndex > 0) {
        return email.substring(0, atIndex);
      }
    }
    return 'Пользователь';
  }

  /// Кнопка уведомлений с индикатором непрочитанных
  Widget _buildNotificationsButton() {
    final user = ref.watch(authStateProvider);
    
    return user.when(
      data: (userData) {
        if (userData == null) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => context.go('/notifications'),
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        }
        
        return Consumer(
          builder: (context, ref, child) {
            final unreadCountAsync = ref.watch(
              NotificationProviders.unreadCountProvider(userData.uid)
            );
            
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => context.go('/notifications'),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                unreadCountAsync.when(
                  data: (count) {
                    if (count > 0) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const IconButton(
          onPressed: null,
          icon: Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      error: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Shimmer эффект для загрузки
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Карточка быстрого действия
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка статистики
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Получить приветствие в зависимости от времени суток
  String _getGreetingByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Доброе утро';
    } else if (hour >= 12 && hour < 17) {
      return 'Добрый день';
    } else if (hour >= 17 && hour < 22) {
      return 'Добрый вечер';
    } else {
      return 'Доброй ночи';
    }
  }

  /// Получить отображаемое имя пользователя с fallback
  String _getUserDisplayName(dynamic userData) {
    // Приоритет: displayName -> name -> email (до @) -> "Пользователь"
    if (userData.displayName != null && userData.displayName!.isNotEmpty) {
      return userData.displayName!;
    }
    if (userData.name != null && userData.name!.isNotEmpty) {
      return userData.name!;
    }
    if (userData.email != null && userData.email!.isNotEmpty) {
      final email = userData.email!;
      final atIndex = email.indexOf('@');
      if (atIndex > 0) {
        return email.substring(0, atIndex);
      }
    }
    return 'Пользователь';
  }
}
