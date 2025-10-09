import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../providers/auth_providers.dart';
import '../services/event_ideas_service.dart';

class ShareIdeaScreen extends ConsumerStatefulWidget {
  const ShareIdeaScreen({super.key, required this.idea});
  final EventIdea idea;

  @override
  ConsumerState<ShareIdeaScreen> createState() => _ShareIdeaScreenState();
}

class _ShareIdeaScreenState extends ConsumerState<ShareIdeaScreen> {
  final EventIdeasService _ideasService = EventIdeasService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поделиться идеей'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Войдите в аккаунт, чтобы поделиться идеей'),
            );
          }

          return Column(
            children: [
              // Превью идеи
              _buildIdeaPreview(),

              // Список чатов
              Expanded(
                child: _buildChatsList(user.id),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  Widget _buildIdeaPreview() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Превью медиа
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.idea.mediaUrl?.isNotEmpty ?? false
                    ? widget.idea.isVideo ?? false
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                widget.idea.mediaUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.video_library),
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          )
                        : Image.network(
                            widget.idea.mediaUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                          )
                    : Icon(
                        widget.idea.isVideo ?? false
                            ? Icons.video_library
                            : Icons.image,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Информация об идее
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.idea.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.idea.authorName ?? 'Неизвестный',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.idea.category ?? 'Без категории',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildChatsList(String currentUserId) => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка загрузки чатов: ${snapshot.error}'),
            );
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет чатов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Начните общение с другими пользователями',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data()! as Map<String, dynamic>;
              final chatId = chats[index].id;

              // Найти собеседника
              final participants =
                  List<String>.from(chat['participants'] ?? []);
              final otherParticipantId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              return _buildChatItem(chatId, otherParticipantId, chat);
            },
          );
        },
      );

  Widget _buildChatItem(String chatId, String otherParticipantId,
          Map<String, dynamic> chat) =>
      FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(otherParticipantId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Загрузка...'),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final userName = userData?['name'] ?? 'Пользователь';
          final userAvatar = userData?['avatar'];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  userAvatar != null ? NetworkImage(userAvatar) : null,
              child: userAvatar == null ? const Icon(Icons.person) : null,
            ),
            title: Text(userName),
            subtitle: Text(
              chat['lastMessage'] ?? 'Нет сообщений',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () =>
                        _shareToChat(chatId, otherParticipantId, userName),
                  ),
            onTap: () => _shareToChat(chatId, otherParticipantId, userName),
          );
        },
      );

  Future<void> _shareToChat(String chatId, String otherParticipantId,
      String otherParticipantName) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // Создать сообщение с идеей
      final messageData = {
        'type': 'idea_share',
        'content': 'Поделился идеей: ${widget.idea.title}',
        'senderId': currentUser.id,
        'senderName': currentUser.name ?? 'Пользователь',
        'senderAvatar': currentUser.avatar,
        'timestamp': FieldValue.serverTimestamp(),
        'ideaId': widget.idea.id,
        'ideaTitle': widget.idea.title,
        'ideaDescription': widget.idea.description,
        'ideaCategory': widget.idea.category,
        'ideaMediaUrl': widget.idea.mediaUrl,
        'ideaIsVideo': widget.idea.isVideo,
        'ideaAuthorName': widget.idea.authorName,
        'ideaAuthorAvatar': widget.idea.authorAvatar,
      };

      // Добавить сообщение в чат
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Обновить информацию о чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': 'Поделился идеей: ${widget.idea.title}',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.id,
      });

      // Увеличить счетчик репостов идеи
      // await _ideasService.shareIdea(widget.idea.id, currentUser.id);

      // Показать уведомление
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Идея отправлена в чат с $otherParticipantName'),
          action: SnackBarAction(
            label: 'Открыть чат',
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Открыть чат
            },
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }
}
