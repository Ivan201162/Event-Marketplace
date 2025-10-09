import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_providers.dart';
import '../data/feed_model.dart';
import '../data/feed_service.dart';
import '../data/subscription_service.dart';

/// Провайдер сервиса ленты
final feedServiceProvider = Provider<FeedService>((ref) => FeedService());

/// Провайдер сервиса подписок
final subscriptionServiceProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService());

/// Провайдер текущего фильтра ленты
final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.all);

/// Провайдер выбранной категории для фильтрации
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Провайдер постов ленты с фильтрацией
final feedPostsProvider = StreamProvider<List<FeedPost>>((ref) {
  final feedService = ref.watch(feedServiceProvider);
  final filter = ref.watch(feedFilterProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  return currentUser.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }

      // Получаем подписки пользователя
      final followedIdsAsync = ref.watch(subscriptionProvider);

      // Используем дефолтный город
      const userCity = 'Москва';

      return followedIdsAsync.when(
        data: (followedIds) => feedService.getFilteredPosts(
          city: userCity,
          followedIds: followedIds,
          filter: filter,
          category: selectedCategory,
        ),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Провайдер постов пользователя
final userPostsProvider =
    StreamProvider.family<List<FeedPost>, String>((ref, userId) {
  final feedService = ref.watch(feedServiceProvider);
  return feedService.getUserPosts(userId);
});

/// Провайдер состояния загрузки
final feedLoadingProvider = StateProvider<bool>((ref) => false);

/// Провайдер ошибок ленты
final feedErrorProvider = StateProvider<String?>((ref) => null);

/// Провайдер для управления лайками
final likePostProvider =
    FutureProvider.family<void, String>((ref, postId) async {
  final feedService = ref.watch(feedServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  final user = currentUser.value;
  if (user == null) {
    throw Exception('Пользователь не авторизован');
  }

  try {
    await feedService.likePost(postId, user.id);
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для добавления комментариев
final addCommentProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final feedService = ref.watch(feedServiceProvider);
  final postId = params['postId'] as String;
  final comment = params['comment'] as FeedComment;

  try {
    await feedService.addComment(postId, comment);
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для создания постов
final createPostProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final feedService = ref.watch(feedServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  final user = currentUser.value;
  if (user == null) {
    throw Exception('Пользователь не авторизован');
  }

  try {
    await feedService.createPostWithMedia(
      userId: user.id,
      userName: user.displayName ?? 'Пользователь',
      userCity: 'Москва',
      userAvatar: user.photoUrl ?? '',
      description: params['description'] as String,
      taggedCategories: params['taggedCategories'] as List<String>,
      type: params['type'] as PostType,
      mediaFile: params['mediaFile'] as File?,
    );
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для удаления постов
final deletePostProvider =
    FutureProvider.family<void, String>((ref, postId) async {
  final feedService = ref.watch(feedServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  final user = currentUser.value;
  if (user == null) {
    throw Exception('Пользователь не авторизован');
  }

  try {
    await feedService.deletePost(postId, user.id);
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для выбора изображения
final pickImageProvider = FutureProvider<File?>((ref) async {
  final feedService = ref.watch(feedServiceProvider);
  try {
    return await feedService.pickImage();
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для выбора видео
final pickVideoProvider = FutureProvider<File?>((ref) async {
  final feedService = ref.watch(feedServiceProvider);
  try {
    return await feedService.pickVideo();
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для загрузки медиа
final uploadMediaProvider =
    FutureProvider.family<String, Map<String, dynamic>>((ref, params) async {
  final feedService = ref.watch(feedServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  final file = params['file'] as File;
  final type = params['type'] as PostType;

  final user = currentUser.value;
  if (user == null) {
    throw Exception('Пользователь не авторизован');
  }

  try {
    return await feedService.uploadMedia(file, user.id, type);
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для управления подписками
final subscriptionProvider = StreamProvider<List<String>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  return currentUser.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }
      return subscriptionService.getUserFollowingStream(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Провайдер для подписки/отписки
final followUserProvider =
    FutureProvider.family<void, String>((ref, targetUserId) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  final user = currentUser.value;
  if (user == null) {
    throw Exception('Пользователь не авторизован');
  }

  try {
    await subscriptionService.followUser(user.id, targetUserId);
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для отписки
final unfollowUserProvider =
    FutureProvider.family<void, String>((ref, targetUserId) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  final user = currentUser.value;
  if (user == null) {
    throw Exception('Пользователь не авторизован');
  }

  try {
    await subscriptionService.unfollowUser(user.id, targetUserId);
  } catch (e) {
    ref.read(feedErrorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Провайдер для проверки подписки
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetUserId) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  final user = currentUser.value;
  if (user == null) {
    return false;
  }

  try {
    return await subscriptionService.isFollowing(user.id, targetUserId);
  } catch (e) {
    return false;
  }
});

/// Провайдер статистики подписок
final subscriptionStatsProvider =
    FutureProvider.family<SubscriptionStats, String>((ref, userId) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getSubscriptionStats(userId);
});

/// Провайдер для управления состоянием создания поста
final createPostStateProvider =
    StateNotifierProvider<CreatePostNotifier, CreatePostState>(
  (ref) => CreatePostNotifier(),
);

/// Состояние создания поста
class CreatePostState {
  const CreatePostState({
    this.description = '',
    this.taggedCategories = const [],
    this.selectedType,
    this.selectedFile,
    this.isUploading = false,
    this.error,
  });
  final String description;
  final List<String> taggedCategories;
  final PostType? selectedType;
  final File? selectedFile;
  final bool isUploading;
  final String? error;

  CreatePostState copyWith({
    String? description,
    List<String>? taggedCategories,
    PostType? selectedType,
    File? selectedFile,
    bool? isUploading,
    String? error,
  }) =>
      CreatePostState(
        description: description ?? this.description,
        taggedCategories: taggedCategories ?? this.taggedCategories,
        selectedType: selectedType ?? this.selectedType,
        selectedFile: selectedFile ?? this.selectedFile,
        isUploading: isUploading ?? this.isUploading,
        error: error ?? this.error,
      );
}

/// Notifier для управления состоянием создания поста
class CreatePostNotifier extends StateNotifier<CreatePostState> {
  CreatePostNotifier() : super(const CreatePostState());

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateTaggedCategories(List<String> categories) {
    state = state.copyWith(taggedCategories: categories);
  }

  void selectType(PostType type) {
    state = state.copyWith(selectedType: type);
  }

  void selectFile(File file) {
    state = state.copyWith(selectedFile: file);
  }

  void setUploading(bool uploading) {
    state = state.copyWith(isUploading: uploading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const CreatePostState();
  }
}
