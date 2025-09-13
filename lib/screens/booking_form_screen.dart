import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';

class BookingFormScreen extends StatefulWidget {
  final String customerId;
  final String specialistId;
  final double totalPrice;

  const BookingFormScreen({
    super.key,
    required this.customerId,
    required this.specialistId,
    required this.totalPrice,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  DateTime? selectedDate;
  final BookingService bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Бронирование специалиста")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(selectedDate != null
                  ? selectedDate!.toLocal().toString().split(' ')[0]
                  : "Выберите дату"),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedDate == null ? null : _submitBooking,
              child: const Text("Отправить заявку"),
            ),
          ],
        ),
      ),
    );
  }

  void _submitBooking() async {
    final booking = Booking(
      id: _generateId(),
      customerId: widget.customerId,
      specialistId: widget.specialistId,
      eventDate: selectedDate!,
      status: "pending",
      prepayment: widget.totalPrice * 0.3,
      totalPrice: widget.totalPrice,
      prepaymentPaid: false,
    );

    await bookingService.addBooking(booking);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заявка отправлена специалисту!")),
      );

      Navigator.pop(context);
    }
  }

  String _generateId() {
    // Простая генерация ID без внешних зависимостей
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'booking_${timestamp}_$random';
  }
}
