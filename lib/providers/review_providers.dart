import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../models/review.dart';
import '../services/review_service.dart';

/// Провайдер сервиса отзывов
final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

/// Провайдер для проверки доступности отзывов
final reviewsAvailableProvider =
    Provider<bool>((ref) => FeatureFlags.reviewsEnabled);

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
  return reviewService.getUserReviewForTarget(
    params.userId,
    params.targetId,
  );
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
  const ReviewFormState({
    this.title = '',
    this.content = '',
    this.comment = '',
    this.rating = 5,
    this.tags = const [],
    this.selectedTags = const [],
    this.images = const [],
    this.isSubmitting = false,
    this.isPublic = true,
    this.error,
    this.errorMessage,
    this.isLoading = false,
  });
  final String title;
  final String content;
  final String comment;
  final int rating;
  final List<String> tags;
  final List<String> selectedTags;
  final List<String> images;
  final bool isSubmitting;
  final bool isPublic;
  final String? error;
  final String? errorMessage;
  final bool isLoading;

  ReviewFormState copyWith({
    String? title,
    String? content,
    String? comment,
    int? rating,
    List<String>? tags,
    List<String>? selectedTags,
    List<String>? images,
    bool? isSubmitting,
    bool? isPublic,
    String? error,
    String? errorMessage,
  }) =>
      ReviewFormState(
        title: title ?? this.title,
        content: content ?? this.content,
        comment: comment ?? this.comment,
        rating: rating ?? this.rating,
        tags: tags ?? this.tags,
        selectedTags: selectedTags ?? this.selectedTags,
        images: images ?? this.images,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isPublic: isPublic ?? this.isPublic,
        error: error ?? this.error,
        errorMessage: errorMessage ?? this.errorMessage,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Провайдер состояния формы отзыва
final reviewFormProvider =
    NotifierProvider<ReviewFormNotifier, ReviewFormState>(
  ReviewFormNotifier.new,
);

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

  void updateComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  void updateSelectedTags(List<String> selectedTags) {
    state = state.copyWith(selectedTags: selectedTags);
  }

  void updateIsPublic(bool isPublic) {
    state = state.copyWith(isPublic: isPublic);
  }

  /// Создать отзыв
  Future<void> createReview({
    required String targetId,
    required ReviewType type,
  }) async {
    try {
      state = state.copyWith(error: null);
      
      final reviewService = ref.read(reviewServiceProvider);
      await reviewService.createReview(
        targetId: targetId,
        type: type,
        title: state.title,
        content: state.content,
        rating: state.rating,
        tags: state.selectedTags,
        images: state.images,
      );
      
      state = state.copyWith();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setErrorMessage(String? errorMessage) {
    state = state.copyWith(errorMessage: errorMessage);
  }

  void addTag(String tag) {
    final tags = List<String>.from(state.tags);
    if (!tags.contains(tag)) {
      tags.add(tag);
      state = state.copyWith(tags: tags);
    }
  }

  void removeTag(String tag) {
    final tags = List<String>.from(state.tags);
    tags.remove(tag);
    state = state.copyWith(tags: tags);
  }

  void togglePublic() {
    state = state.copyWith(isPublic: !state.isPublic);
  }

  bool get isValid =>
      state.title.isNotEmpty && state.content.isNotEmpty && state.rating > 0;

  void startSubmitting() {
    state = state.copyWith(isSubmitting: true);
  }

  void finishSubmitting() {
    state = state.copyWith(isSubmitting: false);
  }

  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  String? get errorMessage => state.error;
  String get comment => state.content;
  List<String> get selectedTags => state.tags;
  bool get isPublic => true; // По умолчанию публичный
}

/// Состояние отзывов
class ReviewState {
  const ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
  });
  final List<Review> reviews;
  final bool isLoading;
  final String? error;

  ReviewState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? error,
  }) =>
      ReviewState(
        reviews: reviews ?? this.reviews,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Провайдер состояния отзывов
final reviewStateProvider =
    NotifierProvider<ReviewStateNotifier, ReviewState>(ReviewStateNotifier.new);

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

  Future<void> createReview({
    required String targetId,
    required ReviewType type,
    required String title,
    required String content,
    required int rating,
    List<String> tags = const [],
    List<String> images = const [],
  }) async {
    // Здесь должна быть логика создания отзыва
    // Пока что просто заглушка
  }
}

/// Провайдер отзывов специалиста
final specialistReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final reviewService = ref.read(reviewServiceProvider);
  return reviewService.getReviewsForTarget(specialistId, ReviewType.specialist);
});

/// Параметры отзывов специалиста
class SpecialistReviewsParams {
  const SpecialistReviewsParams({
    required this.targetId,
    required this.type,
  });
  final String targetId;
  final ReviewType type;
}
