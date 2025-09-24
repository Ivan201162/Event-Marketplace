import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../services/event_ideas_service.dart';

/// Провайдер сервиса идей мероприятий
final eventIdeasServiceProvider = Provider<EventIdeasService>((ref) => EventIdeasService());

/// Провайдер всех идей
final eventIdeasProvider = StreamProvider<List<EventIdea>>((ref) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getIdeas();
});

/// Провайдер рекомендуемых идей
final featuredIdeasProvider = StreamProvider<List<EventIdea>>((ref) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getFeaturedIdeas();
});

/// Провайдер популярных идей
final popularIdeasProvider = StreamProvider<List<EventIdea>>((ref) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getPopularIdeas();
});

/// Провайдер идей по типу
final ideasByTypeProvider = StreamProvider.family<List<EventIdea>, EventIdeaType>((ref, type) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getIdeasByType(type);
});

/// Провайдер идей пользователя
final userIdeasProvider = StreamProvider.family<List<EventIdea>, String>((ref, userId) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getUserIdeas(userId);
});

/// Провайдер сохраненных идей пользователя
final savedIdeasProvider = StreamProvider.family<List<EventIdea>, String>((ref, userId) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getSavedIdeas(userId);
});

/// Провайдер поиска идей
final searchIdeasProvider = StreamProvider.family<List<EventIdea>, String>((ref, query) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.searchIdeas(query);
});

/// Провайдер статистики идей
final ideasStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getIdeasStats();
});

/// Провайдер похожих идей
final similarIdeasProvider = FutureProvider.family<List<EventIdea>, String>((ref, ideaId) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getSimilarIdeas(ideaId);
});

/// Провайдер конкретной идеи
final ideaProvider = FutureProvider.family<EventIdea?, String>((ref, ideaId) {
  final service = ref.watch(eventIdeasServiceProvider);
  return service.getIdeaById(ideaId);
});

/// Провайдер фильтров идей
final ideasFiltersProvider = NotifierProvider<IdeasFiltersNotifier, IdeasFilters>(
  IdeasFiltersNotifier.new,
);

/// Фильтры для идей
class IdeasFilters {
  const IdeasFilters({
    this.type,
    this.tags = const [],
    this.searchQuery = '',
    this.sortBy = IdeasSortBy.newest,
    this.minBudget,
    this.maxBudget,
    this.minGuests,
    this.maxGuests,
  });

  final EventIdeaType? type;
  final List<String> tags;
  final String searchQuery;
  final IdeasSortBy sortBy;
  final int? minBudget;
  final int? maxBudget;
  final int? minGuests;
  final int? maxGuests;

  IdeasFilters copyWith({
    EventIdeaType? type,
    List<String>? tags,
    String? searchQuery,
    IdeasSortBy? sortBy,
    int? minBudget,
    int? maxBudget,
    int? minGuests,
    int? maxGuests,
  }) =>
      IdeasFilters(
        type: type ?? this.type,
        tags: tags ?? this.tags,
        searchQuery: searchQuery ?? this.searchQuery,
        sortBy: sortBy ?? this.sortBy,
        minBudget: minBudget ?? this.minBudget,
        maxBudget: maxBudget ?? this.maxBudget,
        minGuests: minGuests ?? this.minGuests,
        maxGuests: maxGuests ?? this.maxGuests,
      );

  bool get hasFilters =>
      type != null ||
      tags.isNotEmpty ||
      searchQuery.isNotEmpty ||
      minBudget != null ||
      maxBudget != null ||
      minGuests != null ||
      maxGuests != null;
}

/// Способы сортировки идей
enum IdeasSortBy {
  newest, // Новые
  oldest, // Старые
  popular, // Популярные
  mostLiked, // Больше лайков
  mostSaved, // Больше сохранений
  mostViewed, // Больше просмотров
}

/// Расширение для получения названий сортировки
extension IdeasSortByExtension on IdeasSortBy {
  String get displayName {
    switch (this) {
      case IdeasSortBy.newest:
        return 'Новые';
      case IdeasSortBy.oldest:
        return 'Старые';
      case IdeasSortBy.popular:
        return 'Популярные';
      case IdeasSortBy.mostLiked:
        return 'Больше лайков';
      case IdeasSortBy.mostSaved:
        return 'Больше сохранений';
      case IdeasSortBy.mostViewed:
        return 'Больше просмотров';
    }
  }
}

/// Нотификатор фильтров идей
class IdeasFiltersNotifier extends Notifier<IdeasFilters> {
  @override
  IdeasFilters build() => const IdeasFilters();

  /// Обновить тип
  void updateType(EventIdeaType? type) {
    state = state.copyWith(type: type);
  }

  /// Обновить теги
  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags);
  }

  /// Добавить тег
  void addTag(String tag) {
    if (!state.tags.contains(tag)) {
      state = state.copyWith(tags: [...state.tags, tag]);
    }
  }

  /// Удалить тег
  void removeTag(String tag) {
    state = state.copyWith(tags: state.tags.where((t) => t != tag).toList());
  }

  /// Обновить поисковый запрос
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Обновить сортировку
  void updateSortBy(IdeasSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// Обновить бюджет
  void updateBudget(int? minBudget, int? maxBudget) {
    state = state.copyWith(minBudget: minBudget, maxBudget: maxBudget);
  }

  /// Обновить количество гостей
  void updateGuests(int? minGuests, int? maxGuests) {
    state = state.copyWith(minGuests: minGuests, maxGuests: maxGuests);
  }

  /// Сбросить фильтры
  void resetFilters() {
    state = const IdeasFilters();
  }

  /// Очистить поиск
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

/// Провайдер отфильтрованных идей
final filteredIdeasProvider = StreamProvider<List<EventIdea>>((ref) {
  final service = ref.watch(eventIdeasServiceProvider);
  final filters = ref.watch(ideasFiltersProvider);

  if (filters.searchQuery.isNotEmpty) {
    return service.searchIdeas(filters.searchQuery);
  }

  if (filters.type != null) {
    return service.getIdeasByType(filters.type!);
  }

  return service.getIdeas();
});

/// Провайдер избранных идей пользователя
final favoriteIdeasProvider = NotifierProvider<FavoriteIdeasNotifier, List<String>>(
  FavoriteIdeasNotifier.new,
);

/// Нотификатор избранных идей
class FavoriteIdeasNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Добавить в избранное
  void addToFavorites(String ideaId) {
    if (!state.contains(ideaId)) {
      state = [...state, ideaId];
    }
  }

  /// Удалить из избранного
  void removeFromFavorites(String ideaId) {
    state = state.where((id) => id != ideaId).toList();
  }

  /// Проверить, в избранном ли
  bool isFavorite(String ideaId) => state.contains(ideaId);

  /// Очистить избранное
  void clearFavorites() {
    state = [];
  }
}

/// Провайдер лайкнутых идей пользователя
final likedIdeasProvider = NotifierProvider<LikedIdeasNotifier, List<String>>(
  LikedIdeasNotifier.new,
);

/// Нотификатор лайкнутых идей
class LikedIdeasNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Добавить лайк
  void addLike(String ideaId) {
    if (!state.contains(ideaId)) {
      state = [...state, ideaId];
    }
  }

  /// Убрать лайк
  void removeLike(String ideaId) {
    state = state.where((id) => id != ideaId).toList();
  }

  /// Проверить, лайкнута ли
  bool isLiked(String ideaId) => state.contains(ideaId);

  /// Очистить лайки
  void clearLikes() {
    state = [];
  }
}
