/// Статистика бейджей
class BadgeStats {
  final int totalBadges;
  final int earnedBadges;
  final int availableBadges;
  final Map<String, int> categoryCounts;
  final DateTime lastEarned;

  const BadgeStats({
    required this.totalBadges,
    required this.earnedBadges,
    required this.availableBadges,
    required this.categoryCounts,
    required this.lastEarned,
  });

  factory BadgeStats.fromMap(Map<String, dynamic> data) {
    return BadgeStats(
      totalBadges: data['totalBadges'] as int? ?? 0,
      earnedBadges: data['earnedBadges'] as int? ?? 0,
      availableBadges: data['availableBadges'] as int? ?? 0,
      categoryCounts: Map<String, int>.from(data['categoryCounts'] ?? {}),
      lastEarned: DateTime.parse(data['lastEarned'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBadges': totalBadges,
      'earnedBadges': earnedBadges,
      'availableBadges': availableBadges,
      'categoryCounts': categoryCounts,
      'lastEarned': lastEarned.toIso8601String(),
    };
  }
}

/// Запись в таблице лидеров по бейджам
class BadgeLeaderboardEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int badgeCount;
  final List<String> recentBadges;
  final int rank;

  const BadgeLeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.badgeCount,
    required this.recentBadges,
    required this.rank,
  });

  factory BadgeLeaderboardEntry.fromMap(Map<String, dynamic> data) {
    return BadgeLeaderboardEntry(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userAvatar: data['userAvatar'] as String?,
      badgeCount: data['badgeCount'] as int? ?? 0,
      recentBadges: List<String>.from(data['recentBadges'] ?? []),
      rank: data['rank'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'badgeCount': badgeCount,
      'recentBadges': recentBadges,
      'rank': rank,
    };
  }
}
