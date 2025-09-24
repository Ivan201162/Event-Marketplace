import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/review_service.dart';
import '../models/review.dart';

/// Провайдер сервиса отзывов
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Провайдер отзывов специалиста
final specialistReviewsProvider = StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getSpecialistReviews(specialistId);
});

/// Провайдер среднего рейтинга специалиста
final specialistRatingProvider = FutureProvider.family<double, String>((ref, specialistId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getSpecialistAverageRating(specialistId);
});

/// Провайдер распределения рейтинга
final ratingDistributionProvider = FutureProvider.family<Map<int, int>, String>((ref, specialistId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getRatingDistribution(specialistId);
});

/// Провайдер возможности оставить отзыв
final canLeaveReviewProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.canUserLeaveReview(params['bookingId']!, params['userId']!);
});