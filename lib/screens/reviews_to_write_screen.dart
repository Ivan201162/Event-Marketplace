import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/specialist.dart';
import '../services/review_service.dart';
import '../widgets/booking_card.dart';

/// Экран заказов, для которых можно оставить отзыв
class ReviewsToWriteScreen extends StatefulWidget {
  const ReviewsToWriteScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  State<ReviewsToWriteScreen> createState() => _ReviewsToWriteScreenState();
}

class _ReviewsToWriteScreenState extends State<ReviewsToWriteScreen> {
  final ReviewService _reviewService = ReviewService();
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() => _isLoading = true);

      final bookings = await _reviewService.getCompletedBookingsForReview(widget.userId);

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки заказов: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Оставить отзыв'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return BookingCard(
                          booking: booking,
                          onTap: () => _writeReview(booking),
                          trailing: ElevatedButton(
                            onPressed: () => _writeReview(booking),
                            child: const Text('Оставить отзыв'),
                          ),
                        );
                      },
                    ),
                  ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет заказов для отзыва',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Завершите заказ, чтобы оставить отзыв специалисту',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Future<void> _writeReview(Booking booking) async {
    // Получаем информацию о специалисте
    try {
      final specialistDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(booking.specialistId)
          .get();

      if (!specialistDoc.exists) {
        _showErrorSnackBar('Информация о специалисте не найдена');
        return;
      }

      final specialist = Specialist.fromMap(specialistDoc.data()!);

      final result = await Navigator.pushNamed(
        context,
        '/write-review',
        arguments: {
          'specialist': specialist,
          'booking': booking,
        },
      );

      if (result == true) {
        // Обновляем список после добавления отзыва
        _loadBookings();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    }
  }
}
