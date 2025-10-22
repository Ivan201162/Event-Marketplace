import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/follow_service.dart';

/// Провайдеры для подписок
class FollowProviders {
  /// Сервис подписок
  static final followServiceProvider = Provider<FollowService>((ref) {
    return FollowService();
  });

  /// Подписчики пользователя
  static final followersProvider = StreamProvider.family<List<FollowUser>, String>((ref, userId) {
    final service = ref.watch(followServiceProvider);
    return service.getFollowers(userId);
  });

  /// Подписки пользователя
  static final followingProvider = StreamProvider.family<List<FollowUser>, String>((ref, userId) {
    final service = ref.watch(followServiceProvider);
    return service.getFollowing(userId);
  });

  /// Количество подписчиков
  static final followersCountProvider = StreamProvider.family<int, String>((ref, userId) {
    final service = ref.watch(followServiceProvider);
    return service.getFollowersCount(userId);
  });

  /// Количество подписок
  static final followingCountProvider = StreamProvider.family<int, String>((ref, userId) {
    final service = ref.watch(followServiceProvider);
    return service.getFollowingCount(userId);
  });

  /// Рекомендуемые пользователи
  static final recommendedUsersProvider = FutureProvider.family<List<FollowUser>, String>((ref, userId) {
    final service = ref.watch(followServiceProvider);
    return service.getRecommendedUsers(userId);
  });

  /// Поиск пользователей
  static final searchUsersProvider = FutureProvider.family<List<FollowUser>, String>((ref, query) {
    final service = ref.watch(followServiceProvider);
    return service.searchUsers(query);
  });

  /// Статус подписки (подписан ли текущий пользователь на целевого)
  static final isFollowingProvider = FutureProvider.family<bool, String>((ref, targetUserId) {
    final service = ref.watch(followServiceProvider);
    return service.isFollowing(targetUserId);
  });
}
