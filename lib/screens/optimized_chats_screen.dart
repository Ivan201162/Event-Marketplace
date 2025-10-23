import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/app_user.dart';
import '../providers/optimized_data_providers.dart';
import '../services/optimized_chat_service.dart';

/// Оптимизированная лента с реальными данными и обработкой состояний
class OptimizedChatsScreen extends ConsumerStatefulWidget {
  const OptimizedChatsScreen({super.key});

  @override
  ConsumerState<OptimizedChatsScreen> createState() =>
      _OptimizedChatsScreenState();
}

class _OptimizedChatsScreenState extends ConsumerState<OptimizedChatsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _showOnlineOnly = false;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Активные'),
            Tab(text: 'Закрепленные'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Фильтры'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Новый чат'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск и фильтры
          if (_searchQuery.isNotEmpty || _showOnlineOnly || _showUnreadOnly)
            _buildSearchAndFilters(),

          // Список чатов
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatsList('all'),
                _buildChatsList('active'),
                _buildChatsList('pinned'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Поиск
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Поиск в чатах...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // Фильтры
          Row(
            children: [
              FilterChip(
                label: const Text('Только онлайн'),
                selected: _showOnlineOnly,
                onSelected: (selected) {
                  setState(() {
                    _showOnlineOnly = selected;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Непрочитанные'),
                selected: _showUnreadOnly,
                onSelected: (selected) {
                  setState(() {
                    _showUnreadOnly = selected;
                  });
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Очистить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList(String type) {
    final chatAsync = ref.watch(chatsProvider({
      'type': type,
      'search': _searchQuery,
      'onlineOnly': _showOnlineOnly,
      'unreadOnly': _showUnreadOnly,
    }));

    return chatAsync.when(
      data: (chatsState) => _buildChatsContent(chatsState),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildChatsContent(ChatsState chatsState) {
    if (chatsState.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshChats,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chatsState.chats.length,
        itemBuilder: (context, index) {
          final chat = chatsState.chats[index];
          return _ChatListItemWidget(chat: chat);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка чатов...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет чатов',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Начните новый разговор',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.chat),
            label: const Text('Новый чат'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки чатов',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshChats,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
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
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Введите имя пользователя или сообщение...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = _searchController.text;
              });
            },
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filter':
        _showFilterDialog();
        break;
      case 'new_chat':
        _startNewChat();
        break;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Фильтры чатов'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Только онлайн'),
                value: _showOnlineOnly,
                onChanged: (value) {
                  setDialogState(() {
                    _showOnlineOnly = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Только непрочитанные'),
                value: _showUnreadOnly,
                onChanged: (value) {
                  setDialogState(() {
                    _showUnreadOnly = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _showOnlineOnly = false;
                  _showUnreadOnly = false;
                });
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }

  void _startNewChat() {
    // TODO: Открыть экран выбора пользователя для нового чата
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Функция создания нового чата в разработке')),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _showOnlineOnly = false;
      _showUnreadOnly = false;
      _searchController.clear();
    });
  }

  Future<void> _refreshChats() async {
    ref.invalidate(chatsProvider);
  }
}

class _ChatListItemWidget extends ConsumerWidget {
  const _ChatListItemWidget({required this.chat});
  final Chat chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatService = ref.read(optimizedChatServiceProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: chat.participantAvatar != null
                  ? CachedNetworkImageProvider(chat.participantAvatar!)
                  : null,
              child: chat.participantAvatar == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            if (chat.isParticipantOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.participantName,
                style: TextStyle(
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.isPinned)
              const Icon(
                Icons.push_pin,
                size: 16,
                color: Colors.amber,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.lastMessage ?? 'Нет сообщений',
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight:
                    chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatLastMessageTime(chat.lastMessageTime),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                if (chat.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${chat.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => _openChat(context, chat),
        onLongPress: () => _showChatOptions(context, chat, chatService),
      ),
    );
  }

  void _openChat(BuildContext context, Chat chat) {
    // TODO: Открыть экран чата
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открыть чат с ${chat.participantName}')),
    );
  }

  void _showChatOptions(
      BuildContext context, Chat chat, OptimizedChatService chatService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: chat.isPinned ? Colors.amber : null,
              ),
              title: Text(chat.isPinned ? 'Открепить' : 'Закрепить'),
              onTap: () {
                Navigator.pop(context);
                chatService.togglePin(chat.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Отметить как прочитанное'),
              onTap: () {
                Navigator.pop(context);
                chatService.markAsRead(chat.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить чат',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(context, chat, chatService);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat(
      BuildContext context, Chat chat, OptimizedChatService chatService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить чат'),
        content: Text(
            'Вы уверены, что хотите удалить чат с ${chat.participantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              chatService.deleteChat(chat.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Чат удален')),
              );
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }
}
