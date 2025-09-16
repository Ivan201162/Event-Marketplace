import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';

/// Провайдер сервиса идей
final ideaServiceProvider = Provider<IdeaService>((ref) => IdeaService());

/// Провайдер для получения идей с фильтром
final ideasProvider =
    StreamProvider.family<List<Idea>, IdeaFilter>((ref, filter) {
  return ref.watch(ideaServiceProvider).getIdeas(filter);
});

/// Провайдер для получения идеи по ID
final ideaProvider = FutureProvider.family<Idea?, String>((ref, ideaId) {
  return ref.watch(ideaServiceProvider).getIdea(ideaId);
});

/// Провайдер для получения идей пользователя
final userIdeasProvider =
    StreamProvider.family<List<Idea>, String>((ref, userId) {
  return ref.watch(ideaServiceProvider).getUserIdeas(userId);
});

/// Провайдер для получения сохраненных идей пользователя
final savedIdeasProvider =
    StreamProvider.family<List<Idea>, String>((ref, userId) {
  return ref.watch(ideaServiceProvider).getSavedIdeas(userId);
});

/// Провайдер для получения топ идей недели
final topIdeasProvider = StreamProvider<List<Idea>>((ref) {
  return ref.watch(ideaServiceProvider).getTopIdeasOfWeek();
});

/// Провайдер для получения комментариев идеи
final ideaCommentsProvider =
    StreamProvider.family<List<IdeaComment>, String>((ref, ideaId) {
  return ref.watch(ideaServiceProvider).getIdeaComments(ideaId);
});

/// Провайдер для получения коллекций пользователя
final userCollectionsProvider =
    StreamProvider.family<List<IdeaCollection>, String>((ref, userId) {
  return ref.watch(ideaServiceProvider).getUserCollections(userId);
});

/// Провайдер для получения статистики идей
final ideaStatsProvider = FutureProvider<IdeaStats>((ref) {
  return ref.watch(ideaServiceProvider).getIdeaStats();
});
