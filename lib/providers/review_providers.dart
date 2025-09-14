import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/review_service.dart';
import '../models/review.dart';

/// Провайдер сервиса отзывов
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Провайдер отзывов специалиста
final specialistReviewsProvider = StreamProvider.family<List<Review>, SpecialistReviewsParams>((ref, params) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getSpecialistReviewsStream(
    params.specialistId,
    limit: params.limit,
    onlyPublic: params.onlyPublic,
  );
});

/// Провайдер отзывов клиента
final customerReviewsProvider = FutureProvider.family<List<Review>, String>((ref, customerId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getCustomerReviews(customerId);
});

/// Провайдер отзыва по заявке
final reviewByBookingProvider = FutureProvider.family<Review?, String>((ref, bookingId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getReviewByBooking(bookingId);
});

/// Провайдер статистики отзывов специалиста
final specialistReviewStatisticsProvider = FutureProvider.family<ReviewStatistics, String>((ref, specialistId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getSpecialistReviewStatistics(specialistId);
});

/// Провайдер статистики отзывов клиента
final customerReviewStatisticsProvider = FutureProvider.family<ReviewStatistics, String>((ref, customerId) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getCustomerReviewStatistics(customerId);
});

/// Провайдер топ специалистов
final topSpecialistsProvider = FutureProvider.family<List<Map<String, dynamic>>, TopSpecialistsParams>((ref, params) {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getTopSpecialists(
    limit: params.limit,
    minReviews: params.minReviews,
  );
});

/// Провайдер для управления состоянием отзывов
final reviewStateProvider = StateNotifierProvider<ReviewStateNotifier, ReviewState>((ref) {
  return ReviewStateNotifier(ref.read(reviewServiceProvider));
});

/// Состояние отзывов
class ReviewState {
  final bool isLoading;
  final String? errorMessage;
  final Review? currentReview;
  final List<Review> recentReviews;

  const ReviewState({
    this.isLoading = false,
    this.errorMessage,
    this.currentReview,
    this.recentReviews = const [],
  });

  ReviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    Review? currentReview,
    List<Review>? recentReviews,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentReview: currentReview ?? this.currentReview,
      recentReviews: recentReviews ?? this.recentReviews,
    );
  }
}

/// Нотификатор состояния отзывов
class ReviewStateNotifier extends StateNotifier<ReviewState> {
  final ReviewService _reviewService;

  ReviewStateNotifier(this._reviewService) : super(const ReviewState());

  /// Создать отзыв
  Future<Review?> createReview({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required int rating,
    String? title,
    String? comment,
    List<String> tags = const [],
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final review = await _reviewService.createReview(
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        rating: rating,
        title: title,
        comment: comment,
        tags: tags,
      );
      
      state = state.copyWith(
        isLoading: false,
        currentReview: review,
      );
      return review;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Обновить отзыв
  Future<void> updateReview(
    String reviewId, {
    int? rating,
    String? title,
    String? comment,
    List<String>? tags,
    bool? isPublic,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _reviewService.updateReview(
        reviewId,
        rating: rating,
        title: title,
        comment: comment,
        tags: tags,
        isPublic: isPublic,
      );
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _reviewService.deleteReview(reviewId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Параметры для отзывов специалиста
class SpecialistReviewsParams {
  final String specialistId;
  final int limit;
  final bool onlyPublic;

  const SpecialistReviewsParams({
    required this.specialistId,
    this.limit = 50,
    this.onlyPublic = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistReviewsParams &&
        other.specialistId == specialistId &&
        other.limit == limit &&
        other.onlyPublic == onlyPublic;
  }

  @override
  int get hashCode => specialistId.hashCode ^ limit.hashCode ^ onlyPublic.hashCode;
}

/// Параметры для топ специалистов
class TopSpecialistsParams {
  final int limit;
  final int minReviews;

  const TopSpecialistsParams({
    this.limit = 10,
    this.minReviews = 5,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopSpecialistsParams &&
        other.limit == limit &&
        other.minReviews == minReviews;
  }

  @override
  int get hashCode => limit.hashCode ^ minReviews.hashCode;
}

/// Провайдер для управления формой отзыва
final reviewFormProvider = StateNotifierProvider<ReviewFormNotifier, ReviewFormState>((ref) {
  return ReviewFormNotifier();
});

/// Состояние формы отзыва
class ReviewFormState {
  final int rating;
  final String title;
  final String comment;
  final List<String> selectedTags;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isPublic;

  const ReviewFormState({
    this.rating = 5,
    this.title = '',
    this.comment = '',
    this.selectedTags = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.isPublic = true,
  });

  ReviewFormState copyWith({
    int? rating,
    String? title,
    String? comment,
    List<String>? selectedTags,
    bool? isSubmitting,
    String? errorMessage,
    bool? isPublic,
  }) {
    return ReviewFormState(
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      selectedTags: selectedTags ?? this.selectedTags,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

/// Нотификатор формы отзыва
class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  ReviewFormNotifier() : super(const ReviewFormState());

  /// Установить рейтинг
  void setRating(int rating) {
    if (rating >= 1 && rating <= 5) {
      state = state.copyWith(rating: rating);
    }
  }

  /// Обновить заголовок
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// Обновить комментарий
  void updateComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  /// Добавить тег
  void addTag(String tag) {
    if (!state.selectedTags.contains(tag)) {
      final newTags = [...state.selectedTags, tag];
      state = state.copyWith(selectedTags: newTags);
    }
  }

  /// Удалить тег
  void removeTag(String tag) {
    final newTags = state.selectedTags.where((t) => t != tag).toList();
    state = state.copyWith(selectedTags: newTags);
  }

  /// Переключить публичность
  void togglePublic() {
    state = state.copyWith(isPublic: !state.isPublic);
  }

  /// Начать отправку
  void startSubmitting() {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
  }

  /// Завершить отправку
  void finishSubmitting() {
    state = state.copyWith(isSubmitting: false);
  }

  /// Установить ошибку
  void setError(String error) {
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: error,
    );
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Сбросить форму
  void reset() {
    state = const ReviewFormState();
  }

  /// Проверить валидность формы
  bool get isValid {
    return state.rating >= 1 && 
           state.rating <= 5 && 
           (state.title.isNotEmpty || state.comment.isNotEmpty);
  }
}
