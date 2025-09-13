import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../providers/firestore_providers.dart';
import '../providers/user_role_provider.dart';

final myBookingsProvider = StreamProvider.autoDispose<List<Booking>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final customerId = ref.watch(demoCustomerIdProvider);
  return service.bookingsByCustomerStream(customerId);
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои заявки')),
      body: async.when(
        data: (bookings) {
          if (bookings.isEmpty) return const Center(child: Text('У вас пока нет заявок'));
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Специалист: ${b.specialistId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Дата: ${b.eventDate.toLocal().toString().split(" ")[0]}'),
                      Text('Статус: ${b.status}'),
                      Text('Итог: ${b.totalPrice} ₽, Аванс: ${b.prepayment} ₽'),
                      Text('Оплата: ${b.paymentStatus}'),
                    ],
                  ),
                  trailing: (b.status == 'confirmed' && !b.prepaymentPaid)
                      ? ElevatedButton(
                          onPressed: () async {
                            // имитация оплаты: обновляем в Firestore
                            await ref.read(firestoreServiceProvider).updatePaymentStatus(b.id, prepaymentPaid: true, paymentStatus: 'paid');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Аванс оплачен (имитация)')));
                            }
                          },
                          child: const Text('Оплатить аванс'),
                        )
                      : null,
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
}