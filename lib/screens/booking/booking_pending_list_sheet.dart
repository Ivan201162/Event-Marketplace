import 'dart:async';

import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/services/chat_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// BottomSheet со списком pending заявок на дату (специалист)
class BookingPendingListSheet extends StatefulWidget {
  const BookingPendingListSheet({
    required this.specialistId,
    required this.date,
    super.key,
  });

  final String specialistId;
  final DateTime date;

  @override
  State<BookingPendingListSheet> createState() => _BookingPendingListSheetState();
}

class _BookingPendingListSheetState extends State<BookingPendingListSheet> {
  final _bookingService = BookingService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugLog("SHEET_OPENED:booking_pending_list");
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookings = await _bookingService.getBookingsForDate(
        widget.specialistId,
        widget.date,
      );
      
      // Фильтруем только pending
      final pendingBookings = bookings.where((b) => b.status == BookingStatus.pending).toList();
      
      if (mounted) {
        setState(() {
          _bookings = pendingBookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      debugLog("ERROR:load_pending_bookings:$e");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      await _bookingService.acceptBooking(bookingId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка принята')),
        );
      }
    } catch (e) {
      debugPrint('Error accepting booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await _bookingService.rejectBooking(bookingId);
      if (mounted) {
        _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка отклонена')),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _openChat(String clientId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // TODO: Получить chatId из booking или создать
    // Пока просто логируем
    debugLog("CALENDAR_DATE_TAP:specialist:chat:$clientId");
    if (mounted) {
      // context.push('/chat/$chatId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Переход в чат (в разработке)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Заявки на ${DateFormat('d MMMM yyyy', 'ru').format(widget.date)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ошибка: $_error'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadBookings,
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          )
                        : _bookings.isEmpty
                            ? const Center(child: Text('На эту дату заявок нет'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _bookings.length,
                                itemBuilder: (context, index) {
                                  final booking = _bookings[index];
                                  return _buildBookingCard(booking);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final eventTypeLabel = booking.eventType;
    String timeLabel = 'не указано';
    if (booking.timeFrom != null && booking.timeTo != null) {
      timeLabel = '${booking.timeFrom}–${booking.timeTo}';
    } else if (booking.durationOption != null) {
      timeLabel = booking.durationOption == '4h' ? '4 часа' :
                  booking.durationOption == '5h' ? '5 часов' :
                  booking.durationOption == '6h' ? '6 часов' :
                  'Длительность не указана';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Клиент (заглушка - нужно загрузить данные)
            const Text(
              'Клиент',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Тип: $eventTypeLabel'),
            Text('Время: $timeLabel'),
            if (booking.message != null && booking.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Комментарий: ${booking.message}'),
            ],
            if (booking.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Создано: ${DateFormat('d MMM yyyy, HH:mm', 'ru').format(booking.createdAt!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptBooking(booking.id),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Принять'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _rejectBooking(booking.id),
                  child: const Text('Отклонить'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () => _openChat(booking.clientId),
                  tooltip: 'Открыть чат',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

