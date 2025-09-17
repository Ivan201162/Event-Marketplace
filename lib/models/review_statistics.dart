/// Статистика отзывов
class ReviewStatistics {
  final double averageRating;
  final int totalReviews;
  final int verifiedReviews;
  final Map<int, int> ratingDistribution; // рейтинг -> количество
  final List<String> topTags;
  final List<String> commonTags;
  final double responseRate;
  final DateTime lastReviewDate;
  final String averageRatingDescription;
  final double verifiedPercentage;

  const ReviewStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.verifiedReviews,
    required this.ratingDistribution,
    required this.topTags,
    required this.commonTags,
    required this.responseRate,
    required this.lastReviewDate,
    required this.averageRatingDescription,
    required this.verifiedPercentage,
  });

  factory ReviewStatistics.fromMap(Map<String, dynamic> data) {
    return ReviewStatistics(
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      verifiedReviews: data['verifiedReviews'] as int? ?? 0,
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      topTags: List<String>.from(data['topTags'] ?? []),
      commonTags: List<String>.from(data['commonTags'] ?? []),
      responseRate: (data['responseRate'] as num?)?.toDouble() ?? 0.0,
      lastReviewDate: DateTime.parse(data['lastReviewDate'] as String),
      averageRatingDescription:
          data['averageRatingDescription'] as String? ?? '',
      verifiedPercentage:
          (data['verifiedPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'verifiedReviews': verifiedReviews,
      'ratingDistribution': ratingDistribution,
      'topTags': topTags,
      'commonTags': commonTags,
      'responseRate': responseRate,
      'lastReviewDate': lastReviewDate.toIso8601String(),
      'averageRatingDescription': averageRatingDescription,
      'verifiedPercentage': verifiedPercentage,
    };
  }

  /// Получить процент рейтинга
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[rating] ?? 0) / totalReviews * 100;
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
