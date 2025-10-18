import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

/// Провайдер для текущего профиля пользователя
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Здесь нужно получить ID текущего пользователя
  // Пока используем заглушку
  const userId = 'current_user_id'; // TODO(developer): Получить из AuthService
  return UserProfileService.getUserProfile(userId);
});

/// Провайдер для профиля по ID
final userProfileProvider = FutureProvider.family<UserProfile?, String>(
  (ref, userId) async => UserProfileService.getUserProfile(userId),
);

/// Провайдер для постов пользователя
final userPostsProvider = StreamProvider.family<List<UserPost>, String>(
  (ref, userId) => UserProfileService.getUserPosts(userId),
);

/// Провайдер для сторис пользователя
final userStoriesProvider = StreamProvider.family<List<UserStory>, String>(
  (ref, userId) => UserProfileService.getUserStories(userId),
);

/// Провайдер для отзывов специалиста
final specialistReviewsProvider = StreamProvider.family<List<UserReview>, String>(
  (ref, specialistId) => UserProfileService.getSpecialistReviews(specialistId),
);

/// Провайдер для рекомендуемых специалистов
final recommendedSpecialistsProvider = FutureProvider<List<UserProfile>>((ref) async {
  const userId = 'current_user_id'; // TODO(developer): Получить из AuthService
  return UserProfileService.getRecommendedSpecialists(userId);
});

/// Провайдер для поиска специалистов
final searchSpecialistsProvider = FutureProvider.family<List<UserProfile>, String>(
  (ref, query) async => UserProfileService.searchSpecialists(query),
);

/// Провайдер для управления состоянием профиля
class UserProfileNotifier extends Notifier<AsyncValue<UserProfile?>> {
  @override
  AsyncValue<UserProfile?> build() => const AsyncValue.loading();

  /// Загрузить профиль пользователя
  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await UserProfileService.getUserProfile(userId);
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Обновить профиль
  Future<void> updateProfile(UserProfile profile) async {
    try {
      final success = await UserProfileService.saveUserProfile(profile);
      if (success) {
        state = AsyncValue.data(profile);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Обновить аватар
  Future<void> updateAvatar(String userId, String imagePath) async {
    try {
      final downloadUrl = await UserProfileService.updateAvatar(userId, imagePath);
      if (downloadUrl != null && state.hasValue) {
        final updatedProfile = state.value!.copyWith(avatarUrl: downloadUrl);
        state = AsyncValue.data(updatedProfile);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Обновить обложку
  Future<void> updateCover(String userId, String imagePath) async {
    try {
      final downloadUrl = await UserProfileService.updateCover(userId, imagePath);
      if (downloadUrl != null && state.hasValue) {
        final updatedProfile = state.value!.copyWith(coverUrl: downloadUrl);
        state = AsyncValue.data(updatedProfile);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Обновить прайс-лист
  Future<void> updateServices(
    String userId,
    List<ServicePrice> services,
  ) async {
    try {
      final success = await UserProfileService.updateServices(userId, services);
      if (success && state.hasValue) {
        final updatedProfile = state.value!.copyWith(services: services);
        state = AsyncValue.data(updatedProfile);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Провайдер для UserProfileNotifier
final userProfileNotifierProvider =
    NotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
  () => UserProfileNotifier(),
);

/// Провайдер для управления постами
class UserPostsNotifier extends Notifier<AsyncValue<List<UserPost>>> {
  @override
  AsyncValue<List<UserPost>> build() => const AsyncValue.loading();

  /// Загрузить посты пользователя
  void loadPosts(String userId) {
    // Здесь можно добавить логику загрузки постов
    // Пока используем StreamProvider
  }

  /// Создать пост
  Future<void> createPost(UserPost post) async {
    try {
      final success = await UserProfileService.createPost(post);
      if (success && state.hasValue) {
        final updatedPosts = [post, ...state.value!];
        state = AsyncValue.data(updatedPosts);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId) async {
    try {
      final success = await UserProfileService.deletePost(postId);
      if (success && state.hasValue) {
        final updatedPosts = state.value!.where((post) => post.id != postId).toList();
        state = AsyncValue.data(updatedPosts);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Лайкнуть/убрать лайк с поста
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final success = await UserProfileService.togglePostLike(postId, userId);
      if (success && state.hasValue) {
        final updatedPosts = state.value!.map((post) {
          if (post.id == postId) {
            final isLiked = post.likedBy.contains(userId);
            return post.copyWith(
              likes: isLiked ? post.likes - 1 : post.likes + 1,
              likedBy: isLiked
                  ? post.likedBy.where((id) => id != userId).toList()
                  : [...post.likedBy, userId],
            );
          }
          return post;
        }).toList();
        state = AsyncValue.data(updatedPosts);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Провайдер для UserPostsNotifier
final userPostsNotifierProvider =
    NotifierProvider<UserPostsNotifier, AsyncValue<List<UserPost>>>(
  () => UserPostsNotifier(),
);

/// Провайдер для управления сторис
class UserStoriesNotifier extends Notifier<AsyncValue<List<UserStory>>> {
  @override
  AsyncValue<List<UserStory>> build() => const AsyncValue.loading();

  /// Создать сторис
  Future<void> createStory(UserStory story) async {
    try {
      final success = await UserProfileService.createStory(story);
      if (success && state.hasValue) {
        final updatedStories = [story, ...state.value!];
        state = AsyncValue.data(updatedStories);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Удалить сторис
  Future<void> deleteStory(String storyId) async {
    try {
      final success = await UserProfileService.deleteStory(storyId);
      if (success && state.hasValue) {
        final updatedStories = state.value!.where((story) => story.id != storyId).toList();
        state = AsyncValue.data(updatedStories);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Отметить сторис как просмотренную
  Future<void> markAsViewed(String storyId, String userId) async {
    try {
      final success = await UserProfileService.markStoryAsViewed(storyId, userId);
      if (success && state.hasValue) {
        final updatedStories = state.value!.map((story) {
          if (story.id == storyId && !story.viewedBy.contains(userId)) {
            return story.copyWith(viewedBy: [...story.viewedBy, userId]);
          }
          return story;
        }).toList();
        state = AsyncValue.data(updatedStories);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Провайдер для UserStoriesNotifier
final userStoriesNotifierProvider =
    NotifierProvider<UserStoriesNotifier, AsyncValue<List<UserStory>>>(
  () => UserStoriesNotifier(),
);

/// Провайдер для управления отзывами
class ReviewsNotifier extends Notifier<AsyncValue<List<UserReview>>> {
  @override
  AsyncValue<List<UserReview>> build() => const AsyncValue.loading();

  /// Создать отзыв
  Future<void> createReview(UserReview review) async {
    try {
      final success = await UserProfileService.createReview(review);
      if (success && state.hasValue) {
        final updatedReviews = [review, ...state.value!];
        state = AsyncValue.data(updatedReviews);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Провайдер для ReviewsNotifier
final reviewsNotifierProvider =
    NotifierProvider<ReviewsNotifier, AsyncValue<List<UserReview>>>(
  () => ReviewsNotifier(),
);
