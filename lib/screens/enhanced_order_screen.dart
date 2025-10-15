import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_order.dart';
import '../services/enhanced_orders_service.dart';
import '../widgets/order_comments_widget.dart';
import '../widgets/order_timeline_widget.dart';

/// Расширенный экран заявки
class EnhancedOrderScreen extends ConsumerStatefulWidget {
  const EnhancedOrderScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  ConsumerState<EnhancedOrderScreen> createState() =>
      _EnhancedOrderScreenState();
}

class _EnhancedOrderScreenState extends ConsumerState<EnhancedOrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedOrdersService _ordersService = EnhancedOrdersService();

  EnhancedOrder? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrder();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Реализовать получение заявки по ID
      // Пока что создаём заглушку
      setState(() {
        _order = _createMockOrder();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  EnhancedOrder _createMockOrder() => EnhancedOrder(
        id: widget.orderId,
        customerId: 'customer_1',
        specialistId: 'specialist_1',
        title: 'Организация свадьбы',
        description:
            'Нужна помощь в организации свадебного торжества на 50 человек. Дата: 15 июня 2024 года.',
        status: OrderStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        budget: 150000,
        deadline: DateTime.now().add(const Duration(days: 30)),
        location: 'Москва, ресторан "Золотой"',
        category: 'Свадьбы',
        priority: OrderPriority.high,
        comments: [
          OrderComment(
            id: '1',
            authorId: 'customer_1',
            text: 'Добро пожаловать! Рад работать с вами над этим проектом.',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          OrderComment(
            id: '2',
            authorId: 'specialist_1',
            text: 'Спасибо за доверие! Начнём с обсуждения деталей.',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ],
        timeline: [
          OrderTimelineEvent(
            id: '1',
            type: OrderTimelineEventType.created,
            title: 'Заявка создана',
            description: 'Заявка "Организация свадьбы" была создана',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            authorId: 'customer_1',
          ),
          OrderTimelineEvent(
            id: '2',
            type: OrderTimelineEventType.accepted,
            title: 'Заявка принята',
            description: 'Специалист принял заявку к выполнению',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            authorId: 'specialist_1',
          ),
          OrderTimelineEvent(
            id: '3',
            type: OrderTimelineEventType.started,
            title: 'Работа начата',
            description: 'Специалист начал работу над заявкой',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            authorId: 'specialist_1',
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrder,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Заявка не найдена')),
        body: const Center(child: Text('Заявка не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_order!.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Редактировать'),
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Поделиться'),
                ),
              ),
              if (_order!.status == OrderStatus.pending)
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title:
                        Text('Отменить', style: TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Детали', icon: Icon(Icons.info)),
            Tab(text: 'История', icon: Icon(Icons.timeline)),
            Tab(text: 'Комментарии', icon: Icon(Icons.comment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildTimelineTab(),
          _buildCommentsTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация
            _buildBasicInfo(),
            const SizedBox(height: 20),

            // Бюджет и дедлайн
            _buildBudgetAndDeadline(),
            const SizedBox(height: 20),

            // Статус и приоритет
            _buildStatusAndPriority(),
            const SizedBox(height: 20),

            // Вложения
            _buildAttachments(),
            const SizedBox(height: 20),

            // Действия
            _buildActions(),
          ],
        ),
      );

  Widget _buildTimelineTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: OrderTimelineWidget(timeline: _order!.timeline),
      );

  Widget _buildCommentsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: OrderCommentsWidget(
          comments: _order!.comments,
          currentUserId: 'current_user', // TODO: Получить из провайдера
          onAddComment: _addComment,
          onAddAttachment: _addAttachment,
        ),
      );

  Widget _buildBasicInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Описание заявки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _order!.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _order!.location ?? 'Местоположение не указано',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _order!.category ?? 'Категория не указана',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildBudgetAndDeadline() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Бюджет и сроки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Бюджет',
                    _order!.budget != null
                        ? '${_order!.budget!.toInt()}₽'
                        : 'Не указан',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Дедлайн',
                    _order!.deadline != null
                        ? '${_order!.deadline!.day}.${_order!.deadline!.month}.${_order!.deadline!.year}'
                        : 'Не указан',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatusAndPriority() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус и приоритет',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Статус',
                    _order!.status.displayName,
                    _order!.status.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    'Приоритет',
                    _order!.priority.displayName,
                    _order!.priority.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildAttachments() {
    if (_order!.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Вложения',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _order!.attachments.map(_buildAttachmentChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() => Column(
        children: [
          if (_order!.status == OrderStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _acceptOrder,
                icon: const Icon(Icons.check),
                label: const Text('Принять заявку'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_order!.status == OrderStatus.accepted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startOrder,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Начать работу'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_order!.status == OrderStatus.inProgress) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _completeOrder,
                icon: const Icon(Icons.check_circle),
                label: const Text('Завершить заявку'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _contactUser,
              icon: const Icon(Icons.message),
              label: const Text('Написать сообщение'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatusCard(String title, String value, String color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(int.parse(color.replaceFirst('#', '0xFF')))
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(int.parse(color.replaceFirst('#', '0xFF')))
                .withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildAttachmentChip(OrderAttachment attachment) => GestureDetector(
        onTap: () {
          // TODO: Открыть вложение
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                attachment.type.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                attachment.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editOrder();
        break;
      case 'share':
        _shareOrder();
        break;
      case 'cancel':
        _cancelOrder();
        break;
    }
  }

  void _editOrder() {
    // TODO: Реализовать редактирование заявки
    debugPrint('Редактирование заявки');
  }

  void _shareOrder() {
    // TODO: Реализовать шаринг заявки
    debugPrint('Шаринг заявки');
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку'),
        content: const Text('Вы уверены, что хотите отменить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Реализовать отмену заявки
            },
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );
  }

  void _acceptOrder() {
    // TODO: Реализовать принятие заявки
    debugPrint('Принятие заявки');
  }

  void _startOrder() {
    // TODO: Реализовать начало работы
    debugPrint('Начало работы');
  }

  void _completeOrder() {
    // TODO: Реализовать завершение заявки
    debugPrint('Завершение заявки');
  }

  void _contactUser() {
    // TODO: Реализовать переход к чату
    debugPrint('Переход к чату');
  }

  void _addComment(String text, bool isInternal) {
    // TODO: Реализовать добавление комментария
    debugPrint('Добавление комментария: $text (внутренний: $isInternal)');
  }

  void _addAttachment(OrderAttachment attachment) {
    // TODO: Реализовать добавление вложения
    debugPrint('Добавление вложения: ${attachment.name}');
  }
}
