import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../models/wedding_anniversary.dart';
import '../services/anniversary_service.dart';

/// Экран управления годовщинами свадьбы
class AnniversaryScreen extends ConsumerStatefulWidget {
  const AnniversaryScreen({super.key});

  @override
  ConsumerState<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends ConsumerState<AnniversaryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AnniversaryService _anniversaryService = AnniversaryService();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedWeddingDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.anniversaryTrackingEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Годовщины свадьбы')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Отслеживание годовщин временно недоступно',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Годовщины свадьбы'),
        backgroundColor: Colors.pink[50],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои годовщины', icon: Icon(Icons.favorite)),
            Tab(text: 'Предстоящие', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Добавить', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyAnniversariesTab(),
          _buildUpcomingAnniversariesTab(),
          _buildAddAnniversaryTab(),
        ],
      ),
    );
  }

  Widget _buildMyAnniversariesTab() => StreamBuilder<List<WeddingAnniversary>>(
    stream: _anniversaryService.getCustomerAnniversaries(
      'current_user_id',
    ), // TODO(developer): Получить реальный ID
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
              Text('Ошибка загрузки годовщин: ${snapshot.error}'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => setState(() {}), child: const Text('Повторить')),
            ],
          ),
        );
      }

      final anniversaries = snapshot.data ?? [];
      if (anniversaries.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('У вас пока нет годовщин', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text(
                'Добавьте дату свадьбы, чтобы отслеживать годовщины',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: anniversaries.length,
        itemBuilder: (context, index) {
          final anniversary = anniversaries[index];
          return _buildAnniversaryCard(anniversary);
        },
      );
    },
  );

  Widget _buildAnniversaryCard(WeddingAnniversary anniversary) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.pink[600], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anniversary.anniversaryName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${anniversary.yearsMarried} лет вместе',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAnniversaryAction(value, anniversary),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [Icon(Icons.edit), SizedBox(width: 8), Text('Редактировать')],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnniversaryDetails(anniversary),
          const SizedBox(height: 16),
          _buildAnniversaryActions(anniversary),
        ],
      ),
    ),
  );

  Widget _buildAnniversaryDetails(WeddingAnniversary anniversary) => Column(
    children: [
      _buildDetailRow(
        Icons.calendar_today,
        'Дата свадьбы',
        '${anniversary.weddingDate.day}.${anniversary.weddingDate.month}.${anniversary.weddingDate.year}',
      ),
      _buildDetailRow(
        Icons.cake,
        'Следующая годовщина',
        '${anniversary.nextAnniversary.day}.${anniversary.nextAnniversary.month}.${anniversary.nextAnniversary.year}',
      ),
      _buildDetailRow(
        Icons.schedule,
        'Дней до годовщины',
        '${anniversary.nextAnniversary.difference(DateTime.now()).inDays}',
      ),
    ],
  );

  Widget _buildDetailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _buildAnniversaryActions(WeddingAnniversary anniversary) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showRecommendations(anniversary),
          icon: const Icon(Icons.lightbulb),
          label: const Text('Рекомендации'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _showSpecialists(anniversary),
          icon: const Icon(Icons.people),
          label: const Text('Специалисты'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink[600],
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ],
  );

  Widget _buildUpcomingAnniversariesTab() => StreamBuilder<List<WeddingAnniversary>>(
    stream: _anniversaryService.getUpcomingAnniversaries('current_user'),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Ошибка загрузки предстоящих годовщин: ${snapshot.error}'));
      }

      final anniversaries = snapshot.data ?? [];
      if (anniversaries.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Нет предстоящих годовщин', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text(
                'В ближайшие 30 дней годовщин не ожидается',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: anniversaries.length,
        itemBuilder: (context, index) {
          final anniversary = anniversaries[index];
          return _buildUpcomingAnniversaryCard(anniversary);
        },
      );
    },
  );

  Widget _buildUpcomingAnniversaryCard(WeddingAnniversary anniversary) {
    final daysUntil = anniversary.nextAnniversary.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.pink[100],
                  child: Text(
                    '${anniversary.yearsMarried + 1}',
                    style: TextStyle(color: Colors.pink[600], fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anniversary.anniversaryName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(anniversary.customerName, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: daysUntil <= 7 ? Colors.red[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    daysUntil == 0 ? 'Сегодня!' : '$daysUntil дн.',
                    style: TextStyle(
                      color: daysUntil <= 7 ? Colors.red[600] : Colors.orange[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(anniversary.anniversaryDescription, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAnniversaryTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildWeddingDateInput(),
        const SizedBox(height: 24),
        _buildPreviewSection(),
        const SizedBox(height: 24),
        _buildSubmitButton(),
      ],
    ),
  );

  Widget _buildHeader() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.pink[600], size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Добавить годовщину',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Укажите дату вашей свадьбы, и мы будем отслеживать ваши годовщины, отправлять напоминания и предлагать идеи для празднования',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );

  Widget _buildWeddingDateInput() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Дата свадьбы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _dateController,
            decoration: InputDecoration(
              hintText: 'Выберите дату свадьбы',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _dateController.clear();
                  setState(() {
                    _selectedWeddingDate = null;
                  });
                },
              ),
            ),
            readOnly: true,
            onTap: _selectWeddingDate,
          ),
        ],
      ),
    ),
  );

  Widget _buildPreviewSection() {
    if (_selectedWeddingDate == null) {
      return const SizedBox.shrink();
    }

    final yearsMarried = WeddingAnniversary.calculateYearsMarried(_selectedWeddingDate!);
    final nextAnniversary = WeddingAnniversary.calculateNextAnniversary(_selectedWeddingDate!);
    final daysUntil = nextAnniversary.difference(DateTime.now()).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Предварительный просмотр',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.pink[100],
                  child: Text(
                    '${yearsMarried + 1}',
                    style: TextStyle(color: Colors.pink[600], fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAnniversaryName(yearsMarried + 1),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Следующая годовщина через $daysUntil дней',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getAnniversaryDescription(yearsMarried + 1),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _selectedWeddingDate != null ? _addAnniversary : null,
      icon: const Icon(Icons.add),
      label: const Text('Добавить годовщину'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );

  Future<void> _selectWeddingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedWeddingDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedWeddingDate = date;
        _dateController.text = '${date.day}.${date.month}.${date.year}';
      });
    }
  }

  Future<void> _addAnniversary() async {
    if (_selectedWeddingDate == null) return;

    try {
      await _anniversaryService.addWeddingAnniversary(
        customerId: 'current_user_id', // TODO(developer): Получить реальный ID
        spouseName: 'Текущий пользователь', // TODO(developer): Получить реальное имя
        weddingDate: _selectedWeddingDate!,
      );

      _dateController.clear();
      setState(() {
        _selectedWeddingDate = null;
      });

      _tabController.animateTo(0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Годовщина успешно добавлена!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка добавления: $e'), backgroundColor: Colors.red));
    }
  }

  void _handleAnniversaryAction(String action, WeddingAnniversary anniversary) {
    switch (action) {
      case 'edit':
        _editAnniversary(anniversary);
        break;
      case 'delete':
        _deleteAnniversary(anniversary);
        break;
    }
  }

  void _editAnniversary(WeddingAnniversary anniversary) {
    // TODO(developer): Реализовать редактирование годовщины
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Функция редактирования будет добавлена')));
  }

  void _deleteAnniversary(WeddingAnniversary anniversary) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить годовщину'),
        content: const Text('Вы уверены, что хотите удалить эту годовщину?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _anniversaryService.deleteAnniversary(anniversary.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Годовщина удалена'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showRecommendations(WeddingAnniversary anniversary) {
    showModalBottomSheet<void>(
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
              Text(
                'Рекомендации для ${anniversary.anniversaryName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: anniversary.anniversaryRecommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = anniversary.anniversaryRecommendations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.lightbulb, color: Colors.amber[600]),
                        title: Text(recommendation),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpecialists(WeddingAnniversary anniversary) {
    // TODO(developer): Показать специалистов для организации годовщины
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Функция поиска специалистов будет добавлена')));
  }

  String _getAnniversaryName(int years) {
    // Упрощенная версия для предварительного просмотра
    switch (years) {
      case 1:
        return 'Бумажная свадьба';
      case 5:
        return 'Деревянная свадьба';
      case 10:
        return 'Розовая свадьба';
      case 25:
        return 'Серебряная свадьба';
      case 50:
        return 'Золотая свадьба';
      default:
        return 'Годовщина свадьбы';
    }
  }

  String _getAnniversaryDescription(int years) {
    switch (years) {
      case 1:
        return 'Первый год совместной жизни - время узнавания друг друга';
      case 5:
        return 'Пять лет брака - отношения окрепли, семья стала крепче';
      case 10:
        return 'Десять лет брака - юбилейная дата, требующая особого внимания';
      case 25:
        return 'Серебряная свадьба - четверть века счастливой семейной жизни';
      case 50:
        return 'Золотая свадьба - полвека любви, верности и взаимопонимания';
      default:
        return 'Еще один год счастливой семейной жизни';
    }
  }
}
