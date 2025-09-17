import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/services/story_service.dart';

part 'story_providers.g.dart';

/// Провайдер для StoryService
@riverpod
StoryService storyService(StoryServiceRef ref) {
  return StoryService();
}

/// Провайдер для получения сторисов специалиста
@riverpod
Future<List<Story>> specialistStories(
    SpecialistStoriesRef ref, String specialistId) async {
  final service = ref.watch(storyServiceProvider);
  return service.getSpecialistStories(specialistId);
}

/// Провайдер для получения всех активных сторисов
@riverpod
Future<List<Story>> allActiveStories(AllActiveStoriesRef ref) async {
  final service = ref.watch(storyServiceProvider);
  return service.getAllActiveStories();
}

/// Провайдер для статистики сторисов специалиста
@riverpod
Future<StoryStatistics> specialistStoryStatistics(
    SpecialistStoryStatisticsRef ref, String specialistId) async {
  final service = ref.watch(storyServiceProvider);
  return service.getSpecialistStoryStatistics(specialistId);
}
