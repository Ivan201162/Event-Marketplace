import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enhanced_chat.dart';
import '../models/enhanced_message.dart';
import '../widgets/chat_list_item_widget.dart';
import '../widgets/chat_search_widget.dart';

/// Улучшенный экран чатов с полным функционалом
class EnhancedChatsScreen extends ConsumerStatefulWidget {
  const EnhancedChatsScreen({super.key});

  @override
  ConsumerState<EnhancedChatsScreen> createState() => _EnhancedChatsScreenState();
}

class _EnhancedChatsScreenState extends ConsumerState<EnhancedChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _showOnlineOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Поиск и фильтры
          _buildSearchAndFilters(),

          // Табы
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все чаты'),
              Tab(text: 'Активные'),
              Tab(text: 'Закреплённые'),
            ],
          ),

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
      );

  Widget _buildSearchAndFilters() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поиск
            ChatSearchWidget(
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),

            const SizedBox(height: 12),

            // Фильтры
            Row(
              children: [
                FilterChip(
                  selected: _showOnlineOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlineOnly = selected;
                    });
                  },
                  label: const Text('Только онлайн'),
                  avatar: Icon(
                    Icons.circle,
                    size: 12,
                    color: _showOnlineOnly ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  onSelected: (selected) {
                    // TODO: Показать только непрочитанные
                  },
                  label: const Text('Непрочитанные'),
                  avatar: const Icon(Icons.mark_email_unread, size: 16),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildChatsList(String type) {
    // Тестовые данные чатов
    final chats = _getTestChats(type);

    if (chats.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Обновить данные
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ChatListItemWidget(
            chat: chat,
            onTap: () => _openChat(chat),
            onPin: () => _togglePin(chat),
            onDelete: () => _deleteChat(chat),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'active':
        title = 'Нет активных чатов';
        subtitle = 'Активные чаты будут отображаться здесь';
        icon = Icons.chat_bubble_outline;
        break;
      case 'pinned':
        title = 'Нет закреплённых чатов';
        subtitle = 'Закреплённые чаты будут показаны здесь';
        icon = Icons.push_pin;
        break;
      default:
        title = 'Нет чатов';
        subtitle = 'Начните общение со специалистами';
        icon = Icons.chat_bubble_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add_comment),
            label: const Text('Начать чат'),
          ),
        ],
      ),
    );
  }

  List<EnhancedChat> _getTestChats(String type) {
    final allChats = [
      EnhancedChat(
        id: '1',
        type: ChatType.direct,
        members: [
          ChatMember(
            userId: 'customer_1',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'specialist_1',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            isOnline: true,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        name: 'Анна Фотограф',
        avatarUrl: 'https://picsum.photos/50/50?random=1',
        lastMessage: ChatLastMessage(
          id: '1',
          senderId: 'specialist_1',
          text: 'Привет! Готова обсудить детали фотосъёмки',
          type: MessageType.text,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ),
      EnhancedChat(
        id: '2',
        type: ChatType.direct,
        members: [
          ChatMember(
            userId: 'customer_1',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ChatMember(
            userId: 'specialist_2',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        name: 'Дмитрий DJ',
        avatarUrl: 'https://picsum.photos/50/50?random=2',
        lastMessage: ChatLastMessage(
          id: '2',
          senderId: 'customer_1',
          text: 'Спасибо за отличную работу!',
          type: MessageType.text,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        isPinned: true,
      ),
      EnhancedChat(
        id: '3',
        type: ChatType.direct,
        members: [
          ChatMember(
            userId: 'customer_1',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 3)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'specialist_3',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 3)),
            isOnline: true,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        name: 'Елена Видеограф',
        avatarUrl: 'https://picsum.photos/50/50?random=3',
        lastMessage: ChatLastMessage(
          id: '3',
          senderId: 'specialist_3',
          text: 'Отправляю вам видео с мероприятия',
          type: MessageType.video,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ),
      EnhancedChat(
        id: '4',
        type: ChatType.direct,
        members: [
          ChatMember(
            userId: 'customer_1',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          ChatMember(
            userId: 'specialist_4',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        name: 'Михаил Аниматор',
        avatarUrl: 'https://picsum.photos/50/50?random=4',
        lastMessage: ChatLastMessage(
          id: '4',
          senderId: 'specialist_4',
          text: 'Добро пожаловать! Как дела?',
          type: MessageType.text,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ),
    ];

    switch (type) {
      case 'active':
        return allChats
            .where(
              (chat) => chat.members.any((member) => member.isOnline),
            )
            .toList();
      case 'pinned':
        return allChats.where((chat) => chat.isPinned).toList();
      default:
        return allChats;
    }
  }

  void _openChat(EnhancedChat chat) {
    context.push('/chat/${chat.id}');
  }

  void _togglePin(EnhancedChat chat) {
    // TODO: Реализовать закрепление/открепление чата
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          chat.isPinned ? 'Чат откреплён' : 'Чат закреплён',
        ),
      ),
    );
  }

  void _deleteChat(EnhancedChat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить чат'),
        content: const Text('Вы уверены, что хотите удалить этот чат?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Удалить чат
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Чат удалён')),
              );
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _startNewChat() {
    // TODO: Реализовать создание нового чата
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание нового чата будет реализовано')),
    );
  }
}
