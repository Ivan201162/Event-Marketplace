import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_navigator.dart';
import '../models/chat.dart';
import '../providers/auth_providers.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

/// Экран списка чатов
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentUserProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Необходимо войти в систему'),
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) {
              await AppNavigator.handleBackPress(context);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Сообщения'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showOptionsMenu,
                ),
              ],
            ),
            body: _buildChatList(user.uid),
            floatingActionButton: FloatingActionButton(
              onPressed: _createNewChat,
              child: const Icon(Icons.message),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  Widget _buildChatList(String currentUserId) => StreamBuilder<List<Chat>>(
        stream: _chatService.getUserChatsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatItem(chat, currentUserId);
            },
          );
        },
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет сообщений',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Начните общение с другими пользователями',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewChat,
              icon: const Icon(Icons.message),
              label: const Text('Начать чат'),
            ),
          ],
        ),
      );

  Widget _buildChatItem(Chat chat, String currentUserId) {
    final otherParticipantName = chat.getDisplayName(currentUserId);
    final otherParticipantAvatar = chat.getDisplayAvatar(currentUserId);
    final lastMessageTime = chat.lastMessageTime;
    final unreadCount = chat.unreadCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: otherParticipantAvatar != null
                  ? CachedNetworkImageProvider(otherParticipantAvatar)
                  : null,
              child: otherParticipantAvatar == null
                  ? Text(
                      otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          otherParticipantName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                chat.lastMessageContent ?? 'Нет сообщений',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastMessageTime != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatTime(lastMessageTime),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _openChat(chat, currentUserId),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }

  void _openChat(Chat chat, String currentUserId) {
    final otherParticipantId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => chat.participants.first,
    );
    final otherParticipantName = chat.getDisplayName(currentUserId);
    final otherParticipantAvatar = chat.getDisplayAvatar(currentUserId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.id,
        ),
      ),
    );
  }

  void _createNewChat() {
    // TODO: Открыть экран создания нового чата
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание нового чата будет доступно в следующей версии'),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск сообщений'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Введите текст для поиска...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать поиск
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Архивные чаты'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Открыть архивные чаты
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Заблокированные'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Открыть заблокированных пользователей
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Настройки чатов'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Открыть настройки
              },
            ),
          ],
        ),
      ),
    );
  }
}
