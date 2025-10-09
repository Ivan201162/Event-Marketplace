import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../services/review_service.dart';

/// Теги для отзывов
class ReviewTags {
  static const List<String> commonTags = [
    'Качество работы',
    'Пунктуальность',
    'Коммуникация',
    'Профессионализм',
    'Цена/качество',
    'Креативность',
    'Организация',
    'Гибкость',
    'Техническое оснащение',
    'Атмосфера',
  ];

  /// Получить теги по рейтингу
  static List<String> getTagsByRating(int rating) {
    switch (rating) {
      case 5:
        return ['Отлично', 'Превосходно', 'Рекомендую'];
      case 4:
        return ['Хорошо', 'Качественно', 'Доволен'];
      case 3:
        return ['Нормально', 'Удовлетворительно'];
      case 2:
        return ['Плохо', 'Не рекомендую'];
      case 1:
        return ['Ужасно', 'Очень плохо'];
      default:
        return commonTags;
    }
  }
}

/// Провайдер для получения отзывов специалиста
final specialistReviewsProvider = StreamProvider.family<List<Review>, String>(
  (ref, specialistId) => FirebaseFirestore.instance
      .collection('reviews')
      .where('specialistId', isEqualTo: specialistId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Review.fromDocument).toList()),
);

/// Провайдер для получения статистики отзывов специалиста
final specialistReviewStatsProvider =
    FutureProvider.family<SpecialistReviewStats, String>(
        (ref, specialistId) async {
  final reviews =
      await ref.read(specialistReviewsProvider(specialistId).future);
  return SpecialistReviewStats.fromReviews(reviews);
});

/// Провайдер для получения отзывов заказчика
final customerReviewsProvider = StreamProvider.family<List<Review>, String>(
  (ref, customerId) => FirebaseFirestore.instance
      .collection('reviews')
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Review.fromDocument).toList()),
);

/// Провайдер для создания отзыва
final createReviewProvider =
    FutureProvider.family<void, CreateReviewParams>((ref, params) async {
  final review = Review(
    id: '',
    specialistId: params.specialistId,
    customerId: params.customerId,
    customerName: params.customerName,
    rating: params.rating,
    comment: params.comment,
    serviceTags: params.serviceTags,
    createdAt: DateTime.now(),
  );

  await FirebaseFirestore.instance.collection('reviews').add(review.toMap());
});

/// Провайдер для сервиса отзывов
final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

/// Провайдер для состояния формы отзыва
final reviewFormProvider =
    StateNotifierProvider<ReviewFormNotifier, ReviewFormState>(
        (ref) => ReviewFormNotifier(ref.read(reviewServiceProvider)),);

/// Провайдер для состояния отзывов
final reviewStateProvider =
    StateNotifierProvider<ReviewStateNotifier, ReviewState>(
        (ref) => ReviewStateNotifier(ref.read(reviewServiceProvider)),);

/// Состояние формы отзыва
class ReviewFormState {
  const ReviewFormState({
    this.rating = 0,
    this.comment = '',
    this.serviceTags = const [],
    this.selectedTags = const [],
    this.isLoading = false,
    this.error,
    this.title = '',
    this.isPublic = true,
    this.isSubmitting = false,
  });

  final int rating;
  final String comment;
  final List<String> serviceTags;
  final List<String> selectedTags;
  final bool isLoading;
  final String? error;
  final String title;
  final bool isPublic;
  final bool isSubmitting;

  String? get errorMessage => error;

  ReviewFormState copyWith({
    int? rating,
    String? comment,
    List<String>? serviceTags,
    List<String>? selectedTags,
    bool? isLoading,
    String? error,
    String? title,
    bool? isPublic,
    bool? isSubmitting,
  }) =>
      ReviewFormState(
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        serviceTags: serviceTags ?? this.serviceTags,
        selectedTags: selectedTags ?? this.selectedTags,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        title: title ?? this.title,
        isPublic: isPublic ?? this.isPublic,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

/// Нотификатор для формы отзыва
class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  ReviewFormNotifier(this._reviewService) : super(const ReviewFormState());

  final ReviewService _reviewService;

  void updateRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void updateComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  void updateServiceTags(List<String> tags) {
    state = state.copyWith(serviceTags: tags);
  }

  void updateSelectedTags(List<String> tags) {
    state = state.copyWith(selectedTags: tags);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void addTag(String tag) {
    final tags = List<String>.from(state.serviceTags);
    if (!tags.contains(tag)) {
      tags.add(tag);
      state = state.copyWith(serviceTags: tags);
    }
  }

  void removeTag(String tag) {
    final tags = List<String>.from(state.serviceTags);
    tags.remove(tag);
    state = state.copyWith(serviceTags: tags);
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
    state = state.copyWith(error: error);
  }

  bool get isValid => state.rating > 0 && state.comment.isNotEmpty;

  Future<void> submitReview(
      String specialistId, String customerId, String customerName,) async {
    state = state.copyWith(isLoading: true);

    try {
      await _reviewService.createReview(
        specialistId: specialistId,
        customerId: customerId,
        customerName: customerName,
        rating: state.rating,
        comment: state.comment,
        serviceTags: state.serviceTags,
      );
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
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

/// Нотификатор для состояния отзывов
class ReviewStateNotifier extends StateNotifier<ReviewState> {
  ReviewStateNotifier(this._reviewService) : super(const ReviewState());

  final ReviewService _reviewService;

  Future<void> loadReviews(String specialistId) async {
    state = state.copyWith(isLoading: true);

    try {
      final reviews = await _reviewService.getReviews(specialistId);
      state = state.copyWith(reviews: reviews, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createReview(Review review) async {
    state = state.copyWith(isLoading: true);

    try {
      await _reviewService.createReview(
        specialistId: review.specialistId,
        customerId: review.customerId,
        customerName: review.customerName,
        rating: review.rating,
        comment: review.comment,
        serviceTags: review.serviceTags,
      );
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Параметры для создания отзыва
class CreateReviewParams {
  const CreateReviewParams({
    required this.specialistId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    this.serviceTags = const [],
  });

  final String specialistId;
  final String customerId;
  final String customerName;
  final int rating;
  final String comment;
  final List<String> serviceTags;
}

/// Статистика отзывов специалиста
class SpecialistReviewStats {
  const SpecialistReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory SpecialistReviewStats.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) {
      return const SpecialistReviewStats(
        averageRating: 0,
        totalReviews: 0,
        ratingDistribution: {},
      );
    }

    // Вычисляем средний рейтинг
    final totalRating =
        reviews.fold<int>(0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / reviews.length;

    // Подсчитываем распределение по звездам
    final ratingDistribution = <int, int>{};
    for (final review in reviews) {
      ratingDistribution[review.rating] =
          (ratingDistribution[review.rating] ?? 0) + 1;
    }

    return SpecialistReviewStats(
      averageRating: averageRating,
      totalReviews: reviews.length,
      ratingDistribution: ratingDistribution,
    );
  }

  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
}
