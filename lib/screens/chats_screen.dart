import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/test_data_service.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final TestDataService _testDataService = TestDataService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем тестовые чаты
      final testChats = [
        {
          'id': 'chat_1',
          'otherParticipantId': 'specialist_1',
          'otherParticipantName': 'Алексей Смирнов',
          'otherParticipantAvatar': 'https://picsum.photos/200?random=1',
          'lastMessage': 'Здравствуйте! Интересует свадьба 10 октября?',
          'lastMessageTime':
              DateTime.now().subtract(const Duration(minutes: 15)),
          'unreadCount': 2,
          'isOnline': true,
        },
        {
          'id': 'chat_2',
          'otherParticipantId': 'specialist_2',
          'otherParticipantName': 'Анна Лебедева',
          'otherParticipantAvatar': 'https://picsum.photos/200?random=2',
          'lastMessage': 'Отлично! Жду вашего ответа по поводу времени',
          'lastMessageTime': DateTime.now().subtract(const Duration(hours: 1)),
          'unreadCount': 0,
          'isOnline': false,
        },
        {
          'id': 'chat_3',
          'otherParticipantId': 'specialist_3',
          'otherParticipantName': 'Михаил Петров',
          'otherParticipantAvatar': 'https://picsum.photos/200?random=3',
          'lastMessage': 'Спасибо за заказ! До встречи на мероприятии',
          'lastMessageTime': DateTime.now().subtract(const Duration(days: 1)),
          'unreadCount': 0,
          'isOnline': true,
        },
        {
          'id': 'chat_4',
          'otherParticipantId': 'specialist_4',
          'otherParticipantName': 'Елена Козлова',
          'otherParticipantAvatar': 'https://picsum.photos/200?random=4',
          'lastMessage': 'Можем обсудить детали по телефону',
          'lastMessageTime': DateTime.now().subtract(const Duration(days: 2)),
          'unreadCount': 1,
          'isOnline': false,
        },
        {
          'id': 'chat_5',
          'otherParticipantId': 'specialist_5',
          'otherParticipantName': 'Дмитрий Волков',
          'otherParticipantAvatar': 'https://picsum.photos/200?random=5',
          'lastMessage': 'Портфолио отправлено на вашу почту',
          'lastMessageTime': DateTime.now().subtract(const Duration(days: 3)),
          'unreadCount': 0,
          'isOnline': true,
        },
      ];

      setState(() {
        _chats = testChats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки чатов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Сообщения'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Поиск в сообщениях')),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Нет сообщений',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final isUnread = chat['unreadCount'] > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                    chat['otherParticipantAvatar']),
                                radius: 24,
                              ),
                              if (chat['isOnline'])
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            chat['otherParticipantName'],
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            chat['lastMessage'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(chat['lastMessageTime']),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (isUnread)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Text(
                                    '${chat['unreadCount']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            context.push(
                              '/chat/${chat['id']}',
                              extra: {
                                'otherParticipantId':
                                    chat['otherParticipantId'],
                                'otherParticipantName':
                                    chat['otherParticipantName'],
                                'otherParticipantAvatar':
                                    chat['otherParticipantAvatar'],
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
      );

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
}

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key, required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(userName),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Меню чата')),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Сообщения
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 10, // Заглушка
                itemBuilder: (context, index) {
                  final isMe = index % 2 == 0;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Сообщение ${index + 1} от ${isMe ? "меня" : userName}",
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Поле ввода
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Введите сообщение...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Отправка сообщения')),
                      );
                    },
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
