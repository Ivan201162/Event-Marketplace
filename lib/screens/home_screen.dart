import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_role_provider.dart';
import '../widgets/role_switcher.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/enhanced_page_transition.dart';
import '../models/user.dart';
import '../core/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final roleString = userRole == UserRole.customer ? "Клиент" : "Специалист";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Современный AppBar с градиентом
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Event Marketplace",
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
                          "Event Marketplace",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Уведомления пока не реализованы")),
                              );
                            },
                          ),
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
                                  "Добро пожаловать!",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Вы вошли как $roleString",
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
                        "Быстрые действия",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Все"),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Поиск специалистов")),
                          );
                        },
                        child: _buildModernQuickActionCard(
                          context,
                          icon: Icons.search_rounded,
                          title: "Найти специалиста",
                          subtitle: "Поиск по категориям",
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          ),
                          onTap: () {},
                        ),
                      ),
                      AnimatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(userRole == UserRole.customer
                                    ? "Мои заявки"
                                    : "Заявки клиентов")),
                          );
                        },
                        child: _buildModernQuickActionCard(
                          context,
                          icon: userRole == UserRole.customer
                              ? Icons.book_online_rounded
                              : Icons.assignment_rounded,
                          title: userRole == UserRole.customer
                              ? "Мои заявки"
                              : "Заявки клиентов",
                          subtitle: userRole == UserRole.customer
                              ? "Просмотр заявок"
                              : "Управление заявками",
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          onTap: () {},
                        ),
                      ),
                      AnimatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Календарь событий")),
                          );
                        },
                        child: _buildModernQuickActionCard(
                          context,
                          icon: Icons.calendar_today_rounded,
                          title: "Календарь",
                          subtitle: "Расписание событий",
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          onTap: () {},
                        ),
                      ),
                      AnimatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Сообщения")),
                          );
                        },
                        child: _buildModernQuickActionCard(
                          context,
                          icon: Icons.chat_bubble_outline_rounded,
                          title: "Сообщения",
                          subtitle: "Общение с клиентами",
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          ),
                          onTap: () {},
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
                      "Статистика",
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
                                "Активных заявок",
                                "0",
                                Icons.assignment_rounded,
                                BrandColors.primary),
                            _buildModernStatItem(
                                context,
                                "Завершенных",
                                "0",
                                Icons.check_circle_rounded,
                                BrandColors.secondary),
                            _buildModernStatItem(context, "В ожидании", "0",
                                Icons.schedule_rounded, BrandColors.accent),
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
  }

  Widget _buildModernQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
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
  }

  Widget _buildModernStatItem(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Column(
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
  }
}
