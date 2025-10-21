import 'package:flutter/material.dart';
import '../services/support_service.dart';

/// Виджет FAQ
class FAQWidget extends StatefulWidget {
  const FAQWidget({super.key, this.onItemTap});

  final void Function(FAQItem)? onItemTap;

  @override
  State<FAQWidget> createState() => _FAQWidgetState();
}

class _FAQWidgetState extends State<FAQWidget> {
  final SupportService _supportService = SupportService();
  final TextEditingController _searchController = TextEditingController();

  List<FAQItem> _faqItems = [];
  List<FAQItem> _filteredItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFAQ();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQ() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final faqItems = await _supportService.getFAQ();
      setState(() {
        _faqItems = faqItems;
        _filteredItems = faqItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _searchFAQ(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = _faqItems;
      });
      return;
    }

    setState(() {
      _filteredItems = _faqItems.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query.toLowerCase());
        final contentMatch = item.content.toLowerCase().contains(query.toLowerCase());
        return titleMatch || contentMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildFAQList()),
        ],
      );

  Widget _buildSearchBar() => Container(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск в FAQ...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: _searchFAQ,
        ),
      );

  Widget _buildFAQList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorWidget(error: _error!, onRetry: _loadFAQ);
    }

    if (_filteredItems.isEmpty) {
      return _EmptyWidget(isSearching: _searchController.text.isNotEmpty);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _FAQItemCard(item: item, onTap: () => widget.onItemTap?.call(item));
      },
    );
  }
}

/// Виджет ошибки
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки FAQ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      );
}

/// Виджет пустого состояния
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSearching ? Icons.search_off : Icons.help_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Ничего не найдено' : 'FAQ пуст',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Попробуйте изменить поисковый запрос'
                  : 'Часто задаваемые вопросы появятся здесь',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

/// Карточка FAQ
class _FAQItemCard extends StatelessWidget {
  const _FAQItemCard({required this.item, required this.onTap});

  final FAQItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  if (item.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

/// Виджет детального просмотра FAQ
class FAQDetailWidget extends StatelessWidget {
  const FAQDetailWidget({super.key, required this.item});

  final FAQItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('FAQ'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.category.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(item.content, style: const TextStyle(fontSize: 16, height: 1.5)),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Теги:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags
                      .map((tag) => Chip(label: Text(tag), backgroundColor: Colors.grey[200]))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
}
