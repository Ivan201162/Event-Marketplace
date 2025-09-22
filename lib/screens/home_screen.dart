import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../core/constants/app_routes.dart';
import '../core/responsive_utils.dart';
import '../models/user.dart';
import '../providers/user_role_provider.dart';
import '../widgets/enhanced_page_transition.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/role_switcher.dart';
import '../widgets/theme_switch_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final roleString = userRole == UserRole.customer ? 'Клиент' : 'Специалист';

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, userRole, roleString),
      tablet: _buildTabletLayout(context, userRole, roleString),
      desktop: _buildDesktopLayout(context, userRole, roleString),
      largeDesktop: _buildLargeDesktopLayout(context, userRole, roleString),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    UserRole userRole,
    String roleString,
  ) =>
      Scaffold(
        body: CustomScrollView(
          slivers: [
            // Современный AppBar с градиентом
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Event Marketplace',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: BrandColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 40, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Event Marketplace',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const QuickThemeToggle(
                                  iconColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Уведомления пока не реализованы',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Основной контент
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Переключатель ролей
                  const RoleSwitcher(),

                  // Приветственная карточка с градиентом
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: BrandColors.secondaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.secondary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                userRole == UserRole.customer
                                    ? Icons.person_outline
                                    : Icons.work_outline,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Добро пожаловать!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Вы вошли как $roleString',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Быстрые действия
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Быстрые действия',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push(AppRoutes.search);
                          },
                          child: const Text('Все'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Сетка быстрых действий
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        AnimatedButton(
                          onPressed: () {
                            context.push(AppRoutes.search);
                          },
                          child: _buildModernQuickActionCard(
                            context,
                            icon: Icons.search_rounded,
                            title: 'Найти специалиста',
                            subtitle: 'Поиск по категориям',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                            onTap: () {
                              context.push(AppRoutes.search);
                            },
                          ),
                        ),
                        AnimatedButton(
                          onPressed: () {
                            context.push(AppRoutes.myBookings);
                          },
                          child: _buildModernQuickActionCard(
                            context,
                            icon: userRole == UserRole.customer
                                ? Icons.book_online_rounded
                                : Icons.assignment_rounded,
                            title: userRole == UserRole.customer
                                ? 'Мои заявки'
                                : 'Заявки клиентов',
                            subtitle: userRole == UserRole.customer
                                ? 'Просмотр заявок'
                                : 'Управление заявками',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            onTap: () {
                              context.push(AppRoutes.myBookings);
                            },
                          ),
                        ),
                        AnimatedButton(
                          onPressed: () {
                            context.push(AppRoutes.calendar);
                          },
                          child: _buildModernQuickActionCard(
                            context,
                            icon: Icons.calendar_today_rounded,
                            title: 'Календарь',
                            subtitle: 'Расписание событий',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            onTap: () {
                              context.push(AppRoutes.calendar);
                            },
                          ),
                        ),
                        AnimatedButton(
                          onPressed: () {
                            context.push(AppRoutes.chat);
                          },
                          child: _buildModernQuickActionCard(
                            context,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Сообщения',
                            subtitle: 'Общение с клиентами',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                            ),
                            onTap: () {
                              context.push(AppRoutes.chat);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Статистика
                  AnimatedContent(
                    delay: const Duration(milliseconds: 200),
                    type: AnimationType.slideUp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Статистика',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  AnimatedContent(
                    delay: const Duration(milliseconds: 400),
                    type: AnimationType.scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildModernStatItem(
                                context,
                                'Активных заявок',
                                '0',
                                Icons.assignment_rounded,
                                BrandColors.primary,
                              ),
                              _buildModernStatItem(
                                context,
                                'Завершенных',
                                '0',
                                Icons.check_circle_rounded,
                                BrandColors.secondary,
                              ),
                              _buildModernStatItem(
                                context,
                                'В ожидании',
                                '0',
                                Icons.schedule_rounded,
                                BrandColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Секция рекомендаций
                  const RecommendationsSection(),

                  const SizedBox(height: 100), // Отступ для нижней навигации
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTabletLayout(
    BuildContext context,
    UserRole userRole,
    String roleString,
  ) =>
      Scaffold(
        body: ResponsiveContainer(
          child: CustomScrollView(
            slivers: [
              // Адаптивный AppBar для планшета
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Event Marketplace',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: BrandColors.primaryGradient,
                    ),
                  ),
                ),
              ),
              // Основной контент для планшета
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Приветственная карточка
                    _buildWelcomeCard(context, userRole, roleString),
                    const SizedBox(height: 24),
                    // Быстрые действия в сетке 2x2
                    _buildQuickActionsGrid(context, userRole, 2),
                    const SizedBox(height: 32),
                    // Статистика
                    _buildStatsSection(context),
                    const SizedBox(height: 32),
                    // Секция рекомендаций
                    const RecommendationsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDesktopLayout(
    BuildContext context,
    UserRole userRole,
    String roleString,
  ) =>
      Scaffold(
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель с быстрыми действиями
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildWelcomeCard(context, userRole, roleString),
                    const SizedBox(height: 24),
                    _buildQuickActionsList(context, userRole),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Основной контент
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 160,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text(
                          'Event Marketplace',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: BrandColors.primaryGradient,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsSection(context),
                          const SizedBox(height: 32),
                          const RecommendationsSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout(
    BuildContext context,
    UserRole userRole,
    String roleString,
  ) =>
      Scaffold(
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель
              SizedBox(
                width: 350,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildWelcomeCard(context, userRole, roleString),
                    const SizedBox(height: 24),
                    _buildQuickActionsList(context, userRole),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Основной контент
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text(
                          'Event Marketplace',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: BrandColors.primaryGradient,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsSection(context),
                          const SizedBox(height: 32),
                          const RecommendationsSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Правая панель с дополнительной информацией
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildInfoPanel(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildWelcomeCard(
    BuildContext context,
    UserRole userRole,
    String roleString,
  ) =>
      ResponsiveCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                userRole == UserRole.customer
                    ? Icons.person_outline
                    : Icons.work_outline,
                size: 32,
                color: BrandColors.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Добро пожаловать!',
                    isTitle: true,
                  ),
                  const SizedBox(height: 4),
                  ResponsiveText(
                    'Вы вошли как $roleString',
                    isSubtitle: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActionsGrid(
    BuildContext context,
    UserRole userRole,
    int crossAxisCount,
  ) =>
      ResponsiveGrid(
        crossAxisCount: crossAxisCount,
        children: [
          _buildQuickActionCard(
            context,
            userRole,
            'Найти специалиста',
            'Поиск по категориям',
            Icons.search_rounded,
            const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
          ),
          _buildQuickActionCard(
            context,
            userRole,
            userRole == UserRole.customer ? 'Мои заявки' : 'Заявки клиентов',
            userRole == UserRole.customer
                ? 'Просмотр заявок'
                : 'Управление заявками',
            userRole == UserRole.customer
                ? Icons.book_online_rounded
                : Icons.assignment_rounded,
            const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          _buildQuickActionCard(
            context,
            userRole,
            'Календарь',
            'Расписание событий',
            Icons.calendar_today_rounded,
            const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
          ),
          _buildQuickActionCard(
            context,
            userRole,
            'Сообщения',
            'Общение с клиентами',
            Icons.chat_bubble_outline_rounded,
            const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
          ),
        ],
      );

  Widget _buildQuickActionsList(BuildContext context, UserRole userRole) =>
      ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Быстрые действия',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildQuickActionItem(
              context,
              userRole,
              'Найти специалиста',
              Icons.search_rounded,
              const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
            ),
            _buildQuickActionItem(
              context,
              userRole,
              userRole == UserRole.customer ? 'Мои заявки' : 'Заявки клиентов',
              userRole == UserRole.customer
                  ? Icons.book_online_rounded
                  : Icons.assignment_rounded,
              const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
            ),
            _buildQuickActionItem(
              context,
              userRole,
              'Календарь',
              Icons.calendar_today_rounded,
              const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
            ),
            _buildQuickActionItem(
              context,
              userRole,
              'Сообщения',
              Icons.chat_bubble_outline_rounded,
              const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActionItem(
    BuildContext context,
    UserRole userRole,
    String title,
    IconData icon,
    LinearGradient gradient,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedButton(
          onPressed: () {
            // Навигация в зависимости от типа действия
            switch (title) {
              case 'Найти специалиста':
                context.push(AppRoutes.search);
                break;
              case 'Мои заявки':
              case 'Заявки клиентов':
                context.push(AppRoutes.myBookings);
                break;
              case 'Календарь':
                context.push(AppRoutes.calendar);
                break;
              case 'Сообщения':
                context.push(AppRoutes.chat);
                break;
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title - функция в разработке')),
                );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: ResponsiveText(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildStatsSection(BuildContext context) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Статистика',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItemStub(
                  context,
                  'Активных заявок',
                  '0',
                  Icons.assignment_rounded,
                  BrandColors.primary,
                ),
                _buildStatItemStub(
                  context,
                  'Завершенных',
                  '0',
                  Icons.check_circle_rounded,
                  BrandColors.secondary,
                ),
                _buildStatItemStub(
                  context,
                  'В ожидании',
                  '0',
                  Icons.schedule_rounded,
                  BrandColors.accent,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildInfoPanel(BuildContext context) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Информация',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildInfoItem('Версия приложения', '1.0.0'),
            _buildInfoItem('Последнее обновление', 'Сегодня'),
            _buildInfoItem('Активных пользователей', '1,234'),
          ],
        ),
      );

  Widget _buildInfoItem(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(label, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  Widget _buildQuickActionCard(
    BuildContext context,
    UserRole userRole,
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
  ) =>
      AnimatedButton(
        onPressed: () {
          // Навигация в зависимости от типа действия
          switch (title) {
            case 'Найти специалиста':
              context.push(AppRoutes.search);
              break;
            case 'Мои заявки':
            case 'Заявки клиентов':
              context.push(AppRoutes.myBookings);
              break;
            case 'Календарь':
              context.push(AppRoutes.calendar);
              break;
            case 'Сообщения':
              context.push(AppRoutes.chat);
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title - функция в разработке')),
              );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ResponsiveText(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildModernQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) =>
      Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildModernStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildStatItemStub(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
