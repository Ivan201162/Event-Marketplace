import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_role_provider.dart';
import '../widgets/role_switcher.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final roleString = userRole == UserRole.customer ? "Клиент" : "Специалист";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Marketplace"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Уведомления пока не реализованы")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Переключатель ролей
            const RoleSwitcher(),
            
            // Приветствие
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            userRole == UserRole.customer ? Icons.person : Icons.work,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Добро пожаловать!",
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  "Вы вошли как $roleString",
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Быстрые действия
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Быстрые действия",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickActionCard(
                    context,
                    icon: Icons.search,
                    title: "Найти специалиста",
                    subtitle: "Поиск по категориям",
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Переход на экран поиска
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Поиск специалистов")),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: userRole == UserRole.customer ? Icons.book_online : Icons.assignment,
                    title: userRole == UserRole.customer ? "Мои заявки" : "Заявки клиентов",
                    subtitle: userRole == UserRole.customer ? "Просмотр заявок" : "Управление заявками",
                    color: Colors.green,
                    onTap: () {
                      // TODO: Переход на экран заявок
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(userRole == UserRole.customer ? "Мои заявки" : "Заявки клиентов")),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.calendar_today,
                    title: "Календарь",
                    subtitle: "Расписание событий",
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Переход на календарь
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Календарь событий")),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.chat,
                    title: "Сообщения",
                    subtitle: "Общение с клиентами",
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Переход в чаты
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Сообщения")),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Статистика
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Статистика",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(context, "Активных заявок", "0", Icons.assignment),
                          _buildStatItem(context, "Завершенных", "0", Icons.check_circle),
                          _buildStatItem(context, "В ожидании", "0", Icons.schedule),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
