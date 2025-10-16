import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/social_models.dart';
import '../services/supabase_service.dart';

class SocialChatsListScreen extends ConsumerStatefulWidget {
  const SocialChatsListScreen({super.key});

  @override
  ConsumerState<SocialChatsListScreen> createState() => _SocialChatsListScreenState();
}

class _SocialChatsListScreenState extends ConsumerState<SocialChatsListScreen> {
  List<ChatListItem> _chats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chats = await SupabaseService.getChatsList();
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [
          IconButton(
            onPressed: _loadChats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки чатов',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет сообщений',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Начните общение с другими пользователями',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Переход к поиску пользователей
                context.push('/search');
              },
              icon: const Icon(Icons.search),
              label: const Text('Найти пользователей'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return _buildChatItem(chat);
        },
      ),
    );
  }

  Widget _buildChatItem(ChatListItem chat) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: chat.otherUser.avatarUrl != null
            ? CachedNetworkImageProvider(chat.otherUser.avatarUrl!)
            : null,
        child: chat.otherUser.avatarUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(
        chat.otherUser.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: chat.lastMessage != null
          ? Text(
              chat.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            )
          : const Text(
              'Нет сообщений',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageTime != null)
            Text(
              _formatTime(chat.lastMessageTime!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          const SizedBox(height: 4),
          // Индикатор непрочитанных сообщений (можно добавить позже)
          // Container(
          //   width: 8,
          //   height: 8,
          //   decoration: const BoxDecoration(
          //     color: Colors.red,
          //     shape: BoxShape.circle,
          //   ),
          // ),
        ],
      ),
      onTap: () {
        context.push('/chat/${chat.chatId}');
      },
    );
  }

  String _formatTime(String timeString) {
    try {
      final dateTime = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'сейчас';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}м';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}ч';
      } else if (difference.inDays == 1) {
        return 'вчера';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}д';
      } else {
        return '${dateTime.day}.${dateTime.month}';
      }
    } catch (e) {
      return 'давно';
    }
  }
}


