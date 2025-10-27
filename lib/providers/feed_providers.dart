import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';
import '../models/story.dart';
import '../services/feed_service.dart';

/// Провайдер сервиса ленты
final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService();
});

/// Провайдер состояния ленты
final feedProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>((ref) {
  return FeedNotifier(ref.read(feedServiceProvider));
});

/// Провайдер Stories
final storiesProvider = FutureProvider<List<Story>>((ref) async {
  final feedService = ref.read(feedServiceProvider);
  return await feedService.getStories();
});

/// Notifier для управления состоянием ленты
class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final FeedService _feedService;

  FeedNotifier(this._feedService) : super(const AsyncValue.loading()) {
    _loadInitialPosts();
  }

  Future<void> _loadInitialPosts() async {
    try {
      state = const AsyncValue.loading();
      final posts = await _feedService.getPosts();
      state = AsyncValue.data(posts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshFeed() async {
    await _loadInitialPosts();
  }

  Future<void> loadMorePosts() async {
    if (state.hasValue) {
      try {
        final currentPosts = state.value!;
        final newPosts = await _feedService.getMorePosts(currentPosts.length);
        state = AsyncValue.data([...currentPosts, ...newPosts]);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> searchPosts(String query) async {
    try {
      state = const AsyncValue.loading();
      final posts = await _feedService.searchPosts(query);
      state = AsyncValue.data(posts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterPosts(String filter) async {
    try {
      state = const AsyncValue.loading();
      final posts = await _feedService.filterPosts(filter);
      state = AsyncValue.data(posts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> likePost(String postId) async {
    try {
      await _feedService.likePost(postId);
      // Обновить состояние поста
      if (state.hasValue) {
        final posts = state.value!;
        final updatedPosts = posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              likesCount: post.likesCount + 1,
              isLiked: true,
            );
          }
          return post;
        }).toList();
        state = AsyncValue.data(updatedPosts);
      }
    } catch (error) {
      // Обработка ошибки лайка
    }
  }

  Future<void> sharePost(String postId) async {
    try {
      await _feedService.sharePost(postId);
    } catch (error) {
      // Обработка ошибки шаринга
    }
  }

  Future<void> savePost(String postId) async {
    try {
      await _feedService.savePost(postId);
    } catch (error) {
      // Обработка ошибки сохранения
    }
  }
}
