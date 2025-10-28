import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Улучшенный экран заявок с полным функционалом
class RequestsScreenEnhanced extends ConsumerStatefulWidget {
  const RequestsScreenEnhanced({super.key});

  @override
  ConsumerState<RequestsScreenEnhanced> createState() =>
      _RequestsScreenEnhancedState();
}

class _RequestsScreenEnhancedState extends ConsumerState<RequestsScreenEnhanced>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  String _selectedSort = 'date';
  final bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _filters = [
    {'value': 'all', 'label': 'Все', 'icon': Icons.list},
    {'value': 'pending', 'label': 'В ожидании', 'icon': Icons.schedule},
    {'value': 'confirmed', 'label': 'Подтверждено', 'icon': Icons.check_circle},
    {'value': 'cancelled', 'label': 'Отменено', 'icon': Icons.cancel},
    {'value': 'completed', 'label': 'Завершено', 'icon': Icons.done_all},
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'date', 'label': 'По дате', 'icon': Icons.calendar_today},
    {'value': 'budget', 'label': 'По бюджету', 'icon': Icons.attach_money},
    {'value': 'status', 'label': 'По статусу', 'icon': Icons.sort},
    {'value': 'title', 'label': 'По названию', 'icon': Icons.title},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              _buildHeader(),

              // Основной контент
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Заголовок экрана
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.assignment,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Заявки',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.go('/create-request');
            },
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  /// Основной контент
  Widget _buildContent() {
    return Column(
      children: [
        // Фильтры и сортировка
        _buildFiltersSection(),

        // Список заявок
        Expanded(
          child: _buildRequestsList(),
        ),
      ],
    );
  }

  /// Секция фильтров
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Фильтры
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter['value'] == _selectedFilter;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter['value'];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8,),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[300]!),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1E3A8A).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'],
                            color: isSelected ? Colors.white : Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            filter['label'],
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Сортировка
          Row(
            children: [
              const Text(
                'Сортировка:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    isExpanded: true,
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['value'],
                        child: Row(
                          children: [
                            Icon(
                              option['icon'],
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(option['label']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSort = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Список заявок
  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data()! as Map<String, dynamic>;

            return _buildRequestCard(doc.id, data);
          },
        );
      },
    );
  }

  /// Поток заявок с фильтрацией
  Stream<QuerySnapshot> _getRequestsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(QuerySnapshot.empty());
    }

    Query query = FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid);

    // Применяем фильтр по статусу
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    // Применяем сортировку
    switch (_selectedSort) {
      case 'date':
        query = query.orderBy('createdAt', descending: true);
      case 'budget':
        query = query.orderBy('budget', descending: true);
      case 'status':
        query = query.orderBy('status');
      case 'title':
        query = query.orderBy('title');
    }

    return query.snapshots();
  }

  /// Карточка заявки
  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Заголовок заявки
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Без названия',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(data['createdAt']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(data['status'] ?? 'pending'),
              ],
            ),
          ),

          // Описание
          if (data['description'] != null && data['description'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                data['description'],
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Детали
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildDetailChip(
                  icon: Icons.attach_money,
                  label: '${data['budget'] ?? 0} ₽',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: Icons.location_on,
                  label: data['location'] ?? 'Не указано',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: Icons.event,
                  label: _formatDate(data['eventDate']),
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          // Действия
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRequestDetails(requestId, data);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Подробнее'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _editRequest(requestId, data);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Редактировать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Чип статуса
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'В ожидании';
        icon = Icons.schedule;
      case 'confirmed':
        color = Colors.green;
        label = 'Подтверждено';
        icon = Icons.check_circle;
      case 'cancelled':
        color = Colors.red;
        label = 'Отменено';
        icon = Icons.cancel;
      case 'completed':
        color = Colors.blue;
        label = 'Завершено';
        icon = Icons.done_all;
      default:
        color = Colors.grey;
        label = 'Неизвестно';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
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

  /// Чип детали
  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Состояние загрузки
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 200, height: 20, borderRadius: 10),
                  const Spacer(),
                  ShimmerBox(width: 80, height: 24, borderRadius: 12),
                ],
              ),
              const SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 60, borderRadius: 8),
              const SizedBox(height: 12),
              Row(
                children: [
                  ShimmerBox(width: 60, height: 20, borderRadius: 10),
                  const SizedBox(width: 8),
                  ShimmerBox(width: 80, height: 20, borderRadius: 10),
                  const SizedBox(width: 8),
                  ShimmerBox(width: 70, height: 20, borderRadius: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Состояние ошибки
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Пустое состояние
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
            'Заявок пока нет',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первую заявку для поиска специалистов',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/create-request');
            },
            icon: const Icon(Icons.add),
            label: const Text('Создать заявку'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Показать детали заявки
  void _showRequestDetails(String requestId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['title'] ?? 'Заявка'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['description'] != null) ...[
                const Text(
                  'Описание:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(data['description']),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Бюджет', '${data['budget'] ?? 0} ₽'),
              _buildDetailRow('Локация', data['location'] ?? 'Не указано'),
              _buildDetailRow('Дата события', _formatDate(data['eventDate'])),
              _buildDetailRow(
                  'Статус', _getStatusLabel(data['status'] ?? 'pending'),),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editRequest(requestId, data);
            },
            child: const Text('Редактировать'),
          ),
        ],
      ),
    );
  }

  /// Строка детали
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  /// Редактировать заявку
  void _editRequest(String requestId, Map<String, dynamic> data) {
    // TODO: Реализовать редактирование заявки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Редактирование заявки будет реализовано'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Получить лейбл статуса
  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'В ожидании';
      case 'confirmed':
        return 'Подтверждено';
      case 'cancelled':
        return 'Отменено';
      case 'completed':
        return 'Завершено';
      default:
        return 'Неизвестно';
    }
  }

  /// Форматирование даты
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Не указано';

    final date = timestamp is Timestamp
        ? timestamp.toDate()
        : DateTime.parse(timestamp.toString());

    return '${date.day}.${date.month}.${date.year}';
  }
}
