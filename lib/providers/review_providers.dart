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

/// Состояние формы отзыва
class ReviewFormState {
  final String title;
  final String content;
  final int rating;
  final List<String> tags;
  final List<String> images;
  final bool isSubmitting;
  final String? error;

  const ReviewFormState({
    this.title = '',
    this.content = '',
    this.rating = 5,
    this.tags = const [],
    this.images = const [],
    this.isSubmitting = false,
    this.error,
  });

  ReviewFormState copyWith({
    String? title,
    String? content,
    int? rating,
    List<String>? tags,
    List<String>? images,
    bool? isSubmitting,
    String? error,
  }) {
    return ReviewFormState(
      title: title ?? this.title,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }
}

/// Провайдер состояния формы отзыва
final reviewFormProvider = NotifierProvider<ReviewFormNotifier, ReviewFormState>(() {
  return ReviewFormNotifier();
});

/// Notifier для формы отзыва
class ReviewFormNotifier extends Notifier<ReviewFormState> {
  @override
  ReviewFormState build() => const ReviewFormState();

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  void updateRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags);
  }

  void updateImages(List<String> images) {
    state = state.copyWith(images: images);
  }

  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const ReviewFormState();
  }
}

/// Состояние отзывов
class ReviewState {
  final List<Review> reviews;
  final bool isLoading;
  final String? error;

  const ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
  });

  ReviewState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? error,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Провайдер состояния отзывов
final reviewStateProvider = NotifierProvider<ReviewStateNotifier, ReviewState>(() {
  return ReviewStateNotifier();
});

/// Notifier для состояния отзывов
class ReviewStateNotifier extends Notifier<ReviewState> {
  @override
  ReviewState build() => const ReviewState();

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setReviews(List<Review> reviews) {
    state = state.copyWith(reviews: reviews);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Провайдер отзывов специалиста
final specialistReviewsProvider = StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getReviewsForTarget(specialistId, ReviewType.specialist);
});

/// Параметры отзывов специалиста
class SpecialistReviewsParams {
  final String targetId;
  final ReviewType type;

  const SpecialistReviewsParams({
    required this.targetId,
    required this.type,
  });
}
