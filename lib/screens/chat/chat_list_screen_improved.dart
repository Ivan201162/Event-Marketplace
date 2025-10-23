import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/chat.dart';
import '../../providers/chat_providers.dart';

/// Улучшенный экран списка чатов
class ChatListScreenImproved extends ConsumerStatefulWidget {
  const ChatListScreenImproved({super.key});

  @override
  ConsumerState<ChatListScreenImproved> createState() => _ChatListScreenImprovedState();
}

class _ChatListScreenImprovedState extends ConsumerState<ChatListScreenImproved> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(filteredChatsProvider);
    final totalUnread = ref.watch(totalUnreadCountProvider).value ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Чаты',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (totalUnread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // TODO: Navigate to new chat
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Основной контент
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Поиск
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            ref.read(chatSearchProvider.notifier).setSearchQuery(value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Поиск в чатах...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(chatSearchProvider.notifier).clearSearch();
                                    },
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      
                      // Список чатов
                      Expanded(
                        child: chats.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: chats.length,
                                itemBuilder: (context, index) {
                                  final chat = chats[index];
                                  return _ChatListItem(chat: chat);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          const Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет чатов',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Начните общение с другими пользователями',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to new chat
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Начать чат'),
          ),
        ],
      ),
    );
  }
}

/// Элемент списка чатов
class _ChatListItem extends ConsumerWidget {
  final Chat chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final unreadCount = chat.getUnreadCount(user.uid);
    final chatWithUser = ref.watch(chatWithUserProvider(chat.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(selectedChatProvider.notifier).selectChat(chat.id);
            context.go('/chat/${chat.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: chatWithUser.when(
                        data: (userData) => userData?['avatarUrl'] != null
                            ? NetworkImage(userData!['avatarUrl'])
                            : null,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                      child: chatWithUser.when(
                        data: (userData) => userData?['avatarUrl'] == null
                            ? const Icon(Icons.person, size: 28)
                            : null,
                        loading: () => const CircularProgressIndicator(strokeWidth: 2),
                        error: (_, __) => const Icon(Icons.person, size: 28),
                      ),
                    ),
                    // Индикатор онлайн статуса
                    if (chatWithUser.value?['isOnline'] == true)
                      Positioned(
                        bottom: 0,
                        right: 0,
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
                
                const SizedBox(width: 16),
                
                // Информация о чате
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название чата и время
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chatWithUser.when(
                                data: (userData) => userData?['name'] ?? chat.name,
                                loading: () => chat.name,
                                error: (_, __) => chat.name,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            chat.formattedLastMessageTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Последнее сообщение
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessageContent ?? 'Нет сообщений',
                              style: TextStyle(
                                fontSize: 14,
                                color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
