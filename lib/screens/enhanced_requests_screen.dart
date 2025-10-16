import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enhanced_order.dart';
import '../widgets/order_card_widget.dart';
import '../widgets/order_timeline_widget.dart';
import '../providers/auth_providers.dart';

/// Улучшенный экран заявок с полным функционалом
class EnhancedRequestsScreen extends ConsumerStatefulWidget {
  const EnhancedRequestsScreen({super.key});

  @override
  ConsumerState<EnhancedRequestsScreen> createState() =>
      _EnhancedRequestsScreenState();
}

class _EnhancedRequestsScreenState extends ConsumerState<EnhancedRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedFilter = 'all';
  String _searchQuery = '';

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
  Widget build(BuildContext context) => Column(
        children: [
          // Поиск и фильтры
          _buildSearchAndFilters(),

          // Табы заявок
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Мои заявки'),
              Tab(text: 'Заявки мне'),
            ],
          ),

          // Список заявок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyRequestsList(),
                _buildRequestsForMeList(),
              ],
            ),
          ),
        ],
      );

  Widget _buildSearchAndFilters() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поиск
            TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по заявкам...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      );

  Widget _buildMyRequestsList() {
    // Заявки, созданные текущим пользователем
    final orders = _getMyRequests();

    if (orders.isEmpty) {
      return _buildEmptyState('my_requests');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Обновить данные
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCardWidget(
            order: order,
            onTap: () => _openOrderDetails(order),
            onEdit: () => _editOrder(order),
            onCancel: () => _cancelOrder(order),
            onComplete: () => _completeOrder(order),
          );
        },
      ),
    );
  }

  Widget _buildRequestsForMeList() {
    // Заявки, назначенные на текущего пользователя
    final orders = _getRequestsForMe();

    if (orders.isEmpty) {
      return _buildEmptyState('requests_for_me');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Обновить данные
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCardWidget(
            order: order,
            onTap: () => _openOrderDetails(order),
            onEdit: () => _editOrder(order),
            onCancel: () => _cancelOrder(order),
            onComplete: () => _completeOrder(order),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title;
    String subtitle;
    IconData icon;

    switch (status) {
      case 'my_requests':
        title = 'Нет ваших заявок';
        subtitle = 'Создайте первую заявку к специалисту';
        icon = Icons.assignment;
        break;
      case 'requests_for_me':
        title = 'Нет заявок для вас';
        subtitle = 'Заявки, назначенные на вас, будут отображаться здесь';
        icon = Icons.assignment_ind;
        break;
      default:
        title = 'Нет заявок';
        subtitle = 'Создайте первую заявку к специалисту';
        icon = Icons.assignment;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewOrder,
            icon: const Icon(Icons.add),
            label: const Text('Создать заявку'),
          ),
        ],
      ),
    );
  }

  List<EnhancedOrder> _getTestOrders(String status) {
    final currentUser = ref.read(currentUserProvider).value;
    final currentUserId = currentUser?.uid ?? 'current_user';

    final allOrders = [
      EnhancedOrder(
        id: '1',
        customerId: currentUserId,
        specialistId: 'specialist_1',
        title: 'Свадебная фотосъёмка',
        description:
            'Нужен фотограф на свадьбу 15 июня. Съёмка в парке, около 6 часов.',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        budget: 25000,
        deadline: DateTime.now().add(const Duration(days: 20)),
        location: 'Москва, Парк Сокольники',
        category: 'Фотограф',
        comments: [
          OrderComment(
            id: '1',
            authorId: currentUserId,
            text: 'Хотелось бы обсудить детали съёмки',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
        timeline: [
          OrderTimelineEvent(
            id: '1',
            type: OrderTimelineEventType.created,
            title: 'Заявка создана',
            description: 'Заявка на свадебную фотосъёмку создана',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            authorId: currentUserId,
          ),
        ],
      ),
      EnhancedOrder(
        id: '2',
        customerId: currentUserId,
        specialistId: 'specialist_2',
        title: 'DJ на корпоратив',
        description: 'Нужен DJ для корпоративного мероприятия 25 мая.',
        status: OrderStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        budget: 15000,
        deadline: DateTime.now().add(const Duration(days: 10)),
        location: 'Москва, офис компании',
        category: 'DJ',
        priority: OrderPriority.high,
        comments: [],
        timeline: [
          OrderTimelineEvent(
            id: '1',
            type: OrderTimelineEventType.created,
            title: 'Заявка создана',
            description: 'Заявка на DJ создана',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            authorId: currentUserId,
          ),
          OrderTimelineEvent(
            id: '2',
            type: OrderTimelineEventType.accepted,
            title: 'Заявка принята',
            description: 'Специалист принял заявку',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            authorId: 'specialist_2',
          ),
        ],
      ),
      EnhancedOrder(
        id: '3',
        customerId: currentUserId,
        specialistId: 'specialist_3',
        title: 'Видеосъёмка мероприятия',
        description: 'Нужна видеосъёмка детского праздника',
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        budget: 20000,
        deadline: DateTime.now().subtract(const Duration(days: 5)),
        location: 'Москва, детский центр',
        category: 'Видеограф',
        priority: OrderPriority.low,
        comments: [],
        timeline: [
          OrderTimelineEvent(
            id: '1',
            type: OrderTimelineEventType.created,
            title: 'Заявка создана',
            description: 'Заявка на видеосъёмку создана',
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            authorId: currentUserId,
          ),
          OrderTimelineEvent(
            id: '2',
            type: OrderTimelineEventType.accepted,
            title: 'Заявка принята',
            description: 'Специалист принял заявку',
            createdAt: DateTime.now().subtract(const Duration(days: 12)),
            authorId: 'specialist_3',
          ),
          OrderTimelineEvent(
            id: '3',
            type: OrderTimelineEventType.completed,
            title: 'Работа выполнена',
            description: 'Видеосъёмка завершена',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            authorId: 'specialist_3',
          ),
        ],
      ),
      // Заявки, где текущий пользователь является специалистом
      EnhancedOrder(
        id: '4',
        customerId: 'customer_2',
        specialistId: currentUserId,
        title: 'Фотосессия для портфолио',
        description:
            'Нужна профессиональная фотосессия для обновления портфолио модели',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        budget: 12000,
        deadline: DateTime.now().add(const Duration(days: 7)),
        location: 'Москва, студия',
        category: 'Фотограф',
        comments: [],
        timeline: [
          OrderTimelineEvent(
            id: '1',
            type: OrderTimelineEventType.created,
            title: 'Заявка создана',
            description: 'Заявка на фотосессию создана',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            authorId: 'customer_2',
          ),
        ],
      ),
      EnhancedOrder(
        id: '5',
        customerId: 'customer_3',
        specialistId: currentUserId,
        title: 'Свадебная видеосъёмка',
        description: 'Полная видеосъёмка свадьбы с монтажом',
        status: OrderStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        budget: 35000,
        deadline: DateTime.now().add(const Duration(days: 14)),
        location: 'Москва, ресторан',
        category: 'Видеограф',
        priority: OrderPriority.high,
        comments: [],
        timeline: [
          OrderTimelineEvent(
            id: '1',
            type: OrderTimelineEventType.created,
            title: 'Заявка создана',
            description: 'Заявка на видеосъёмку создана',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            authorId: 'customer_3',
          ),
          OrderTimelineEvent(
            id: '2',
            type: OrderTimelineEventType.accepted,
            title: 'Заявка принята',
            description: 'Специалист принял заявку',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            authorId: currentUserId,
          ),
        ],
      ),
    ];

    switch (status) {
      case 'pending':
        return allOrders
            .where((order) => order.status == OrderStatus.pending)
            .toList();
      case 'in_progress':
        return allOrders
            .where((order) => order.status == OrderStatus.inProgress)
            .toList();
      case 'completed':
        return allOrders
            .where((order) => order.status == OrderStatus.completed)
            .toList();
      default:
        return allOrders;
    }
  }

  List<EnhancedOrder> _getMyRequests() {
    // Заявки, созданные текущим пользователем
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return [];

    final allOrders = _getTestOrders('all');

    return allOrders
        .where((order) => order.customerId == currentUser.uid)
        .toList();
  }

  List<EnhancedOrder> _getRequestsForMe() {
    // Заявки, назначенные на текущего пользователя
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return [];

    final allOrders = _getTestOrders('all');

    return allOrders
        .where((order) => order.specialistId == currentUser.uid)
        .toList();
  }

  void _openOrderDetails(EnhancedOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Статус
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Описание
              const Text(
                'Описание',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(order.description),

              const SizedBox(height: 16),

              // Детали
              _buildOrderDetails(order),

              const SizedBox(height: 16),

              // Таймлайн
              const Text(
                'История заявки',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: OrderTimelineWidget(
                  timeline: order.timeline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(EnhancedOrder order) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Бюджет', '${order.budget} ₽'),
          _buildDetailRow(
            'Срок',
            order.deadline != null ? _formatDate(order.deadline!) : 'Не указан',
          ),
          _buildDetailRow('Место', order.location ?? 'Не указано'),
          _buildDetailRow('Категория', order.category ?? 'Не указана'),
          _buildDetailRow('Приоритет', _getPriorityText(order.priority)),
        ],
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  void _editOrder(EnhancedOrder order) {
    // TODO: Реализовать редактирование заявки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование заявки будет реализовано')),
    );
  }

  void _cancelOrder(EnhancedOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заявку'),
        content: const Text('Вы уверены, что хотите отменить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Отменить заявку
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Заявка отменена')),
              );
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  void _completeOrder(EnhancedOrder order) {
    // TODO: Реализовать завершение заявки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Завершение заявки будет реализовано')),
    );
  }

  void _createNewOrder() {
    context.push('/create-order');
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.accepted:
        return 'Принята';
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.completed:
        return 'Завершена';
      case OrderStatus.cancelled:
        return 'Отменена';
    }
  }

  String _getPriorityText(OrderPriority priority) {
    switch (priority) {
      case OrderPriority.low:
        return 'Низкий';
      case OrderPriority.medium:
        return 'Средний';
      case OrderPriority.high:
        return 'Высокий';
      case OrderPriority.urgent:
        return 'Срочный';
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
