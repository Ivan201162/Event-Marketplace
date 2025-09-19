import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

class SpecialistRequestsScreen extends StatefulWidget {
  const SpecialistRequestsScreen({super.key, required this.specialistId});
  final String specialistId;

  @override
  State<SpecialistRequestsScreen> createState() =>
      _SpecialistRequestsScreenState();
}

class _SpecialistRequestsScreenState extends State<SpecialistRequestsScreen> {
  final BookingService bookingService = BookingService();
  List<Booking> pendingBookings = [];

  @override
  void initState() {
    super.initState();
    _loadPendingBookings();
  }

  Future<void> _loadPendingBookings() async {
    final bookings =
        await bookingService.getBookingsForSpecialist(widget.specialistId);
    setState(() {
      pendingBookings = bookings.where((b) => b.status == 'pending').toList();
    });
  }

  Future<void> _updateStatus(Booking booking, String status) async {
    booking.status = status;
    await bookingService.addBooking(booking);
    _loadPendingBookings();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Заявки на бронирование')),
        body: pendingBookings.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Нет новых заявок',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: pendingBookings.length,
                itemBuilder: (context, index) {
                  final booking = pendingBookings[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        "Заказчик: ${booking.customerId} | Дата: ${booking.eventDate.toLocal().toString().split(' ')[0]}",
                      ),
                      subtitle: Text('Аванс: ${booking.prepayment.toInt()} ₽'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                _updateStatus(booking, 'confirmed'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _updateStatus(booking, 'rejected'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
}
