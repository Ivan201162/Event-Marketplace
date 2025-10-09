import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_idea.dart';
import '../services/enhanced_ideas_service.dart';

/// Провайдер сервиса идей
final enhancedIdeasServiceProvider =
    Provider<EnhancedIdeasService>((ref) => EnhancedIdeasService());

/// Провайдер всех идей
final ideasProvider = FutureProvider<List<EnhancedIdea>>((ref) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getIdeas();
});

/// Провайдер идей по типу
final ideasByTypeProvider =
    FutureProvider.family<List<EnhancedIdea>, IdeaType>((ref, type) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getIdeas(type: type);
});

/// Провайдер идей пользователя
final userIdeasProvider =
    FutureProvider.family<List<EnhancedIdea>, String>((ref, userId) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getUserIdeas(userId: userId);
});

/// Провайдер идеи по ID
final ideaProvider =
    FutureProvider.family<EnhancedIdea?, String>((ref, ideaId) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getIdeaById(ideaId);
});

/// Провайдер комментариев идеи
final ideaCommentsProvider =
    FutureProvider.family<List<IdeaComment>, String>((ref, ideaId) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getIdeaComments(ideaId: ideaId);
});

/// Провайдер сохранённых идей
final savedIdeasProvider =
    FutureProvider.family<List<EnhancedIdea>, String>((ref, userId) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getSavedIdeas(userId: userId);
});

/// Провайдер поиска идей
final searchIdeasProvider =
    FutureProvider.family<List<EnhancedIdea>, Map<String, dynamic>>(
        (ref, params) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.searchIdeas(
    query: params['query'] as String,
    tags: params['tags'] as List<String>?,
    category: params['category'] as String?,
    type: params['type'] as IdeaType?,
    minBudget: params['minBudget'] as double?,
    maxBudget: params['maxBudget'] as double?,
    location: params['location'] as String?,
  );
});

/// Провайдер популярных идей
final popularIdeasProvider =
    FutureProvider.family<List<EnhancedIdea>, IdeaType?>((ref, type) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getPopularIdeas(type: type);
});

/// Провайдер коллекций пользователя
final userCollectionsProvider =
    FutureProvider.family<List<IdeaCollection>, String>((ref, userId) async {
  final service = ref.read(enhancedIdeasServiceProvider);
  return service.getUserCollections(userId: userId);
});

/// Провайдер состояния создания идеи
final createIdeaStateProvider =
    StateNotifierProvider<CreateIdeaStateNotifier, CreateIdeaState>((ref) =>
        CreateIdeaStateNotifier(ref.read(enhancedIdeasServiceProvider)));

/// Состояние создания идеи
class CreateIdeaState {
  const CreateIdeaState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  final bool isLoading;
  final String? error;
  final bool success;

  CreateIdeaState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) =>
      CreateIdeaState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        success: success ?? this.success,
      );
}

/// Нотификатор состояния создания идеи
class CreateIdeaStateNotifier extends StateNotifier<CreateIdeaState> {
  CreateIdeaStateNotifier(this._service) : super(const CreateIdeaState());

  final EnhancedIdeasService _service;

  Future<void> createIdea({
    required String authorId,
    required String title,
    required String description,
    required IdeaType type,
    List<String>? tags,
    String? category,
    double? budget,
    String? timeline,
    String? location,
    bool isPublic = true,
  }) async {
    state = state.copyWith(isLoading: true, success: false);

    try {
      await _service.createIdea(
        authorId: authorId,
        title: title,
        description: description,
        type: type,
        tags: tags,
        category: category,
        budget: budget,
        timeline: timeline,
        location: location,
        isPublic: isPublic,
      );

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const CreateIdeaState();
  }
}

/// Провайдер состояния лайков идеи
final ideaLikeStateProvider =
    StateNotifierProvider.family<IdeaLikeStateNotifier, IdeaLikeState, String>(
  (ref, ideaId) => IdeaLikeStateNotifier(
    ref.read(enhancedIdeasServiceProvider),
    ideaId,
  ),
);

/// Состояние лайка идеи
class IdeaLikeState {
  const IdeaLikeState({
    this.isLiked = false,
    this.likesCount = 0,
    this.isLoading = false,
  });

  final bool isLiked;
  final int likesCount;
  final bool isLoading;

  IdeaLikeState copyWith({
    bool? isLiked,
    int? likesCount,
    bool? isLoading,
  }) =>
      IdeaLikeState(
        isLiked: isLiked ?? this.isLiked,
        likesCount: likesCount ?? this.likesCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Нотификатор состояния лайка идеи
class IdeaLikeStateNotifier extends StateNotifier<IdeaLikeState> {
  IdeaLikeStateNotifier(this._service, this._ideaId)
      : super(const IdeaLikeState());

  final EnhancedIdeasService _service;
  final String _ideaId;

  Future<void> toggleLike(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      if (state.isLiked) {
        await _service.unlikeIdea(_ideaId, userId);
        state = state.copyWith(
          isLiked: false,
          likesCount: state.likesCount - 1,
          isLoading: false,
        );
      } else {
        await _service.likeIdea(_ideaId, userId);
        state = state.copyWith(
          isLiked: true,
          likesCount: state.likesCount + 1,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // TODO: Показать ошибку
    }
  }

  void setInitialState(bool isLiked, int likesCount) {
    state = state.copyWith(
      isLiked: isLiked,
      likesCount: likesCount,
    );
  }
}

/// Провайдер состояния сохранения идеи
final ideaSaveStateProvider =
    StateNotifierProvider.family<IdeaSaveStateNotifier, IdeaSaveState, String>(
  (ref, ideaId) => IdeaSaveStateNotifier(
    ref.read(enhancedIdeasServiceProvider),
    ideaId,
  ),
);

/// Состояние сохранения идеи
class IdeaSaveState {
  const IdeaSaveState({
    this.isSaved = false,
    this.savesCount = 0,
    this.isLoading = false,
  });

  final bool isSaved;
  final int savesCount;
  final bool isLoading;

  IdeaSaveState copyWith({
    bool? isSaved,
    int? savesCount,
    bool? isLoading,
  }) =>
      IdeaSaveState(
        isSaved: isSaved ?? this.isSaved,
        savesCount: savesCount ?? this.savesCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Нотификатор состояния сохранения идеи
class IdeaSaveStateNotifier extends StateNotifier<IdeaSaveState> {
  IdeaSaveStateNotifier(this._service, this._ideaId)
      : super(const IdeaSaveState());

  final EnhancedIdeasService _service;
  final String _ideaId;

  Future<void> toggleSave(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      if (state.isSaved) {
        await _service.unsaveIdea(_ideaId, userId);
        state = state.copyWith(
          isSaved: false,
          savesCount: state.savesCount - 1,
          isLoading: false,
        );
      } else {
        await _service.saveIdea(_ideaId, userId);
        state = state.copyWith(
          isSaved: true,
          savesCount: state.savesCount + 1,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // TODO: Показать ошибку
    }
  }

  void setInitialState(bool isSaved, int savesCount) {
    state = state.copyWith(
      isSaved: isSaved,
      savesCount: savesCount,
    );
  }
}
