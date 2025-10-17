import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/specialist.dart';
import '../services/enhanced_review_service.dart';
import '../services/firestore_service.dart';

/// Виджет статистики специалиста
class SpecialistStatsWidget extends ConsumerWidget {
  const SpecialistStatsWidget({
    super.key,
    required this.specialistId,
    this.specialist,
  });

  final String specialistId;
  final Specialist? specialist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(specialistStatsProvider(specialistId));
    final reviewsStatsAsync = ref.watch(specialistReviewStatsProvider(specialistId));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Основные показатели
            _buildMainStats(context, statsAsync, reviewsStatsAsync),

            const SizedBox(height: 16),

            // Детальная статистика
            _buildDetailedStats(context, statsAsync, reviewsStatsAsync),
          ],
        ),
      ),
    );
  }

  /// Построить основные показатели
  Widget _buildMainStats(
    BuildContext context,
    AsyncValue<SpecialistStats> statsAsync,
    AsyncValue<ReviewStats> reviewsStatsAsync,
  ) =>
      Row(
        children: [
          // Рейтинг
          Expanded(
            child: _buildStatCard(
              context,
              'Рейтинг',
              reviewsStatsAsync.when(
                data: (stats) => stats.averageRating.toStringAsFixed(1),
                loading: () => '...',
                error: (_, __) => '0.0',
              ),
              Icons.star,
              Colors.amber,
              subtitle: reviewsStatsAsync.when(
                data: (stats) => '${stats.totalReviews} отзывов',
                loading: () => '',
                error: (_, __) => '0 отзывов',
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Всего заявок
          Expanded(
            child: _buildStatCard(
              context,
              'Заявки',
              statsAsync.when(
                data: (stats) => stats.totalBookings.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              Icons.event,
              Colors.blue,
              subtitle: statsAsync.when(
                data: (stats) => 'всего',
                loading: () => '',
                error: (_, __) => '',
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Завершенные заявки
          Expanded(
            child: _buildStatCard(
              context,
              'Завершено',
              statsAsync.when(
                data: (stats) => stats.completedBookings.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              Icons.done_all,
              Colors.green,
              subtitle: statsAsync.when(
                data: (stats) => '${_calculateCompletionRate(stats)}%',
                loading: () => '',
                error: (_, __) => '0%',
              ),
            ),
          ),
        ],
      );

  /// Построить детальную статистику
  Widget _buildDetailedStats(
    BuildContext context,
    AsyncValue<SpecialistStats> statsAsync,
    AsyncValue<ReviewStats> reviewsStatsAsync,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Детальная статистика',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Статистика по статусам заявок
          statsAsync.when(
            data: (stats) => _buildBookingStatusStats(context, stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Распределение рейтингов
          reviewsStatsAsync.when(
            data: (stats) => _buildRatingDistribution(context, stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      );

  /// Построить статистику по статусам заявок
  Widget _buildBookingStatusStats(
    BuildContext context,
    SpecialistStats stats,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Заявки по статусам',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  context,
                  'Ожидают',
                  stats.pendingBookings,
                  Colors.orange,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  context,
                  'Подтверждены',
                  stats.confirmedBookings,
                  Colors.blue,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  context,
                  'Завершены',
                  stats.completedBookings,
                  Colors.green,
                  Icons.done_all,
                ),
              ),
            ],
          ),
        ],
      );

  /// Построить распределение рейтингов
  Widget _buildRatingDistribution(BuildContext context, ReviewStats stats) {
    if (stats.totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Распределение рейтингов',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (index) {
          final rating = 5 - index; // От 5 до 1
          final count = stats.getRatingCount(rating);
          final percentage = stats.getRatingPercentage(rating);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('$rating⭐'),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRatingColor(rating),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Построить карточку статистики
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );

  /// Построить элемент статуса
  Widget _buildStatusItem(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// Рассчитать процент завершения
  String _calculateCompletionRate(SpecialistStats stats) {
    if (stats.totalBookings == 0) return '0';
    return ((stats.completedBookings / stats.totalBookings) * 100).round().toString();
  }

  /// Получить цвет рейтинга
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Статистика специалиста
class SpecialistStats {
  const SpecialistStats({
    required this.totalBookings,
    required this.completedBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.rejectedBookings,
    required this.totalEarnings,
    required this.averageRating,
    required this.totalReviews,
  });

  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final int rejectedBookings;
  final double totalEarnings;
  final double averageRating;
  final int totalReviews;
}

/// Провайдер для статистики специалиста
final specialistStatsProvider = StreamProvider.family<SpecialistStats, String>((ref, specialistId) {
  final firestoreService = ref.watch(firestoreServiceProvider);

  return firestoreService.bookingsBySpecialistStream(specialistId).map((bookings) {
    final totalBookings = bookings.length;
    final completedBookings = bookings.where((b) => b.status == BookingStatus.completed).length;
    final pendingBookings = bookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmedBookings = bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final cancelledBookings = bookings.where((b) => b.status == BookingStatus.cancelled).length;
    final rejectedBookings = bookings.where((b) => b.status == BookingStatus.rejected).length;

    final totalEarnings = bookings
        .where((b) => b.status == BookingStatus.completed)
        .fold<double>(0, (sum, booking) => sum + booking.totalPrice);

    return SpecialistStats(
      totalBookings: totalBookings,
      completedBookings: completedBookings,
      pendingBookings: pendingBookings,
      confirmedBookings: confirmedBookings,
      cancelledBookings: cancelledBookings,
      rejectedBookings: rejectedBookings,
      totalEarnings: totalEarnings,
      averageRating: 0, // Будет обновлено из отзывов
      totalReviews: 0, // Будет обновлено из отзывов
    );
  });
});

/// Провайдер для сервиса Firestore
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// Провайдер для статистики отзывов специалиста
final specialistReviewStatsProvider =
    StreamProvider.family<ReviewStats, String>((ref, specialistId) {
  final service = ref.watch(enhancedReviewServiceProvider);
  return service.getSpecialistReviewStatsStream(specialistId);
});

/// Провайдер для улучшенного сервиса отзывов
final enhancedReviewServiceProvider =
    Provider<EnhancedReviewService>((ref) => EnhancedReviewService());
