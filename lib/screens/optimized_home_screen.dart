import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../models/specialist.dart';
import '../models/category.dart';
import '../providers/auth_providers.dart';
import '../providers/optimized_data_providers.dart';
import '../widgets/optimized_category_grid.dart';
import '../widgets/optimized_specialists_carousel.dart';
import '../widgets/optimized_search_section.dart';

/// Оптимизированная главная страница с реальными данными из Firestore
class OptimizedHomeScreen extends ConsumerStatefulWidget {
  const OptimizedHomeScreen({super.key});

  @override
  ConsumerState<OptimizedHomeScreen> createState() => _OptimizedHomeScreenState();
}

class _OptimizedHomeScreenState extends ConsumerState<OptimizedHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: _buildHomeContent,
      loading: _buildLoadingState,
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildHomeContent(AppUser? user) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserProfileCard(user),
        const SizedBox(height: 16),
        const OptimizedSearchSection(),
        const SizedBox(height: 20),
        _buildPopularSpecialistsSection(
          title: 'Топ-10 недели по России',
          isCountryWide: true,
        ),
        const SizedBox(height: 20),
        _buildPopularSpecialistsSection(
          title: 'Топ-10 недели по городу ${user?.city ?? ''}',
          isCountryWide: false,
          city: user?.city,
        ),
        const SizedBox(height: 20),
        _buildCategoriesSection(),
        const SizedBox(height: 20),
        _buildQuickActionsSection(),
      ],
    ),
  );

  Widget _buildUserProfileCard(AppUser? user) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor,
          Theme.of(context).primaryColor.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundImage: user?.photoURL != null 
              ? NetworkImage(user!.photoURL!) 
              : null,
          child: user?.photoURL == null 
              ? const Icon(Icons.person, size: 30, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Добро пожаловать!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.displayName ?? 'Пользователь',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user?.city != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      user!.city!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _buildPopularSpecialistsSection({
    required String title,
    required bool isCountryWide,
    String? city,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        OptimizedSpecialistsCarousel(
          isCountryWide: isCountryWide,
          city: city,
        ),
      ],
    ),
  );

  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Популярные категории',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const OptimizedCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Создать заявку',
                icon: Icons.add_circle_outline,
                color: Colors.blue,
                onTap: () => context.push('/create-request'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Мои заявки',
                icon: Icons.assignment,
                color: Colors.green,
                onTap: () => context.push('/requests'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Идеи',
                icon: Icons.lightbulb_outline,
                color: Colors.orange,
                onTap: () => context.push('/ideas'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Чаты',
                icon: Icons.chat,
                color: Colors.purple,
                onTap: () => context.push('/chats'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildLoadingState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Загрузка данных...'),
      ],
    ),
  );

  Widget _buildErrorState(String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Ошибка загрузки',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(context).textTheme.bodyMedium,
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
  );
}
