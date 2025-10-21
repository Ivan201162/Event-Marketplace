import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advanced_search_filters.dart';
import '../models/common_types.dart';
import '../models/specialist.dart';
import '../providers/advanced_search_providers.dart';

/// Виджет результатов поиска специалистов
class SpecialistSearchResultsWidget extends ConsumerStatefulWidget {
  const SpecialistSearchResultsWidget({
    super.key,
    required this.filters,
    this.onSpecialistSelected,
    this.onFiltersChanged,
  });

  final AdvancedSearchFilters filters;
  final void Function(Specialist)? onSpecialistSelected;
  final void Function(AdvancedSearchFilters)? onFiltersChanged;

  @override
  ConsumerState<SpecialistSearchResultsWidget> createState() =>
      _SpecialistSearchResultsWidgetState();
}

class _SpecialistSearchResultsWidgetState extends ConsumerState<SpecialistSearchResultsWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Запускаем поиск при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(advancedSearchProvider.notifier).searchSpecialists(widget.filters);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SpecialistSearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Запускаем новый поиск при изменении фильтров
    if (oldWidget.filters != widget.filters) {
      ref.read(advancedSearchProvider.notifier).searchSpecialists(widget.filters);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_isLoadingMore) {
      setState(() => _isLoadingMore = true);
      ref.read<AdvancedSearchNotifier>(advancedSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(advancedSearchProvider);

    return Column(
      children: [
        // Статистика поиска
        _buildSearchStats(searchState),

        // Результаты поиска
        Expanded(
          child: searchState.when(
            data: _buildResults,
            loading: _buildLoadingState,
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchStats(AsyncValue<AdvancedSearchState> searchState) => searchState.when(
        data: (state) {
          if (state.results.isEmpty && !state.isLoading) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Найдено ${state.totalCount} специалистов',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const Spacer(),
                if (state.searchTime > 0)
                  Text(
                    'за ${state.searchTime}мс',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (error, stack) => const SizedBox.shrink(),
      );

  Widget _buildResults(AdvancedSearchState state) {
    if (state.results.isEmpty && !state.isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read<AdvancedSearchNotifier>(advancedSearchProvider.notifier)
            .searchSpecialists(widget.filters);
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.results.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.results.length) {
            return _buildLoadMoreIndicator();
          }

          final result = state.results[index];
          return _buildSpecialistCard(result);
        },
      ),
    );
  }

  Widget _buildSpecialistCard(AdvancedSearchResult result) {
    final specialist = result.specialist;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => widget.onSpecialistSelected?.call(specialist),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок карточки
              Row(
                children: [
                  // Аватар
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage:
                        specialist.avatarUrl != null ? NetworkImage(specialist.avatarUrl!) : null,
                    child: specialist.avatarUrl == null
                        ? Text(
                            specialist.name.isNotEmpty ? specialist.name[0].toUpperCase() : '?',
                            style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // Информация о специалисте
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialist.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialist.category?.displayName ?? 'Категория',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (result.locationDisplay.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  result.locationDisplay,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Рейтинг и статус
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            specialist.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${specialist.reviewCount} отзывов',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (specialist.isVerified) ...[
                        const SizedBox(height: 4),
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Описание
              if (specialist.description != null && specialist.description!.isNotEmpty) ...[
                Text(
                  specialist.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Категории и услуги
              if (specialist.categories != null && specialist.categories!.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (specialist.categories ?? [])
                      .take(3)
                      .map(
                        (category) => Chip(
                          label: Text(category, style: theme.textTheme.bodySmall),
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Цена и опыт
              Row(
                children: [
                  // Цена
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Цена',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(specialist.price ?? 0).toInt()} ₽',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Опыт
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Опыт',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${specialist.yearsOfExperience} лет',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Расстояние (если есть)
                  if (result.distance != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Расстояние',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            result.distanceDisplay,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Балл релевантности (для отладки)
              if (result.relevanceScore > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: result.relevanceScore,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Релевантность: ${(result.relevanceScore * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Поиск специалистов...')
          ],
        ),
      );

  Widget _buildErrorState(Object error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Ошибка поиска', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read<AdvancedSearchNotifier>(advancedSearchProvider.notifier)
                    .searchSpecialists(widget.filters);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Специалисты не найдены', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged?.call(const AdvancedSearchFilters());
              },
              child: const Text('Сбросить фильтры'),
            ),
          ],
        ),
      );
}
