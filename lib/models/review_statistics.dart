/// Статистика отзывов
class ReviewStatistics {
  final double averageRating;
  final int totalReviews;
  final int verifiedReviews;
  final Map<int, int> ratingDistribution; // рейтинг -> количество
  final List<String> topTags;
  final double responseRate;
  final DateTime lastReviewDate;

  const ReviewStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.verifiedReviews,
    required this.ratingDistribution,
    required this.topTags,
    required this.responseRate,
    required this.lastReviewDate,
  });

  factory ReviewStatistics.fromMap(Map<String, dynamic> data) {
    return ReviewStatistics(
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      verifiedReviews: data['verifiedReviews'] as int? ?? 0,
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      topTags: List<String>.from(data['topTags'] ?? []),
      responseRate: (data['responseRate'] as num?)?.toDouble() ?? 0.0,
      lastReviewDate: DateTime.parse(data['lastReviewDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'verifiedReviews': verifiedReviews,
      'ratingDistribution': ratingDistribution,
      'topTags': topTags,
      'responseRate': responseRate,
      'lastReviewDate': lastReviewDate.toIso8601String(),
    };
  }
}

/// Детальный рейтинг
class DetailedRating {
  final double overall;
  final double quality;
  final double communication;
  final double punctuality;
  final double value;

  const DetailedRating({
    required this.overall,
    required this.quality,
    required this.communication,
    required this.punctuality,
    required this.value,
  });

  factory DetailedRating.fromMap(Map<String, dynamic> data) {
    return DetailedRating(
      overall: (data['overall'] as num?)?.toDouble() ?? 0.0,
      quality: (data['quality'] as num?)?.toDouble() ?? 0.0,
      communication: (data['communication'] as num?)?.toDouble() ?? 0.0,
      punctuality: (data['punctuality'] as num?)?.toDouble() ?? 0.0,
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overall': overall,
      'quality': quality,
      'communication': communication,
      'punctuality': punctuality,
      'value': value,
    };
  }
}
