import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../services/review_service.dart';

/// Review service provider
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Specialist reviews provider
final specialistReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, specialistId) async {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getSpecialistReviews(specialistId);
});

/// Client reviews provider
final clientReviewsProvider = FutureProvider.family<List<Review>, String>((ref, clientId) async {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getClientReviews(clientId);
});

/// Reviews by rating provider
final reviewsByRatingProvider = FutureProvider.family<List<Review>, int>((ref, rating) async {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getReviewsByRating(rating);
});

/// Review by ID provider
final reviewByIdProvider = FutureProvider.family<Review?, String>((ref, reviewId) async {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getReviewById(reviewId);
});

/// Specialist reviews stream provider
final specialistReviewsStreamProvider =
    StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getSpecialistReviewsStream(specialistId);
});

/// Client reviews stream provider
final clientReviewsStreamProvider = StreamProvider.family<List<Review>, String>((ref, clientId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getClientReviewsStream(clientId);
});

/// Reviews by rating stream provider
final reviewsByRatingStreamProvider = StreamProvider.family<List<Review>, int>((ref, rating) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getReviewsByRatingStream(rating);
});

/// Specialist review statistics provider
final specialistReviewStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, specialistId) async {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getSpecialistReviewStats(specialistId);
});

/// Recent reviews provider
final recentReviewsProvider = FutureProvider.family<List<Review>, int>((ref, limit) async {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getRecentReviews(limit: limit);
});

/// Top rated specialists provider
final topRatedSpecialistsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, limit) async {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getTopRatedSpecialists(limit: limit);
});

/// Can client review specialist provider
final canClientReviewProvider =
    FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final reviewService = ref.read(reviewServiceProvider);
  final clientId = params['clientId']!;
  final specialistId = params['specialistId']!;
  return reviewService.canClientReviewSpecialist(clientId, specialistId);
});

/// Review statistics provider
final reviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final reviewService = ref.read(reviewServiceProvider);

  // Get overall statistics
  final recentReviews = await reviewService.getRecentReviews(limit: 100);
  final topSpecialists = await reviewService.getTopRatedSpecialists();

  final totalReviews = recentReviews.length;
  final averageRating = recentReviews.isNotEmpty
      ? recentReviews.fold(0.0, (sum, review) => sum + review.rating) / recentReviews.length
      : 0.0;

  final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  for (final review in recentReviews) {
    ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
  }

  return {
    'totalReviews': totalReviews,
    'averageRating': averageRating,
    'ratingDistribution': ratingDistribution,
    'topSpecialists': topSpecialists,
  };
});

/// Reviews with images provider
final reviewsWithImagesProvider =
    FutureProvider.family<List<Review>, String>((ref, specialistId) async {
  final reviewService = ref.read(reviewServiceProvider);
  final reviews = await reviewService.getSpecialistReviews(specialistId);
  return reviews.where((review) => review.hasImages).toList();
});

/// Reviews with images stream provider
final reviewsWithImagesStreamProvider =
    StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService
      .getSpecialistReviewsStream(specialistId)
      .map((reviews) => reviews.where((review) => review.hasImages).toList());
});

/// High rating reviews provider (4+ stars)
final highRatingReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, specialistId) async {
  final reviewService = ref.read(reviewServiceProvider);
  final reviews = await reviewService.getSpecialistReviews(specialistId);
  return reviews.where((review) => review.rating >= 4).toList();
});

/// High rating reviews stream provider
final highRatingReviewsStreamProvider =
    StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService
      .getSpecialistReviewsStream(specialistId)
      .map((reviews) => reviews.where((review) => review.rating >= 4).toList());
});

/// Low rating reviews provider (1-2 stars)
final lowRatingReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, specialistId) async {
  final reviewService = ref.read(reviewServiceProvider);
  final reviews = await reviewService.getSpecialistReviews(specialistId);
  return reviews.where((review) => review.rating <= 2).toList();
});

/// Low rating reviews stream provider
final lowRatingReviewsStreamProvider =
    StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService
      .getSpecialistReviewsStream(specialistId)
      .map((reviews) => reviews.where((review) => review.rating <= 2).toList());
});

/// Reviews count provider
final reviewsCountProvider = FutureProvider.family<int, String>((ref, specialistId) async {
  final reviewService = ref.read(reviewServiceProvider);
  final reviews = await reviewService.getSpecialistReviews(specialistId);
  return reviews.length;
});

/// Reviews count stream provider
final reviewsCountStreamProvider = StreamProvider.family<int, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getSpecialistReviewsStream(specialistId).map((reviews) => reviews.length);
});

/// Average rating provider
final averageRatingProvider = FutureProvider.family<double, String>((ref, specialistId) async {
  final reviewService = ref.read(reviewServiceProvider);
  final stats = await reviewService.getSpecialistReviewStats(specialistId);
  return stats['averageRating'] as double;
});

/// Average rating stream provider
final averageRatingStreamProvider = StreamProvider.family<double, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getSpecialistReviewsStream(specialistId).map((reviews) {
    if (reviews.isEmpty) return 0.0;
    final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  });
});
