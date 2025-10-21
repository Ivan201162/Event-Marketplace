import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
import '../providers/hosts_providers.dart';
import '../widgets/host_card.dart';
import '../widgets/host_filters_widget.dart';

/// Экран со списком всех ведущих
class AllHostsScreen extends ConsumerStatefulWidget {
  const AllHostsScreen({super.key});

  @override
  ConsumerState<AllHostsScreen> createState() => _AllHostsScreenState();
}

class _AllHostsScreenState extends ConsumerState<AllHostsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Загружаем больше данных при приближении к концу списка
      ref.read(mockPaginatedHostsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final hostsAsync = ref.watch(mockPaginatedHostsProvider);
    final filters = ref.watch(hostFiltersProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Все ведущие'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Кнопка переключения фильтров
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: filters.hasActiveFilters ? theme.primaryColor : null,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Фильтры',
          ),
          // Кнопка сброса фильтров
          if (filters.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                ref.read(hostFiltersProvider.notifier).state = const HostFilters();
                ref.read(mockPaginatedHostsProvider.notifier).clearFilters();
              },
              tooltip: 'Сбросить фильтры',
            ),
        ],
      ),
      body: Column(
        children: [
          // Панель фильтров
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: HostFiltersWidget(
                onFiltersChanged: (newFilters) {
                  ref.read(hostFiltersProvider.notifier).state = newFilters;
                  ref.read(mockPaginatedHostsProvider.notifier).applyFilters(newFilters);
                },
              ),
            ),

          // Список ведущих
          Expanded(
            child: hostsAsync.when(
              data: (hosts) {
                if (hosts.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(mockPaginatedHostsProvider.notifier).loadHosts(refresh: true);
                  },
                  child: _buildHostsList(hosts, isMobile),
                );
              },
              loading: _buildLoadingState,
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Ведущие не найдены',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить фильтры поиска',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(hostFiltersProvider.notifier).state = const HostFilters();
              ref.read(mockPaginatedHostsProvider.notifier).clearFilters();
            },
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor)),
          const SizedBox(height: 16),
          Text(
            'Загрузка ведущих...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(mockPaginatedHostsProvider.notifier).loadHosts(refresh: true);
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildHostsList(List<Specialist> hosts, bool isMobile) {
    final theme = Theme.of(context);
    final crossAxisCount = isMobile ? 2 : 4;
    final childAspectRatio = isMobile ? 0.75 : 0.8;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: hosts.length,
      itemBuilder: (context, index) {
        final host = hosts[index];
        return HostCard(
          specialist: host,
          onTap: () {
            // Переход к профилю специалиста
            context.go('/specialist/${host.id}');
          },
        );
      },
    );
  }
}
