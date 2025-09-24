import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/badge.dart' as badge_model;
import '../services/badge_service.dart' as badge_service;

/// Провайдер для сервиса бейджей
final badgeServiceProvider =
    Provider<badge_service.BadgeService>((ref) => badge_service.BadgeService());

/// Провайдер для бейджей пользователя
final userBadgesProvider =
    StreamProvider.family<List<badge_model.Badge>, String>((ref, userId) {
  final service = ref.read(badgeServiceProvider);
  return Stream.fromFuture(service.getUserBadges(userId));
});

/// Провайдер для статистики бейджей пользователя
final userBadgeStatsProvider =
    FutureProvider.family<badge_model.BadgeStats, String>((ref, userId) {
  final service = ref.read(badgeServiceProvider);
  return service.getBadgeStats(userId);
});

/// Провайдер для таблицы лидеров по бейджам
final badgeLeaderboardProvider =
    FutureProvider.family<List<badge_model.BadgeLeaderboardEntry>, int>(
        (ref, limit) {
  final service = ref.read(badgeServiceProvider);
  return service.getBadgeLeaderboard(limit: limit);
});

/// Провайдер для бейджей по категориям
final userBadgesByCategoryProvider = Provider.family<
    Map<badge_model.BadgeCategory, List<badge_model.Badge>>,
    String>((ref, userId) {
  final badgesAsync = ref.watch(userBadgesProvider(userId));

  return badgesAsync.when(
    data: (badges) => badges.groupedByCategory,
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Провайдер для видимых бейджей пользователя
final visibleUserBadgesProvider =
    Provider.family<List<badge_model.Badge>, String>((ref, userId) {
  final badgesAsync = ref.watch(userBadgesProvider(userId));

  return badgesAsync.when(
    data: (badges) => badges.visible,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Провайдер для последних бейджей пользователя
final recentUserBadgesProvider =
    Provider.family<List<badge_model.Badge>, String>((ref, userId) {
  final badgesAsync = ref.watch(userBadgesProvider(userId));

  return badgesAsync.when(
    data: (badges) => badges.recent.take(3).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Провайдер для управления бейджами
final badgeManagerProvider = Provider<BadgeManager>(
  (ref) => BadgeManager(ref.read(badgeServiceProvider)),
);

/// Менеджер бейджей
class BadgeManager {
  BadgeManager(this._service);
  final badge_service.BadgeService _service;

  /// Проверить бейджи после бронирования
  Future<void> checkBookingBadges(
    String customerId,
    String specialistId,
  ) async {
    await _service.checkBookingBadges(customerId, specialistId);
  }

  /// Проверить бейджи после отзыва
  Future<void> checkReviewBadges(
    String customerId,
    String specialistId,
    int rating,
  ) async {
    await _service.checkReviewBadges(customerId, specialistId, rating);
  }

  /// Переключить видимость бейджа
  Future<void> toggleBadgeVisibility(String badgeId, bool isVisible) async {
    await _service.toggleBadgeVisibility(badgeId, isVisible);
  }

  /// Получить статистику бейджей
  Future<badge_model.BadgeStats> getBadgeStats(String userId) async =>
      _service.getBadgeStats(userId);

  /// Получить таблицу лидеров
  Future<List<badge_model.BadgeLeaderboardEntry>> getLeaderboard({
    int limit = 10,
  }) async =>
      _service.getBadgeLeaderboard(limit: limit);
}

/// Провайдер для проверки новых бейджей
final newBadgeCheckerProvider =
    NotifierProvider<NewBadgeChecker, NewBadgeState>(NewBadgeChecker.new);

/// Состояние новых бейджей
class NewBadgeState {
  const NewBadgeState({
    this.newBadges = const [],
    this.hasNewBadges = false,
  });
  final List<badge_model.Badge> newBadges;
  final bool hasNewBadges;

  NewBadgeState copyWith({
    List<badge_model.Badge>? newBadges,
    bool? hasNewBadges,
  }) =>
      NewBadgeState(
        newBadges: newBadges ?? this.newBadges,
        hasNewBadges: hasNewBadges ?? this.hasNewBadges,
      );
}

/// Нотификатор для проверки новых бейджей
class NewBadgeChecker extends Notifier<NewBadgeState> {
  late final badge_service.BadgeService _service;
  String? _lastUserId;
  List<badge_model.Badge> _lastBadges = [];

  @override
  NewBadgeState build() {
    _service = ref.read(badgeServiceProvider);
    return const NewBadgeState();
  }

  /// Проверить новые бейджи для пользователя
  Future<void> checkNewBadges(String userId) async {
    try {
      final currentBadges = await _service.getUserBadges(userId);

      if (_lastUserId == userId && _lastBadges.isNotEmpty) {
        // Проверяем новые бейджи
        final newBadges = currentBadges
            .where(
              (badge) =>
                  !_lastBadges.any((lastBadge) => lastBadge.id == badge.id),
            )
            .toList();

        if (newBadges.isNotEmpty) {
          state = state.copyWith(
            newBadges: newBadges,
            hasNewBadges: true,
          );
        }
      }

      _lastUserId = userId;
      _lastBadges = currentBadges;
    } catch (e) {
      print('Error checking new badges: $e');
    }
  }

  /// Отметить бейджи как просмотренные
  void markBadgesAsViewed() {
    state = state.copyWith(
      newBadges: [],
      hasNewBadges: false,
    );
  }

  /// Сбросить состояние
  void reset() {
    state = const NewBadgeState();
    _lastUserId = null;
    _lastBadges = [];
  }
}

/// Провайдер для достижений пользователя
final userAchievementsProvider =
    Provider.family<UserAchievements, String>((ref, userId) {
  final badgesAsync = ref.watch(userBadgesProvider(userId));
  final statsAsync = ref.watch(userBadgeStatsProvider(userId));

  return UserAchievements(
    badges: badgesAsync.value ?? [],
    stats: statsAsync.value ??
        const badge_model.BadgeStats(
          totalBadges: 0,
          earnedBadges: 0,
          availableBadges: 0,
          recentBadges: [],
          badgesByCategory: {},
        ),
    isLoading: badgesAsync.isLoading || statsAsync.isLoading,
  );
});

/// Достижения пользователя
class UserAchievements {
  const UserAchievements({
    required this.badges,
    required this.stats,
    required this.isLoading,
  });
  final List<badge_model.Badge> badges;
  final badge_model.BadgeStats stats;
  final bool isLoading;

  /// Получить прогресс до следующего бейджа
  Map<String, int> get progressToNextBadge {
    final progress = <String, int>{};

    // Примеры прогресса (можно расширить)
    progress['bookings'] = stats.specialistBadges; // Для специалистов
    progress['events'] = stats.customerBadges; // Для заказчиков

    return progress;
  }

  /// Получить уровень пользователя
  int get userLevel {
    return (stats.totalBadges / 5).floor() +
        1; // Каждые 5 бейджей = новый уровень
  }

  /// Получить прогресс до следующего уровня
  double get levelProgress => (stats.totalBadges % 5) / 5.0;

  /// Получить название уровня
  String get levelName {
    final level = userLevel;
    if (level <= 5) return 'Новичок';
    if (level <= 10) return 'Любитель';
    if (level <= 15) return 'Профессионал';
    if (level <= 20) return 'Эксперт';
    return 'Мастер';
  }
}
