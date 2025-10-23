import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_extended.dart';
import '../services/payment_extended_service.dart';
import '../widgets/payment_card_widget.dart';
import '../widgets/payment_type_selector.dart';

/// Расширенный экран управления платежами
class PaymentsExtendedScreen extends ConsumerStatefulWidget {
  const PaymentsExtendedScreen(
      {super.key, required this.userId, this.isCustomer = true});
  final String userId;
  final bool isCustomer;

  @override
  ConsumerState<PaymentsExtendedScreen> createState() =>
      _PaymentsExtendedScreenState();
}

class _PaymentsExtendedScreenState extends ConsumerState<PaymentsExtendedScreen>
    with TickerProviderStateMixin {
  final PaymentExtendedService _paymentService = PaymentExtendedService();
  late TabController _tabController;
  AdvancePaymentSettings _settings = const AdvancePaymentSettings();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.isCustomer ? 'Мои платежи' : 'Платежи клиентов'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.list)),
              Tab(text: 'Ожидают', icon: Icon(Icons.pending)),
              Tab(text: 'Статистика', icon: Icon(Icons.analytics)),
            ],
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showCreatePaymentDialog),
            if (!widget.isCustomer)
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSettingsDialog),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllPaymentsTab(),
            _buildPendingPaymentsTab(),
            _buildStatsTab()
          ],
        ),
      );

  Widget _buildAllPaymentsTab() => StreamBuilder<List<PaymentExtended>>(
        stream: _paymentService.getUserPayments(widget.userId,
            isCustomer: widget.isCustomer),
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
                      child: const Text('Повторить')),
                ],
              ),
            );
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return _buildEmptyState(
              'Нет платежей',
              'Создайте первый платеж для начала работы',
              Icons.payment,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return PaymentCardWidget(
                payment: payment,
                onTap: () => _showPaymentDetails(payment),
                onPay: payment.remainingAmount > 0
                    ? () => _showPaymentDialog(payment)
                    : null,
                onDownloadReceipt: payment.receiptPdfUrl != null
                    ? () => _downloadReceipt(payment)
                    : null,
                onDownloadInvoice: payment.invoicePdfUrl != null
                    ? () => _downloadInvoice(payment)
                    : null,
              );
            },
          );
        },
      );

  Widget _buildPendingPaymentsTab() => StreamBuilder<List<PaymentExtended>>(
        stream: _paymentService.getUserPayments(widget.userId,
            isCustomer: widget.isCustomer),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPayments = snapshot.data ?? [];
          final pendingPayments = allPayments
              .where((p) =>
                  p.status == PaymentStatus.pending ||
                  p.status == PaymentStatus.processing)
              .toList();

          if (pendingPayments.isEmpty) {
            return _buildEmptyState(
              'Нет ожидающих платежей',
              'Все платежи обработаны',
              Icons.check_circle,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: pendingPayments.length,
            itemBuilder: (context, index) {
              final payment = pendingPayments[index];
              return PaymentCardWidget(
                payment: payment,
                onTap: () => _showPaymentDetails(payment),
                onPay: () => _showPaymentDialog(payment),
                onDownloadReceipt: payment.receiptPdfUrl != null
                    ? () => _downloadReceipt(payment)
                    : null,
                onDownloadInvoice: payment.invoicePdfUrl != null
                    ? () => _downloadInvoice(payment)
                    : null,
              );
            },
          );
        },
      );

  Widget _buildStatsTab() => FutureBuilder<PaymentStats>(
        future: _paymentService.getPaymentStats(widget.userId,
            isCustomer: widget.isCustomer),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? PaymentStats.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Общая статистика
                _buildStatsCard('Общая статистика', [
                  _buildStatItem('Всего платежей',
                      stats.totalPayments.toString(), Icons.payment),
                  _buildStatItem('Завершено',
                      stats.completedPayments.toString(), Icons.check_circle),
                  _buildStatItem('Ожидают', stats.pendingPayments.toString(),
                      Icons.pending),
                  _buildStatItem(
                      'Ошибки', stats.failedPayments.toString(), Icons.error),
                ]),

                const SizedBox(height: 16),

                // Финансовая статистика
                _buildStatsCard('Финансовая статистика', [
                  _buildStatItem(
                    'Общая сумма',
                    '${stats.totalAmount.toStringAsFixed(2)} ₽',
                    Icons.account_balance_wallet,
                  ),
                  _buildStatItem(
                    'Оплачено',
                    '${stats.paidAmount.toStringAsFixed(2)} ₽',
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    'Остаток',
                    '${stats.pendingAmount.toStringAsFixed(2)} ₽',
                    Icons.pending,
                  ),
                  _buildStatItem(
                    'Успешность',
                    '${stats.successRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                  ),
                ]),

                const SizedBox(height: 16),

                // Типы платежей
                if (stats.paymentsByType.isNotEmpty) ...[
                  _buildStatsCard(
                    'По типам платежей',
                    stats.paymentsByType.entries
                        .map(
                          (entry) => _buildStatItem(
                            _getPaymentTypeText(entry.key),
                            entry.value.toString(),
                            _getPaymentTypeIcon(entry.key),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Статусы платежей
                if (stats.paymentsByStatus.isNotEmpty) ...[
                  _buildStatsCard(
                    'По статусам',
                    stats.paymentsByStatus.entries
                        .map(
                          (entry) => _buildStatItem(
                            _getStatusText(entry.key),
                            entry.value.toString(),
                            _getStatusIcon(entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        },
      );

  Widget _buildEmptyState(String title, String subtitle, IconData icon) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildStatsCard(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildStatItem(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Future<void> _loadSettings() async {
    final settings = await _paymentService.getAdvancePaymentSettings();
    setState(() {
      _settings = settings;
    });
  }

  void _showCreatePaymentDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать платеж'),
        content: SizedBox(
          width: double.maxFinite,
          child: PaymentTypeSelector(
            totalAmount: 50000, // TODO(developer): Получить из контекста
            settings: _settings,
            onPaymentTypeSelected:
                (type, advancePercentage, installments) async {
              Navigator.pop(context);
              await _createPayment(type, advancePercentage, installments);
            },
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(PaymentExtended payment) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Платеж ${payment.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Тип: ${_getPaymentTypeText(payment.type.name)}'),
              Text('Статус: ${_getStatusText(payment.status.name)}'),
              Text('Общая сумма: ${payment.totalAmount.toStringAsFixed(2)} ₽'),
              Text('Оплачено: ${payment.paidAmount.toStringAsFixed(2)} ₽'),
              Text('Остаток: ${payment.remainingAmount.toStringAsFixed(2)} ₽'),
              const SizedBox(height: 16),
              const Text('Взносы:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...payment.installments.map(
                (installment) => ListTile(
                  title: Text(_formatDate(installment.dueDate)),
                  subtitle: Text('${installment.amount.toStringAsFixed(2)} ₽'),
                  trailing: Text(_getStatusText(installment.status.name)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showPaymentDialog(PaymentExtended payment) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оплата'),
        content: const Text(
            'Функция оплаты будет интегрирована с платежными системами.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simulatePayment(payment);
            },
            child: const Text('Оплатить'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки предоплаты'),
        content: const Text(
            'Настройки предоплаты будут доступны в следующих версиях.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Future<void> _createPayment(
    PaymentType type,
    double? advancePercentage,
    int? installments,
  ) async {
    final paymentId = await _paymentService.createPayment(
      bookingId: 'demo_booking_${DateTime.now().millisecondsSinceEpoch}',
      customerId: widget.userId,
      specialistId: 'demo_specialist',
      totalAmount: 50000,
      type: type,
      advancePercentage: advancePercentage,
      installmentsCount: installments,
    );

    if (mounted) {
      if (paymentId != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Платеж создан успешно')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка создания платежа')));
      }
    }
  }

  Future<void> _simulatePayment(PaymentExtended payment) async {
    // Симуляция оплаты
    final success = await _paymentService.payInstallment(
      paymentId: payment.id,
      installmentId: payment.installments.first.id,
      transactionId:
          'demo_transaction_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Платеж выполнен успешно')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка выполнения платежа')));
      }
    }
  }

  Future<void> _downloadReceipt(PaymentExtended payment) async {
    if (payment.receiptPdfUrl == null) {
      final url = await _paymentService.generateReceiptPdf(payment);
      if (url != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Квитанция сгенерирована')));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Скачивание квитанции (в разработке)')));
    }
  }

  Future<void> _downloadInvoice(PaymentExtended payment) async {
    if (payment.invoicePdfUrl == null) {
      final url = await _paymentService.generateInvoicePdf(payment);
      if (url != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Счёт сгенерирован')));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Скачивание счёта (в разработке)')));
    }
  }

  String _getPaymentTypeText(String type) {
    switch (type) {
      case 'full':
        return 'Полная оплата';
      case 'advance':
        return 'Предоплата';
      case 'installment':
        return 'Рассрочка';
      case 'partial':
        return 'Частичная оплата';
      default:
        return type;
    }
  }

  IconData _getPaymentTypeIcon(String type) {
    switch (type) {
      case 'full':
        return Icons.payment;
      case 'advance':
        return Icons.account_balance_wallet;
      case 'installment':
        return Icons.schedule;
      case 'partial':
        return Icons.percent;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'processing':
        return 'Обработка';
      case 'completed':
        return 'Завершено';
      case 'failed':
        return 'Ошибка';
      case 'cancelled':
        return 'Отменено';
      case 'refunded':
        return 'Возвращено';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
