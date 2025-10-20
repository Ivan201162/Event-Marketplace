import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/idea.dart';
import '../services/idea_service.dart';

/// Idea service provider
final ideaServiceProvider = Provider<IdeaService>((ref) {
  return IdeaService();
});

/// All ideas provider
final ideasProvider = FutureProvider<List<Idea>>((ref) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getIdeas();
});

/// Popular ideas provider
final popularIdeasProvider = FutureProvider<List<Idea>>((ref) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getPopularIdeas();
});

/// Trending ideas provider
final trendingIdeasProvider = FutureProvider<List<Idea>>((ref) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getTrendingIdeas();
});

/// Ideas by category provider
final ideasByCategoryProvider = FutureProvider.family<List<Idea>, String>((ref, category) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getIdeasByCategory(category);
});

/// Ideas by tags provider
final ideasByTagsProvider = FutureProvider.family<List<Idea>, List<String>>((ref, tags) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getIdeasByTags(tags);
});

/// Ideas by difficulty provider
final ideasByDifficultyProvider =
    FutureProvider.family<List<Idea>, String>((ref, difficulty) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getIdeasByDifficulty(difficulty);
});

/// Idea by ID provider
final ideaByIdProvider = FutureProvider.family<Idea?, String>((ref, ideaId) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getIdeaById(ideaId);
});

/// Stream of ideas provider
final ideasStreamProvider = StreamProvider<List<Idea>>((ref) {
  final service = ref.read(ideaServiceProvider);
  return service.getIdeasStream();
});

/// Stream of ideas by category provider
final ideasByCategoryStreamProvider = StreamProvider.family<List<Idea>, String>((ref, category) {
  final service = ref.read(ideaServiceProvider);
  return service.getIdeasByCategoryStream(category);
});

/// Search ideas provider
final searchIdeasProvider = FutureProvider.family<List<Idea>, String>((ref, query) async {
  final service = ref.read(ideaServiceProvider);
  return await service.searchIdeas(query);
});

/// Available categories provider
final ideaCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getCategories();
});

/// Available tags provider
final ideaTagsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(ideaServiceProvider);
  return await service.getTags();
});
