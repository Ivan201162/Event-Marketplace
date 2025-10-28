import 'package:event_marketplace_app/screens/enhanced_chat_screen.dart';
import 'package:event_marketplace_app/screens/enhanced_chats_list_screen.dart';
import 'package:event_marketplace_app/services/chat_service.dart';
import 'package:event_marketplace_app/services/media_upload_service.dart';
import 'package:event_marketplace_app/services/typing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран для тестирования функций чатов
class ChatTestingScreen extends ConsumerStatefulWidget {
  const ChatTestingScreen({super.key});

  @override
  ConsumerState<ChatTestingScreen> createState() => _ChatTestingScreenState();
}

class _ChatTestingScreenState extends ConsumerState<ChatTestingScreen> {
  final ChatService _chatService = ChatService();
  final TypingService _typingService = TypingService();

  String? _testChatId;
  String? _currentUserId;
  String? _currentUserName;
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserName = 'Тестовый пользователь';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тестирование чатов'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTestResults(),
              const SizedBox(height: 20),
              _buildTestButtons(),
              const SizedBox(height: 20),
              _buildNavigationButtons(),
            ],
          ),
        ),
      );

  Widget _buildTestResults() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Результаты тестирования:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_testResults.isEmpty)
                const Text('Тесты еще не запущены')
              else
                ..._testResults.map(
                  (result) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $result'),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildTestButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Тесты функций:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _testCreateChat,
              child: const Text('1. Создать тестовый чат'),),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _testSendTextMessage,
            child: const Text('2. Отправить текстовое сообщение'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _testSendFileMessage,
            child: const Text('3. Отправить сообщение с файлом'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _testTypingIndicator,
            child: const Text('4. Тест индикатора печатания'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _testUnreadMessages,
            child: const Text('5. Тест непрочитанных сообщений'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _testMessageDeletion,
            child: const Text('6. Тест удаления сообщений'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _testChatCategories,
              child: const Text('7. Тест категорий чатов'),),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _testAutoUpdate,
              child: const Text('8. Тест автообновления'),),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _testPushNotifications,
            child: const Text('9. Тест push-уведомлений'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _testFirebaseStorage,
            child: const Text('10. Тест Firebase Storage'),
          ),
        ],
      );

  Widget _buildNavigationButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Навигация:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(
                  builder: (context) => const EnhancedChatsListScreen(),),);
            },
            child: const Text('Открыть список чатов'),
          ),
          const SizedBox(height: 8),
          if (_testChatId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        EnhancedChatScreen(chatId: _testChatId!),
                  ),
                );
              },
              child: const Text('Открыть тестовый чат'),
            ),
        ],
      );

  void _addTestResult(String result) {
    setState(() {
      _testResults
          .add('${DateTime.now().toString().substring(11, 19)}: $result');
    });
  }

  Future<void> _testCreateChat() async {
    try {
      _addTestResult('Запуск теста создания чата...');

      final chatId = await _chatService.createChatWithCategory(
        name: 'Тестовый чат',
        participants: [_currentUserId!, 'other_user_id'],
        participantNames: {
          _currentUserId!: _currentUserName!,
          'other_user_id': 'Другой пользователь',
        },
        participantAvatars: {},
        category: 'test',
        description: 'Чат для тестирования функций',
        createdBy: _currentUserId!,
      );

      _testChatId = chatId;
      _addTestResult('✅ Чат создан успешно. ID: $chatId');
    } catch (e) {
      _addTestResult('❌ Ошибка создания чата: $e');
    }
  }

  Future<void> _testSendTextMessage() async {
    if (_testChatId == null) {
      _addTestResult('❌ Сначала создайте тестовый чат');
      return;
    }

    try {
      _addTestResult('Запуск теста отправки текстового сообщения...');

      final message = ChatMessage(
        id: '',
        chatId: _testChatId!,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        type: MessageType.text,
        content: 'Тестовое сообщение ${DateTime.now().millisecondsSinceEpoch}',
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      );

      await _chatService.sendMessage(_testChatId!, message);
      _addTestResult('✅ Текстовое сообщение отправлено успешно');
    } catch (e) {
      _addTestResult('❌ Ошибка отправки текстового сообщения: $e');
    }
  }

  Future<void> _testSendFileMessage() async {
    if (_testChatId == null) {
      _addTestResult('❌ Сначала создайте тестовый чат');
      return;
    }

    try {
      _addTestResult('Запуск теста отправки файла...');

      // Создаем тестовый файл
      final testFileContent = 'Тестовое содержимое файла ${DateTime.now()}';
      final testFileBytes = testFileContent.codeUnits;

      final fileUrl = await _chatService.uploadFile(
        chatId: _testChatId!,
        senderId: _currentUserId!,
        fileData: testFileBytes,
        fileName: 'test_file.txt',
        fileType: 'text/plain',
      );

      await _chatService.sendMessageWithFile(
        chatId: _testChatId!,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        content: 'Тестовый файл',
        fileUrl: fileUrl,
        fileType: 'text/plain',
        fileName: 'test_file.txt',
        fileSize: testFileBytes.length,
      );

      _addTestResult('✅ Файл отправлен успешно. URL: $fileUrl');
    } catch (e) {
      _addTestResult('❌ Ошибка отправки файла: $e');
    }
  }

  Future<void> _testTypingIndicator() async {
    if (_testChatId == null) {
      _addTestResult('❌ Сначала создайте тестовый чат');
      return;
    }

    try {
      _addTestResult('Запуск теста индикатора печатания...');

      // Начинаем печатание
      await _typingService.startTyping(
        chatId: _testChatId!,
        userId: _currentUserId!,
        userName: _currentUserName!,
      );

      _addTestResult('✅ Индикатор печатания запущен');

      // Останавливаем через 3 секунды
      await Future.delayed(const Duration(seconds: 3));
      await _typingService.stopTyping(
          chatId: _testChatId!, userId: _currentUserId!,);

      _addTestResult('✅ Индикатор печатания остановлен');
    } catch (e) {
      _addTestResult('❌ Ошибка теста индикатора печатания: $e');
    }
  }

  Future<void> _testUnreadMessages() async {
    if (_testChatId == null) {
      _addTestResult('❌ Сначала создайте тестовый чат');
      return;
    }

    try {
      _addTestResult('Запуск теста непрочитанных сообщений...');

      final unreadCount = _chatService.getUnreadMessagesCount(_currentUserId!);
      _addTestResult('✅ Количество непрочитанных сообщений: $unreadCount');

      // Тестируем поток непрочитанных сообщений
      final stream = _chatService.getUnreadMessagesCountStream(_currentUserId!);
      stream.take(1).listen((count) {
        _addTestResult(
            '✅ Поток непрочитанных сообщений работает. Количество: $count',);
      });
    } catch (e) {
      _addTestResult('❌ Ошибка теста непрочитанных сообщений: $e');
    }
  }

  Future<void> _testMessageDeletion() async {
    if (_testChatId == null) {
      _addTestResult('❌ Сначала создайте тестовый чат');
      return;
    }

    try {
      _addTestResult('Запуск теста удаления сообщений...');

      // Сначала отправляем сообщение
      final message = ChatMessage(
        id: '',
        chatId: _testChatId!,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        type: MessageType.text,
        content: 'Сообщение для удаления',
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      );

      await _chatService.sendMessage(_testChatId!, message);
      _addTestResult('✅ Тестовое сообщение отправлено');

      // TODO(developer): Получить ID сообщения и удалить его
      _addTestResult('⚠️ Удаление сообщения требует получения ID из Firestore');
    } catch (e) {
      _addTestResult('❌ Ошибка теста удаления сообщений: $e');
    }
  }

  Future<void> _testChatCategories() async {
    try {
      _addTestResult('Запуск теста категорий чатов...');

      // Создаем чаты разных категорий
      final ordersChatId = await _chatService.createChatWithCategory(
        name: 'Чат с заказом',
        participants: [_currentUserId!, 'organizer_id'],
        participantNames: {
          _currentUserId!: _currentUserName!,
          'organizer_id': 'Организатор',
        },
        participantAvatars: {},
        category: 'orders',
        createdBy: _currentUserId!,
      );

      final specialistsChatId = await _chatService.createChatWithCategory(
        name: 'Чат с исполнителем',
        participants: [_currentUserId!, 'specialist_id'],
        participantNames: {
          _currentUserId!: _currentUserName!,
          'specialist_id': 'Исполнитель',
        },
        participantAvatars: {},
        category: 'specialists',
        createdBy: _currentUserId!,
      );

      // Получаем чаты по категориям
      final ordersChats =
          await _chatService.getChatsByCategory(_currentUserId!, 'orders');
      final specialistsChats = await _chatService.getChatsByCategory(
        _currentUserId!,
        'specialists',
      );

      _addTestResult('✅ Чат с заказом создан. ID: $ordersChatId');
      _addTestResult('✅ Чат с исполнителем создан. ID: $specialistsChatId');
      _addTestResult(
        '✅ Чаты по категориям: заказы=${ordersChats.length}, исполнители=${specialistsChats.length}',
      );
    } catch (e) {
      _addTestResult('❌ Ошибка теста категорий чатов: $e');
    }
  }

  Future<void> _testAutoUpdate() async {
    if (_testChatId == null) {
      _addTestResult('❌ Сначала создайте тестовый чат');
      return;
    }

    try {
      _addTestResult('Запуск теста автообновления...');

      // Тестируем поток сообщений
      final messagesStream = _chatService.getChatMessages(_testChatId!);
      messagesStream.take(1).listen((messages) {
        _addTestResult(
            '✅ Поток сообщений работает. Сообщений: ${messages.length}',);
      });

      // Тестируем поток чата
      final chatStream = _chatService.getChat(_testChatId!);
      chatStream.take(1).listen((chat) {
        if (chat != null) {
          _addTestResult('✅ Поток чата работает. Название: ${chat.name}');
        }
      });

      _addTestResult('✅ Потоки автообновления настроены');
    } catch (e) {
      _addTestResult('❌ Ошибка теста автообновления: $e');
    }
  }

  Future<void> _testPushNotifications() async {
    try {
      _addTestResult('Запуск теста push-уведомлений...');

      // TODO(developer): Реализовать тест FCM уведомлений
      _addTestResult('⚠️ Тест push-уведомлений требует настройки FCM');
    } catch (e) {
      _addTestResult('❌ Ошибка теста push-уведомлений: $e');
    }
  }

  Future<void> _testFirebaseStorage() async {
    try {
      _addTestResult('Запуск теста Firebase Storage...');

      // Тестируем загрузку файла
      const testContent = 'Тестовое содержимое для Firebase Storage';
      final testBytes = testContent.codeUnits;

      final fileUrl = await _chatService.uploadFile(
        chatId: 'test_storage',
        senderId: _currentUserId!,
        fileData: testBytes,
        fileName: 'storage_test.txt',
        fileType: 'text/plain',
      );

      _addTestResult('✅ Файл загружен в Firebase Storage. URL: $fileUrl');
    } catch (e) {
      _addTestResult('❌ Ошибка теста Firebase Storage: $e');
    }
  }
}
