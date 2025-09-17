import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:event_marketplace_app/models/feed_post.dart';
import 'package:event_marketplace_app/services/feed_service.dart';

part 'feed_providers.g.dart';

/// Провайдер для FeedService
@riverpod
FeedService feedService(FeedServiceRef ref) {
  return FeedService();
}

/// Провайдер для получения ленты новостей
@riverpod
Future<List<FeedPost>> feedPosts(FeedPostsRef ref) async {
  final service = ref.watch(feedServiceProvider);
  return service.getFeedPosts();
}

/// Провайдер для получения постов специалиста
@riverpod
Future<List<FeedPost>> specialistPosts(
    SpecialistPostsRef ref, String specialistId) async {
  final service = ref.watch(feedServiceProvider);
  return service.getSpecialistPosts(specialistId: specialistId);
}

/// Провайдер для получения комментариев к посту
@riverpod
Future<List<PostComment>> postComments(
    PostCommentsRef ref, String postId) async {
  final service = ref.watch(feedServiceProvider);
  return service.getPostComments(postId: postId);
}

/// Провайдер для статистики ленты специалиста
@riverpod
Future<FeedStatistics> specialistFeedStatistics(
    SpecialistFeedStatisticsRef ref, String specialistId) async {
  final service = ref.watch(feedServiceProvider);
  return service.getSpecialistFeedStatistics(specialistId);
}
