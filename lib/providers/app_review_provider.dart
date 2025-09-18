import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_review_service.dart';

/// Провайдер для управления отзывами о приложении
final appReviewProvider =
    NotifierProvider<AppReviewNotifier, AppReviewState>((ref) {
  return AppReviewNotifier();
});

/// Провайдер для статистики отзывов
final reviewStatsProvider = FutureProvider<ReviewStats>((ref) async {
  return await AppReviewService.getReviewStats();
});

/// Провайдер для проверки доступности in-app review
final reviewAvailabilityProvider = FutureProvider<bool>((ref) async {
  return await AppReviewService.isAvailable();
});

/// Провайдер для рекомендуемого времени запроса отзыва
final reviewTimingProvider = FutureProvider<ReviewTiming>((ref) async {
  return await AppReviewService.getRecommendedTiming();
});

/// Состояние отзывов о приложении
class AppReviewState {
  final bool isRequesting;
  final bool isAvailable;
  final String? error;
  final ReviewTiming recommendedTiming;
  final bool shouldShowRequest;

  const AppReviewState({
    this.isRequesting = false,
    this.isAvailable = false,
    this.error,
    this.recommendedTiming = ReviewTiming.notYet,
    this.shouldShowRequest = false,
  });

  AppReviewState copyWith({
    bool? isRequesting,
    bool? isAvailable,
    String? error,
    ReviewTiming? recommendedTiming,
    bool? shouldShowRequest,
  }) {
    return AppReviewState(
      isRequesting: isRequesting ?? this.isRequesting,
      isAvailable: isAvailable ?? this.isAvailable,
      error: error ?? this.error,
      recommendedTiming: recommendedTiming ?? this.recommendedTiming,
      shouldShowRequest: shouldShowRequest ?? this.shouldShowRequest,
    );
  }

  /// Получить статус отзыва
  String get reviewStatus {
    if (isRequesting) return 'Запрос отзыва...';
    if (error != null) return 'Ошибка запроса';
    if (shouldShowRequest) return 'Готов к запросу';
    return 'Не готов к запросу';
  }

  /// Получить цвет статуса
  int get statusColor {
    if (isRequesting) return 0xFF2196F3; // Синий
    if (error != null) return 0xFFF44336; // Красный
    if (shouldShowRequest) return 0xFFFF9800; // Оранжевый
    return 0xFF4CAF50; // Зеленый
  }
}

/// Нотификатор для управления отзывами
class AppReviewNotifier extends Notifier<AppReviewState> {
  AppReviewNotifier() : super(const AppReviewState()) {
    _initialize();
  }

  /// Инициализация
  Future<void> _initialize() async {
    await _updateAvailability();
    await _updateRecommendedTiming();
    await _updateShouldShowRequest();
  }

  /// Обновить доступность in-app review
  Future<void> _updateAvailability() async {
    try {
      final isAvailable = await AppReviewService.isAvailable();
      state = state.copyWith(isAvailable: isAvailable);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить рекомендуемое время
  Future<void> _updateRecommendedTiming() async {
    try {
      final timing = await AppReviewService.getRecommendedTiming();
      state = state.copyWith(recommendedTiming: timing);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить необходимость показа запроса
  Future<void> _updateShouldShowRequest() async {
    try {
      final shouldShow = await AppReviewService.shouldShowReviewRequest();
      state = state.copyWith(shouldShowRequest: shouldShow);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Запросить отзыв
  Future<void> requestReview() async {
    state = state.copyWith(isRequesting: true, error: null);

    try {
      await AppReviewService.requestReview();
      await _updateShouldShowRequest();
      state = state.copyWith(isRequesting: false);
    } catch (e) {
      state = state.copyWith(
        isRequesting: false,
        error: e.toString(),
      );
    }
  }

  /// Открыть страницу в магазине
  Future<void> openStoreListing() async {
    state = state.copyWith(isRequesting: true, error: null);

    try {
      await AppReviewService.openStoreListing();
      await _updateShouldShowRequest();
      state = state.copyWith(isRequesting: false);
    } catch (e) {
      state = state.copyWith(
        isRequesting: false,
        error: e.toString(),
      );
    }
  }

  /// Открыть страницу отзывов в браузере
  Future<void> openReviewPageInBrowser() async {
    state = state.copyWith(isRequesting: true, error: null);

    try {
      await AppReviewService.openReviewPageInBrowser();
      await _updateShouldShowRequest();
      state = state.copyWith(isRequesting: false);
    } catch (e) {
      state = state.copyWith(
        isRequesting: false,
        error: e.toString(),
      );
    }
  }

  /// Отклонить запрос на отзыв
  Future<void> dismissReviewRequest() async {
    try {
      await AppReviewService.dismissReviewRequest();
      await _updateShouldShowRequest();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Отметить использование функции
  Future<void> markFeatureUsed(FeatureType featureType) async {
    try {
      await AppReviewService.markFeatureUsed(featureType.name);
      await _updateRecommendedTiming();
      await _updateShouldShowRequest();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Увеличить счетчик запусков
  Future<void> incrementAppLaunchCount() async {
    try {
      await AppReviewService.incrementAppLaunchCount();
      await _updateRecommendedTiming();
      await _updateShouldShowRequest();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Сбросить состояние отзыва
  Future<void> resetReviewState() async {
    try {
      await AppReviewService.resetReviewState();
      await _updateRecommendedTiming();
      await _updateShouldShowRequest();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить все данные
  Future<void> refresh() async {
    await _initialize();
  }

  /// Очистить ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Провайдер для проверки, нужно ли показать диалог отзыва
final shouldShowReviewDialogProvider = Provider<bool>((ref) {
  final reviewState = ref.watch(appReviewProvider);
  return reviewState.shouldShowRequest &&
      reviewState.recommendedTiming == ReviewTiming.now &&
      !reviewState.isRequesting;
});

/// Провайдер для получения описания рекомендуемого времени
final reviewTimingDescriptionProvider = Provider<String>((ref) {
  final timing = ref.watch(appReviewProvider).recommendedTiming;

  switch (timing) {
    case ReviewTiming.now:
      return 'Готов к запросу отзыва';
    case ReviewTiming.soon:
      return 'Скоро можно будет запросить отзыв';
    case ReviewTiming.notYet:
      return 'Еще рано для запроса отзыва';
  }
});

/// Провайдер для получения цвета рекомендуемого времени
final reviewTimingColorProvider = Provider<int>((ref) {
  final timing = ref.watch(appReviewProvider).recommendedTiming;

  switch (timing) {
    case ReviewTiming.now:
      return 0xFF4CAF50; // Зеленый
    case ReviewTiming.soon:
      return 0xFFFF9800; // Оранжевый
    case ReviewTiming.notYet:
      return 0xFF9E9E9E; // Серый
  }
});

/// Провайдер для получения иконки рекомендуемого времени
final reviewTimingIconProvider = Provider<String>((ref) {
  final timing = ref.watch(appReviewProvider).recommendedTiming;

  switch (timing) {
    case ReviewTiming.now:
      return '⭐';
    case ReviewTiming.soon:
      return '⏰';
    case ReviewTiming.notYet:
      return '⏳';
  }
});
