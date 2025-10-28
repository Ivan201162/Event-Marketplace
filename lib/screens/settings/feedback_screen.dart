import 'package:event_marketplace_app/models/feedback_ticket.dart';
import 'package:event_marketplace_app/services/feedback_service.dart';
import 'package:event_marketplace_app/widgets/common/custom_app_bar.dart';
import 'package:event_marketplace_app/widgets/common/loading_overlay.dart';
import 'package:flutter/material.dart';

/// Экран обратной связи
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackService = FeedbackService();

  List<FeedbackTicket> _tickets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  /// Загрузить тикеты обратной связи
  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    try {
      final tickets = await _feedbackService.getUserTickets();
      setState(() => _tickets = tickets);
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки тикетов: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Создать новый тикет
  Future<void> _createTicket() async {
    final result = await Navigator.of(context).push<FeedbackTicket>(
      MaterialPageRoute(
        builder: (context) => const CreateTicketScreen(),
      ),
    );

    if (result != null) {
      _loadTickets();
    }
  }

  /// Просмотреть тикет
  Future<void> _viewTicket(FeedbackTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailsScreen(ticket: ticket),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Обратная связь'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Кнопка создания тикета
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createTicket,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать обращение'),
                ),
              ),
            ),

            // Список тикетов
            Expanded(
              child: _tickets.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return _buildTicketCard(ticket);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Обращений пока нет',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Создайте обращение, если у вас есть вопросы или предложения',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(FeedbackTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(ticket.status),
          child: Icon(
            _getStatusIcon(ticket.status),
            color: Colors.white,
          ),
        ),
        title: Text(ticket.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тикет #${ticket.id}'),
            const SizedBox(height: 4),
            Text(
              'Создан ${_formatDate(ticket.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getStatusText(ticket.status),
              style: TextStyle(
                color: _getStatusColor(ticket.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _viewTicket(ticket),
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Icons.fiber_new;
      case TicketStatus.inProgress:
        return Icons.hourglass_empty;
      case TicketStatus.resolved:
        return Icons.check;
      case TicketStatus.closed:
        return Icons.close;
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Открыт';
      case TicketStatus.inProgress:
        return 'В работе';
      case TicketStatus.resolved:
        return 'Решен';
      case TicketStatus.closed:
        return 'Закрыт';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}

/// Экран создания тикета
class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TicketCategory _selectedCategory = TicketCategory.bug;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Создать тикет
  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ticket = FeedbackTicket(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        status: TicketStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachments: [],
      );

      await FeedbackService().createTicket(ticket);

      Navigator.of(context).pop(ticket);
    } catch (e) {
      _showErrorSnackBar('Ошибка создания тикета: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать обращение'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createTicket,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Категория
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Категория',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...TicketCategory.values
                        .map((category) => RadioListTile<TicketCategory>(
                              title: Text(_getCategoryTitle(category)),
                              subtitle: Text(_getCategoryDescription(category)),
                              value: category,
                              groupValue: _selectedCategory,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCategory = value);
                                }
                              },
                            ),),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Заголовок
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Заголовок',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Краткое описание проблемы',
                        border: OutlineInputBorder(),
                        hintText: 'Например: Приложение не запускается',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите заголовок';
                        }
                        if (value.trim().length < 5) {
                          return 'Заголовок должен содержать минимум 5 символов';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Описание
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Описание',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Подробное описание проблемы',
                        border: OutlineInputBorder(),
                        hintText: 'Опишите проблему максимально подробно...',
                      ),
                      maxLines: 5,
                      maxLength: 1000,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите описание';
                        }
                        if (value.trim().length < 10) {
                          return 'Описание должно содержать минимум 10 символов';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Вложения
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Вложения',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showInfoSnackBar(
                              'Добавление вложений будет реализовано',);
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Добавить файлы'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Можно прикрепить скриншоты, логи или другие файлы',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTitle(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return 'Ошибка';
      case TicketCategory.feature:
        return 'Предложение';
      case TicketCategory.complaint:
        return 'Жалоба';
      case TicketCategory.payment:
        return 'Платеж';
    }
  }

  String _getCategoryDescription(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return 'Сообщить об ошибке в приложении';
      case TicketCategory.feature:
        return 'Предложить новую функцию';
      case TicketCategory.complaint:
        return 'Пожаловаться на пользователя или контент';
      case TicketCategory.payment:
        return 'Проблемы с платежами и транзакциями';
    }
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Экран деталей тикета
class TicketDetailsScreen extends StatelessWidget {
  const TicketDetailsScreen({
    required this.ticket, super.key,
  });

  final FeedbackTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Тикет #${ticket.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Информация о тикете
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(_getCategoryTitle(ticket.category)),
                        backgroundColor: Colors.blue[100],
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_getStatusText(ticket.status)),
                        backgroundColor:
                            _getStatusColor(ticket.status).withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // История сообщений
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'История сообщений',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Здесь будет отображаться переписка с поддержкой',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryTitle(TicketCategory category) {
    switch (category) {
      case TicketCategory.bug:
        return 'Ошибка';
      case TicketCategory.feature:
        return 'Предложение';
      case TicketCategory.complaint:
        return 'Жалоба';
      case TicketCategory.payment:
        return 'Платеж';
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Открыт';
      case TicketStatus.inProgress:
        return 'В работе';
      case TicketStatus.resolved:
        return 'Решен';
      case TicketStatus.closed:
        return 'Закрыт';
    }
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }
}
