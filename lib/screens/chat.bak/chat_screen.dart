import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/message.dart';
import '../../providers/auth_providers.dart';
import '../../providers/chat_providers.dart';
import '../../widgets/animations/animated_content.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/error/error_state_widget.dart';
import '../../widgets/loading/loading_state_widget.dart';

/// Экран чата
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
  });

  final String chatId;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isTyping = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
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

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Автоматическая прокрутка к последнему сообщению при загрузке
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    final chatState = ref.read(chatStateProvider(widget.chatId).notifier);
    await chatState.sendMessage(
      text: text,
      senderId: _currentUserId!,
      senderName: ref.read(currentUserProvider).value?.name,
      senderAvatar: ref.read(currentUserProvider).value?.avatarUrl,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _onMessageSent() {
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final chatState = ref.watch(chatStateProvider(widget.chatId));

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Пользователь не авторизован'),
            ),
          );
        }

        _currentUserId = user.uid;

        return Scaffold(
          appBar: _buildAppBar(context, user),
          body: AnimatedContent(
            animationType: AnimationType.fadeSlideIn,
            child: Column(
              children: [
                Expanded(
                  child: _buildMessagesList(messagesAsync),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: LoadingStateWidget(message: 'Загрузка чата...'),
      ),
      error: (error, stack) => Scaffold(
        body: ErrorStateWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(currentUserProvider),
          title: 'Ошибка загрузки чата',
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppUser currentUser) {
    final theme = Theme.of(context);

    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: widget.otherUserAvatar != null
                ? NetworkImage(widget.otherUserAvatar!)
                : null,
            child: widget.otherUserAvatar == null
                ? Icon(Icons.person, size: 18, color: theme.primaryColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName ?? 'Пользователь',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'В сети',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showChatOptions,
        ),
      ],
    );
  }

  Widget _buildMessagesList(AsyncValue<List<Message>> messagesAsync) {
    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        // Отмечаем сообщения как прочитанные
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_currentUserId != null) {
            ref
                .read(chatStateProvider(widget.chatId).notifier)
                .markAsRead(_currentUserId!);
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isFromCurrentUser = message.senderId == _currentUserId;
            final showAvatar =
                index == 0 || messages[index - 1].senderId != message.senderId;

            if (message.type == MessageType.system) {
              return SystemMessageBubble(message: message);
            }

            return MessageBubble(
              message: message,
              isFromCurrentUser: isFromCurrentUser,
              showAvatar: showAvatar,
            );
          },
        );
      },
      loading: () => const LoadingStateWidget(
        message: 'Загрузка сообщений...',
      ),
      error: (error, stack) => ErrorStateWidget(
        error: error.toString(),
        onRetry: () => ref.invalidate(chatMessagesProvider(widget.chatId)),
        title: 'Ошибка загрузки сообщений',
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
            'Начните общение',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Отправьте первое сообщение',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Напишите сообщение...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              onChanged: (text) {
                // Здесь можно добавить логику для индикатора печати
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: chatState.isSending ? null : _sendMessage,
              icon: chatState.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Информация о чате'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Показать информацию о чате
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Заблокировать пользователя'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Заблокировать пользователя
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Удалить чат'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Удалить чат
              },
            ),
          ],
        ),
      ),
    );
  }
}
