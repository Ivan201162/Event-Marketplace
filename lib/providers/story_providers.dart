import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/story.dart';
import '../services/story_service.dart';

/// Провайдер сервиса сторис
final storyServiceProvider = Provider<StoryService>((ref) => StoryService());

/// Провайдер сторис пользователя
final userStoriesProvider = FutureProvider.family<List<Story>, String>((ref, userId) async {
  final storyService = ref.read(storyServiceProvider);
  return storyService.getUserStories(userId);
});

/// Провайдер всех активных сторис
final allStoriesProvider = FutureProvider<List<Story>>((ref) async {
  final storyService = ref.read(storyServiceProvider);
  return storyService.getAllActiveStories();
});

/// Провайдер сторис по ID
final storyByIdProvider = FutureProvider.family<Story?, String>((ref, storyId) async {
  final storyService = ref.read(storyServiceProvider);
  return await storyService.getStoryById(storyId);
});

/// Провайдер просмотров сторис
final storyViewsProvider = FutureProvider.family<List<StoryView>, String>((ref, storyId) async {
  final storyService = ref.read(storyServiceProvider);
  return await storyService.getStoryViews(storyId);
});

/// Провайдер для создания сторис
final createStoryProvider = FutureProvider.family<String, CreateStory>((ref, createStory) async {
  final storyService = ref.read(storyServiceProvider);
  return storyService.createStory(
    specialistId: createStory.specialistId,
    mediaUrl: createStory.mediaUrl,
    text: createStory.text,
    metadata: createStory.metadata,
  );
});

/// Провайдер для загрузки изображения сторис
final uploadStoryImageProvider =
    FutureProvider.family<String, UploadStoryImageParams>((ref, params) async {
  final storyService = ref.read(storyServiceProvider);
  return await storyService.uploadStoryImage(
    authorId: params.authorId,
    imageFile: params.imageFile as dynamic,
  );
});

/// Провайдер для загрузки видео сторис
final uploadStoryVideoProvider =
    FutureProvider.family<String, UploadStoryVideoParams>((ref, params) async {
  final storyService = ref.read(storyServiceProvider);
  return await storyService.uploadStoryVideo(
    authorId: params.authorId,
    videoFile: params.videoFile as dynamic,
  );
});

/// Параметры для загрузки изображения сторис
class UploadStoryImageParams {
  const UploadStoryImageParams({
    required this.authorId,
    required this.imageFile,
  });

  final String authorId;
  final dynamic imageFile; // XFile
}

/// Параметры для загрузки видео сторис
class UploadStoryVideoParams {
  const UploadStoryVideoParams({
    required this.authorId,
    required this.videoFile,
  });

  final String authorId;
  final dynamic videoFile; // XFile
}
