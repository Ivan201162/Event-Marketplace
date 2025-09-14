import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/chat_widgets.dart';
import '../models/chat.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Чаты'),
            Tab(icon: Icon(Icons.notifications), text: 'Уведомления'),
          ],
        ),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Необходима авторизация',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChatsTab(user.id, user.isSpecialist),
              _buildNotificationsTab(user.id),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Вкладка чатов
  Widget _buildChatsTab(String userId, bool isSpecialist) {
    return Column(
      children: [
        // Поиск и фильтры
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск чатов...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showCreateChatDialog(context, userId, isSpecialist),
                icon: const Icon(Icons.add),
                tooltip: 'Создать чат',
              ),
            ],
          ),
        ),
        
        // Список чатов
        Expanded(
          child: ChatListWidget(
            userId: userId,
            isSpecialist: isSpecialist,
            onChatSelected: (chat) => _openChat(context, chat, userId),
          ),
        ),
      ],
    );
  }

  /// Вкладка уведомлений
  Widget _buildNotificationsTab(String userId) {
    final notificationsAsync = ref.watch(userNotificationsProvider(UserNotificationsParams(
      userId: userId,
      limit: 100,
    )));

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет уведомлений',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Уведомления появятся при активности',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Действия с уведомлениями
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAllAsRead(userId),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Отметить все как прочитанные'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _showNotificationSettings(context),
                    icon: const Icon(Icons.settings),
                    tooltip: 'Настройки уведомлений',
                  ),
                ],
              ),
            ),
            
            // Список уведомлений
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationWidget(
                    notification: notification,
                    onTap: () => _handleNotificationTap(context, notification),
                    onDismiss: () => _dismissNotification(notification.id),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки уведомлений: $error'),
          ],
        ),
      ),
    );
  }

  /// Открыть чат
  void _openChat(BuildContext context, Chat chat, String currentUserId) {
    final otherUserId = chat.specialistId == currentUserId ? chat.customerId : chat.specialistId;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chat: chat,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  /// Показать диалог создания чата
  void _showCreateChatDialog(BuildContext context, String userId, bool isSpecialist) {
    final otherUserIdController = TextEditingController();
    final bookingIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать чат'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: otherUserIdController,
              decoration: InputDecoration(
                labelText: isSpecialist ? 'ID клиента' : 'ID специалиста',
                hintText: 'Введите ID пользователя',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bookingIdController,
              decoration: const InputDecoration(
                labelText: 'ID заявки (необязательно)',
                hintText: 'Связать с заявкой',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final otherUserId = otherUserIdController.text.trim();
              final bookingId = bookingIdController.text.trim().isEmpty 
                  ? null 
                  : bookingIdController.text.trim();

              if (otherUserId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите ID пользователя')),
                );
                return;
              }

              try {
                final chat = await ref.read(chatStateProvider.notifier).createChat(
                  customerId: isSpecialist ? otherUserId : userId,
                  specialistId: isSpecialist ? userId : otherUserId,
                  bookingId: bookingId,
                );

                if (context.mounted && chat != null) {
                  Navigator.of(context).pop();
                  _openChat(context, chat, userId);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка создания чата: $e')),
                  );
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  /// Отметить все уведомления как прочитанные
  void _markAllAsRead(String userId) {
    ref.read(notificationStateProvider.notifier).markAllAsRead(userId);
  }

  /// Показать настройки уведомлений
  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки уведомлений'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Push-уведомления'),
              subtitle: Text('Получать уведомления на устройство'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              title: Text('Email-уведомления'),
              subtitle: Text('Получать уведомления на email'),
              trailing: Switch(value: false, onChanged: null),
            ),
            ListTile(
              title: Text('Звуковые уведомления'),
              subtitle: Text('Воспроизводить звук при получении'),
              trailing: Switch(value: true, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Обработать нажатие на уведомление
  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    // Отмечаем как прочитанное
    ref.read(notificationStateProvider.notifier).markAsRead(notification.id);

    // Переходим по ссылке, если есть
    if (notification.actionUrl != null) {
      // TODO: Реализовать навигацию по URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Переход к: ${notification.actionUrl}')),
      );
    }
  }

  /// Скрыть уведомление
  void _dismissNotification(String notificationId) {
    ref.read(notificationStateProvider.notifier).archiveNotification(notificationId);
  }
}

/// Экран детального чата
class ChatDetailScreen extends ConsumerStatefulWidget {
  final Chat chat;
  final String currentUserId;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Отмечаем сообщения как прочитанные при открытии чата
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatStateProvider.notifier).markMessagesAsRead(
        widget.chat.id,
        widget.currentUserId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат с пользователем ${widget.otherUserId}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showChatInfo(context),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Информация о чате',
          ),
        ],
      ),
      body: Column(
        children: [
          // Сообщения
          Expanded(
            child: ChatMessagesWidget(
              chatId: widget.chat.id,
              currentUserId: widget.currentUserId,
              otherUserId: widget.otherUserId,
            ),
          ),
          
          // Ввод сообщения
          MessageInputWidget(
            chatId: widget.chat.id,
            senderId: widget.currentUserId,
            receiverId: widget.otherUserId,
          ),
        ],
      ),
    );
  }

  /// Показать информацию о чате
  void _showChatInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о чате'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ID чата', widget.chat.id),
            _buildInfoRow('Клиент', widget.chat.customerId),
            _buildInfoRow('Специалист', widget.chat.specialistId),
            if (widget.chat.bookingId != null)
              _buildInfoRow('Заявка', widget.chat.bookingId!),
            _buildInfoRow('Создан', _formatDate(widget.chat.createdAt)),
            _buildInfoRow('Обновлен', _formatDate(widget.chat.updatedAt)),
            _buildInfoRow('Непрочитанных', widget.chat.unreadCount.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Построить строку информации
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
