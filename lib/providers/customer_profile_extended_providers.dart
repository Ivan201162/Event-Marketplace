import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_profile_extended.dart';
import '../services/customer_profile_extended_service.dart';

/// Провайдер сервиса расширенного профиля
final customerProfileExtendedServiceProvider =
    Provider<CustomerProfileExtendedService>((ref) {
  return CustomerProfileExtendedService();
});

/// Провайдер расширенного профиля заказчика
final customerProfileExtendedProvider =
    FutureProvider.family<CustomerProfileExtended?, String>(
        (ref, userId) async {
  final service = ref.read(customerProfileExtendedServiceProvider);
  return await service.getExtendedProfile(userId);
});

/// Провайдер заметок заказчика
final customerNotesProvider =
    FutureProvider.family<List<CustomerNote>, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.notes ?? [];
});

/// Провайдер фото для вдохновения
final inspirationPhotosProvider =
    FutureProvider.family<List<InspirationPhoto>, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.inspirationPhotos ?? [];
});

/// Провайдер избранных специалистов
final favoriteSpecialistsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.favoriteSpecialists ?? [];
});

/// Провайдер сохранённых событий
final savedEventsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.savedEvents ?? [];
});

/// Провайдер заметок по тегу
final notesByTagProvider =
    FutureProvider.family<List<CustomerNote>, (String, String)>(
        (ref, params) async {
  final (userId, tag) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return await service.getNotesByTag(userId, tag);
});

/// Провайдер фото по тегу
final photosByTagProvider =
    FutureProvider.family<List<InspirationPhoto>, (String, String)>(
        (ref, params) async {
  final (userId, tag) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return await service.getPhotosByTag(userId, tag);
});

/// Провайдер поиска по заметкам
final searchNotesProvider =
    FutureProvider.family<List<CustomerNote>, (String, String)>(
        (ref, params) async {
  final (userId, query) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return await service.searchNotes(userId, query);
});

/// Провайдер поиска по фото
final searchPhotosProvider =
    FutureProvider.family<List<InspirationPhoto>, (String, String)>(
        (ref, params) async {
  final (userId, query) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return await service.searchPhotos(userId, query);
});

/// Провайдер статистики профиля
final customerProfileStatsProvider =
    FutureProvider.family<CustomerProfileStats, String>((ref, userId) async {
  final service = ref.read(customerProfileExtendedServiceProvider);
  return await service.getProfileStats(userId);
});

/// Провайдер всех тегов пользователя
final userTagsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.allTags ?? [];
});

/// Провайдер закреплённых заметок
final pinnedNotesProvider =
    FutureProvider.family<List<CustomerNote>, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.pinnedNotes ?? [];
});

/// Провайдер публичных фото
final publicPhotosProvider =
    FutureProvider.family<List<InspirationPhoto>, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.publicPhotos ?? [];
});

/// Провайдер предпочтений пользователя
final customerPreferencesProvider =
    FutureProvider.family<CustomerPreferences?, String>((ref, userId) async {
  final profile =
      await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.preferences;
});

/// Провайдер для управления состоянием загрузки фото
final photoUploadStateProvider = StateProvider<Map<String, bool>>((ref) => {});

/// Провайдер для управления состоянием создания заметок
final noteCreationStateProvider = StateProvider<Map<String, bool>>((ref) => {});

/// Провайдер для управления состоянием поиска
final searchStateProvider = StateProvider<Map<String, String>>((ref) => {});

/// Провайдер для управления выбранными тегами
final selectedTagsProvider = StateProvider<Set<String>>((ref) => Set<String>());

/// Провайдер для управления фильтрами заметок
final noteFiltersProvider =
    StateProvider<NoteFilters>((ref) => const NoteFilters());

/// Провайдер для управления фильтрами фото
final photoFiltersProvider =
    StateProvider<PhotoFilters>((ref) => const PhotoFilters());

/// Фильтры для заметок
class NoteFilters {
  final String? searchQuery;
  final List<String> selectedTags;
  final bool showPinnedOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? eventId;
  final String? specialistId;

  const NoteFilters({
    this.searchQuery,
    this.selectedTags = const [],
    this.showPinnedOnly = false,
    this.showByDate = false,
    this.fromDate,
    this.toDate,
    this.eventId,
    this.specialistId,
  });

  NoteFilters copyWith({
    String? searchQuery,
    List<String>? selectedTags,
    bool? showPinnedOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
    String? eventId,
    String? specialistId,
  }) {
    return NoteFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      showPinnedOnly: showPinnedOnly ?? this.showPinnedOnly,
      showByDate: showByDate ?? this.showByDate,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      eventId: eventId ?? this.eventId,
      specialistId: specialistId ?? this.specialistId,
    );
  }
}

/// Фильтры для фото
class PhotoFilters {
  final String? searchQuery;
  final List<String> selectedTags;
  final bool showPublicOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  const PhotoFilters({
    this.searchQuery,
    this.selectedTags = const [],
    this.showPublicOnly = false,
    this.showByDate = false,
    this.fromDate,
    this.toDate,
  });

  PhotoFilters copyWith({
    String? searchQuery,
    List<String>? selectedTags,
    bool? showPublicOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return PhotoFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      showPublicOnly: showPublicOnly ?? this.showPublicOnly,
      showByDate: showByDate ?? this.showByDate,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}
