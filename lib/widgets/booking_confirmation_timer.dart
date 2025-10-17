import 'dart:async';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

/// Виджет таймера подтверждения бронирования
class BookingConfirmationTimer extends StatefulWidget {
  const BookingConfirmationTimer({
    super.key,
    required this.booking,
    required this.bookingService,
  });
  final Booking booking;
  final BookingService bookingService;

  @override
  State<BookingConfirmationTimer> createState() => _BookingConfirmationTimerState();
}

class _BookingConfirmationTimerState extends State<BookingConfirmationTimer> {
  Duration? _timeRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateTimeRemaining() {
    final timeRemaining = widget.bookingService.getTimeUntilExpiry(widget.booking);
    if (mounted) {
      setState(() {
        _timeRemaining = timeRemaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.booking.status != BookingStatus.pending || _timeRemaining == null) {
      return const SizedBox.shrink();
    }

    final hours = _timeRemaining!.inHours;
    final minutes = _timeRemaining!.inMinutes % 60;
    final seconds = _timeRemaining!.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Colors.orange[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ожидает подтверждения',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Время на подтверждение: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          if (_timeRemaining!.inSeconds <= 300) // Последние 5 минут
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'СРОЧНО!',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Виджет для отображения статуса подтверждения
class BookingConfirmationStatus extends StatelessWidget {
  const BookingConfirmationStatus({
    super.key,
    required this.booking,
    required this.bookingService,
  });
  final Booking booking;
  final BookingService bookingService;

  @override
  Widget build(BuildContext context) {
    switch (booking.status) {
      case BookingStatus.pending:
        return BookingConfirmationTimer(
          booking: booking,
          bookingService: bookingService,
        );
      case BookingStatus.confirmed:
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Бронирование подтверждено',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
        );
      case BookingStatus.cancelled:
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cancel,
                color: Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Бронирование отменено',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
        );
      case BookingStatus.rejected:
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.close,
                color: Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Бронирование отклонено',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
        );
      case BookingStatus.completed:
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_available,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Мероприятие завершено',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        );
    }
  }
}
