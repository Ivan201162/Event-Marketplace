import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../providers/firestore_providers.dart';
import '../providers/user_role_provider.dart';
import '../providers/payment_providers.dart';
import '../widgets/payment_widgets.dart';

final myBookingsProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final customerId = ref.watch(demoCustomerIdProvider);
  return service.bookingsByCustomerStream(customerId);
});

// Провайдер для фильтрации заявок по статусу
final bookingFilterProvider = StateProvider<String>((ref) => 'all');

// Провайдер для отфильтрованных заявок
final filteredBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(myBookingsProvider).when(
    data: (bookings) => bookings,
    loading: () => <Booking>[],
    error: (_, __) => <Booking>[],
  );
  
  final filter = ref.watch(bookingFilterProvider);
  
  if (filter == 'all') return bookings;
  return bookings.where((booking) => booking.status == filter).toList();
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBookingsProvider);
    final filteredBookings = ref.watch(filteredBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заявки'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: async.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'У вас пока нет заявок',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Создайте первую заявку в разделе "Поиск"',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (filteredBookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет заявок с выбранным фильтром',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Статистика заявок
              _buildBookingsStats(context, bookings),
              // Список заявок
              Expanded(
                child: ListView.builder(
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildBookingCard(context, ref, booking);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myBookingsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Построение статистики заявок
  Widget _buildBookingsStats(BuildContext context, List<Booking> bookings) {
    final pendingCount = bookings.where((b) => b.status == 'pending').length;
    final confirmedCount = bookings.where((b) => b.status == 'confirmed').length;
    final rejectedCount = bookings.where((b) => b.status == 'rejected').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Ожидают', pendingCount, Colors.orange),
          _buildStatItem(context, 'Подтверждены', confirmedCount, Colors.green),
          _buildStatItem(context, 'Отклонены', rejectedCount, Colors.red),
        ],
      ),
    );
  }

  /// Построение элемента статистики
  Widget _buildStatItem(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// Построение карточки заявки
  Widget _buildBookingCard(BuildContext context, WidgetRef ref, Booking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showBookingDetails(context, ref, booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с статусом
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Специалист: ${booking.specialistId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),
              const SizedBox(height: 12),
              
              // Информация о дате и времени
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm', 'ru').format(booking.eventDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Информация о стоимости
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Итого: ${booking.totalPrice.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Аванс: ${booking.prepayment.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Статус оплаты
              Row(
                children: [
                  Icon(
                    booking.prepaymentPaid ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: booking.prepaymentPaid ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Аванс: ${booking.prepaymentPaid ? 'Оплачен' : 'Не оплачен'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: booking.prepaymentPaid ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Платежи
              const SizedBox(height: 12),
              _buildPaymentsSection(context, ref, booking),
              
              // Кнопка действия
              if (booking.status == 'confirmed' && !booking.prepaymentPaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(context, ref, booking),
                    icon: const Icon(Icons.payment),
                    label: const Text('Оплатить аванс'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Построение чипа статуса
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Ожидает';
        break;
      case 'confirmed':
        color = Colors.green;
        label = 'Подтверждена';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Отклонена';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Показать диалог фильтрации
  Future<void> _showFilterDialog(BuildContext context, WidgetRef ref) async {
    final currentFilter = ref.read(bookingFilterProvider);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр заявок'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Все заявки'),
              value: 'all',
              groupValue: currentFilter,
              onChanged: (value) {
                if (value != null) {
                  ref.read(bookingFilterProvider.notifier).state = value;
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Ожидают подтверждения'),
              value: 'pending',
              groupValue: currentFilter,
              onChanged: (value) {
                if (value != null) {
                  ref.read(bookingFilterProvider.notifier).state = value;
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Подтверждены'),
              value: 'confirmed',
              groupValue: currentFilter,
              onChanged: (value) {
                if (value != null) {
                  ref.read(bookingFilterProvider.notifier).state = value;
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Отклонены'),
              value: 'rejected',
              groupValue: currentFilter,
              onChanged: (value) {
                if (value != null) {
                  ref.read(bookingFilterProvider.notifier).state = value;
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  /// Показать детали заявки
  Future<void> _showBookingDetails(BuildContext context, WidgetRef ref, Booking booking) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали заявки'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID заявки', booking.id),
              _buildDetailRow('Специалист', booking.specialistId),
              _buildDetailRow('Дата создания', DateFormat('dd.MM.yyyy HH:mm', 'ru').format(booking.createdAt)),
              _buildDetailRow('Дата мероприятия', DateFormat('dd.MM.yyyy HH:mm', 'ru').format(booking.eventDate)),
              _buildDetailRow('Статус', _getStatusLabel(booking.status)),
              _buildDetailRow('Общая стоимость', '${booking.totalPrice.toStringAsFixed(0)} ₽'),
              _buildDetailRow('Аванс', '${booking.prepayment.toStringAsFixed(0)} ₽'),
              _buildDetailRow('Остаток к доплате', '${(booking.totalPrice - booking.prepayment).toStringAsFixed(0)} ₽'),
              _buildDetailRow('Статус оплаты аванса', booking.prepaymentPaid ? 'Оплачен' : 'Не оплачен'),
              _buildDetailRow('Статус платежа', booking.paymentStatus),
            ],
          ),
        ),
        actions: [
          if (booking.status == 'pending') ...[
            TextButton(
              onPressed: () => _showCancelDialog(context, ref, booking),
              child: const Text('Отменить заявку', style: TextStyle(color: Colors.red)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Построение строки деталей
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Получить русское название статуса
  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Ожидает подтверждения';
      case 'confirmed':
        return 'Подтверждена';
      case 'rejected':
        return 'Отклонена';
      default:
        return status;
    }
  }

  /// Показать диалог оплаты
  Future<void> _showPaymentDialog(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оплата аванса'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сумма к оплате: ${booking.prepayment.toStringAsFixed(0)} ₽'),
            const SizedBox(height: 12),
            const Text(
              'Это имитация оплаты. В реальном приложении здесь будет интеграция с платежной системой.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Оплатить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(firestoreServiceProvider).updatePaymentStatus(
          booking.id, 
          prepaymentPaid: true, 
          paymentStatus: 'paid'
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Аванс успешно оплачен!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка оплаты: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Показать диалог отмены заявки
  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена заявки'),
        content: const Text(
          'Вы уверены, что хотите отменить эту заявку? Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(firestoreServiceProvider).updateBookingStatus(booking.id, 'cancelled');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заявка отменена'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(); // Закрыть диалог деталей
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка отмены: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Построить секцию платежей
  Widget _buildPaymentsSection(BuildContext context, WidgetRef ref, Booking booking) {
    final paymentsAsync = ref.watch(paymentsByBookingProvider(booking.id));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Платежи не созданы',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Платежи (${payments.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...payments.map((payment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPaymentItem(context, payment),
            )),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 20,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ошибка загрузки платежей',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить элемент платежа
  Widget _buildPaymentItem(BuildContext context, Payment payment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getPaymentStatusColor(payment.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getPaymentStatusIcon(payment.status),
            size: 16,
            color: _getPaymentStatusColor(payment.status),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.typeDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${payment.amount.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (payment.isPending)
            GestureDetector(
              onTap: () => _showQuickPaymentDialog(context, payment),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Оплатить',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Показать диалог быстрой оплаты
  void _showQuickPaymentDialog(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(payment: payment),
    );
  }

  /// Получить цвет статуса платежа
  Color _getPaymentStatusColor(PaymentStatus status) {
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

  /// Получить иконку статуса платежа
  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.processing:
        return Icons.hourglass_empty;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.undo;
    }
  }
}