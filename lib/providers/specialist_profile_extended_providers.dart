import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_profile_extended.dart';
import '../services/specialist_profile_extended_service.dart';

/// Провайдер сервиса расширенного профиля специалиста
final specialistProfileExtendedServiceProvider =
    Provider<SpecialistProfileExtendedService>(
        (ref) => SpecialistProfileExtendedService());

/// Провайдер расширенного профиля специалиста
final specialistProfileExtendedProvider =
    FutureProvider.family<SpecialistProfileExtended?, String>(
        (ref, specialistId) async {
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return service.getExtendedProfile(specialistId);
});

/// Провайдер FAQ специалиста
final specialistFAQProvider =
    FutureProvider.family<List<FAQItem>, String>((ref, specialistId) async {
  final profile =
      await ref.read(specialistProfileExtendedProvider(specialistId).future);
  return profile?.faqItems ?? [];
});

/// Провайдер портфолио видео специалиста
final specialistPortfolioVideosProvider =
    FutureProvider.family<List<PortfolioVideo>, String>(
        (ref, specialistId) async {
  final profile =
      await ref.read(specialistProfileExtendedProvider(specialistId).future);
  return profile?.portfolioVideos ?? [];
});

/// Провайдер сертификатов специалиста
final specialistCertificationsProvider =
    FutureProvider.family<List<String>, String>((ref, specialistId) async {
  final profile =
      await ref.read(specialistProfileExtendedProvider(specialistId).future);
  return profile?.certifications ?? [];
});

/// Провайдер наград специалиста
final specialistAwardsProvider =
    FutureProvider.family<List<String>, String>((ref, specialistId) async {
  final profile =
      await ref.read(specialistProfileExtendedProvider(specialistId).future);
  return profile?.awards ?? [];
});

/// Провайдер отзывов специалиста
final specialistTestimonialsProvider =
    FutureProvider.family<List<String>, String>((ref, specialistId) async {
  final profile =
      await ref.read(specialistProfileExtendedProvider(specialistId).future);
  return profile?.testimonials ?? [];
});

/// Провайдер FAQ по категории
final specialistFAQByCategoryProvider =
    FutureProvider.family<List<FAQItem>, (String, String)>((ref, params) async {
  final (specialistId, category) = params;
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return service.getFAQByCategory(specialistId, category);
});

/// Провайдер публичных видео
final specialistPublicVideosProvider =
    FutureProvider.family<List<PortfolioVideo>, String>(
        (ref, specialistId) async {
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return service.getPublicVideos(specialistId);
});

/// Провайдер поиска по FAQ
final specialistFAQSearchProvider =
    FutureProvider.family<List<FAQItem>, (String, String)>((ref, params) async {
  final (specialistId, query) = params;
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return service.searchFAQ(specialistId, query);
});

/// Провайдер поиска по видео
final specialistVideoSearchProvider =
    FutureProvider.family<List<PortfolioVideo>, (String, String)>(
        (ref, params) async {
  final (specialistId, query) = params;
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return service.searchVideos(specialistId, query);
});

/// Провайдер статистики профиля специалиста
final specialistProfileStatsProvider =
    FutureProvider.family<SpecialistProfileStats, String>(
        (ref, specialistId) async {
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return service.getProfileStats(specialistId);
});

/// Нотификатор для состояния загрузки видео
class VideoUploadStateNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  void setUploading(String videoId, bool isUploading) {
    state = {...state, videoId: isUploading};
  }

  void clearState() {
    state = {};
  }
}

/// Провайдер для управления состоянием загрузки видео
final videoUploadStateProvider =
    NotifierProvider<VideoUploadStateNotifier, Map<String, bool>>(
  VideoUploadStateNotifier.new,
);

/// Нотификатор для состояния создания FAQ
class FaqCreationStateNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  void setCreating(String faqId, bool isCreating) {
    state = {...state, faqId: isCreating};
  }

  void clearState() {
    state = {};
  }
}

/// Провайдер для управления состоянием создания FAQ
final faqCreationStateProvider =
    NotifierProvider<FaqCreationStateNotifier, Map<String, bool>>(
  FaqCreationStateNotifier.new,
);

/// Нотификатор для состояния поиска специалистов
class SpecialistSearchStateNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  void setSearchQuery(String query) {
    state = {...state, 'query': query};
  }

  void clearState() {
    state = {};
  }
}

/// Провайдер для управления состоянием поиска
final specialistSearchStateProvider =
    NotifierProvider<SpecialistSearchStateNotifier, Map<String, String>>(
  SpecialistSearchStateNotifier.new,
);

/// Нотификатор для выбранных категорий FAQ
class SelectedFAQCategoriesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggleCategory(String category) {
    if (state.contains(category)) {
      state = state.where((c) => c != category).toSet();
    } else {
      state = {...state, category};
    }
  }

  void clearSelection() {
    state = {};
  }
}

/// Провайдер для управления выбранными категориями FAQ
final selectedFAQCategoriesProvider =
    NotifierProvider<SelectedFAQCategoriesNotifier, Set<String>>(
  SelectedFAQCategoriesNotifier.new,
);

/// Нотификатор для фильтров FAQ
class FaqFiltersNotifier extends Notifier<FAQFilters> {
  @override
  FAQFilters build() => const FAQFilters();

  void updateFilters(FAQFilters filters) {
    state = filters;
  }

  void resetFilters() {
    state = const FAQFilters();
  }
}

/// Провайдер для управления фильтрами FAQ
final faqFiltersProvider = NotifierProvider<FaqFiltersNotifier, FAQFilters>(
  FaqFiltersNotifier.new,
);

/// Нотификатор для фильтров видео
class VideoFiltersNotifier extends Notifier<VideoFilters> {
  @override
  VideoFilters build() => const VideoFilters();

  void updateFilters(VideoFilters filters) {
    state = filters;
  }

  void resetFilters() {
    state = const VideoFilters();
  }
}

/// Провайдер для управления фильтрами видео
final videoFiltersProvider =
    NotifierProvider<VideoFiltersNotifier, VideoFilters>(
  VideoFiltersNotifier.new,
);

/// Фильтры для FAQ
class FAQFilters {
  const FAQFilters({
    this.searchQuery,
    this.selectedCategories = const [],
    this.showPublishedOnly = true,
    this.showByDate = false,
    this.fromDate,
    this.toDate,
  });
  final String? searchQuery;
  final List<String> selectedCategories;
  final bool showPublishedOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  FAQFilters copyWith({
    String? searchQuery,
    List<String>? selectedCategories,
    bool? showPublishedOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      FAQFilters(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedCategories: selectedCategories ?? this.selectedCategories,
        showPublishedOnly: showPublishedOnly ?? this.showPublishedOnly,
        showByDate: showByDate ?? this.showByDate,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );
}

/// Фильтры для видео
class VideoFilters {
  const VideoFilters({
    this.searchQuery,
    this.selectedTags = const [],
    this.selectedPlatforms = const [],
    this.showPublicOnly = true,
    this.showByDate = false,
    this.fromDate,
    this.toDate,
  });
  final String? searchQuery;
  final List<String> selectedTags;
  final List<String> selectedPlatforms;
  final bool showPublicOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  VideoFilters copyWith({
    String? searchQuery,
    List<String>? selectedTags,
    List<String>? selectedPlatforms,
    bool? showPublicOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      VideoFilters(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedTags: selectedTags ?? this.selectedTags,
        selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
        showPublicOnly: showPublicOnly ?? this.showPublicOnly,
        showByDate: showByDate ?? this.showByDate,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );
}
