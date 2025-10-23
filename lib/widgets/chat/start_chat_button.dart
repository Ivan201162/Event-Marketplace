import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../services/chat_service.dart';

/// Кнопка для начала чата с пользователем
class StartChatButton extends ConsumerStatefulWidget {
  const StartChatButton({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
    this.isCompact = false,
  });

  final String userId;
  final String? userName;
  final String? userAvatar;
  final bool isCompact;

  @override
  ConsumerState<StartChatButton> createState() => _StartChatButtonState();
}

class _StartChatButtonState extends ConsumerState<StartChatButton>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _animationController.forward();

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        _showError('Пользователь не авторизован');
        return;
      }

      if (currentUser.uid == widget.userId) {
        _showError('Нельзя начать чат с самим собой');
        return;
      }

      // Создаем или получаем чат
      final chatId =
          await _chatService.getOrCreateChat(currentUser.uid, widget.userId);

      if (mounted) {
        context.push('/chat/$chatId', extra: {
          'otherUserId': widget.userId,
          'otherUserName': widget.userName,
          'otherUserAvatar': widget.userAvatar,
        });
      }
    } catch (e) {
      _showError('Ошибка создания чата: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.reverse();
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isCompact) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: IconButton(
              onPressed: _isLoading ? null : _startChat,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    )
                  : Icon(
                      Icons.chat,
                      color: theme.primaryColor,
                    ),
              tooltip: 'Написать сообщение',
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _startChat,
            icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.chat),
            label: Text(_isLoading ? 'Создание чата...' : 'Написать сообщение'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Кнопка для быстрого начала чата (плавающая)
class FloatingStartChatButton extends StatelessWidget {
  const FloatingStartChatButton({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
  });

  final String userId;
  final String? userName;
  final String? userAvatar;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return StartChatButton(
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          isCompact: false,
        );
      },
    );
  }
}

/// Виджет для отображения статуса чата
class ChatStatusWidget extends StatelessWidget {
  const ChatStatusWidget({
    super.key,
    required this.userId,
    this.showOnlineStatus = true,
  });

  final String userId;
  final bool showOnlineStatus;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Получить статус пользователя из провайдера
        final isOnline = false; // Временная заглушка

        if (!showOnlineStatus) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isOnline ? 'В сети' : 'Не в сети',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
