import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/idea.dart';
import '../services/ideas_service.dart';

/// Провайдер сервиса идей
final ideasServiceProvider = Provider<IdeasService>((ref) {
  return IdeasService();
});

/// Провайдер состояния идей
final ideasProvider = StateNotifierProvider<IdeasNotifier, AsyncValue<List<Idea>>>((ref) {
  return IdeasNotifier(ref.read(ideasServiceProvider));
});

/// Notifier для управления состоянием идей
class IdeasNotifier extends StateNotifier<AsyncValue<List<Idea>>> {
  final IdeasService _ideasService;

  IdeasNotifier(this._ideasService) : super(const AsyncValue.loading()) {
    _loadInitialIdeas();
  }

  Future<void> _loadInitialIdeas() async {
    try {
      state = const AsyncValue.loading();
      final ideas = await _ideasService.getIdeas();
      state = AsyncValue.data(ideas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshIdeas() async {
    await _loadInitialIdeas();
  }

  Future<void> loadMoreIdeas() async {
    if (state.hasValue) {
      try {
        final currentIdeas = state.value!;
        final newIdeas = await _ideasService.getMoreIdeas(currentIdeas.length);
        state = AsyncValue.data([...currentIdeas, ...newIdeas]);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> searchIdeas(String query) async {
    try {
      state = const AsyncValue.loading();
      final ideas = await _ideasService.searchIdeas(query);
      state = AsyncValue.data(ideas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterIdeas(String filter) async {
    try {
      state = const AsyncValue.loading();
      final ideas = await _ideasService.filterIdeas(filter);
      state = AsyncValue.data(ideas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createIdea(Idea idea) async {
    try {
      await _ideasService.createIdea(idea);
      await refreshIdeas();
    } catch (error) {
      // Обработка ошибки создания идеи
      rethrow;
    }
  }

  Future<void> likeIdea(String ideaId) async {
    try {
      await _ideasService.likeIdea(ideaId);
      // Обновить состояние идеи
      if (state.hasValue) {
        final ideas = state.value!;
        final updatedIdeas = ideas.map((idea) {
          if (idea.id == ideaId) {
            return idea.copyWith(
              likesCount: idea.likesCount + 1,
              isLiked: true,
            );
          }
          return idea;
        }).toList();
        state = AsyncValue.data(updatedIdeas);
      }
    } catch (error) {
      // Обработка ошибки лайка
    }
  }

  Future<void> saveIdea(String ideaId) async {
    try {
      await _ideasService.saveIdea(ideaId);
    } catch (error) {
      // Обработка ошибки сохранения
    }
  }

  Future<void> shareIdea(String ideaId) async {
    try {
      await _ideasService.shareIdea(ideaId);
    } catch (error) {
      // Обработка ошибки шаринга
    }
  }

  Future<void> deleteIdea(String ideaId) async {
    try {
      await _ideasService.deleteIdea(ideaId);
      await refreshIdeas();
    } catch (error) {
      // Обработка ошибки удаления идеи
      rethrow;
    }
  }
}