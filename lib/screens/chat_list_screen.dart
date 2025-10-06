import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_navigator.dart';
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
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: _buildChatList(user.uid),
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

  Widget _buildChatList(String currentUserId) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Text('У вас пока нет сообщений'),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants =
                  List<String>.from(chat['participants'] ?? []);
              final participantNames =
                  Map<String, String>.from(chat['participantNames'] ?? {});

              final otherParticipant = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => participants.first,
              );

              final otherParticipantName = participantNames[otherParticipant] ??
                  'Неизвестный пользователь';

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(otherParticipantName),
                subtitle: Text(chat['lastMessageContent'] ?? 'Нет сообщений'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => ChatScreen(
                        chatId: chat['id'],
                        otherParticipantId: otherParticipant,
                        otherParticipantName: otherParticipantName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
}
