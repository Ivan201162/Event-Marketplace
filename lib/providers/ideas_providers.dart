import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/idea.dart';
import '../services/ideas_service.dart';

/// Провайдер сервиса идей
final ideasServiceProvider = Provider<IdeasService>((ref) {
  return IdeasService();
});

/// Провайдер списка идей
final ideasProvider = FutureProvider<List<Idea>>((ref) async {
  final ideasService = ref.read(ideasServiceProvider);
  return await ideasService.getIdeas();
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