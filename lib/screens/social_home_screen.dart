import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/animated_profile_banner.dart';
import '../widgets/weekly_leaders_widget.dart';
import '../widgets/filters_dialog.dart';
import '../services/supabase_service.dart';
import '../models/social_models.dart';

class SocialHomeScreen extends ConsumerStatefulWidget {
  const SocialHomeScreen({super.key});

  @override
  ConsumerState<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends ConsumerState<SocialHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  Profile? _currentProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final profile = await SupabaseService.getProfile(currentUser.id);
        setState(() {
          _currentProfile = profile;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCurrentProfile,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Анимированная плашка профиля
          SliverToBoxAdapter(
            child: AnimatedProfileBanner(
              scrollController: _scrollController,
              profile: _currentProfile,
            ),
          ),

          // Поисковая строка
          SliverToBoxAdapter(
            child: _buildSearchSection(),
          ),

          // Лучшие специалисты недели
          SliverToBoxAdapter(
            child: WeeklyLeadersWidget(
              userCity: _currentProfile?.city,
            ),
          ),

          // Категории
          SliverToBoxAdapter(
            child: _buildCategoriesSection(),
          ),

          // Дополнительный контент
          SliverToBoxAdapter(
            child: _buildAdditionalContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Найти специалиста',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск по имени, навыкам или городу...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      // Открыть фильтры
                      _showFiltersDialog();
                    },
                    icon: const Icon(Icons.tune),
                    tooltip: 'Фильтры',
                  ),
                  IconButton(
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        context.push('/search?q=${Uri.encodeComponent(_searchController.text)}');
                      }
                    },
                    icon: const Icon(Icons.search),
                    tooltip: 'Поиск',
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onSubmitted: (query) {
              if (query.isNotEmpty) {
                context.push('/search?q=${Uri.encodeComponent(query)}');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Свадьбы', 'icon': '💒', 'color': Colors.pink},
      {'name': 'Корпоративы', 'icon': '🏢', 'color': Colors.blue},
      {'name': 'Дни рождения', 'icon': '🎂', 'color': Colors.orange},
      {'name': 'Детские праздники', 'icon': '🎈', 'color': Colors.purple},
      {'name': 'Фотографы', 'icon': '📸', 'color': Colors.indigo},
      {'name': 'Видеографы', 'icon': '🎬', 'color': Colors.red},
      {'name': 'DJ', 'icon': '🎵', 'color': Colors.purple},
      {'name': 'Ведущие', 'icon': '🎤', 'color': Colors.teal},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    context.push('/search?category=${Uri.encodeComponent(category['name'] as String)}');
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (category['color'] as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category['icon'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: (category['color'] as Color),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAdditionalContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Рекомендации',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _RecommendationCard(
            title: 'Специалисты рядом с вами',
            subtitle: 'Найдите лучших специалистов в вашем городе',
            icon: Icons.location_on,
            color: Colors.blue,
            onTap: () => context.push('/search?nearby=true'),
          ),
          const SizedBox(height: 12),
          _RecommendationCard(
            title: 'Новые специалисты',
            subtitle: 'Познакомьтесь с новыми талантами',
            icon: Icons.person_add,
            color: Colors.green,
            onTap: () => context.push('/search?sort=newest'),
          ),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => FiltersDialog(
        onApplyFilters: (filters) {
          // Применяем фильтры к поиску
          final queryParams = <String, String>{};
          
          if (filters['city'] != null) {
            queryParams['city'] = filters['city'];
          }
          if (filters['category'] != null) {
            queryParams['category'] = filters['category'];
          }
          if (filters['minRating'] != null) {
            queryParams['minRating'] = filters['minRating'].toString();
          }
          if (filters['maxRating'] != null) {
            queryParams['maxRating'] = filters['maxRating'].toString();
          }
          if (filters['specialistType'] != null) {
            queryParams['specialistType'] = filters['specialistType'];
          }
          if (filters['minPrice'] != null) {
            queryParams['minPrice'] = filters['minPrice'].toString();
          }
          if (filters['maxPrice'] != null) {
            queryParams['maxPrice'] = filters['maxPrice'].toString();
          }
          
          // Переходим к экрану поиска с фильтрами
          final queryString = queryParams.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&');
          
          context.push('/search?$queryString');
        },
      ),
    );
  }
}


class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}
