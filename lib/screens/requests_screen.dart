import 'package:event_marketplace_app/models/social_models.dart';
import 'package:event_marketplace_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран заявок с вкладками "Мои заявки" и "Заявки мне"
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<Request> _myRequests = [];
  List<Request> _assignedRequests = [];
  bool _isLoadingMyRequests = true;
  bool _isLoadingAssignedRequests = true;
  String? _errorMyRequests;
  String? _errorAssignedRequests;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyRequests();
    _loadAssignedRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRequests() async {
    try {
      setState(() {
        _isLoadingMyRequests = true;
        _errorMyRequests = null;
      });

      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return;

      final requests =
          await SupabaseService.getUserRequests(userId: currentUserId);

      setState(() {
        _myRequests = requests;
        _isLoadingMyRequests = false;
      });
    } catch (e) {
      setState(() {
        _errorMyRequests = e.toString();
        _isLoadingMyRequests = false;
      });
    }
  }

  Future<void> _loadAssignedRequests() async {
    try {
      setState(() {
        _isLoadingAssignedRequests = true;
        _errorAssignedRequests = null;
      });

      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) return;

      final requests = await SupabaseService.getUserRequests(
        userId: currentUserId,
        isCreatedBy: false,
      );

      setState(() {
        _assignedRequests = requests;
        _isLoadingAssignedRequests = false;
      });
    } catch (e) {
      setState(() {
        _errorAssignedRequests = e.toString();
        _isLoadingAssignedRequests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'Мои заявки'),
            Tab(text: 'Заявки мне'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/requests/create'),
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [_buildMyRequestsTab(), _buildAssignedRequestsTab()],
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: _buildRequestsList(
        requests: _myRequests,
        isLoading: _isLoadingMyRequests,
        error: _errorMyRequests,
        isMyRequests: true,
      ),
    );
  }

  Widget _buildAssignedRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadAssignedRequests,
      child: _buildRequestsList(
        requests: _assignedRequests,
        isLoading: _isLoadingAssignedRequests,
        error: _errorAssignedRequests,
        isMyRequests: false,
      ),
    );
  }

  Widget _buildRequestsList({
    required List<Request> requests,
    required bool isLoading,
    required String? error,
    required bool isMyRequests,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Ошибка загрузки заявок',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isMyRequests ? _loadMyRequests : _loadAssignedRequests,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isMyRequests ? 'Нет ваших заявок' : 'Нет заявок для вас',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              isMyRequests
                  ? 'Создайте заявку, чтобы найти исполнителя'
                  : 'Заявки, назначенные вам, появятся здесь',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isMyRequests)
              ElevatedButton(
                onPressed: () => context.push('/requests/create'),
                child: const Text('Создать заявку'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request, isMyRequests);
      },
    );
  }

  Widget _buildRequestCard(Request request, bool isMyRequests) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/requests/${request.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,),
                    ),
                  ),
                  _buildStatusChip(request.status),
                ],
              ),
              const SizedBox(height: 8),

              // Описание
              if (request.description != null) ...[
                Text(
                  request.description!,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Детали
              Row(
                children: [
                  if (request.category != null) ...[
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      request.category!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (request.budget != null) ...[
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${request.budget!.toStringAsFixed(0)} ₽',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (request.location != null) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      request.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Информация о пользователях
              Row(
                children: [
                  if (isMyRequests) ...[
                    // Показываем исполнителя
                    if (request.assignee != null) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            theme.primaryColor.withValues(alpha: 0.1),
                        backgroundImage: request.assignee!.avatarUrl != null
                            ? NetworkImage(request.assignee!.avatarUrl!)
                            : null,
                        child: request.assignee!.avatarUrl == null
                            ? Icon(Icons.person,
                                size: 12, color: theme.primaryColor,)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Исполнитель: ${request.assignee!.name}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500,),
                      ),
                    ] else ...[
                      Icon(Icons.person_outline,
                          size: 16, color: Colors.grey[600],),
                      const SizedBox(width: 4),
                      Text(
                        'Исполнитель не назначен',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ] else ...[
                    // Показываем заказчика
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          theme.primaryColor.withValues(alpha: 0.1),
                      backgroundImage: request.creator?.avatarUrl != null
                          ? NetworkImage(request.creator!.avatarUrl!)
                          : null,
                      child: request.creator?.avatarUrl == null
                          ? Icon(Icons.person,
                              size: 12, color: theme.primaryColor,)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Заказчик: ${request.creator?.name ?? 'Неизвестный'}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500,),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatTime(request.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.blue;
        label = 'Открыта';
      case 'in_progress':
        color = Colors.orange;
        label = 'В работе';
      case 'completed':
        color = Colors.green;
        label = 'Завершена';
      case 'cancelled':
        color = Colors.red;
        label = 'Отменена';
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'сейчас';
    }
  }
}
