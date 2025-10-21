import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feed_model.dart';
import '../providers/feed_providers.dart';

/// Панель фильтров для ленты
class FeedFiltersBar extends ConsumerWidget {
  const FeedFiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(feedFilterProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Фильтры
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FeedFilter.values.map((filter) {
                  final isSelected = currentFilter == filter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(feedFilterProvider.notifier).state = filter;

                          // Сбрасываем категорию при смене фильтра
                          if (filter != FeedFilter.categories) {
                            ref.read(selectedCategoryProvider.notifier).state = null;
                          }
                        }
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Кнопка категорий (если выбран фильтр по категориям)
          if (currentFilter == FeedFilter.categories)
            IconButton(
              icon: Icon(
                Icons.category,
                color: selectedCategory != null ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _showCategoryDialog(context, ref),
            ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref) {
    final categories = [
      'Оформители',
      'Ведущие',
      'Диджеи',
      'Фотографы',
      'Видеографы',
      'Музыканты',
      'Аниматоры',
      'Кейтеринг',
      'Декор',
      'Техника',
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите категорию'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length + 1, // +1 для "Все категории"
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('Все категории'),
                  leading: const Icon(Icons.all_inclusive),
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = null;
                    Navigator.of(context).pop();
                  },
                );
              }

              final category = categories[index - 1];
              return ListTile(
                title: Text(category),
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        ],
      ),
    );
  }
}
