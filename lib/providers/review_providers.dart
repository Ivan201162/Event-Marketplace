import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/review_service.dart';
import '../models/review.dart';
import '../core/feature_flags.dart';

/// Провайдер сервиса отзывов
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Провайдер для проверки доступности отзывов
final reviewsAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.reviewsEnabled;
});

/// Провайдер отзывов для цели
final reviewsForTargetProvider = StreamProvider.family<List<Review>,
    ({String targetId, ReviewType type, ReviewFilter? filter})>((ref, params) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getReviewsForTarget(
    params.targetId,
    params.type,
    filter: params.filter,
  );
});

/// Провайдер статистики отзывов
final reviewStatsProvider =
    StreamProvider.family<ReviewStats, ({String targetId, ReviewType type})>(
        (ref, params) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getReviewStatsStream(params.targetId, params.type);
});

/// Провайдер отзыва пользователя для цели
final userReviewForTargetProvider =
    FutureProvider.family<Review?, ({String userId, String targetId})>(
        (ref, params) async {
  final reviewService = ref.read(reviewServiceProvider);
  return await reviewService.getUserReviewForTarget(
      params.userId, params.targetId);
});

/// Провайдер отзывов пользователя
final userReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, userId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getUserReviews(userId);
});

/// Провайдер отзывов на рассмотрении
final pendingReviewsProvider = StreamProvider<List<Review>>((ref) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getPendingReviews();
});

/// Провайдер поиска отзывов
final searchReviewsProvider = StreamProvider.family<List<Review>,
    ({String? query, ReviewType? type, ReviewFilter? filter})>((ref, params) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.searchReviews(
    query: params.query,
    type: params.type,
    filter: params.filter,
  );
});
