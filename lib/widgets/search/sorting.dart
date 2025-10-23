import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/specialist_sorting.dart' as sorting_utils;
import '../../providers/search_providers.dart';

class SearchSortingWidget extends ConsumerStatefulWidget {
  const SearchSortingWidget(
      {super.key, this.onSortingChanged, this.showTitle = true});
  final VoidCallback? onSortingChanged;
  final bool showTitle;

  @override
  ConsumerState<SearchSortingWidget> createState() =>
      _SearchSortingWidgetState();
}

class _SearchSortingWidgetState extends ConsumerState<SearchSortingWidget> {
  late sorting_utils.SpecialistSorting _currentSorting;

  @override
  void initState() {
    super.initState();
    _currentSorting = ref.read(searchSortingProvider);
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.showTitle)
              const ListTile(
                  leading: Icon(Icons.sort), title: Text('Сортировка')),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSortingOptions(),
                  const SizedBox(height: 16),
                  _buildActionButtons()
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSortingOptions() {
    final sortOptions = ref.watch(sortOptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Сортировать по:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...sortOptions.map(_buildSortOption),
      ],
    );
  }

  Widget _buildSortOption(sorting_utils.SpecialistSortOption option) {
    // final isSelected = _currentSorting.sortOption == option; // Unused variable

    return RadioListTile<sorting_utils.SpecialistSortOption>(
      title: Text(option.label),
      subtitle: Text(
        option.description,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      value: option,
      // groupValue: _currentSorting.sortOption,
      // onChanged: (value) {
      //   if (value != null) {
      //     setState(() {
      //       _currentSorting = _currentSorting.copyWith(sortOption: value);
      //     });
      //   }
      // },
      dense: true,
    );
  }

  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearSorting,
              icon: const Icon(Icons.clear),
              label: const Text('Сбросить'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _applySorting,
              icon: const Icon(Icons.sort),
              label: const Text('Применить'),
            ),
          ),
        ],
      );

  void _applySorting() {
    ref.read(searchSortingProvider.notifier).updateSorting(_currentSorting);
    widget.onSortingChanged?.call();
  }

  void _clearSorting() {
    setState(() {
      _currentSorting = const sorting_utils.SpecialistSorting();
    });
    ref.read(searchSortingProvider.notifier).updateSorting(_currentSorting);
    widget.onSortingChanged?.call();
  }
}

/// Виджет для быстрого выбора сортировки
class QuickSortingWidget extends ConsumerWidget {
  const QuickSortingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularOptions = ref.watch(popularSortOptionsProvider);
    final currentSorting = ref.watch(searchSortingProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Быстрая сортировка:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularOptions.map<Widget>((option) {
              final isSelected = currentSorting.sortOption == option;
              return FilterChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(searchSortingProvider.notifier).updateSorting(
                        sorting_utils.SpecialistSorting(sortOption: option));
                  } else {
                    ref
                        .read(searchSortingProvider.notifier)
                        .updateSorting(const sorting_utils.SpecialistSorting());
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения текущей сортировки
class CurrentSortingWidget extends ConsumerWidget {
  const CurrentSortingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSorting = ref.watch(searchSortingProvider);

    if (!currentSorting.isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.sort, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Сортировка: ${currentSorting.displayName}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              ref
                  .read(searchSortingProvider.notifier)
                  .updateSorting(const sorting_utils.SpecialistSorting());
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

/// Виджет для выбора сортировки в диалоге
class SortingDialog extends ConsumerStatefulWidget {
  const SortingDialog({super.key});

  @override
  ConsumerState<SortingDialog> createState() => _SortingDialogState();
}

class _SortingDialogState extends ConsumerState<SortingDialog> {
  late sorting_utils.SpecialistSorting _selectedSorting;

  @override
  void initState() {
    super.initState();
    _selectedSorting = ref.read(searchSortingProvider);
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = ref.watch(sortOptionsProvider);

    return AlertDialog(
      title: const Text('Сортировка'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: sortOptions.length,
          itemBuilder: (context, index) {
            final option = sortOptions[index];
            // final isSelected = _selectedSorting.sortOption == option;

            return RadioListTile<sorting_utils.SpecialistSortOption>(
              title: Text(option.label),
              subtitle: Text(
                option.description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: option,
              // groupValue: _selectedSorting.sortOption,
              // onChanged: (value) {
              //   if (value != null) {
              //     setState(() {
              //       _selectedSorting = _selectedSorting.copyWith(sortOption: value);
              //     });
              //   }
              // },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedSorting = const sorting_utils.SpecialistSorting();
            });
          },
          child: const Text('Сбросить'),
        ),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () {
            ref
                .read(searchSortingProvider.notifier)
                .updateSorting(_selectedSorting);
            Navigator.of(context).pop();
          },
          child: const Text('Применить'),
        ),
      ],
    );
  }
}

/// Виджет для отображения статистики сортировки
class SortingStatsWidget extends ConsumerWidget {
  const SortingStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchStats = ref.watch(searchStatsProvider);
    final currentSorting = ref.watch(searchSortingProvider);

    if (!currentSorting.isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Статистика сортировки',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Найдено',
                    '${searchStats['totalCount'] ?? 0}', Icons.search),
              ),
              Expanded(
                child: _buildStatItem(
                  'Средняя цена',
                  '${(searchStats['averagePrice'] ?? 0).toInt()}₽',
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Средний рейтинг',
                  (searchStats['averageRating'] ?? 0.0).toStringAsFixed(1),
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700),
          ),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.blue.shade600)),
        ],
      );
}
