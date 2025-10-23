import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story.dart';
import '../services/story_service.dart';

/// Провайдер сервиса сторис
final storyServiceProvider = Provider<StoryService>((ref) => StoryService());

/// Провайдер сторис пользователя
final userStoriesProvider =
    FutureProvider.family<List<Story>, String>((ref, userId) async {
  final storyService = ref.read(storyServiceProvider);
  return storyService.getUserStories(userId);
});

/// Провайдер всех активных сторис
final allStoriesProvider = FutureProvider<List<Story>>((ref) async {
  final storyService = ref.read(storyServiceProvider);
  return storyService.getAllActiveStories();
});

/// Провайдер сторис по ID (используем getStoriesBySpecialist)
final storyByIdProvider =
    FutureProvider.family<Story?, String>((ref, storyId) async {
  final storyService = ref.read(storyServiceProvider);
  final stories = await storyService.getStoriesBySpecialist(storyId);
  return stories.isNotEmpty ? stories.first : null;
});

/// Провайдер для создания сторис
final createStoryProvider =
    FutureProvider.family<String, Story>((ref, story) async {
  final storyService = ref.read(storyServiceProvider);
  return await storyService.createStory(story);
});

// Провайдеры для загрузки медиа удалены, так как соответствующие методы отсутствуют в StoryService

// Неиспользуемые классы параметров удалены
