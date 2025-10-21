import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../services/review_service.dart';

/// Review service provider
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Review form state
class ReviewFormState {
  const ReviewFormState({
    this.rating = 0,
    this.comment = '',
    this.title = '',
    this.selectedTags = const [],
    this.isPublic = true,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final int rating;
  final String comment;
  final String title;
  final List<String> selectedTags;
  final bool isPublic;
  final bool isSubmitting;
  final String? errorMessage;

  ReviewFormState copyWith({
    int? rating,
    String? comment,
    String? title,
    List<String>? selectedTags,
    bool? isPublic,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return ReviewFormState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      title: title ?? this.title,
      selectedTags: selectedTags ?? this.selectedTags,
      isPublic: isPublic ?? this.isPublic,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isValid => rating > 0 && comment.isNotEmpty;
}

/// Review form notifier
class ReviewFormNotifier extends Notifier<ReviewFormState> {
  @override
  ReviewFormState build() => const ReviewFormState();

  void updateRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void updateComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void addTag(String tag) {
    if (!state.selectedTags.contains(tag)) {
      state = state.copyWith(selectedTags: [...state.selectedTags, tag]);
    }
  }

  void removeTag(String tag) {
    state = state.copyWith(selectedTags: state.selectedTags.where((t) => t != tag).toList());
  }

  void togglePublic() {
    state = state.copyWith(isPublic: !state.isPublic);
  }

  void startSubmitting() {
    state = state.copyWith(isSubmitting: true);
  }

  void finishSubmitting() {
    state = state.copyWith(isSubmitting: false);
  }

  void setError(String error) {
    state = state.copyWith(isSubmitting: false, errorMessage: error);
  }

  void reset() {
    state = const ReviewFormState();
  }
}

/// Review form provider
final reviewFormProvider = NotifierProvider<ReviewFormNotifier, ReviewFormState>(
  ReviewFormNotifier.new,
);

/// Review state
class ReviewState {
  const ReviewState({this.reviews = const [], this.isLoading = false, this.error});

  final List<Review> reviews;
  final bool isLoading;
  final String? error;

  ReviewState copyWith({List<Review>? reviews, bool? isLoading, String? error}) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Review state notifier
class ReviewStateNotifier extends Notifier<ReviewState> {
  @override
  ReviewState build() => const ReviewState();

  Future<void> loadReviews(String specialistId) async {
    state = state.copyWith(isLoading: true);

    try {
      final service = ref.read(reviewServiceProvider);
      final reviews = await service.getReviewsBySpecialist(specialistId);
      state = state.copyWith(reviews: reviews, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createReview(Review review) async {
    try {
      final service = ref.read(reviewServiceProvider);
      await service.addReview(review);
      // Reload reviews
      await loadReviews(review.specialistId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateReview(String reviewId, Map<String, dynamic> updates) async {
    try {
      final service = ref.read(reviewServiceProvider);
      await service.updateReview(reviewId, updates['rating'] ?? 0, updates['comment'] ?? '');
      // Reload reviews
      final currentReviews = state.reviews;
      final specialistId = currentReviews.isNotEmpty ? currentReviews.first.specialistId : '';
      if (specialistId.isNotEmpty) {
        await loadReviews(specialistId);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      final service = ref.read(reviewServiceProvider);
      await service.deleteReview(reviewId);
      // Reload reviews
      final currentReviews = state.reviews;
      final specialistId = currentReviews.isNotEmpty ? currentReviews.first.specialistId : '';
      if (specialistId.isNotEmpty) {
        await loadReviews(specialistId);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Review state provider
final reviewStateProvider = NotifierProvider<ReviewStateNotifier, ReviewState>(
  ReviewStateNotifier.new,
);

/// Reviews by specialist provider
final reviewsBySpecialistProvider = FutureProvider.family<List<Review>, String>((
  ref,
  specialistId,
) async {
  final service = ref.read(reviewServiceProvider);
  return service.getReviewsBySpecialist(specialistId);
});

/// Review stats provider
final reviewStatsProvider = FutureProvider.family<ReviewStats?, String>((ref, specialistId) async {
  final service = ref.read(reviewServiceProvider);
  return service.getReviewStats(specialistId);
});

/// Specialist review stats provider
final specialistReviewStatsProvider = FutureProvider.family<SpecialistReviewStats?, String>((
  ref,
  specialistId,
) async {
  final service = ref.read(reviewServiceProvider);
  return service.getSpecialistReviewStats(specialistId);
});

/// Specialist reviews provider
final specialistReviewsProvider = FutureProvider.family<List<Review>, String>((
  ref,
  specialistId,
) async {
  final service = ref.read(reviewServiceProvider);
  return service.getSpecialistReviews(specialistId);
});
