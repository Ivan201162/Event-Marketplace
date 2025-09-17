import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_post.dart';
import '../services/feed_service.dart';

/// Провайдер сервиса ленты
final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService();
});

/// Провайдер для ленты новостей
final feedPostsProvider = StreamProvider<List<FeedPost>>((ref) {
  final feedService = ref.read(feedServiceProvider);
  return feedService.getFeedPosts();
});

/// Провайдер для комментариев поста
final postCommentsProvider = StreamProvider.family<List<FeedComment>, String>((ref, postId) {
  final feedService = ref.read(feedServiceProvider);
  return feedService.getPostComments(postId);
});

/// Провайдер для лайков поста
final postLikesProvider = StreamProvider.family<List<String>, String>((ref, postId) {
  final feedService = ref.read(feedServiceProvider);
  return feedService.getPostLikes(postId);
});

/// Провайдер для состояния ленты
final feedStateProvider = StateNotifierProvider<FeedStateNotifier, FeedState>((ref) {
  return FeedStateNotifier();
});

/// Состояние ленты
class FeedState {
  final List<FeedPost> posts;
  final bool isLoading;
  final String? error;
  final Map<String, bool> likedPosts;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.likedPosts = const {},
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoading,
    String? error,
    Map<String, bool>? likedPosts,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      likedPosts: likedPosts ?? this.likedPosts,
    );
  }
}

/// Нотификатор для состояния ленты
class FeedStateNotifier extends StateNotifier<FeedState> {
  FeedStateNotifier() : super(const FeedState());

  void setPosts(List<FeedPost> posts) {
    state = state.copyWith(posts: posts);
  }

  void addPost(FeedPost post) {
    final updatedPosts = [post, ...state.posts];
    state = state.copyWith(posts: updatedPosts);
  }

  void updatePost(FeedPost post) {
    final updatedPosts = state.posts.map((p) => p.id == post.id ? post : p).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  void removePost(String postId) {
    final updatedPosts = state.posts.where((p) => p.id != postId).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  void toggleLike(String postId, bool isLiked) {
    final updatedLikedPosts = Map<String, bool>.from(state.likedPosts);
    updatedLikedPosts[postId] = isLiked;
    state = state.copyWith(likedPosts: updatedLikedPosts);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}