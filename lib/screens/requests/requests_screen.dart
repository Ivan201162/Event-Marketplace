import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/requests_providers.dart';
import '../../widgets/request_card.dart';
import '../../widgets/request_filters.dart';
import 'create_request_screen.dart';
import 'request_details_screen.dart';

/// Экран списка заявок
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final requestsState = ref.watch(requestsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          RequestFilters(
            selectedFilter: _selectedFilter,
            selectedSort: _selectedSort,
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            onSortChanged: (sort) => setState(() => _selectedSort = sort),
          ),
          
          // Список заявок
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(requestsProvider.notifier).refreshRequests();
              },
              child: requestsState.when(
                data: (requests) => ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return RequestCard(
                      request: request,
                      onTap: () => _openRequestDetails(request.id),
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Ошибка загрузки заявок: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(requestsProvider.notifier).refreshRequests(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createRequest(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск заявок'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите запрос...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(requestsProvider.notifier).searchRequests(_searchQuery);
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Все'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('Открытые'),
              leading: Radio<String>(
                value: 'open',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('В работе'),
              leading: Radio<String>(
                value: 'in_progress',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('Завершённые'),
              leading: Radio<String>(
                value: 'done',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(requestsProvider.notifier).filterRequests(_selectedFilter);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _createRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRequestScreen(),
      ),
    );
  }

  void _openRequestDetails(String requestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailsScreen(requestId: requestId),
      ),
    );
  }
}