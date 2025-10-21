import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_profile_extended.dart';
import '../providers/specialist_profile_extended_providers.dart';
import '../services/specialist_profile_extended_service.dart';
import '../widgets/faq_editor_widget.dart';
import '../widgets/faq_filter_widget.dart';
import '../widgets/faq_item_widget.dart';

/// Экран управления FAQ специалиста
class SpecialistFAQScreen extends ConsumerStatefulWidget {
  const SpecialistFAQScreen({super.key, required this.specialistId});
  final String specialistId;

  @override
  ConsumerState<SpecialistFAQScreen> createState() => _SpecialistFAQScreenState();
}

class _SpecialistFAQScreenState extends ConsumerState<SpecialistFAQScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqAsync = ref.watch(specialistFAQProvider(widget.specialistId));
    final statsAsync = ref.watch(specialistProfileStatsProvider(widget.specialistId));
    // final faqFilters = ref.watch(faqFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Часто задаваемые вопросы'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все вопросы', icon: Icon(Icons.help_outline)),
            Tab(text: 'Опубликованные', icon: Icon(Icons.public)),
            Tab(text: 'По категориям', icon: Icon(Icons.category)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearchDialog),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
        ],
      ),
      body: Column(
        children: [
          // Статистика
          statsAsync.when(
            data: _buildStatsCard,
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          // Контент по вкладкам
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAllFAQTab(faqAsync), _buildPublishedFAQTab(), _buildCategoriesTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFAQDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(SpecialistProfileStats stats) => Card(
    margin: const EdgeInsets.all(8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Всего вопросов', stats.totalFAQItems, Icons.help_outline),
          _buildStatItem('Опубликованных', stats.publishedFAQItems, Icons.public),
          _buildStatItem('Категорий', _getCategoriesCount(), Icons.category),
        ],
      ),
    ),
  );

  Widget _buildStatItem(String label, int value, IconData icon) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 24),
      const SizedBox(height: 4),
      Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  Widget _buildAllFAQTab(AsyncValue<List<FAQItem>> faqAsync) => faqAsync.when(
    data: (faqItems) {
      if (faqItems.isEmpty) {
        return _buildEmptyState(
          'Нет вопросов',
          'Добавьте часто задаваемые вопросы, чтобы помочь клиентам',
          Icons.help_outline,
        );
      }

      // Сортируем по категории и порядку
      final sortedFAQ = List<FAQItem>.from(faqItems);
      sortedFAQ.sort((a, b) {
        final categoryCompare = a.category.compareTo(b.category);
        if (categoryCompare != 0) return categoryCompare;
        return a.order.compareTo(b.order);
      });

      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedFAQ.length,
        itemBuilder: (context, index) {
          final faqItem = sortedFAQ[index];
          return FAQItemWidget(
            faqItem: faqItem,
            onTap: () => _showFAQDetails(faqItem),
            onEdit: () => _showEditFAQDialog(faqItem),
            onDelete: () => _deleteFAQ(faqItem),
            onTogglePublish: () => _togglePublish(faqItem),
          );
        },
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => _buildErrorState(error.toString()),
  );

  Widget _buildPublishedFAQTab() {
    final faqAsync = ref.watch(specialistFAQProvider(widget.specialistId));

    return faqAsync.when(
      data: (faqItems) {
        final publishedItems = faqItems.where((item) => item.isPublished).toList();

        if (publishedItems.isEmpty) {
          return _buildEmptyState(
            'Нет опубликованных вопросов',
            'Опубликуйте вопросы, чтобы клиенты могли их видеть',
            Icons.public_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: publishedItems.length,
          itemBuilder: (context, index) {
            final faqItem = publishedItems[index];
            return FAQItemWidget(
              faqItem: faqItem,
              onTap: () => _showFAQDetails(faqItem),
              onEdit: () => _showEditFAQDialog(faqItem),
              onDelete: () => _deleteFAQ(faqItem),
              onTogglePublish: () => _togglePublish(faqItem),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildCategoriesTab() {
    final faqAsync = ref.watch(specialistFAQProvider(widget.specialistId));

    return faqAsync.when(
      data: (faqItems) {
        final categories = faqItems.map((item) => item.category).toSet().toList();
        categories.sort();

        if (categories.isEmpty) {
          return _buildEmptyState(
            'Нет категорий',
            'Добавьте вопросы с категориями для лучшей организации',
            Icons.category_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildCategoryCard(String category) {
    final faqByCategoryAsync = ref.watch(
      specialistFAQByCategoryProvider((widget.specialistId, category)),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.category),
        title: Text(_getCategoryDisplayName(category)),
        subtitle: faqByCategoryAsync.when(
          data: (items) => Text('${items.length} вопросов'),
          loading: () => const Text('Загрузка...'),
          error: (_, __) => const Text('Ошибка'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showFAQByCategory(category),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildErrorState(String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text('Ошибка: $error'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(specialistFAQProvider(widget.specialistId)),
          child: const Text('Повторить'),
        ),
      ],
    ),
  );

  void _showAddFAQDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => FAQEditorWidget(
        specialistId: widget.specialistId,
        onFAQSaved: () {
          ref.refresh(specialistFAQProvider(widget.specialistId));
          ref.refresh(specialistProfileStatsProvider(widget.specialistId));
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск по FAQ'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Введите запрос для поиска...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                _showSearchResults(query);
              }
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => FAQFilterWidget(
        currentFilters: ref.read(faqFiltersProvider),
        onFiltersChanged: (filters) {
          ref.read(faqFiltersProvider.notifier).state = filters;
        },
      ),
    );
  }

  void _showFAQDetails(FAQItem faqItem) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            children: [
              AppBar(
                title: Text(faqItem.question),
                actions: [
                  IconButton(
                    icon: Icon(faqItem.isPublished ? Icons.public : Icons.lock),
                    onPressed: () {
                      Navigator.pop(context);
                      _togglePublish(faqItem);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditFAQDialog(faqItem);
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faqItem.answer, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Chip(
                            label: Text(_getCategoryDisplayName(faqItem.category)),
                            backgroundColor: Colors.blue[100],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Порядок: ${faqItem.order}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Создано: ${_formatDate(faqItem.createdAt)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (faqItem.updatedAt != faqItem.createdAt) ...[
                            const SizedBox(width: 16),
                            Text(
                              'Обновлено: ${_formatDate(faqItem.updatedAt)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFAQDialog(FAQItem faqItem) {
    showDialog<void>(
      context: context,
      builder: (context) => FAQEditorWidget(
        specialistId: widget.specialistId,
        existingFAQ: faqItem,
        onFAQSaved: () {
          ref.refresh(specialistFAQProvider(widget.specialistId));
          ref.refresh(specialistProfileStatsProvider(widget.specialistId));
        },
      ),
    );
  }

  void _deleteFAQ(FAQItem faqItem) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить вопрос?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(specialistProfileExtendedServiceProvider);
              await service.removeFAQItem(widget.specialistId, faqItem.id);
              ref.refresh(specialistFAQProvider(widget.specialistId));
              ref.refresh(specialistProfileStatsProvider(widget.specialistId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePublish(FAQItem faqItem) async {
    final service = ref.read(specialistProfileExtendedServiceProvider);
    final updatedFAQ = faqItem.copyWith(isPublished: !faqItem.isPublished);
    await service.updateFAQItem(widget.specialistId, updatedFAQ);
    ref.refresh(specialistFAQProvider(widget.specialistId));
    ref.refresh(specialistProfileStatsProvider(widget.specialistId));
  }

  void _showFAQByCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            FAQByCategoryScreen(specialistId: widget.specialistId, category: category),
      ),
    );
  }

  void _showSearchResults(String query) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            FAQSearchResultsScreen(specialistId: widget.specialistId, query: query),
      ),
    );
  }

  int _getCategoriesCount() {
    final faqAsync = ref.read(specialistFAQProvider(widget.specialistId));
    return faqAsync.when(
      data: (faqItems) => faqItems.map((item) => item.category).toSet().length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'general':
        return 'Общие вопросы';
      case 'pricing':
        return 'Цены и оплата';
      case 'booking':
        return 'Бронирование';
      case 'services':
        return 'Услуги';
      case 'equipment':
        return 'Оборудование';
      case 'cancellation':
        return 'Отмена и возврат';
      default:
        return category;
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}

/// Экран FAQ по категории
class FAQByCategoryScreen extends ConsumerWidget {
  const FAQByCategoryScreen({super.key, required this.specialistId, required this.category});
  final String specialistId;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqAsync = ref.watch(specialistFAQByCategoryProvider((specialistId, category)));

    return Scaffold(
      appBar: AppBar(title: Text('FAQ: ${_getCategoryDisplayName(category)}')),
      body: faqAsync.when(
        data: (faqItems) {
          if (faqItems.isEmpty) {
            return const Center(child: Text('Нет вопросов в этой категории'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: faqItems.length,
            itemBuilder: (context, index) {
              final faqItem = faqItems[index];
              return FAQItemWidget(
                faqItem: faqItem,
                onTap: () => _showFAQDetails(context, faqItem),
                onEdit: () => _showEditFAQDialog(context, ref, faqItem),
                onDelete: () => _deleteFAQ(context, ref, faqItem),
                onTogglePublish: () => _togglePublish(context, ref, faqItem),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'general':
        return 'Общие вопросы';
      case 'pricing':
        return 'Цены и оплата';
      case 'booking':
        return 'Бронирование';
      case 'services':
        return 'Услуги';
      case 'equipment':
        return 'Оборудование';
      case 'cancellation':
        return 'Отмена и возврат';
      default:
        return category;
    }
  }

  void _showFAQDetails(BuildContext context, FAQItem faqItem) {
    // TODO(developer): Показать детали FAQ
  }

  void _showEditFAQDialog(BuildContext context, WidgetRef ref, FAQItem faqItem) {
    // TODO(developer): Редактировать FAQ
  }

  void _deleteFAQ(BuildContext context, WidgetRef ref, FAQItem faqItem) {
    // TODO(developer): Удалить FAQ
  }

  void _togglePublish(BuildContext context, WidgetRef ref, FAQItem faqItem) {
    // TODO(developer): Переключить публикацию
  }
}

/// Экран результатов поиска FAQ
class FAQSearchResultsScreen extends ConsumerWidget {
  const FAQSearchResultsScreen({super.key, required this.specialistId, required this.query});
  final String specialistId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqAsync = ref.watch(specialistFAQSearchProvider((specialistId, query)));

    return Scaffold(
      appBar: AppBar(title: Text('Результаты поиска: $query')),
      body: faqAsync.when(
        data: (faqItems) {
          if (faqItems.isEmpty) {
            return const Center(child: Text('Ничего не найдено'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: faqItems.length,
            itemBuilder: (context, index) {
              final faqItem = faqItems[index];
              return FAQItemWidget(
                faqItem: faqItem,
                onTap: () => _showFAQDetails(context, faqItem),
                onEdit: () => _showEditFAQDialog(context, ref, faqItem),
                onDelete: () => _deleteFAQ(context, ref, faqItem),
                onTogglePublish: () => _togglePublish(context, ref, faqItem),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  void _showFAQDetails(BuildContext context, FAQItem faqItem) {
    // TODO(developer): Показать детали FAQ
  }

  void _showEditFAQDialog(BuildContext context, WidgetRef ref, FAQItem faqItem) {
    // TODO(developer): Редактировать FAQ
  }

  void _deleteFAQ(BuildContext context, WidgetRef ref, FAQItem faqItem) {
    // TODO(developer): Удалить FAQ
  }

  void _togglePublish(BuildContext context, WidgetRef ref, FAQItem faqItem) {
    // TODO(developer): Переключить публикацию
  }
}
