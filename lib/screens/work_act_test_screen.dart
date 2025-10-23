import 'package:flutter/material.dart';
import '../services/work_act_service.dart';
import '../widgets/work_act_signature_widget.dart';
import '../widgets/work_act_widget.dart';

/// Тестовый экран для проверки функциональности актов выполненных работ
class WorkActTestScreen extends StatefulWidget {
  const WorkActTestScreen({super.key});

  @override
  State<WorkActTestScreen> createState() => _WorkActTestScreenState();
}

class _WorkActTestScreenState extends State<WorkActTestScreen>
    with TickerProviderStateMixin {
  final WorkActService _workActService = WorkActService();

  final String _testBookingId = 'test_booking_123';
  final String _testSpecialistId = 'test_specialist_456';
  final String _testCustomerId = 'test_customer_789';

  List<WorkAct> _workActs = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadWorkActs();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тест актов выполненных работ'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: TabController(
                length: 3, vsync: this, initialIndex: _selectedTabIndex),
            onTap: (index) => setState(() => _selectedTabIndex = index),
            tabs: const [
              Tab(icon: Icon(Icons.add), text: 'Создать'),
              Tab(icon: Icon(Icons.list), text: 'Список'),
              Tab(icon: Icon(Icons.edit), text: 'Подписать'),
            ],
          ),
        ),
        body: TabBarView(
          controller: TabController(
              length: 3, vsync: this, initialIndex: _selectedTabIndex),
          children: [_buildCreateTab(), _buildListTab(), _buildSignTab()],
        ),
      );

  Widget _buildCreateTab() => SingleChildScrollView(
        child: Column(
          children: [
            _buildTestInfo(),
            const SizedBox(height: 16),
            WorkActWidget(
              bookingId: _testBookingId,
              specialistId: _testSpecialistId,
              customerId: _testCustomerId,
              onActCreated: () {
                _loadWorkActs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Акт создан!'),
                      backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
      );

  Widget _buildListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadWorkActs, child: const Text('Повторить')),
          ],
        ),
      );
    }

    if (_workActs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Акты выполненных работ не найдены',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Создайте первый акт на вкладке "Создать"',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workActs.length,
      itemBuilder: (context, index) {
        final workAct = _workActs[index];
        return _buildWorkActCard(workAct);
      },
    );
  }

  Widget _buildSignTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final draftActs =
        _workActs.where((act) => act.status == WorkActStatus.draft).toList();

    if (draftActs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Нет актов для подписания',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Все акты уже подписаны или отклонены',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: draftActs.length,
      itemBuilder: (context, index) {
        final workAct = draftActs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workAct.eventName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildStatusChip(workAct.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Дата: ${workAct.eventDate}'),
                Text('Место: ${workAct.eventLocation}'),
                Text('Сумма: ${workAct.totalAmount.toStringAsFixed(2)} ₽'),
                const SizedBox(height: 16),
                WorkActSignatureWidget(
                  workAct: workAct,
                  userId: _testCustomerId,
                  onActSigned: () {
                    _loadWorkActs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Акт подписан!'),
                          backgroundColor: Colors.green),
                    );
                  },
                  onActRejected: () {
                    _loadWorkActs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Акт отклонен!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestInfo() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Информация о тесте',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Booking ID: $_testBookingId'),
            Text('Specialist ID: $_testSpecialistId'),
            Text('Customer ID: $_testCustomerId'),
            const SizedBox(height: 8),
            const Text(
              'Этот экран позволяет протестировать функциональность создания, просмотра и подписания актов выполненных работ.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildWorkActCard(WorkAct workAct) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workAct.eventName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusChip(workAct.status),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Дата:', workAct.eventDate),
              _buildInfoRow('Место:', workAct.eventLocation),
              _buildInfoRow(
                  'Сумма:', '${workAct.totalAmount.toStringAsFixed(2)} ₽'),
              _buildInfoRow('Создан:', _formatDate(workAct.createdAt)),
              if (workAct.signedAt != null)
                _buildInfoRow('Подписан:', _formatDate(workAct.signedAt!)),
              if (workAct.notes != null) ...[
                const SizedBox(height: 8),
                const Text('Примечания:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(workAct.notes!),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showWorkActDetails(workAct),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Подробнее'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _generatePDF(workAct),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _buildStatusChip(WorkActStatus status) {
    Color color;
    String text;

    switch (status) {
      case WorkActStatus.draft:
        color = Colors.orange;
        text = 'Черновик';
        break;
      case WorkActStatus.signed:
        color = Colors.green;
        text = 'Подписан';
        break;
      case WorkActStatus.rejected:
        color = Colors.red;
        text = 'Отклонен';
        break;
    }

    return Chip(
      label:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  // ========== МЕТОДЫ ==========

  Future<void> _loadWorkActs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final acts = await _workActService.getWorkActsByBooking(_testBookingId);
      setState(() {
        _workActs = acts;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Ошибка загрузки актов: $e';
        _isLoading = false;
      });
    }
  }

  void _showWorkActDetails(WorkAct workAct) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workAct.eventName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Дата:', workAct.eventDate),
              _buildInfoRow('Место:', workAct.eventLocation),
              _buildInfoRow(
                  'Сумма:', '${workAct.totalAmount.toStringAsFixed(2)} ₽'),
              _buildInfoRow('Статус:', _getStatusText(workAct.status)),
              _buildInfoRow('Создан:', _formatDate(workAct.createdAt)),
              if (workAct.signedAt != null)
                _buildInfoRow('Подписан:', _formatDate(workAct.signedAt!)),
              if (workAct.notes != null) ...[
                const SizedBox(height: 8),
                const Text('Примечания:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(workAct.notes!),
              ],
              const SizedBox(height: 16),
              const Text('Выполненные работы:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...workAct.services.map(
                (service) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${service.name} (${service.quantity} шт.) - ${service.price.toStringAsFixed(2)} ₽',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Future<void> _generatePDF(WorkAct workAct) async {
    try {
      await _workActService.generateWorkActPDF(workAct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PDF создан успешно'),
              backgroundColor: Colors.green),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка создания PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getStatusText(WorkActStatus status) {
    switch (status) {
      case WorkActStatus.draft:
        return 'Черновик';
      case WorkActStatus.signed:
        return 'Подписан';
      case WorkActStatus.rejected:
        return 'Отклонен';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
