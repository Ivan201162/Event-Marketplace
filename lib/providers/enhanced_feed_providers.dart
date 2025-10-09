import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/enhanced_feed_service.dart';
import '../models/enhanced_feed_post.dart';

/// Провайдер сервиса ленты
final enhancedFeedServiceProvider = Provider<EnhancedFeedService>((ref) {
  return EnhancedFeedService();
});

/// Провайдер ленты
final feedProvider = FutureProvider<List<EnhancedFeedPost>>((ref) async {
  final service = ref.read(enhancedFeedServiceProvider);
  return await service.getFeed();
});

/// Провайдер постов пользователя
final userPostsProvider = FutureProvider.family<List<EnhancedFeedPost>, String>((ref, userId) async {
  final service = ref.read(enhancedFeedServiceProvider);
  return await service.getUserPosts(userId: userId);
});

/// Провайдер поста по ID
final postProvider = FutureProvider.family<EnhancedFeedPost?, String>((ref, postId) async {
  final service = ref.read(enhancedFeedServiceProvider);
  return await service.getPostById(postId);
});

/// Провайдер комментариев поста
final postCommentsProvider = FutureProvider.family<List<FeedPostComment>, String>((ref, postId) async {
  final service = ref.read(enhancedFeedServiceProvider);
  return await service.getPostComments(postId: postId);
});

/// Провайдер сохранённых постов
final savedPostsProvider = FutureProvider.family<List<EnhancedFeedPost>, String>((ref, userId) async {
  final service = ref.read(enhancedFeedServiceProvider);
  return await service.getSavedPosts(userId: userId);
});

/// Провайдер поиска постов
final searchPostsProvider = FutureProvider.family<List<EnhancedFeedPost>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(enhancedFeedServiceProvider);
  return await service.searchPosts(
    query: params['query'] as String,
    tags: params['tags'] as List<String>?,
    location: params['location'] as String?,
    type: params['type'] as FeedPostType?,
  );
});

/// Провайдер состояния создания поста
final createPostStateProvider = StateNotifierProvider<CreatePostStateNotifier, CreatePostState>((ref) {
  return CreatePostStateNotifier(ref.read(enhancedFeedServiceProvider));
});

/// Состояние создания поста
class CreatePostState {
  const CreatePostState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  final bool isLoading;
  final String? error;
  final bool success;

  CreatePostState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return CreatePostState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }
}

/// Нотификатор состояния создания поста
class CreatePostStateNotifier extends StateNotifier<CreatePostState> {
  CreatePostStateNotifier(this._service) : super(const CreatePostState());

  final EnhancedFeedService _service;

  Future<void> createPost({
    required String authorId,
    required String content,
    required FeedPostType type,
    List<String>? tags,
    String? location,
    bool isSponsored = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);

    try {
      await _service.createPost(
        authorId: authorId,
        content: content,
        type: type,
        tags: tags,
        location: location,
        isSponsored: isSponsored,
      );

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const CreatePostState();
  }
}

/// Провайдер состояния лайков
final likeStateProvider = StateNotifierProvider.family<LikeStateNotifier, LikeState, String>((ref, postId) {
  return LikeStateNotifier(
    ref.read(enhancedFeedServiceProvider),
    postId,
  );
});

/// Состояние лайка
class LikeState {
  const LikeState({
    this.isLiked = false,
    this.likesCount = 0,
    this.isLoading = false,
  });

  final bool isLiked;
  final int likesCount;
  final bool isLoading;

  LikeState copyWith({
    bool? isLiked,
    int? likesCount,
    bool? isLoading,
  }) {
    return LikeState(
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Нотификатор состояния лайка
class LikeStateNotifier extends StateNotifier<LikeState> {
  LikeStateNotifier(this._service, this._postId) : super(const LikeState());

  final EnhancedFeedService _service;
  final String _postId;

  Future<void> toggleLike(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      if (state.isLiked) {
        await _service.unlikePost(_postId, userId);
        state = state.copyWith(
          isLiked: false,
          likesCount: state.likesCount - 1,
          isLoading: false,
        );
      } else {
        await _service.likePost(_postId, userId);
        state = state.copyWith(
          isLiked: true,
          likesCount: state.likesCount + 1,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // TODO: Показать ошибку
    }
  }

  void setInitialState(bool isLiked, int likesCount) {
    state = state.copyWith(
      isLiked: isLiked,
      likesCount: likesCount,
    );
  }
}

/// Провайдер состояния сохранения поста
final saveStateProvider = StateNotifierProvider.family<SaveStateNotifier, SaveState, String>((ref, postId) {
  return SaveStateNotifier(
    ref.read(enhancedFeedServiceProvider),
    postId,
  );
});

/// Состояние сохранения
class SaveState {
  const SaveState({
    this.isSaved = false,
    this.savesCount = 0,
    this.isLoading = false,
  });

  final bool isSaved;
  final int savesCount;
  final bool isLoading;

  SaveState copyWith({
    bool? isSaved,
    int? savesCount,
    bool? isLoading,
  }) {
    return SaveState(
      isSaved: isSaved ?? this.isSaved,
      savesCount: savesCount ?? this.savesCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Нотификатор состояния сохранения
class SaveStateNotifier extends StateNotifier<SaveState> {
  SaveStateNotifier(this._service, this._postId) : super(const SaveState());

  final EnhancedFeedService _service;
  final String _postId;

  Future<void> toggleSave(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      if (state.isSaved) {
        await _service.unsavePost(_postId, userId);
        state = state.copyWith(
          isSaved: false,
          savesCount: state.savesCount - 1,
          isLoading: false,
        );
      } else {
        await _service.savePost(_postId, userId);
        state = state.copyWith(
          isSaved: true,
          savesCount: state.savesCount + 1,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // TODO: Показать ошибку
    }
  }

  void setInitialState(bool isSaved, int savesCount) {
    state = state.copyWith(
      isSaved: isSaved,
      savesCount: savesCount,
    );
  }
}

