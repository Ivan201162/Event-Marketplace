import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_extended.dart';
import '../services/review_extended_service.dart';

/// Провайдер для сервиса расширенных отзывов
final reviewExtendedServiceProvider =
    Provider<ReviewExtendedService>((ref) => ReviewExtendedService());

/// Провайдер для отзывов специалиста
final specialistReviewsProvider =
    StreamProvider.family<List<ReviewExtended>, (String, ReviewFilter)>((ref, params) {
  final (specialistId, filter) = params;
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для конкретного отзыва
final reviewProvider = FutureProvider.family<ReviewExtended?, String>((ref, reviewId) {
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getReview(reviewId);
});

/// Провайдер для статистики отзывов специалиста
final specialistReviewStatsProvider =
    FutureProvider.family<SpecialistReviewStats, String>((ref, specialistId) {
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviewStats(specialistId);
});

/// Нотификатор для фильтра отзывов
class ReviewFilterNotifier extends Notifier<ReviewFilter> {
  @override
  ReviewFilter build() => const ReviewFilter();

  void updateFilter(ReviewFilter filter) {
    state = filter;
  }

  void resetFilter() {
    state = const ReviewFilter();
  }
}

/// Провайдер для фильтра отзывов
final reviewFilterProvider = NotifierProvider<ReviewFilterNotifier, ReviewFilter>(
  ReviewFilterNotifier.new,
);

/// Провайдер для отзывов с медиа
final reviewsWithMediaProvider =
    StreamProvider.family<List<ReviewExtended>, String>((ref, specialistId) {
  const filter = ReviewFilter(hasMedia: true);
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для верифицированных отзывов
final verifiedReviewsProvider =
    StreamProvider.family<List<ReviewExtended>, String>((ref, specialistId) {
  const filter = ReviewFilter(isVerified: true);
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для отзывов по рейтингу
final reviewsByRatingProvider =
    StreamProvider.family<List<ReviewExtended>, (String, int)>((ref, params) {
  final (specialistId, rating) = params;
  final filter = ReviewFilter(minRating: rating, maxRating: rating);
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для отзывов с тегами
final reviewsWithTagsProvider =
    StreamProvider.family<List<ReviewExtended>, (String, List<String>)>((ref, params) {
  final (specialistId, tags) = params;
  final filter = ReviewFilter(tags: tags);
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для последних отзывов
final recentReviewsProvider =
    StreamProvider.family<List<ReviewExtended>, (String, int)>((ref, params) {
  final (specialistId, limit) = params;
  const filter = ReviewFilter();
  return ref.watch(specialistReviewsProvider((specialistId, filter))).when(
        data: (reviews) => Stream.value(reviews.take(limit).toList()),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для топ отзывов по лайкам
final topReviewsByLikesProvider =
    StreamProvider.family<List<ReviewExtended>, (String, int)>((ref, params) {
  final (specialistId, limit) = params;
  const filter = ReviewFilter(sortBy: ReviewSortBy.likes);
  return ref.watch(specialistReviewsProvider((specialistId, filter))).when(
        data: (reviews) => Stream.value(reviews.take(limit).toList()),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для отзывов с высоким рейтингом
final highRatedReviewsProvider =
    StreamProvider.family<List<ReviewExtended>, String>((ref, specialistId) {
  const filter = ReviewFilter(minRating: 4);
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для отзывов с низким рейтингом
final lowRatedReviewsProvider =
    StreamProvider.family<List<ReviewExtended>, String>((ref, specialistId) {
  const filter = ReviewFilter(maxRating: 2);
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для поиска отзывов
final searchReviewsProvider =
    StreamProvider.family<List<ReviewExtended>, (String, String)>((ref, params) {
  final (specialistId, query) = params;
  return ref.watch(specialistReviewsProvider((specialistId, const ReviewFilter()))).when(
        data: (reviews) {
          if (query.isEmpty) return Stream.value(reviews);

          final filtered = reviews
              .where(
                (review) =>
                    review.comment.toLowerCase().contains(query.toLowerCase()) ||
                    review.customerName.toLowerCase().contains(query.toLowerCase()) ||
                    review.tags.any(
                      (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                    ),
              )
              .toList();

          return Stream.value(filtered);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Провайдер для отзывов за период
final reviewsForPeriodProvider =
    StreamProvider.family<List<ReviewExtended>, (String, DateTime, DateTime)>((ref, params) {
  final (specialistId, startDate, endDate) = params;
  final filter = ReviewFilter(startDate: startDate, endDate: endDate);
  final service = ref.read(reviewExtendedServiceProvider);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для отзывов за последний месяц
final reviewsLastMonthProvider =
    StreamProvider.family<List<ReviewExtended>, String>((ref, specialistId) {
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1);
  final service = ref.read(reviewExtendedServiceProvider);
  final filter = ReviewFilter(startDate: lastMonth, endDate: now);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для отзывов за последний год
final reviewsLastYearProvider =
    StreamProvider.family<List<ReviewExtended>, String>((ref, specialistId) {
  final now = DateTime.now();
  final lastYear = DateTime(now.year - 1, now.month, now.day);
  final service = ref.read(reviewExtendedServiceProvider);
  final filter = ReviewFilter(startDate: lastYear, endDate: now);
  return service.getSpecialistReviews(specialistId, filter);
});

/// Провайдер для среднего рейтинга
final averageRatingProvider = StreamProvider.family<double, String>(
  (ref, specialistId) => ref.watch(specialistReviewStatsProvider(specialistId)).when(
        data: (stats) => Stream.value(stats.averageRating),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      ),
);

/// Провайдер для общего количества отзывов
final totalReviewsCountProvider = StreamProvider.family<int, String>(
  (ref, specialistId) => ref.watch(specialistReviewStatsProvider(specialistId)).when(
        data: (stats) => Stream.value(stats.totalReviews),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      ),
);

/// Провайдер для общего количества лайков
final totalLikesCountProvider = StreamProvider.family<int, String>(
  (ref, specialistId) => ref.watch(specialistReviewStatsProvider(specialistId)).when(
        data: (stats) => Stream.value(stats.totalLikes),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      ),
);

/// Провайдер для распределения рейтингов
final ratingDistributionProvider = StreamProvider.family<Map<int, int>, String>(
  (ref, specialistId) => ref.watch(specialistReviewStatsProvider(specialistId)).when(
        data: (stats) => Stream.value(stats.ratingDistribution),
        loading: () => Stream.value({}),
        error: (_, __) => Stream.value({}),
      ),
);

/// Провайдер для топ тегов
final topTagsProvider = StreamProvider.family<List<String>, String>(
  (ref, specialistId) => ref.watch(specialistReviewStatsProvider(specialistId)).when(
        data: (stats) => Stream.value(stats.topTags),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      ),
);

/// Провайдер для рейтингов по категориям
final categoryRatingsProvider = StreamProvider.family<Map<String, double>, String>(
  (ref, specialistId) => ref.watch(specialistReviewStatsProvider(specialistId)).when(
        data: (stats) => Stream.value(stats.categoryRatings),
        loading: () => Stream.value({}),
        error: (_, __) => Stream.value({}),
      ),
);

/// Провайдер для отзывов с детальными оценками
final reviewsWithDetailedRatingsProvider = StreamProvider.family<List<ReviewExtended>, String>(
  (ref, specialistId) =>
      ref.watch(specialistReviewsProvider((specialistId, const ReviewFilter()))).when(
            data: (reviews) => Stream.value(
              reviews
                  .where(
                    (review) =>
                        review.stats.quality > 0 ||
                        review.stats.communication > 0 ||
                        review.stats.punctuality > 0 ||
                        review.stats.value > 0,
                  )
                  .toList(),
            ),
            loading: () => Stream.value([]),
            error: (_, __) => Stream.value([]),
          ),
);

/// Провайдер для отзывов с медиа
final reviewsWithPhotosProvider = StreamProvider.family<List<ReviewExtended>, String>(
  (ref, specialistId) =>
      ref.watch(specialistReviewsProvider((specialistId, const ReviewFilter()))).when(
            data: (reviews) => Stream.value(
              reviews.where((review) => review.photos.isNotEmpty).toList(),
            ),
            loading: () => Stream.value([]),
            error: (_, __) => Stream.value([]),
          ),
);

/// Провайдер для отзывов с видео
final reviewsWithVideosProvider = StreamProvider.family<List<ReviewExtended>, String>(
  (ref, specialistId) =>
      ref.watch(specialistReviewsProvider((specialistId, const ReviewFilter()))).when(
            data: (reviews) => Stream.value(
              reviews.where((review) => review.videos.isNotEmpty).toList(),
            ),
            loading: () => Stream.value([]),
            error: (_, __) => Stream.value([]),
          ),
);

/// Провайдер для отзывов с лайками
final reviewsWithLikesProvider = StreamProvider.family<List<ReviewExtended>, String>(
  (ref, specialistId) =>
      ref.watch(specialistReviewsProvider((specialistId, const ReviewFilter()))).when(
            data: (reviews) => Stream.value(
              reviews.where((review) => review.likesCount > 0).toList(),
            ),
            loading: () => Stream.value([]),
            error: (_, __) => Stream.value([]),
          ),
);

/// Провайдер для отзывов без лайков
final reviewsWithoutLikesProvider = StreamProvider.family<List<ReviewExtended>, String>(
  (ref, specialistId) =>
      ref.watch(specialistReviewsProvider((specialistId, const ReviewFilter()))).when(
            data: (reviews) => Stream.value(
              reviews.where((review) => review.likesCount == 0).toList(),
            ),
            loading: () => Stream.value([]),
            error: (_, __) => Stream.value([]),
          ),
);
