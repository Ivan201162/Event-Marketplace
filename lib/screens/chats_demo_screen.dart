import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/screens/chat_extended_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Демо экран для показа расширенного чата
class ChatsDemoScreen extends ConsumerWidget {
  const ChatsDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: CustomScrollView(
          slivers: [
            // Современный AppBar с градиентом
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Чаты',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white,),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                      gradient: BrandColors.primaryGradient,),
                  child: SafeArea(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 40, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Чаты',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () => _showNewChatDialog(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Основной контент
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Заголовок с описанием новых функций
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.record_voice_over,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Новые возможности чата',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '• Голосовые сообщения с визуализацией\n'
                              '• Реакции на сообщения (эмодзи)\n'
                              '• Улучшенный интерфейс чата\n'
                              '• Статистика и аналитика',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Список чатов
                    _buildChatList(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildChatList(BuildContext context) {
    final demoChats = [
      {
        'name': 'Анна Петрова',
        'avatar': null,
        'lastMessage': '🎤 Голосовое сообщение',
        'time': '14:30',
        'unread': 2,
        'isVoice': true,
      },
      {
        'name': 'Михаил Иванов',
        'avatar': null,
        'lastMessage': '👍 Отлично! Спасибо за работу',
        'time': '12:15',
        'unread': 0,
        'isVoice': false,
      },
      {
        'name': 'Елена Смирнова',
        'avatar': null,
        'lastMessage': '🎤 Голосовое сообщение',
        'time': '10:45',
        'unread': 1,
        'isVoice': true,
      },
      {
        'name': 'Дмитрий Козлов',
        'avatar': null,
        'lastMessage': '🔥 Превосходно!',
        'time': '09:20',
        'unread': 0,
        'isVoice': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Недавние чаты',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
        const SizedBox(height: 8),
        ...demoChats.map((chat) => _buildChatItem(context, chat)),
      ],
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Text(
              chat['name'][0].toUpperCase(),
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,),
            ),
          ),
          title: Text(chat['name'],
              style: const TextStyle(fontWeight: FontWeight.w500),),
          subtitle: Row(
            children: [
              if (chat['isVoice'])
                const Icon(Icons.mic, size: 16, color: Colors.grey),
              if (chat['isVoice']) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  chat['lastMessage'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(chat['time'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),),
              if (chat['unread'] > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    chat['unread'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _openChat(context, chat),
        ),
      );

  void _openChat(BuildContext context, Map<String, dynamic> chat) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatExtendedScreen(
          chatId: 'demo_chat_${chat['name'].hashCode}',
          currentUserId: 'current_user',
          currentUserName: 'Вы',
          otherUserName: chat['name'],
          otherUserAvatar: chat['avatar'],
        ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый чат'),
        content: const Text(
            'Функция создания нового чата будет добавлена в следующих версиях.',),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'),),
        ],
      ),
    );
  }
}
