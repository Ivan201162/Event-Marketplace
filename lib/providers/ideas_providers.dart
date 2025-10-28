import 'package:event_marketplace_app/models/idea.dart';
import 'package:event_marketplace_app/services/ideas_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса идей
final ideasServiceProvider = Provider<IdeasService>((ref) {
  return IdeasService();
});

/// Провайдер списка идей
final ideasProvider = FutureProvider<List<Idea>>((ref) async {
  final ideasService = ref.read(ideasServiceProvider);
  return ideasService.getIdeas();
});

/// Провайдер для создания идеи
final createIdeaProvider = FutureProvider.family<void, Idea>((ref, idea) async {
  final ideasService = ref.read(ideasServiceProvider);
  await ideasService.createIdea(idea);
});

/// Провайдер для обновления идеи
final updateIdeaProvider = FutureProvider.family<void, Idea>((ref, idea) async {
  final ideasService = ref.read(ideasServiceProvider);
  await ideasService.updateIdea(idea);
});
