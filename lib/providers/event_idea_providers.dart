import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_idea.dart';
import '../services/event_idea_service.dart';

/// Провайдер сервиса идей мероприятий
final eventIdeaServiceProvider =
    Provider<EventIdeaService>((ref) => EventIdeaService());

/// Провайдер всех идей мероприятий
final allEventIdeasProvider =
    FutureProvider.family<List<EventIdea>, EventIdeasParams>((
  ref,
  params,
) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.getAllIdeas(
    limit: params.limit,
    category: params.category,
    tags: params.tags,
    searchQuery: params.searchQuery,
  );
});

/// Провайдер идей пользователя
final userEventIdeasProvider =
    FutureProvider.family<List<EventIdea>, String>((ref, userId) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.getUserIdeas(userId);
});

/// Провайдер идеи по ID
final eventIdeaByIdProvider =
    FutureProvider.family<EventIdea?, String>((ref, ideaId) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.getIdeaById(ideaId);
});

/// Провайдер комментариев к идее
final ideaCommentsProvider =
    FutureProvider.family<List<IdeaComment>, String>((ref, ideaId) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.getIdeaComments(ideaId);
});

/// Провайдер популярных тегов
final popularTagsProvider = FutureProvider<List<String>>((ref) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.getPopularTags();
});

/// Провайдер для создания идеи
final createEventIdeaProvider = FutureProvider.family<String, CreateEventIdea>((
  ref,
  createIdea,
) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.createIdea(createIdea);
});

/// Провайдер для загрузки изображений идеи
final uploadIdeaImagesProvider =
    FutureProvider.family<List<String>, UploadIdeaImagesParams>((
  ref,
  params,
) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.uploadIdeaImages(
      authorId: params.authorId, imageFiles: params.imageFiles);
});

/// Провайдер для лайка идеи
final likeIdeaProvider =
    FutureProvider.family<void, String>((ref, ideaId) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.likeIdea(ideaId);
});

/// Провайдер для удаления лайка идеи
final unlikeIdeaProvider =
    FutureProvider.family<void, String>((ref, ideaId) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.unlikeIdea(ideaId);
});

/// Провайдер для добавления комментария
final addCommentProvider =
    FutureProvider.family<String, AddCommentParams>((ref, params) async {
  final ideaService = ref.read(eventIdeaServiceProvider);
  return ideaService.addComment(
    ideaId: params.ideaId,
    authorId: params.authorId,
    text: params.text,
    authorName: params.authorName,
    authorAvatar: params.authorAvatar,
    parentId: params.parentId,
  );
});

/// Параметры для получения идей
class EventIdeasParams {
  const EventIdeasParams(
      {this.limit = 20, this.category, this.tags, this.searchQuery});

  final int limit;
  final String? category;
  final List<String>? tags;
  final String? searchQuery;
}

/// Параметры для загрузки изображений идеи
class UploadIdeaImagesParams {
  const UploadIdeaImagesParams(
      {required this.authorId, required this.imageFiles});

  final String authorId;
  final List<dynamic> imageFiles; // List<XFile>
}

/// Параметры для добавления комментария
class AddCommentParams {
  const AddCommentParams({
    required this.ideaId,
    required this.authorId,
    required this.text,
    this.authorName,
    this.authorAvatar,
    this.parentId,
  });

  final String ideaId;
  final String authorId;
  final String text;
  final String? authorName;
  final String? authorAvatar;
  final String? parentId;
}
