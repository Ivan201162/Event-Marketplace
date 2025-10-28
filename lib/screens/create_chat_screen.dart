import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateChatScreen extends ConsumerStatefulWidget {
  const CreateChatScreen({super.key});

  @override
  ConsumerState<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends ConsumerState<CreateChatScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем список всех пользователей (в реальном приложении это будет запрос к API)
      _allUsers = [
        {
          'id': 'user1',
          'name': 'Анна Петрова',
          'email': 'anna.petrova@email.com',
          'avatar': null,
          'isSpecialist': false,
        },
        {
          'id': 'user2',
          'name': 'Михаил Сидоров',
          'email': 'mikhail.sidorov@company.com',
          'avatar': null,
          'isSpecialist': false,
        },
        {
          'id': 'user3',
          'name': 'Елена Козлова',
          'email': 'elena.kozlova@email.com',
          'avatar': null,
          'isSpecialist': false,
        },
        {
          'id': 'user4',
          'name': 'Дмитрий Волков',
          'email': 'dmitry.volkov@company.com',
          'avatar': null,
          'isSpecialist': false,
        },
        {
          'id': 'specialist1',
          'name': 'Александр Иванов',
          'email': 'alexander.ivanov@specialist.com',
          'avatar': null,
          'isSpecialist': true,
          'category': 'Свадьбы и корпоративы',
        },
        {
          'id': 'specialist2',
          'name': 'Мария Смирнова',
          'email': 'maria.smirnova@specialist.com',
          'avatar': null,
          'isSpecialist': true,
          'category': 'Детские праздники',
        },
        {
          'id': 'specialist3',
          'name': 'Дмитрий Петров',
          'email': 'dmitry.petrov@specialist.com',
          'avatar': null,
          'isSpecialist': true,
          'category': 'Банкеты и фуршеты',
        },
      ];

      _searchResults = _allUsers;
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка загрузки пользователей: $e'),
              backgroundColor: Colors.red,),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _searchResults = _allUsers;
      } else {
        _searchResults = _allUsers
            .where(
              (user) =>
                  user['name'].toLowerCase().contains(query.toLowerCase()) ||
                  user['email'].toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _createChat(Map<String, dynamic> user) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      if (currentUser.uid == user['id']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нельзя создать чат с самим собой'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Проверяем, существует ли уже чат между этими пользователями
      final existingChats = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (final chatDoc in existingChats.docs) {
        final chatData = chatDoc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        if (participants.contains(user['id'])) {
          // Чат уже существует, переходим к нему
          if (mounted) {
            context.pop();
            context.push(
              '/chat',
              extra: {
                'chatId': chatDoc.id,
                'otherParticipantId': user['id'],
                'otherParticipantName': user['name'],
              },
            );
          }
          return;
        }
      }

      // Создаем новый чат
      final chatData = {
        'participants': [currentUser.uid, user['id']],
        'participantNames': {
          currentUser.uid: currentUser.displayName ?? 'Пользователь',
          user['id']: user['name'],
        },
        'lastMessageContent': 'Чат создан',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final chatDoc =
          await FirebaseFirestore.instance.collection('chats').add(chatData);

      // Добавляем первое сообщение
      await chatDoc.collection('messages').add({
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Пользователь',
        'type': 'text',
        'content': 'Чат создан',
        'status': 'sent',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(
            content: Text('Чат создан!'), backgroundColor: Colors.green,),);
        context.pop();
        context.push(
          '/chat',
          extra: {
            'chatId': chatDoc.id,
            'otherParticipantId': user['id'],
            'otherParticipantName': user['name'],
          },
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка создания чата: $e'),
              backgroundColor: Colors.red,),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать чат'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),),
        ),
        body: Column(
          children: [
            // Поиск
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск пользователей...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                      : null,
                ),
                onChanged: _searchUsers,
              ),
            ),

            // Список пользователей
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off,
                                  size: 64, color: Colors.grey,),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Нет пользователей'
                                    : 'Пользователи не найдены',
                                style: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Попробуйте изменить поисковый запрос',
                                  style: Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return _buildUserTile(user);
                          },
                        ),
            ),
          ],
        ),
      );

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isSpecialist = user['isSpecialist'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSpecialist ? Colors.blue : Colors.green,
          child: Text(
            user['name'][0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold,),
          ),
        ),
        title: Text(user['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']),
            if (isSpecialist && user['category'] != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  user['category'],
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () => _createChat(user),
          tooltip: 'Создать чат',
        ),
        onTap: () => _createChat(user),
      ),
    );
  }
}
