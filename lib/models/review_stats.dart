import 'package:equatable/equatable.dart';

/// Review statistics model
class ReviewStats extends Equatable {

  const ReviewStats({
    required this.specialistId,
    required this.totalReviews,
    required this.averageRating,
    this.ratingDistribution = const {},
    this.topTags = const [],
    this.tags = const [],
    this.verifiedReviews = 0,
    this.recentReviews = 0,
    this.responseRate = 0.0,
    this.satisfactionRate = 0.0,
  });

  /// Create ReviewStats from Map
  factory ReviewStats.fromMap(Map<String, dynamic> data) {
    return ReviewStats(
      specialistId: data['specialistId'] ?? '',
      totalReviews: data['totalReviews'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      topTags: List<String>.from(data['topTags'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      verifiedReviews: data['verifiedReviews'] ?? 0,
      recentReviews: data['recentReviews'] ?? 0,
      responseRate: (data['responseRate'] ?? 0.0).toDouble(),
      satisfactionRate: (data['satisfactionRate'] ?? 0.0).toDouble(),
    );
  }
  final String specialistId;
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution; // rating -> count
  final List<String> topTags;
  final List<String> tags;
  final int verifiedReviews;
  final int recentReviews;
  final double responseRate;
  final double satisfactionRate;

  /// Convert ReviewStats to Map
  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
      'topTags': topTags,
      'tags': tags,
      'verifiedReviews': verifiedReviews,
      'recentReviews': recentReviews,
      'responseRate': responseRate,
      'satisfactionRate': satisfactionRate,
    };
  }

  /// Create a copy with updated fields
  ReviewStats copyWith({
    String? specialistId,
    int? totalReviews,
    double? averageRating,
    Map<int, int>? ratingDistribution,
    List<String>? topTags,
    List<String>? tags,
    int? verifiedReviews,
    int? recentReviews,
    double? responseRate,
    double? satisfactionRate,
  }) {
    return ReviewStats(
      specialistId: specialistId ?? this.specialistId,
      totalReviews: totalReviews ?? this.totalReviews,
      averageRating: averageRating ?? this.averageRating,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      topTags: topTags ?? this.topTags,
      tags: tags ?? this.tags,
      verifiedReviews: verifiedReviews ?? this.verifiedReviews,
      recentReviews: recentReviews ?? this.recentReviews,
      responseRate: responseRate ?? this.responseRate,
      satisfactionRate: satisfactionRate ?? this.satisfactionRate,
    );
  }

  @override
  List<Object?> get props => [
        specialistId,
        totalReviews,
        averageRating,
        ratingDistribution,
        topTags,
        tags,
        verifiedReviews,
        recentReviews,
        responseRate,
        satisfactionRate,
      ];

  @override
  String toString() {
    return 'ReviewStats(specialistId: $specialistId, totalReviews: $totalReviews, averageRating: $averageRating)';
  }
}

/// Specialist review statistics model
class SpecialistReviewStats extends ReviewStats { // in hours

  const SpecialistReviewStats({
    required super.specialistId,
    required this.specialistName,
    required super.totalReviews, required super.averageRating, this.specialistAvatar,
    this.specializations = const [],
    this.completedBookings = 0,
    this.responseTime = 0.0,
    super.ratingDistribution,
    super.topTags,
    super.tags,
    super.verifiedReviews,
    super.recentReviews,
    super.responseRate,
    super.satisfactionRate,
  });

  /// Create SpecialistReviewStats from Map
  factory SpecialistReviewStats.fromMap(Map<String, dynamic> data) {
    return SpecialistReviewStats(
      specialistId: data['specialistId'] ?? '',
      specialistName: data['specialistName'] ?? '',
      specialistAvatar: data['specialistAvatar'],
      specializations: List<String>.from(data['specializations'] ?? []),
      completedBookings: data['completedBookings'] ?? 0,
      responseTime: (data['responseTime'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      topTags: List<String>.from(data['topTags'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      verifiedReviews: data['verifiedReviews'] ?? 0,
      recentReviews: data['recentReviews'] ?? 0,
      responseRate: (data['responseRate'] ?? 0.0).toDouble(),
      satisfactionRate: (data['satisfactionRate'] ?? 0.0).toDouble(),
    );
  }
  final String specialistName;
  final String? specialistAvatar;
  final List<String> specializations;
  final int completedBookings;
  final double responseTime;

  /// Convert SpecialistReviewStats to Map
  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'specialistName': specialistName,
      'specialistAvatar': specialistAvatar,
      'specializations': specializations,
      'completedBookings': completedBookings,
      'responseTime': responseTime,
    };
  }

  /// Create a copy with updated fields
  @override
  SpecialistReviewStats copyWith({
    String? specialistId,
    String? specialistName,
    String? specialistAvatar,
    List<String>? specializations,
    int? completedBookings,
    double? responseTime,
    int? totalReviews,
    double? averageRating,
    Map<int, int>? ratingDistribution,
    List<String>? topTags,
    List<String>? tags,
    int? verifiedReviews,
    int? recentReviews,
    double? responseRate,
    double? satisfactionRate,
  }) {
    return SpecialistReviewStats(
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      specialistAvatar: specialistAvatar ?? this.specialistAvatar,
      specializations: specializations ?? this.specializations,
      completedBookings: completedBookings ?? this.completedBookings,
      responseTime: responseTime ?? this.responseTime,
      totalReviews: totalReviews ?? this.totalReviews,
      averageRating: averageRating ?? this.averageRating,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      topTags: topTags ?? this.topTags,
      tags: tags ?? this.tags,
      verifiedReviews: verifiedReviews ?? this.verifiedReviews,
      recentReviews: recentReviews ?? this.recentReviews,
      responseRate: responseRate ?? this.responseRate,
      satisfactionRate: satisfactionRate ?? this.satisfactionRate,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        specialistName,
        specialistAvatar,
        specializations,
        completedBookings,
        responseTime,
      ];

  @override
  String toString() {
    return 'SpecialistReviewStats(specialistId: $specialistId, specialistName: $specialistName, totalReviews: $totalReviews)';
  }
}
