import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_profile_extended.dart';
import '../services/customer_profile_extended_service.dart';

/// Провайдер сервиса расширенного профиля
final customerProfileExtendedServiceProvider = Provider<CustomerProfileExtendedService>(
  (ref) => CustomerProfileExtendedService(),
);

/// Провайдер расширенного профиля заказчика
final customerProfileExtendedProvider =
    FutureProvider.family<CustomerProfileExtended?, String>((ref, userId) async {
  final service = ref.read(customerProfileExtendedServiceProvider);
  return service.getExtendedProfile(userId);
});

/// Провайдер заметок заказчика
final customerNotesProvider =
    FutureProvider.family<List<CustomerNote>, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.notes ?? [];
});

/// Провайдер фото для вдохновения
final inspirationPhotosProvider =
    FutureProvider.family<List<InspirationPhoto>, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.inspirationPhotos ?? [];
});

/// Провайдер избранных специалистов
final favoriteSpecialistsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.favoriteSpecialists ?? [];
});

/// Провайдер сохранённых событий
final savedEventsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.savedEvents ?? [];
});

/// Провайдер заметок по тегу
final notesByTagProvider =
    FutureProvider.family<List<CustomerNote>, (String, String)>((ref, params) async {
  final (userId, tag) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return service.getNotesByTag(userId, tag);
});

/// Провайдер фото по тегу
final photosByTagProvider =
    FutureProvider.family<List<InspirationPhoto>, (String, String)>((ref, params) async {
  final (userId, tag) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return service.getPhotosByTag(userId, tag);
});

/// Провайдер поиска по заметкам
final searchNotesProvider =
    FutureProvider.family<List<CustomerNote>, (String, String)>((ref, params) async {
  final (userId, query) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return service.searchNotes(userId, query);
});

/// Провайдер поиска по фото
final searchPhotosProvider =
    FutureProvider.family<List<InspirationPhoto>, (String, String)>((ref, params) async {
  final (userId, query) = params;
  final service = ref.read(customerProfileExtendedServiceProvider);
  return service.searchPhotos(userId, query);
});

/// Провайдер статистики профиля
final customerProfileStatsProvider =
    FutureProvider.family<CustomerProfileStats, String>((ref, userId) async {
  final service = ref.read(customerProfileExtendedServiceProvider);
  return service.getProfileStats(userId);
});

/// Провайдер всех тегов пользователя
final userTagsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.allTags.toList() ?? <String>[];
});

/// Провайдер закреплённых заметок
final pinnedNotesProvider = FutureProvider.family<List<CustomerNote>, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.pinnedNotes ?? [];
});

/// Провайдер публичных фото
final publicPhotosProvider =
    FutureProvider.family<List<InspirationPhoto>, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.publicPhotos ?? [];
});

/// Провайдер предпочтений пользователя
final customerPreferencesProvider =
    FutureProvider.family<CustomerPreferences?, String>((ref, userId) async {
  final profile = await ref.read(customerProfileExtendedProvider(userId).future);
  return profile?.preferences != null ? CustomerPreferences.fromMap(profile!.preferences!) : null;
});

/// Нотификатор для управления состоянием загрузки фото
class PhotoUploadStateNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  void setUploading(String photoId, bool isUploading) {
    state = {...state, photoId: isUploading};
  }

  void clearUploading(String photoId) {
    state = Map.from(state)..remove(photoId);
  }
}

/// Провайдер для управления состоянием загрузки фото
final photoUploadStateProvider = NotifierProvider<PhotoUploadStateNotifier, Map<String, bool>>(
  PhotoUploadStateNotifier.new,
);

/// Нотификатор для управления состоянием создания заметок
class NoteCreationStateNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  void setCreating(String noteId, bool isCreating) {
    state = {...state, noteId: isCreating};
  }

  void clearCreating(String noteId) {
    state = Map.from(state)..remove(noteId);
  }
}

/// Провайдер для управления состоянием создания заметок
final noteCreationStateProvider = NotifierProvider<NoteCreationStateNotifier, Map<String, bool>>(
  NoteCreationStateNotifier.new,
);

/// Нотификатор для управления состоянием поиска
class SearchStateNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  void setSearchQuery(String field, String query) {
    state = {...state, field: query};
  }

  void clearSearch(String field) {
    state = Map.from(state)..remove(field);
  }
}

/// Провайдер для управления состоянием поиска
final searchStateProvider = NotifierProvider<SearchStateNotifier, Map<String, String>>(
  SearchStateNotifier.new,
);

/// Нотификатор для управления выбранными тегами
class SelectedTagsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void addTag(String tag) {
    state = {...state, tag};
  }

  void removeTag(String tag) {
    state = state.where((t) => t != tag).toSet();
  }

  void clearTags() {
    state = <String>{};
  }
}

/// Провайдер для управления выбранными тегами
final selectedTagsProvider = NotifierProvider<SelectedTagsNotifier, Set<String>>(
  SelectedTagsNotifier.new,
);

/// Нотификатор для управления фильтрами заметок
class NoteFiltersNotifier extends Notifier<NoteFilters> {
  @override
  NoteFilters build() => const NoteFilters();

  void updateFilters(NoteFilters filters) {
    state = filters;
  }

  void resetFilters() {
    state = const NoteFilters();
  }
}

/// Провайдер для управления фильтрами заметок
final noteFiltersProvider =
    NotifierProvider<NoteFiltersNotifier, NoteFilters>(NoteFiltersNotifier.new);

/// Нотификатор для управления фильтрами фото
class PhotoFiltersNotifier extends Notifier<PhotoFilters> {
  @override
  PhotoFilters build() => const PhotoFilters();

  void updateFilters(PhotoFilters filters) {
    state = filters;
  }

  void resetFilters() {
    state = const PhotoFilters();
  }
}

/// Провайдер для управления фильтрами фото
final photoFiltersProvider = NotifierProvider<PhotoFiltersNotifier, PhotoFilters>(
  PhotoFiltersNotifier.new,
);

/// Фильтры для заметок
class NoteFilters {
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
  final String? searchQuery;
  final List<String> selectedTags;
  final bool showPinnedOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? eventId;
  final String? specialistId;

  NoteFilters copyWith({
    String? searchQuery,
    List<String>? selectedTags,
    bool? showPinnedOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
    String? eventId,
    String? specialistId,
  }) =>
      NoteFilters(
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

/// Фильтры для фото
class PhotoFilters {
  const PhotoFilters({
    this.searchQuery,
    this.selectedTags = const [],
    this.showPublicOnly = false,
    this.showByDate = false,
    this.fromDate,
    this.toDate,
  });
  final String? searchQuery;
  final List<String> selectedTags;
  final bool showPublicOnly;
  final bool showByDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  PhotoFilters copyWith({
    String? searchQuery,
    List<String>? selectedTags,
    bool? showPublicOnly,
    bool? showByDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      PhotoFilters(
        searchQuery: searchQuery ?? this.searchQuery,
        selectedTags: selectedTags ?? this.selectedTags,
        showPublicOnly: showPublicOnly ?? this.showPublicOnly,
        showByDate: showByDate ?? this.showByDate,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );
}
