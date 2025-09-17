import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story.dart';
import '../services/story_service.dart';

/// Провайдер сервиса историй
final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService();
});

/// Провайдер для историй специалиста
final specialistStoriesProvider = StreamProvider.family<List<Story>, String>((ref, specialistId) {
  final storyService = ref.read(storyServiceProvider);
  return storyService.getSpecialistStories(specialistId);
});

/// Провайдер для всех историй
final allStoriesProvider = StreamProvider<List<Story>>((ref) {
  final storyService = ref.read(storyServiceProvider);
  return storyService.getAllStories();
});

/// Провайдер для состояния историй
final storyStateProvider = StateNotifierProvider<StoryStateNotifier, StoryState>((ref) {
  return StoryStateNotifier();
});

/// Состояние историй
class StoryState {
  final List<Story> stories;
  final bool isLoading;
  final String? error;
  final Map<String, bool> viewedStories;

  const StoryState({
    this.stories = const [],
    this.isLoading = false,
    this.error,
    this.viewedStories = const {},
  });

  StoryState copyWith({
    List<Story>? stories,
    bool? isLoading,
    String? error,
    Map<String, bool>? viewedStories,
  }) {
    return StoryState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      viewedStories: viewedStories ?? this.viewedStories,
    );
  }
}

/// Нотификатор для состояния историй
class StoryStateNotifier extends StateNotifier<StoryState> {
  StoryStateNotifier() : super(const StoryState());

  void setStories(List<Story> stories) {
    state = state.copyWith(stories: stories);
  }

  void addStory(Story story) {
    final updatedStories = [story, ...state.stories];
    state = state.copyWith(stories: updatedStories);
  }

  void removeStory(String storyId) {
    final updatedStories = state.stories.where((s) => s.id != storyId).toList();
    state = state.copyWith(stories: updatedStories);
  }

  void markAsViewed(String storyId) {
    final updatedViewedStories = Map<String, bool>.from(state.viewedStories);
    updatedViewedStories[storyId] = true;
    state = state.copyWith(viewedStories: updatedViewedStories);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}