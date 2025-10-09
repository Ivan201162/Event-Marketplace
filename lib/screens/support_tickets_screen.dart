import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';
import '../widgets/support_ticket_widget.dart';
import 'create_support_ticket_screen.dart';
import 'support_ticket_detail_screen.dart';

/// Экран тикетов поддержки
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  final SupportService _supportService = SupportService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Поддержка'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createTicket,
            ),
          ],
        ),
        body: Column(
          children: [
            // Быстрые действия
            _buildQuickActions(),

            // Список тикетов
            Expanded(
              child: _buildTicketsList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createTicket,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildQuickActions() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.add,
                title: 'Создать тикет',
                color: Colors.blue,
                onTap: _createTicket,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.help_outline,
                title: 'FAQ',
                color: Colors.green,
                onTap: _showFAQ,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.phone,
                title: 'Связаться',
                color: Colors.orange,
                onTap: _contactSupport,
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTicketsList() => StreamBuilder<List<SupportTicket>>(
        stream: _supportService.getUserTickets(
          'demo_user_id',
        ), // TODO(developer): Получить из контекста
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return SupportTicketWidget(
                ticket: ticket,
                onTap: () => _showTicketDetail(ticket),
              );
            },
          );
        },
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет тикетов поддержки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте тикет для получения помощи',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createTicket,
              icon: const Icon(Icons.add),
              label: const Text('Создать тикет'),
            ),
          ],
        ),
      );

  void _createTicket() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => const CreateSupportTicketScreen(),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showTicketDetail(SupportTicket ticket) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => SupportTicketDetailScreen(
          ticket: ticket,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showFAQ() {
    // TODO(developer): Реализовать экран FAQ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAQ пока не реализован')),
    );
  }

  void _contactSupport() {
    // TODO(developer): Реализовать контакты поддержки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Контакты поддержки пока не реализованы')),
    );
  }
}

/// Экран детального просмотра тикета
class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({
    super.key,
    required this.ticket,
  });
  final SupportTicket ticket;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final SupportService _supportService = SupportService();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Тикет #${widget.ticket.id.substring(0, 8)}'),
          actions: [
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'close',
                  child: ListTile(
                    leading: Icon(Icons.close),
                    title: Text('Закрыть тикет'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Информация о тикете
            _buildTicketInfo(),

            // Сообщения
            Expanded(
              child: _buildMessagesList(),
            ),

            // Поле ввода сообщения
            _buildMessageInput(),
          ],
        ),
      );

  Widget _buildTicketInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и статус
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.ticket.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.ticket.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.ticket.statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    widget.ticket.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.ticket.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Категория и приоритет
            Row(
              children: [
                Icon(
                  widget.ticket.categoryIcon,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  widget.ticket.categoryText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.ticket.priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.ticket.priorityText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Дата создания
            Text(
              'Создан: ${_formatDate(widget.ticket.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildMessagesList() => StreamBuilder<List<SupportMessage>>(
        stream: _supportService.getTicketMessages(widget.ticket.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка загрузки сообщений: ${snapshot.error}'),
            );
          }

          final messages = snapshot.data ?? [];
          if (messages.isEmpty) {
            return const Center(
              child: Text('Нет сообщений'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageBubble(message);
            },
          );
        },
      );

  Widget _buildMessageBubble(SupportMessage message) {
    final isFromSupport = message.isFromSupport;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromSupport ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isFromSupport) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromSupport ? Colors.grey[200] : Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFromSupport) ...[
                    Text(
                      message.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isFromSupport) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Введите сообщение...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await _supportService.addMessage(
        ticketId: widget.ticket.id,
        authorId: 'demo_user_id', // TODO(developer): Получить из контекста
        authorName: 'Пользователь',
        authorEmail: 'user@example.com',
        content: content,
        isFromSupport: false,
      );

      _messageController.clear();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки сообщения: $e')),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'close':
        _closeTicket();
        break;
    }
  }

  void _closeTicket() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Закрыть тикет'),
        content: const Text('Вы уверены, что хотите закрыть этот тикет?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _supportService.updateTicketStatus(
                widget.ticket.id,
                SupportStatus.closed,
              );
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
