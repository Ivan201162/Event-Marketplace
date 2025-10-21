import 'package:equatable/equatable.dart';

/// Specialist review statistics model
class SpecialistReviewStats extends Equatable {
  final String specialistId;
  final String specialistName;
  final String? specialistAvatar;
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution;
  final List<String> topTags;
  final int verifiedReviews;
  final int recentReviews;
  final double responseRate;
  final double satisfactionRate;
  final List<String> specializations;
  final int completedBookings;
  final double responseTime;

  const SpecialistReviewStats({
    required this.specialistId,
    required this.specialistName,
    this.specialistAvatar,
    required this.totalReviews,
    required this.averageRating,
    this.ratingDistribution = const {},
    this.topTags = const [],
    this.verifiedReviews = 0,
    this.recentReviews = 0,
    this.responseRate = 0.0,
    this.satisfactionRate = 0.0,
    this.specializations = const [],
    this.completedBookings = 0,
    this.responseTime = 0.0,
  });

  /// Create SpecialistReviewStats from Map
  factory SpecialistReviewStats.fromMap(Map<String, dynamic> data) {
    return SpecialistReviewStats(
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistAvatar: data['specialistAvatar'],
      totalReviews: data['totalReviews'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      topTags: List<String>.from(data['topTags'] ?? []),
      verifiedReviews: data['verifiedReviews'] ?? 0,
      recentReviews: data['recentReviews'] ?? 0,
      responseRate: (data['responseRate'] ?? 0.0).toDouble(),
      satisfactionRate: (data['satisfactionRate'] ?? 0.0).toDouble(),
      specializations: List<String>.from(data['specializations'] ?? []),
      completedBookings: data['completedBookings'] ?? 0,
      responseTime: (data['responseTime'] ?? 0.0).toDouble(),
    );
  }

  /// Convert SpecialistReviewStats to Map
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'specialistName': specialistName,
      'specialistAvatar': specialistAvatar,
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
      'topTags': topTags,
      'verifiedReviews': verifiedReviews,
      'recentReviews': recentReviews,
      'responseRate': responseRate,
      'satisfactionRate': satisfactionRate,
      'specializations': specializations,
      'completedBookings': completedBookings,
      'responseTime': responseTime,
    };
  }

  /// Create a copy with updated fields
  SpecialistReviewStats copyWith({
    String? specialistId,
    String? specialistName,
    String? specialistAvatar,
    int? totalReviews,
    double? averageRating,
    Map<int, int>? ratingDistribution,
    List<String>? topTags,
    int? verifiedReviews,
    int? recentReviews,
    double? responseRate,
    double? satisfactionRate,
    List<String>? specializations,
    int? completedBookings,
    double? responseTime,
  }) {
    return SpecialistReviewStats(
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistAvatar: specialistAvatar ?? this.specialistAvatar,
      totalReviews: totalReviews ?? this.totalReviews,
      averageRating: averageRating ?? this.averageRating,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      topTags: topTags ?? this.topTags,
      verifiedReviews: verifiedReviews ?? this.verifiedReviews,
      recentReviews: recentReviews ?? this.recentReviews,
      responseRate: responseRate ?? this.responseRate,
      satisfactionRate: satisfactionRate ?? this.satisfactionRate,
      specializations: specializations ?? this.specializations,
      completedBookings: completedBookings ?? this.completedBookings,
      responseTime: responseTime ?? this.responseTime,
    );
  }

  /// Get formatted average rating
  String get formattedAverageRating {
    return averageRating.toStringAsFixed(1);
  }

  /// Get formatted response rate
  String get formattedResponseRate {
    return '${(responseRate * 100).toStringAsFixed(1)}%';
  }

  /// Get formatted satisfaction rate
  String get formattedSatisfactionRate {
    return '${(satisfactionRate * 100).toStringAsFixed(1)}%';
  }

  /// Get formatted response time
  String get formattedResponseTime {
    if (responseTime < 1) {
      return '${(responseTime * 60).toStringAsFixed(0)}м';
    } else if (responseTime < 24) {
      return '${responseTime.toStringAsFixed(1)}ч';
    } else {
      return '${(responseTime / 24).toStringAsFixed(1)}д';
    }
  }

  @override
  List<Object?> get props => [
        specialistId,
        specialistName,
        specialistAvatar,
        totalReviews,
        averageRating,
        ratingDistribution,
        topTags,
        verifiedReviews,
        recentReviews,
        responseRate,
        satisfactionRate,
        specializations,
        completedBookings,
        responseTime,
      ];

  @override
  String toString() {
    return 'SpecialistReviewStats(specialistId: $specialistId, specialistName: $specialistName, totalReviews: $totalReviews)';
  }
}
