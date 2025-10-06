import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/faq.dart';
import '../providers/support_providers.dart';

/// Экран помощи и FAQ
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqAsync = ref.watch(faqProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по вопросам...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Список FAQ
          Expanded(
            child: faqAsync.when(
              data: (faqs) {
                final filteredFaqs = _searchQuery.isEmpty
                    ? faqs
                    : faqs
                        .where(
                          (faq) =>
                              faq.question
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              faq.answer
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()),
                        )
                        .toList();

                if (filteredFaqs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final faq = filteredFaqs[index];
                    return _buildFaqCard(faq);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(faqProvider),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Кнопка связи с поддержкой
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showContactSupportDialog,
                icon: const Icon(Icons.support_agent),
                label: const Text('Связаться с поддержкой'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'Нет вопросов' : 'Ничего не найдено',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Вопросы и ответы появятся здесь'
                  : 'Попробуйте изменить поисковый запрос',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildFaqCard(FAQ faq) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          title: Text(
            faq.question,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq.answer,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      );

  void _showContactSupportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Связаться с поддержкой'),
        content: const Text(
          'Выберите удобный способ связи с нашей службой поддержки:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Навигация к экрану создания тикета поддержки
            },
            child: const Text('Создать тикет'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Открытие email клиента
            },
            child: const Text('Email'),
          ),
        ],
      ),
    );
  }
}
