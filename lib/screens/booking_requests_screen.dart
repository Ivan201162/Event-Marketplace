import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(title: const Text('Заявки клиентов')),
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
                  subtitle: Text('Дата: ${b.eventDate.toLocal().toString().split(" ")[0]} \nАванс: ${b.prepayment} ₽'),
                  isThreeLine: true,
                  trailing: b.status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await ref.read(firestoreServiceProvider).updateBookingStatus(b.id, 'confirmed');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await ref.read(firestoreServiceProvider).updateBookingStatus(b.id, 'rejected');
                              },
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
}