import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ideas_service.dart';
import '../models/event_idea.dart';

/// Провайдер сервиса идей
final ideasServiceProvider = Provider<IdeasService>((ref) {
  return IdeasService();
});

/// Провайдер для получения публичных идей
final publicIdeasProvider = FutureProvider<List<EventIdea>>((ref) {
  final ideasService = ref.watch(ideasServiceProvider);
  return ideasService.getPublicIdeas();
});

/// Провайдер для получения идей по автору
final ideasByAuthorProvider =
    FutureProvider.family<List<EventIdea>, String>((ref, authorId) {
  final ideasService = ref.watch(ideasServiceProvider);
  return ideasService.getIdeasByAuthor(authorId);
});

/// Провайдер для получения сохраненных идей пользователя
final savedIdeasProvider =
    FutureProvider.family<List<EventIdea>, String>((ref, userId) {
  final ideasService = ref.watch(ideasServiceProvider);
  return ideasService.getSavedIdeas(userId);
});

/// Провайдер для получения популярных идей
final popularIdeasProvider = FutureProvider<List<EventIdea>>((ref) {
  final ideasService = ref.watch(ideasServiceProvider);
  return ideasService.getPopularIdeas();
});

/// Провайдер для получения последних идей
final recentIdeasProvider = FutureProvider<List<EventIdea>>((ref) {
  final ideasService = ref.watch(ideasServiceProvider);
  return ideasService.getRecentIdeas();
});

/// Провайдер для проверки лайка идеи
final isIdeaLikedProvider =
    FutureProvider.family<bool, IdeaLikeParams>((ref, params) {
  final ideasService = ref.watch(ideasServiceProvider);
  return ideasService.isIdeaLiked(params.ideaId, params.userId);
});

/// Провайдер для проверки сохранения идеи
final isIdeaSavedProvider =
    FutureProvider.family<bool, IdeaSaveParams>((ref, params) {
  final ideasService = ref.watch(ideasServiceProvider);
  return ideasService.isIdeaSaved(params.ideaId, params.userId);
});

/// Параметры для проверки лайка
class IdeaLikeParams {
  final String ideaId;
  final String userId;

  IdeaLikeParams({
    required this.ideaId,
    required this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdeaLikeParams &&
        other.ideaId == ideaId &&
        other.userId == userId;
  }

  @override
  int get hashCode => ideaId.hashCode ^ userId.hashCode;
}

/// Параметры для проверки сохранения
class IdeaSaveParams {
  final String ideaId;
  final String userId;

  IdeaSaveParams({
    required this.ideaId,
    required this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdeaSaveParams &&
        other.ideaId == ideaId &&
        other.userId == userId;
  }

  @override
  int get hashCode => ideaId.hashCode ^ userId.hashCode;
}
