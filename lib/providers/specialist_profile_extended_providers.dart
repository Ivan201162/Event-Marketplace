import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_profile_extended.dart';
import '../services/specialist_profile_extended_service.dart';

/// Провайдер сервиса расширенного профиля специалиста
final specialistProfileExtendedServiceProvider =
    Provider<SpecialistProfileExtendedService>((ref) {
  return SpecialistProfileExtendedService();
});

/// Провайдер расширенного профиля специалиста
final specialistProfileExtendedProvider =
    FutureProvider.family<SpecialistProfileExtended?, String>(
        (ref, specialistId) async {
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return await service.getExtendedProfile(specialistId);
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
  return await service.getFAQByCategory(specialistId, category);
});

/// Провайдер публичных видео
final specialistPublicVideosProvider =
    FutureProvider.family<List<PortfolioVideo>, String>(
        (ref, specialistId) async {
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return await service.getPublicVideos(specialistId);
});

/// Провайдер поиска по FAQ
final specialistFAQSearchProvider =
    FutureProvider.family<List<FAQItem>, (String, String)>((ref, params) async {
  final (specialistId, query) = params;
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return await service.searchFAQ(specialistId, query);
});

/// Провайдер поиска по видео
final specialistVideoSearchProvider =
    FutureProvider.family<List<PortfolioVideo>, (String, String)>(
        (ref, params) async {
  final (specialistId, query) = params;
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return await service.searchVideos(specialistId, query);
});

/// Провайдер статистики профиля специалиста
final specialistProfileStatsProvider =
    FutureProvider.family<SpecialistProfileStats, String>(
        (ref, specialistId) async {
  final service = ref.read(specialistProfileExtendedServiceProvider);
  return await service.getProfileStats(specialistId);
});

/// Провайдер для управления состоянием загрузки видео
final videoUploadStateProvider = StateProvider<Map<String, bool>>((ref) => {});

/// Провайдер для управления состоянием создания FAQ
final faqCreationStateProvider = StateProvider<Map<String, bool>>((ref) => {});

/// Провайдер для управления состоянием поиска
final specialistSearchStateProvider =
    StateProvider<Map<String, String>>((ref) => {});

/// Провайдер для управления выбранными категориями FAQ
final selectedFAQCategoriesProvider =
    StateProvider<Set<String>>((ref) => Set<String>());

/// Провайдер для управления фильтрами FAQ
final faqFiltersProvider =
    StateProvider<FAQFilters>((ref) => const FAQFilters());

/// Провайдер для управления фильтрами видео
final videoFiltersProvider =
    StateProvider<VideoFilters>((ref) => const VideoFilters());

/// Фильтры для FAQ
class FAQFilters {
  final String? searchQuery;
  final List<String> selectedCategories;
  final bool showPublishedOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  const FAQFilters({
    this.searchQuery,
    this.selectedCategories = const [],
    this.showPublishedOnly = true,
    this.showByDate = false,
    this.fromDate,
    this.toDate,
  });

  FAQFilters copyWith({
    String? searchQuery,
    List<String>? selectedCategories,
    bool? showPublishedOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return FAQFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      showPublishedOnly: showPublishedOnly ?? this.showPublishedOnly,
      showByDate: showByDate ?? this.showByDate,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

/// Фильтры для видео
class VideoFilters {
  final String? searchQuery;
  final List<String> selectedTags;
  final List<String> selectedPlatforms;
  final bool showPublicOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  const VideoFilters({
    this.searchQuery,
    this.selectedTags = const [],
    this.selectedPlatforms = const [],
    this.showPublicOnly = true,
    this.showByDate = false,
    this.fromDate,
    this.toDate,
  });

  VideoFilters copyWith({
    String? searchQuery,
    List<String>? selectedTags,
    List<String>? selectedPlatforms,
    bool? showPublicOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return VideoFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedPlatforms: selectedPlatforms ?? this.selectedPlatforms,
      showPublicOnly: showPublicOnly ?? this.showPublicOnly,
      showByDate: showByDate ?? this.showByDate,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}
