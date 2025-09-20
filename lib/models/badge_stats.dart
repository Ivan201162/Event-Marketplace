/// Статистика по бейджам
class BadgeStats {
  const BadgeStats({
    this.totalBadges = 0,
    this.earnedBadges = 0,
    this.availableBadges = 0,
    this.points = 0,
    this.level = 0,
    this.currentLevel = '',
    this.nextLevelPoints = 0,
    this.progress = 0.0,
  });

  final int totalBadges;
  final int earnedBadges;
  final int availableBadges;
  final int points;
  final int level;
  final String currentLevel;
  final int nextLevelPoints;
  final double progress;

  factory BadgeStats.fromJson(Map<String, dynamic> json) => BadgeStats(
        totalBadges: json['totalBadges'] as int? ?? 0,
        earnedBadges: json['earnedBadges'] as int? ?? 0,
        availableBadges: json['availableBadges'] as int? ?? 0,
        points: json['points'] as int? ?? 0,
        level: json['level'] as int? ?? 0,
        currentLevel: json['currentLevel'] as String? ?? '',
        nextLevelPoints: json['nextLevelPoints'] as int? ?? 0,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'totalBadges': totalBadges,
        'earnedBadges': earnedBadges,
        'availableBadges': availableBadges,
        'points': points,
        'level': level,
        'currentLevel': currentLevel,
        'nextLevelPoints': nextLevelPoints,
        'progress': progress,
      };
}

/// Запись в таблице лидеров по бейджам
class BadgeLeaderboardEntry {
  const BadgeLeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.totalBadges = 0,
    this.points = 0,
    this.level = 0,
    this.position = 0,
  });

  final String userId;
  final String userName;
  final String userAvatar;
  final int totalBadges;
  final int points;
  final int level;
  final int position;

  factory BadgeLeaderboardEntry.fromJson(Map<String, dynamic> json) => BadgeLeaderboardEntry(
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatar: json['userAvatar'] as String,
        totalBadges: json['totalBadges'] as int? ?? 0,
        points: json['points'] as int? ?? 0,
        level: json['level'] as int? ?? 0,
        position: json['position'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'totalBadges': totalBadges,
        'points': points,
        'level': level,
        'position': position,
      };
}
