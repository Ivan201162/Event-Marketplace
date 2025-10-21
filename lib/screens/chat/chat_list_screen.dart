import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/chat.dart';
import '../../providers/auth_providers.dart';
import '../../providers/chat_providers.dart';
import '../../widgets/animations/animated_content.dart';
import '../../widgets/error/error_state_widget.dart';
import '../../widgets/loading/loading_state_widget.dart';

/// Экран списка чатов
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Пользователь не авторизован'),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context),
          body: AnimatedContent(
            animationType: AnimationType.fadeSlideIn,
            child: _buildChatList(user.uid),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showNewChatDialog,
            child: const Icon(Icons.chat),
          ),
        );
      },
      loading: () => const Scaffold(
        body: LoadingStateWidget(message: 'Загрузка чатов...'),
      ),
      error: (error, stack) => Scaffold(
        body: ErrorStateWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(currentUserProvider),
          title: 'Ошибка загрузки чатов',
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Чаты'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showOptions,
        ),
      ],
      bottom: _isSearchVisible
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Поиск чатов...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            )
          : null,
    );
  }

  bool _isSearchVisible = false;

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _onSearchChanged('');
      }
    });
  }

  void _onSearchChanged(String query) {
    // TODO: Реализовать поиск чатов
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Настройки чатов'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Показать настройки
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Архивные чаты'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Показать архивные чаты
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(String userId) {
    final chatListState = ref.watch(chatListStateProvider(userId));

    return chatListState.when(
      data: (state) {
        if (state.isLoading) {
          return const LoadingStateWidget(message: 'Загрузка чатов...');
        }

        if (state.error != null) {
          return ErrorStateWidget(
            error: state.error!,
            onRetry: () => ref.read(chatListStateProvider(userId).notifier).refresh(),
            title: 'Ошибка загрузки чатов',
          );
        }

        if (state.chats.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(chatListStateProvider(userId).notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.chats.length,
            itemBuilder: (context, index) {
              final chat = state.chats[index];
              return _buildChatItem(chat);
            },
          ),
        );
      },
      loading: () => const LoadingStateWidget(message: 'Загрузка чатов...'),
      error: (error, stack) => ErrorStateWidget(
        error: error.toString(),
        onRetry: () => ref.invalidate(chatListStateProvider(userId)),
        title: 'Ошибка загрузки чатов',
      ),
    );
  }

  Widget _buildChatItem(ChatWithUser chat) {
    final theme = Theme.of(context);
    final hasUnread = chat.hasUnreadMessages;
    final unreadCount = chat.unreadCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(chat),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasUnread 
                  ? theme.primaryColor.withValues(alpha: 0.05)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: hasUnread
                  ? Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                      backgroundImage: chat.displayAvatar != null
                          ? NetworkImage(chat.displayAvatar!)
                          : null,
                      child: chat.displayAvatar == null
                          ? Icon(Icons.person, size: 24, color: theme.primaryColor)
                          : null,
                    ),
                    if (chat.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                color: hasUnread ? theme.primaryColor : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.chat.lastMessageTime != null)
                            Text(
                              _formatTime(chat.chat.lastMessageTime!),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.chat.lastMessage ?? 'Нет сообщений',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (hasUnread && unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет чатов',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Начните общение с другими пользователями',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showNewChatDialog,
            icon: const Icon(Icons.chat),
            label: const Text('Начать чат'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _openChat(ChatWithUser chat) {
    context.push('/chat/${chat.chat.id}', extra: {
      'otherUserId': chat.otherUserId,
      'otherUserName': chat.otherUserName,
      'otherUserAvatar': chat.otherUserAvatar,
    });
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый чат'),
        content: const Text('Функция поиска пользователей будет добавлена в следующем обновлении'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }
}
