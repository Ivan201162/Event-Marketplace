import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/request.dart';
import '../providers/optimized_data_providers.dart';
import '../services/optimized_applications_service.dart';

/// Оптимизированная лента заявок с реальными данными и обработкой состояний
class OptimizedApplicationsScreen extends ConsumerStatefulWidget {
  const OptimizedApplicationsScreen({super.key});

  @override
  ConsumerState<OptimizedApplicationsScreen> createState() => _OptimizedApplicationsScreenState();
}

class _OptimizedApplicationsScreenState extends ConsumerState<OptimizedApplicationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';
  String _sortBy = 'newest';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои заявки'),
            Tab(text: 'Заявки для меня'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          _buildFiltersSection(),
          
          // Список заявок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplicationsList('my_requests'),
                _buildApplicationsList('requests_for_me'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Статусы
          Row(
            children: [
              const Text('Статус: '),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('all', 'Все'),
                      _buildStatusChip('pending', 'В ожидании'),
                      _buildStatusChip('accepted', 'Принято'),
                      _buildStatusChip('rejected', 'Отклонено'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Сортировка
          Row(
            children: [
              const Text('Сортировка: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Новые')),
                  DropdownMenuItem(value: 'oldest', child: Text('Старые')),
                  DropdownMenuItem(value: 'status', child: Text('По статусу')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = status;
          });
        },
        backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
        selectedColor: _getStatusColor(status).withValues(alpha: 0.3),
        checkmarkColor: _getStatusColor(status),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildApplicationsList(String type) {
    final applicationsAsync = ref.watch(applicationsProvider({
      'type': type,
      'status': _selectedStatus,
      'sortBy': _sortBy,
    }));

    return applicationsAsync.when(
      data: (applicationsState) => _buildApplicationsContent(applicationsState),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildApplicationsContent(ApplicationsState applicationsState) {
    if (applicationsState.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applicationsState.applications.length,
        itemBuilder: (context, index) {
          final application = applicationsState.applications[index];
          return _ApplicationCard(application: application);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка заявок...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет заявок',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться заявки',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshApplications,
            icon: const Icon(Icons.refresh),
            label: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки заявок',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshApplications,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Фильтры заявок'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Статус'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Все')),
                  DropdownMenuItem(value: 'pending', child: Text('В ожидании')),
                  DropdownMenuItem(value: 'accepted', child: Text('Принято')),
                  DropdownMenuItem(value: 'rejected', child: Text('Отклонено')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(labelText: 'Сортировка'),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Новые')),
                  DropdownMenuItem(value: 'oldest', child: Text('Старые')),
                  DropdownMenuItem(value: 'status', child: Text('По статусу')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedStatus = 'all';
                  _sortBy = 'newest';
                });
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshApplications() async {
    ref.invalidate(applicationsProvider);
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});
  final Request application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsService = ref.read(optimizedApplicationsServiceProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок заявки
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар специалиста/клиента
                CircleAvatar(
                  radius: 24,
                  backgroundImage: application.specialistAvatar != null
                      ? CachedNetworkImageProvider(application.specialistAvatar!)
                      : null,
                  child: application.specialistAvatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.specialistName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        application.eventTitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Статус
                _buildStatusChip(application.status),
              ],
            ),
          ),

          // Описание заявки
          if (application.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                application.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Детали заявки
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(application.eventDate),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.eventLocation,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${application.budget} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatCreatedDate(application.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Действия
          if (application.status == 'pending')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectApplication(applicationsService),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Отклонить', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptApplication(applicationsService),
                      icon: const Icon(Icons.check),
                      label: const Text('Принять'),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewSpecialistProfile(),
                      icon: const Icon(Icons.person),
                      label: const Text('Профиль специалиста'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactSpecialist(),
                      icon: const Icon(Icons.chat),
                      label: const Text('Написать'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'В ожидании';
        icon = Icons.schedule;
        break;
      case 'accepted':
        color = Colors.green;
        label = 'Принято';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Отклонено';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = 'Неизвестно';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _acceptApplication(OptimizedApplicationsService applicationsService) {
    applicationsService.updateApplicationStatus(application.id, 'accepted');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка принята')),
    );
  }

  void _rejectApplication(OptimizedApplicationsService applicationsService) {
    applicationsService.updateApplicationStatus(application.id, 'rejected');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявка отклонена')),
    );
  }

  void _viewSpecialistProfile() {
    // TODO: Открыть профиль специалиста
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открыть профиль ${application.specialistName}')),
    );
  }

  void _contactSpecialist() {
    // TODO: Открыть чат с специалистом
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Написать ${application.specialistName}')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatCreatedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }
}
