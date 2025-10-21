import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../screens/enhanced_chat_screen.dart';
import '../services/chat_service.dart';

/// Улучшенный экран списка чатов с категориями
class EnhancedChatsListScreen extends ConsumerStatefulWidget {
  const EnhancedChatsListScreen({super.key});

  @override
  ConsumerState<EnhancedChatsListScreen> createState() => _EnhancedChatsListScreenState();
}

class _EnhancedChatsListScreenState extends ConsumerState<EnhancedChatsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    // TODO(developer): Получить текущего пользователя из провайдера
    _currentUserId = 'current_user_id';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Мои заказы'),
            Tab(text: 'Мои исполнители'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearch),
          IconButton(icon: const Icon(Icons.add), onPressed: _createNewChat),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsList(null), // Все чаты
          _buildChatsList('orders'), // Мои заказы
          _buildChatsList('specialists'), // Мои исполнители
        ],
      ),
    );
  }

  Widget _buildChatsList(String? category) => StreamBuilder<List<Chat>>(
    stream: category != null ? _getChatsByCategoryStream(category) : _getAllChatsStream(),
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
              ElevatedButton(onPressed: () => setState(() {}), child: const Text('Повторить')),
            ],
          ),
        );
      }

      final chats = snapshot.data ?? [];

      if (chats.isEmpty) {
        return _buildEmptyState(category);
      }

      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _buildChatItem(chat);
        },
      );
    },
  );

  Stream<List<Chat>> _getAllChatsStream() => _chatService.getUserChats(_currentUserId!).asStream();

  Stream<List<Chat>> _getChatsByCategoryStream(String category) =>
      _chatService.getChatsByCategory(_currentUserId!, category).asStream();

  Widget _buildEmptyState(String? category) {
    String title;
    String subtitle;
    IconData icon;

    switch (category) {
      case 'orders':
        title = 'Нет чатов с заказами';
        subtitle = 'Здесь будут отображаться чаты с организаторами ваших мероприятий';
        icon = Icons.event;
        break;
      case 'specialists':
        title = 'Нет чатов с исполнителями';
        subtitle = 'Здесь будут отображаться чаты с исполнителями ваших заказов';
        icon = Icons.people;
        break;
      default:
        title = 'Нет чатов';
        subtitle = 'Начните общение, создав новый чат';
        icon = Icons.chat;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewChat,
            icon: const Icon(Icons.add),
            label: const Text('Создать чат'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat) {
    final displayName = chat.getDisplayName(_currentUserId!);
    final displayAvatar = chat.getDisplayAvatar(_currentUserId!);
    final hasUnread = chat.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: displayAvatar != null ? NetworkImage(displayAvatar) : null,
        child: displayAvatar == null ? Text(displayName[0].toUpperCase()) : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chat.lastMessageContent != null)
            Text(
              _getLastMessagePreview(chat),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? Colors.black87 : Colors.grey[600],
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (chat.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(chat.category!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryLabel(chat.category!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (chat.category != null) const SizedBox(width: 8),
              Text(
                _formatLastMessageTime(chat.lastMessageTime),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _openChat(chat),
      onLongPress: () => _showChatOptions(chat),
    );
  }

  String _getLastMessagePreview(Chat chat) {
    if (chat.lastMessageContent == null) return '';

    switch (chat.lastMessageType) {
      case MessageType.image:
        return '🖼️ Изображение';
      case MessageType.video:
        return '🎥 Видео';
      case MessageType.audio:
        return '🎵 Аудио';
      case MessageType.file:
        return '📎 Файл';
      case MessageType.attachment:
        return '📎 Вложение';
      case MessageType.location:
        return '📍 Местоположение';
      case MessageType.system:
        return 'ℹ️ ${chat.lastMessageContent}';
      default:
        return chat.lastMessageContent!;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'orders':
        return 'Заказ';
      case 'specialists':
        return 'Исполнитель';
      default:
        return 'Чат';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'orders':
        return Colors.blue;
      case 'specialists':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}.${time.month}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }

  void _openChat(Chat chat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            EnhancedChatScreen(chatId: chat.id, chatTitle: chat.getDisplayName(_currentUserId!)),
      ),
    );
  }

  void _showChatOptions(Chat chat) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Информация о чате'),
              onTap: () {
                Navigator.of(context).pop();
                _showChatInfo(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Отключить уведомления'),
              onTap: () {
                Navigator.of(context).pop();
                _toggleNotifications(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all, color: Colors.red),
              title: const Text('Очистить чат', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _clearChat(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить чат', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _deleteChat(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    // TODO(developer): Реализовать поиск по чатам
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Поиск по чатам пока не реализован')));
  }

  void _createNewChat() {
    // TODO(developer): Реализовать создание нового чата
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Создание чата пока не реализовано')));
  }

  void _showChatInfo(Chat chat) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chat.getDisplayName(_currentUserId!)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.description != null) Text('Описание: ${chat.description}'),
            Text('Участников: ${chat.participants.length}'),
            Text('Создан: ${_formatDate(chat.createdAt)}'),
            if (chat.category != null) Text('Категория: ${_getCategoryLabel(chat.category!)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _toggleNotifications(Chat chat) {
    // TODO(developer): Реализовать переключение уведомлений
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Настройки уведомлений пока не реализованы')));
  }

  void _clearChat(Chat chat) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить чат?'),
        content: const Text('Все сообщения будут удалены. Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chatService.clearChat(chat.id);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _deleteChat(Chat chat) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить чат?'),
        content: const Text('Чат будет удален навсегда. Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO(developer): Реализовать удаление чата
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Удаление чата пока не реализовано')));
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
