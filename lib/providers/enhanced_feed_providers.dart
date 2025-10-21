import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_feed_post.dart';
import '../test_data/mock_data.dart';

/// Состояние ленты
class EnhancedFeedState {
  const EnhancedFeedState({this.posts = const [], this.isLoading = false, this.error});
  final List<EnhancedFeedPost> posts;
  final bool isLoading;
  final String? error;

  EnhancedFeedState copyWith({List<EnhancedFeedPost>? posts, bool? isLoading, String? error}) =>
      EnhancedFeedState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Провайдер ленты с тестовыми данными
class EnhancedFeedNotifier extends ChangeNotifier {
  EnhancedFeedNotifier() {
    loadFeed();
  }
  EnhancedFeedState _state = const EnhancedFeedState();

  EnhancedFeedState get state => _state;

  /// Загружает ленту
  Future<void> loadFeed() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Имитируем задержку сети
      await Future.delayed(const Duration(seconds: 1));

      // Загружаем тестовые данные
      final posts = MockData.feedPosts;
      _state = _state.copyWith(posts: posts, isLoading: false);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: 'Ошибка загрузки ленты: $e');
      notifyListeners();
    }
  }

  /// Обновляет ленту
  Future<void> refreshFeed() async {
    await loadFeed();
  }

  /// Переключает лайк поста
  void toggleLike(String postId) {
    final posts = _state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isLiked: !post.isLiked,
          likes: post.isLiked ? post.likes - 1 : post.likes + 1,
        );
      }
      return post;
    }).toList();

    _state = _state.copyWith(posts: posts);
    notifyListeners();
  }

  /// Переключает сохранение поста
  void toggleSave(String postId) {
    final posts = _state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(isSaved: !post.isSaved);
      }
      return post;
    }).toList();

    _state = _state.copyWith(posts: posts);
    notifyListeners();
  }

  /// Добавляет новый пост
  void addPost(EnhancedFeedPost post) {
    final posts = [post, ..._state.posts];
    _state = _state.copyWith(posts: posts);
    notifyListeners();
  }
}

/// Провайдер ленты
final enhancedFeedProvider = ChangeNotifierProvider<EnhancedFeedNotifier>(
  (ref) => EnhancedFeedNotifier(),
);
