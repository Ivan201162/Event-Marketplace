import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_providers.dart';
import '../../widgets/chat_list_item.dart';
import '../../widgets/chat_search_bar.dart';
import 'chat_screen.dart';

/// Экран списка чатов
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
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
          // Поиск
          ChatSearchBar(
            onSearchChanged: (query) => setState(() => _searchQuery = query),
          ),
          
          // Список чатов
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(chatsProvider.notifier).refreshChats();
              },
              child: chatsState.when(
                data: (chats) => ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ChatListItem(
                      chat: chat,
                      onTap: () => _openChat(chat.id),
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
                      Text('Ошибка загрузки чатов: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(chatsProvider.notifier).refreshChats(),
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
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск в чатах'),
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
              ref.read(chatsProvider.notifier).searchChats(_searchQuery);
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
        title: const Text('Фильтры чатов'),
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
              title: const Text('Непрочитанные'),
              leading: Radio<String>(
                value: 'unread',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('С медиа'),
              leading: Radio<String>(
                value: 'media',
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
              ref.read(chatsProvider.notifier).filterChats(_selectedFilter);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _openChat(String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId),
      ),
    );
  }
}
