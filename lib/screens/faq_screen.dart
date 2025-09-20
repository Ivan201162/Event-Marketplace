import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';
import '../widgets/faq_widget.dart';

/// Экран FAQ
class FAQScreen extends ConsumerStatefulWidget {
  const FAQScreen({super.key});

  @override
  ConsumerState<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends ConsumerState<FAQScreen> {
  final SupportService _supportService = SupportService();
  SupportCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Часто задаваемые вопросы'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Категории
            _buildCategorySelector(),

            // Список FAQ
            Expanded(
              child: _buildFAQList(),
            ),
          ],
        ),
      );

  Widget _buildCategorySelector() => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: SupportCategory.values.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              final isSelected = _selectedCategory == null;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Все'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
              );
            }

            final category = SupportCategory.values[index - 1];
            final isSelected = _selectedCategory == category;

            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.categoryText),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
              ),
            );
          },
        ),
      );

  Widget _buildFAQList() => StreamBuilder<List<FAQItem>>(
        stream: _supportService.getFAQ(category: _selectedCategory),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final faqItems = snapshot.data ?? [];
          final filteredItems = _filterFAQItems(faqItems);

          if (filteredItems.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final faqItem = filteredItems[index];
              return FAQWidget(
                faqItem: faqItem,
                onTap: () => _showFAQDetail(faqItem),
              );
            },
          );
        },
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет вопросов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить категорию или поисковый запрос',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  List<FAQItem> _filterFAQItems(List<FAQItem> items) {
    if (_searchQuery.isEmpty) return items;

    final query = _searchQuery.toLowerCase();
    return items
        .where(
          (item) =>
              item.question.toLowerCase().contains(query) ||
              item.answer.toLowerCase().contains(query) ||
              item.tags.any((tag) => tag.toLowerCase().contains(query)),
        )
        .toList();
  }

  void _showFAQDetail(FAQItem faqItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(faqItem.question),
        content: SingleChildScrollView(
          child: Text(
            faqItem.answer,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTicketFromFAQ(faqItem);
            },
            child: const Text('Создать тикет'),
          ),
        ],
      ),
    );

    // Увеличиваем счетчик просмотров
    _supportService.incrementFAQViews(faqItem.id);
  }

  void _createTicketFromFAQ(FAQItem faqItem) {
    // TODO: Перейти к созданию тикета с предзаполненной информацией
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Создание тикета для: ${faqItem.question}')),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск в FAQ'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите поисковый запрос...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }
}

/// Экран детального просмотра FAQ
class FAQDetailScreen extends StatelessWidget {
  const FAQDetailScreen({
    super.key,
    required this.faqItem,
  });
  final FAQItem faqItem;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('FAQ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareFAQ(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Категория
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      faqItem.category.icon,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      faqItem.category.categoryText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Вопрос
              Text(
                faqItem.question,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Ответ
              Text(
                faqItem.answer,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // Теги
              if (faqItem.tags.isNotEmpty) ...[
                const Text(
                  'Теги:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: faqItem.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Статистика
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${faqItem.viewsCount} просмотров',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Обновлено: ${_formatDate(faqItem.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Действия
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _createTicketFromFAQ(context),
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Создать тикет'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareFAQ(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Поделиться'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _createTicketFromFAQ(BuildContext context) {
    // TODO: Перейти к созданию тикета с предзаполненной информацией
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Создание тикета для: ${faqItem.question}')),
    );
  }

  void _shareFAQ(BuildContext context) {
    // TODO: Реализовать шаринг FAQ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAQ скопирован в буфер обмена')),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
