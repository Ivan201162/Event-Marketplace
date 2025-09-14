import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../providers/firestore_providers.dart';
import '../providers/user_role_provider.dart';

final bookingRequestsProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final specialistId = ref.watch(demoSpecialistIdProvider);
  return service.bookingsBySpecialistStream(specialistId);
});

class BookingRequestsScreen extends ConsumerWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки клиентов'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: async.when(
        data: (bookings) {
          if (bookings.isEmpty) return const Center(child: Text('Заявок пока нет'));
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Клиент: ${b.customerId}'),
                  subtitle: Text('Дата: ${DateFormat('dd.MM.yyyy HH:mm', 'ru').format(b.eventDate)} \nАванс: ${b.prepayment.toStringAsFixed(0)} ₽'),
                  isThreeLine: true,
                  trailing: b.status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _showConfirmDialog(context, ref, b),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _showRejectDialog(context, ref, b),
                            ),
                          ],
                        )
                      : Text(b.status),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  /// Показать диалог подтверждения заявки
  Future<void> _showConfirmDialog(BuildContext context, WidgetRef ref, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение заявки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы уверены, что хотите подтвердить заявку от ${booking.customerId}?'),
            const SizedBox(height: 12),
            Text('Дата: ${DateFormat('dd.MM.yyyy HH:mm', 'ru').format(booking.eventDate)}'),
            Text('Аванс: ${booking.prepayment.toStringAsFixed(0)} ₽'),
            Text('Итого: ${booking.totalPrice.toStringAsFixed(0)} ₽'),
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
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _updateBookingStatus(context, ref, booking.id, 'confirmed', 'Заявка подтверждена');
    }
  }

  /// Показать диалог отклонения заявки
  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref, Booking booking) async {
    final rejected = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонение заявки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы уверены, что хотите отклонить заявку от ${booking.customerId}?'),
            const SizedBox(height: 12),
            Text('Дата: ${DateFormat('dd.MM.yyyy HH:mm', 'ru').format(booking.eventDate)}'),
            const SizedBox(height: 8),
            const Text(
              'Это действие нельзя будет отменить.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (rejected == true && context.mounted) {
      await _updateBookingStatus(context, ref, booking.id, 'rejected', 'Заявка отклонена');
    }
  }

  /// Обновление статуса заявки с уведомлением
  Future<void> _updateBookingStatus(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    String status,
    String successMessage,
  ) async {
    try {
      await ref.read(firestoreServiceProvider).updateBookingStatus(bookingId, status);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}