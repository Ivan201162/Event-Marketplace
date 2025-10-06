import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advanced_search_filters.dart';
import '../models/city_region.dart';
import '../models/specialist.dart';
import '../providers/advanced_search_providers.dart';
import '../providers/city_region_providers.dart';

/// Виджет интеллектуальных рекомендаций
class SmartRecommendationsWidget extends ConsumerWidget {
  const SmartRecommendationsWidget({
    super.key,
    this.selectedCity,
    this.selectedRegion,
    this.onSpecialistSelected,
    this.onCategorySelected,
    this.onCitySelected,
  });

  final CityRegion? selectedCity;
  final String? selectedRegion;
  final void Function(Specialist)? onSpecialistSelected;
  final void Function(SpecialistCategory)? onCategorySelected;
  final void Function(CityRegion)? onCitySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Рекомендации для вас',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Контент рекомендаций
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Популярные специалисты в регионе
                _buildPopularSpecialists(context, ref),

                const SizedBox(height: 24),

                // Популярные категории
                _buildPopularCategories(context, ref),

                const SizedBox(height: 24),

                // Рекомендуемые города
                _buildRecommendedCities(context, ref),

                const SizedBox(height: 24),

                // Тренды
                _buildTrends(context, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSpecialists(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final recommendedState = ref.watch(
          recommendedSpecialistsProvider({
            'city': selectedCity,
            'region': selectedRegion,
            'limit': 5,
          }),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Популярные специалисты',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            recommendedState.when(
              data: (results) {
                if (results.isEmpty) {
                  return _buildEmptyRecommendations(
                    context,
                    'Специалисты не найдены',
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return _buildSpecialistRecommendationCard(
                        context,
                        result,
                      );
                    },
                  ),
                );
              },
              loading: () => _buildLoadingCard(context),
              error: (error, stack) =>
                  _buildErrorCard(context, error.toString()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopularCategories(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final categoriesState = ref.watch(
          popularCategoriesProvider({
            'city': selectedCity,
            'region': selectedRegion,
            'limit': 8,
          }),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Популярные категории',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            categoriesState.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return _buildEmptyRecommendations(
                    context,
                    'Категории не найдены',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map<Widget>(
                          (category) => _buildCategoryChip(
                            context,
                            category! as SpecialistCategory,
                          ),
                        )
                        .toList(),
                  ),
                );
              },
              loading: () => _buildLoadingCard(context),
              error: (error, stack) =>
                  _buildErrorCard(context, error.toString()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedCities(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final popularCitiesState = ref.watch(popularCitiesProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Популярные города',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            popularCitiesState.when(
              data: (cities) {
                if (cities.isEmpty) {
                  return _buildEmptyRecommendations(
                    context,
                    'Города не найдены',
                  );
                }

                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      return _buildCityRecommendationCard(context, city);
                    },
                  ),
                );
              },
              loading: () => _buildLoadingCard(context),
              error: (error, stack) =>
                  _buildErrorCard(context, error.toString()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrends(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        final trendsState = ref.watch(searchTrendsProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Тренды поиска',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            trendsState.when(
              data: (trends) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildTrendSection(
                      context,
                      'Популярные запросы',
                      trends['popularQueries'] as List<dynamic>,
                    ),
                    const SizedBox(height: 16),
                    _buildTrendSection(
                      context,
                      'Трендовые услуги',
                      trends['trendingServices'] as List<dynamic>,
                    ),
                  ],
                ),
              ),
              loading: () => _buildLoadingCard(context),
              error: (error, stack) =>
                  _buildErrorCard(context, error.toString()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpecialistRecommendationCard(
    BuildContext context,
    AdvancedSearchResult result,
  ) {
    final specialist = result.specialist;
    final theme = Theme.of(context);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => onSpecialistSelected?.call(specialist),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Аватар
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: specialist.avatarUrl != null
                      ? NetworkImage(specialist.avatarUrl!)
                      : null,
                  child: specialist.avatarUrl == null
                      ? Text(
                          specialist.name.isNotEmpty
                              ? specialist.name[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.primaryColor,
                          ),
                        )
                      : null,
                ),

                const SizedBox(height: 8),

                // Имя
                Text(
                  specialist.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Категория
                Text(
                  specialist.categoryDisplayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Рейтинг и цена
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      specialist.rating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      '${specialist.price.toInt()} ₽',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
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

  Widget _buildCategoryChip(BuildContext context, SpecialistCategory category) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onCategorySelected?.call(category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${category.icon} ${category.displayName}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCityRecommendationCard(BuildContext context, CityRegion city) {
    final theme = Theme.of(context);

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => onCitySelected?.call(city),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка города
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      city.citySize.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Название города
                Text(
                  city.cityName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Население
                Text(
                  '${_formatPopulation(city.population)} жителей',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                // Количество специалистов
                if (city.totalSpecialists > 0)
                  Text(
                    '${city.totalSpecialists} специалистов',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendSection(
    BuildContext context,
    String title,
    List<dynamic> items,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items
              .take(5)
              .map(
                (item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.toString(),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) => Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _buildErrorCard(BuildContext context, String error) => Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            'Ошибка: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );

  Widget _buildEmptyRecommendations(BuildContext context, String message) =>
      Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

  String _formatPopulation(int population) {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}М';
    } else if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(0)}К';
    } else {
      return population.toString();
    }
  }
}
