import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_comment.dart';
import '../models/post.dart';
import '../services/feed_service.dart';

/// Feed service provider
final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService();
});

/// Posts stream provider
final postsStreamProvider = StreamProvider<List<Post>>((ref) {
  final feedService = ref.watch(feedServiceProvider);
  return feedService.getPostsStream();
});

/// Post comments provider
final postCommentsProvider =
    StreamProvider.family<List<FeedComment>, String>((ref, postId) {
  final feedService = ref.watch(feedServiceProvider);
  return feedService.getPostComments(postId);
});
