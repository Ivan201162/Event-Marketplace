import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_feed_post.dart';
import '../test_data/mock_data.dart';

/// Состояние ленты
class EnhancedFeedState {
  const EnhancedFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });
  final List<EnhancedFeedPost> posts;
  final bool isLoading;
  final String? error;

  EnhancedFeedState copyWith({
    List<EnhancedFeedPost>? posts,
    bool? isLoading,
    String? error,
  }) =>
      EnhancedFeedState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Провайдер ленты с тестовыми данными
class EnhancedFeedNotifier extends Notifier<EnhancedFeedState> {
  @override
  EnhancedFeedState build() {
    loadFeed();
    return const EnhancedFeedState();
  }

  /// Загружает ленту
  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true);

    try {
      // Имитируем задержку сети
      await Future.delayed(const Duration(seconds: 1));

      // Загружаем тестовые данные
      final posts = MockData.feedPosts;
      state = state.copyWith(
        posts: posts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки ленты: $e',
      );
    }
  }

  /// Обновляет ленту
  Future<void> refreshFeed() async {
    await loadFeed();
  }

  /// Переключает лайк поста
  void toggleLike(String postId) {
    final posts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          likes: post.likedBy.contains('current_user') 
            ? post.likedBy.where((id) => id != 'current_user').toList()
            : [...post.likedBy, 'current_user'],
        );
      }
      return post;
    }).toList();

    state = state.copyWith(posts: posts);
  }

  /// Переключает сохранение поста
  void toggleSave(String postId) {
    final posts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          savedBy: post.savedBy.contains('current_user')
            ? post.savedBy.where((id) => id != 'current_user').toList()
            : [...post.savedBy, 'current_user'],
        );
      }
      return post;
    }).toList();

    state = state.copyWith(posts: posts);
  }

  /// Добавляет новый пост
  void addPost(EnhancedFeedPost post) {
    final posts = [post, ...state.posts];
    state = state.copyWith(posts: posts);
  }
}

/// Провайдер ленты
final enhancedFeedProvider =
    NotifierProvider<EnhancedFeedNotifier, EnhancedFeedState>(() => EnhancedFeedNotifier());
