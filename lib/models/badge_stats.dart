import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge_stats.freezed.dart';
part 'badge_stats.g.dart';

/// Статистика по бейджам
@freezed
class BadgeStats with _$BadgeStats {
  const factory BadgeStats({
    @Default(0) int totalBadges,
    @Default(0) int earnedBadges,
    @Default(0) int availableBadges,
    @Default(0) int points,
    @Default(0) int level,
    @Default('') String currentLevel,
    @Default(0) int nextLevelPoints,
    @Default(0.0) double progress,
  }) = _BadgeStats;

  factory BadgeStats.fromJson(Map<String, dynamic> json) =>
      _$BadgeStatsFromJson(json);
}

/// Запись в таблице лидеров по бейджам
@freezed
class BadgeLeaderboardEntry with _$BadgeLeaderboardEntry {
  const factory BadgeLeaderboardEntry({
    required String userId,
    required String userName,
    required String userAvatar,
    @Default(0) int totalBadges,
    @Default(0) int points,
    @Default(0) int level,
    @Default(0) int position,
  }) = _BadgeLeaderboardEntry;

  factory BadgeLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$BadgeLeaderboardEntryFromJson(json);
}
