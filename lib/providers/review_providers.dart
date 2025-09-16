import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/review_service.dart';
import '../models/review.dart';

/// Провайдер сервиса отзывов
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Провайдер отзывов по специалисту
final reviewsBySpecialistProvider =
    FutureProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getReviewsBySpecialist(specialistId);
});

/// Провайдер отзывов по заказчику
final reviewsByCustomerProvider =
    FutureProvider.family<List<Review>, String>((ref, customerId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getReviewsByCustomer(customerId);
});

/// Провайдер отзыва по бронированию
final reviewByBookingProvider =
    FutureProvider.family<Review?, String>((ref, bookingId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getReviewByBooking(bookingId);
});

/// Провайдер статистики отзывов специалиста
final reviewStatsProvider =
    FutureProvider.family<ReviewStats, String>((ref, specialistId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getReviewStats(specialistId);
});

/// Провайдер отзывов специалиста (алиас)
final specialistReviewsProvider = reviewsBySpecialistProvider;

/// Провайдер статистики отзывов специалиста (алиас)
final specialistReviewStatisticsProvider = reviewStatsProvider;

/// Провайдер последних отзывов
final recentReviewsProvider = FutureProvider<List<Review>>((ref) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getRecentReviews();
});

/// Провайдер лучших отзывов
final topReviewsProvider = FutureProvider<List<Review>>((ref) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getTopReviews();
});

/// Провайдер проверки возможности оставить отзыв
final canUserReviewProvider =
    FutureProvider.family<bool, ReviewCheckParams>((ref, params) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.canUserReview(
      params.customerId, params.specialistId, params.bookingId);
});

/// Параметры для проверки возможности оставить отзыв
class ReviewCheckParams {
  final String customerId;
  final String specialistId;
  final String bookingId;

  ReviewCheckParams({
    required this.customerId,
    required this.specialistId,
    required this.bookingId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewCheckParams &&
        other.customerId == customerId &&
        other.specialistId == specialistId &&
        other.bookingId == bookingId;
  }

  @override
  int get hashCode =>
      customerId.hashCode ^ specialistId.hashCode ^ bookingId.hashCode;
}
