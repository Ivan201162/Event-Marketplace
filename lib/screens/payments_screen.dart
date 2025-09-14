import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payment_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/payment_widgets.dart';
import '../models/payment.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Платежи'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Все'),
            Tab(icon: Icon(Icons.schedule), text: 'Ожидают'),
            Tab(icon: Icon(Icons.analytics), text: 'Статистика'),
          ],
        ),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Необходима авторизация',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllPaymentsTab(user.id, user.isSpecialist),
              _buildPendingPaymentsTab(user.id, user.isSpecialist),
              _buildStatisticsTab(user.id, user.isSpecialist),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Вкладка всех платежей
  Widget _buildAllPaymentsTab(String userId, bool isSpecialist) {
    final paymentsAsync = isSpecialist
        ? ref.watch(paymentsBySpecialistProvider(userId))
        : ref.watch(paymentsByCustomerProvider(userId));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Платежей пока нет',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Платежи появятся после создания заявок',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(isSpecialist ? paymentsBySpecialistProvider(userId) : paymentsByCustomerProvider(userId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PaymentCard(
                  payment: payment,
                  showActions: !isSpecialist, // Только клиенты могут оплачивать
                  onTap: () => _showPaymentDetails(context, payment),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки платежей: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(isSpecialist ? paymentsBySpecialistProvider(userId) : paymentsByCustomerProvider(userId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Вкладка ожидающих платежей
  Widget _buildPendingPaymentsTab(String userId, bool isSpecialist) {
    final paymentsAsync = isSpecialist
        ? ref.watch(paymentsBySpecialistProvider(userId))
        : ref.watch(paymentsByCustomerProvider(userId));

    return paymentsAsync.when(
      data: (payments) {
        final pendingPayments = payments.where((p) => p.isPending).toList();

        if (pendingPayments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Нет ожидающих платежей',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Все платежи обработаны',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(isSpecialist ? paymentsBySpecialistProvider(userId) : paymentsByCustomerProvider(userId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingPayments.length,
            itemBuilder: (context, index) {
              final payment = pendingPayments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PaymentCard(
                  payment: payment,
                  showActions: !isSpecialist,
                  onTap: () => _showPaymentDetails(context, payment),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки: $error'),
          ],
        ),
      ),
    );
  }

  /// Вкладка статистики
  Widget _buildStatisticsTab(String userId, bool isSpecialist) {
    final statisticsAsync = ref.watch(paymentStatisticsProvider(
      PaymentStatisticsParams(userId: userId, isSpecialist: isSpecialist),
    ));

    return statisticsAsync.when(
      data: (statistics) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Статистика
              PaymentStatisticsWidget(statistics: statistics),
              
              const SizedBox(height: 16),
              
              // Быстрые действия
              _buildQuickActionsCard(context, userId, isSpecialist),
              
              const SizedBox(height: 16),
              
              // Информация о типах организаций
              _buildOrganizationTypesCard(context),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки статистики: $error'),
          ],
        ),
      ),
    );
  }

  /// Карточка быстрых действий
  Widget _buildQuickActionsCard(BuildContext context, String userId, bool isSpecialist) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые действия',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!isSpecialist) ...[
              ElevatedButton.icon(
                onPressed: () => _showPaymentCalculationDialog(context),
                icon: const Icon(Icons.calculate),
                label: const Text('Рассчитать платежи'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => _showTestDataDialog(context),
              icon: const Icon(Icons.science),
              label: const Text('Добавить тестовые данные'),
            ),
          ],
        ),
      ),
    );
  }

  /// Карточка типов организаций
  Widget _buildOrganizationTypesCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Типы организаций и платежи',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOrganizationTypeInfo(
              context,
              'Физические лица',
              'Аванс 30% + доплата 70%',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildOrganizationTypeInfo(
              context,
              'Коммерческие организации',
              'Аванс 30% + доплата 70%',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildOrganizationTypeInfo(
              context,
              'Государственные учреждения',
              'Постоплата 100% (или 70/30)',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildOrganizationTypeInfo(
              context,
              'Некоммерческие организации',
              'Аванс 20% + доплата 80%',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  /// Информация о типе организации
  Widget _buildOrganizationTypeInfo(
    BuildContext context,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Показать детали платежа
  void _showPaymentDetails(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(payment.typeDisplayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID платежа', payment.id),
              _buildDetailRow('Сумма', '${payment.amount.toStringAsFixed(0)} ${payment.currency}'),
              _buildDetailRow('Статус', payment.statusDisplayName),
              _buildDetailRow('Тип организации', _getOrganizationTypeName(payment.organizationType)),
              if (payment.description != null)
                _buildDetailRow('Описание', payment.description!),
              if (payment.paymentMethod != null)
                _buildDetailRow('Способ оплаты', payment.paymentMethod!),
              if (payment.transactionId != null)
                _buildDetailRow('ID транзакции', payment.transactionId!),
              _buildDetailRow('Создан', _formatDate(payment.createdAt)),
              if (payment.completedAt != null)
                _buildDetailRow('Завершен', _formatDate(payment.completedAt!)),
              if (payment.failedAt != null)
                _buildDetailRow('Неудачен', _formatDate(payment.failedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Показать диалог расчета платежей
  void _showPaymentCalculationDialog(BuildContext context) {
    final amountController = TextEditingController();
    OrganizationType selectedType = OrganizationType.individual;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Расчет платежей'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Общая сумма (₽)',
                    hintText: 'Введите сумму',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Тип организации:'),
                const SizedBox(height: 8),
                ...OrganizationType.values.map((type) => RadioListTile<OrganizationType>(
                  title: Text(_getOrganizationTypeName(type)),
                  value: type,
                  groupValue: selectedType,
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                )),
                if (amountController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PaymentCalculationWidget(
                    totalAmount: double.tryParse(amountController.text) ?? 0,
                    organizationType: selectedType,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  /// Показать диалог тестовых данных
  void _showTestDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тестовые данные'),
        content: const Text('Добавить тестовые данные платежей для разработки?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Добавить тестовые данные платежей
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Тестовые данные добавлены')),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  /// Построить строку деталей
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  /// Получить название типа организации
  String _getOrganizationTypeName(OrganizationType type) {
    switch (type) {
      case OrganizationType.individual:
        return 'Физическое лицо';
      case OrganizationType.commercial:
        return 'Коммерческая организация';
      case OrganizationType.government:
        return 'Государственное учреждение';
      case OrganizationType.non_profit:
        return 'Некоммерческая организация';
    }
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
