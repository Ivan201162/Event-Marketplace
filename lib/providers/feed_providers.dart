import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../services/post_service.dart';

/// Post service provider
final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});

/// All posts provider
final postsProvider = FutureProvider<List<Post>>((ref) async {
  final service = ref.read(postServiceProvider);
  return await service.getPosts();
});

/// Popular posts provider
final popularPostsProvider = FutureProvider<List<Post>>((ref) async {
  final service = ref.read(postServiceProvider);
  return await service.getPopularPosts();
});

/// Trending posts provider
final trendingPostsProvider = FutureProvider<List<Post>>((ref) async {
  final service = ref.read(postServiceProvider);
  return await service.getTrendingPosts();
});

/// Posts by user provider
final postsByUserProvider =
    FutureProvider.family<List<Post>, String>((ref, userId) async {
  final service = ref.read(postServiceProvider);
  return await service.getPostsByUser(userId);
});

/// Posts by tags provider
final postsByTagsProvider =
    FutureProvider.family<List<Post>, List<String>>((ref, tags) async {
  final service = ref.read(postServiceProvider);
  return await service.getPostsByTags(tags);
});

/// Post by ID provider
final postByIdProvider =
    FutureProvider.family<Post?, String>((ref, postId) async {
  final service = ref.read(postServiceProvider);
  return await service.getPostById(postId);
});

/// Stream of posts provider
final postsStreamProvider = StreamProvider<List<Post>>((ref) {
  final service = ref.read(postServiceProvider);
  return service.getPostsStream();
});

/// Stream of posts by user provider
final postsByUserStreamProvider =
    StreamProvider.family<List<Post>, String>((ref, userId) {
  final service = ref.read(postServiceProvider);
  return service.getPostsByUserStream(userId);
});

/// Search posts provider
final searchPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, query) async {
  final service = ref.read(postServiceProvider);
  return await service.searchPosts(query);
});
