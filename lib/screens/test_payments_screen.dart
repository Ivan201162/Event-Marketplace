import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/payment.dart';
import 'package:event_marketplace_app/screens/payment_history_screen.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/services/payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Тестовый экран для проверки финансового модуля
class TestPaymentsScreen extends ConsumerStatefulWidget {
  const TestPaymentsScreen({super.key});

  @override
  ConsumerState<TestPaymentsScreen> createState() => _TestPaymentsScreenState();
}

class _TestPaymentsScreenState extends ConsumerState<TestPaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService = BookingService();
  List<Payment> _payments = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  final String _selectedUserId = 'test_user_1';
  final String _selectedSpecialistId = 'test_specialist_1';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payments = await _paymentService.getAllPayments(limit: 20);
      final bookings = await _bookingService.getAllBookings(limit: 10);

      setState(() {
        _payments = payments;
        _bookings = bookings;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тест финансового модуля'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildContent(),
      );

  Widget _buildErrorWidget() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadData, child: const Text('Повторить'),),
          ],
        ),
      );

  Widget _buildContent() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestActions(),
            const SizedBox(height: 24),
            _buildStatistics(),
            const SizedBox(height: 24),
            _buildPaymentsList(),
            const SizedBox(height: 24),
            _buildBookingsList(),
          ],
        ),
      );

  Widget _buildTestActions() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Тестовые действия',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _createTestDepositPayment,
                    child: const Text('Создать предоплату'),
                  ),
                  ElevatedButton(
                    onPressed: _createTestFinalPayment,
                    child: const Text('Создать окончательный платеж'),
                  ),
                  ElevatedButton(
                      onPressed: _createTestRefund,
                      child: const Text('Создать возврат'),),
                  ElevatedButton(
                      onPressed: _updatePaymentStatus,
                      child: const Text('Обновить статус'),),
                  ElevatedButton(
                    onPressed: _generateFinancialReport,
                    child: const Text('Создать отчет'),
                  ),
                  ElevatedButton(
                      onPressed: _showPaymentHistory,
                      child: const Text('История платежей'),),
                  ElevatedButton(
                    onPressed: _showSpecialistPayments,
                    child: const Text('Платежи специалиста'),
                  ),
                  ElevatedButton(
                    onPressed: _testBookingWithPayments,
                    child: const Text('Тест бронирования'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatistics() {
    final completedPayments = _payments.where((p) => p.isCompleted).length;
    final pendingPayments = _payments.where((p) => p.isActive).length;
    final totalAmount = _payments
        .where((p) => p.isCompleted)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Статистика',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Всего платежей',
                    value: _payments.length.toString(),
                    icon: Icons.payment,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Завершенных',
                    value: completedPayments.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Ожидающих',
                    value: pendingPayments.toString(),
                    icon: Icons.schedule,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Общая сумма',
                    value: '${totalAmount.toStringAsFixed(2)} ₽',
                    icon: Icons.account_balance_wallet,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Последние платежи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_payments.isEmpty)
                const Text('Платежи не найдены')
              else
                ..._payments.take(5).map(
                      (payment) => _PaymentListItem(
                          payment: payment,
                          onTap: () => _showPaymentDetails(payment),),
                    ),
            ],
          ),
        ),
      );

  Widget _buildBookingsList() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Бронирования',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16),
              if (_bookings.isEmpty)
                const Text('Бронирования не найдены')
              else
                ..._bookings.take(3).map(
                      (booking) => _BookingListItem(
                          booking: booking,
                          onTap: () => _showBookingDetails(booking),),
                    ),
            ],
          ),
        ),
      );

  Future<void> _createTestDepositPayment() async {
    try {
      final payment = await _paymentService.createDepositPayment(
        bookingId: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        userId: _selectedUserId,
        specialistId: _selectedSpecialistId,
        totalAmount: 50000, // 50,000 рублей
        currency: 'RUB',
        method: PaymentMethod.card,
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );

      _showSuccessMessage('Предоплата создана: ${payment.formattedAmount}');
      _loadData();
    } on Exception catch (e) {
      _showErrorMessage('Ошибка создания предоплаты: $e');
    }
  }

  Future<void> _createTestFinalPayment() async {
    try {
      final payment = await _paymentService.createFinalPayment(
        bookingId: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        userId: _selectedUserId,
        specialistId: _selectedSpecialistId,
        totalAmount: 50000, // 50,000 рублей
        currency: 'RUB',
        method: PaymentMethod.card,
        dueDate: DateTime.now().add(const Duration(days: 7)),
      );

      _showSuccessMessage(
          'Окончательный платеж создан: ${payment.formattedAmount}',);
      _loadData();
    } on Exception catch (e) {
      _showErrorMessage('Ошибка создания окончательного платежа: $e');
    }
  }

  Future<void> _createTestRefund() async {
    try {
      if (_payments.isEmpty) {
        _showErrorMessage('Нет платежей для возврата');
        return;
      }

      final originalPayment = _payments.first;
      final refund = await _paymentService.createRefund(
        originalPaymentId: originalPayment.id,
        bookingId: originalPayment.bookingId,
        userId: originalPayment.userId,
        specialistId: originalPayment.specialistId,
        amount: originalPayment.amount * 0.5, // Возврат 50%
        currency: originalPayment.currency,
        reason: 'Тестовый возврат',
      );

      _showSuccessMessage('Возврат создан: ${refund.formattedAmount}');
      _loadData();
    } on Exception catch (e) {
      _showErrorMessage('Ошибка создания возврата: $e');
    }
  }

  Future<void> _updatePaymentStatus() async {
    if (_payments.isEmpty) {
      _showErrorMessage('Нет платежей для обновления');
      return;
    }

    final payment = _payments.first;
    final newStatus = payment.status == PaymentStatus.pending
        ? PaymentStatus.completed
        : PaymentStatus.pending;

    try {
      await _paymentService.updatePaymentStatus(
        payment.id,
        newStatus,
        transactionId: 'test_txn_${DateTime.now().millisecondsSinceEpoch}',
      );

      _showSuccessMessage('Статус обновлен: ${newStatus.statusName}');
      _loadData();
    } on Exception catch (e) {
      _showErrorMessage('Ошибка обновления статуса: $e');
    }
  }

  Future<void> _generateFinancialReport() async {
    try {
      final report = await _paymentService.generateFinancialReport(
        userId: _selectedUserId,
        period: '2024-01',
      );

      _showSuccessMessage(
        'Отчет создан:\n'
        'Доходы: ${report.formattedIncome}\n'
        'Расходы: ${report.formattedExpenses}\n'
        'Чистый доход: ${report.formattedNetIncome}',
      );
    } on Exception catch (e) {
      _showErrorMessage('Ошибка создания отчета: $e');
    }
  }

  void _showPaymentHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (context) => PaymentHistoryScreen(userId: _selectedUserId),),
    );
  }

  void _showSpecialistPayments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PaymentHistoryScreen(
            userId: _selectedSpecialistId, isSpecialist: true,),
      ),
    );
  }

  Future<void> _testBookingWithPayments() async {
    try {
      // Создаем тестовое бронирование
      final bookingData = Booking(
        id: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        specialistId: _selectedSpecialistId,
        specialistName: 'Тестовый специалист',
        clientId: _selectedUserId,
        clientName: 'Тестовый клиент',
        service: 'Тестовая услуга',
        date: DateTime.now().add(const Duration(days: 7)),
        time: '12:00',
        duration: 2,
        totalPrice: 50000,
        notes: 'Тестовое бронирование для проверки платежей',
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        eventTitle: 'Тестовое событие',
        participantsCount: 10,
      );

      final bookingId = await _bookingService.createBooking(bookingData);

      _showSuccessMessage('Бронирование создано: $bookingId');
      _loadData();
    } on Exception catch (e) {
      _showErrorMessage('Ошибка создания бронирования: $e');
    }
  }

  void _showPaymentDetails(Payment payment) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(payment.typeName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${payment.id}'),
              Text('Сумма: ${payment.formattedAmount}'),
              Text('Статус: ${payment.statusName}'),
              Text('Метод: ${payment.methodName}'),
              Text('Описание: ${payment.description}'),
              if (payment.transactionId != null)
                Text('Транзакция: ${payment.transactionId}'),
              Text('Создан: ${_formatDate(payment.createdAt)}'),
              if (payment.dueDate != null)
                Text('Срок: ${_formatDate(payment.dueDate!)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.eventTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${booking.id}'),
              Text('Статус: ${booking.status.name}'),
              Text('Дата: ${_formatDate(booking.bookingDate)}'),
              Text('Участники: ${booking.participantsCount}'),
              Text('Цена: ${booking.totalPrice} ₽'),
              Text('Заметки: ${booking.notes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

/// Карточка статистики
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color,),
            ),
            Text(title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,),
          ],
        ),
      );
}

/// Элемент списка платежей
class _PaymentListItem extends StatelessWidget {
  const _PaymentListItem({required this.payment, required this.onTap});

  final Payment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(payment.status),
          child: Text(payment.typeIcon, style: const TextStyle(fontSize: 16)),
        ),
        title: Text(payment.typeName),
        subtitle: Text('${payment.formattedAmount} • ${payment.statusName}'),
        trailing: Text(_formatDate(payment.createdAt)),
        onTap: onTap,
      );

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
}

/// Элемент списка бронирований
class _BookingListItem extends StatelessWidget {
  const _BookingListItem({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(booking.status),
          child: Text(
            booking.status.name[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold,),
          ),
        ),
        title: Text(booking.eventTitle),
        subtitle: Text(
            '${booking.participantsCount} участников • ${booking.totalPrice} ₽',),
        trailing: Text(_formatDate(booking.bookingDate)),
        onTap: onTap,
      );

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.rejected:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
}
