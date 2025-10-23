import 'package:equatable/equatable.dart';

/// Visibility information model
class VisibilityInfo extends Equatable {
  final bool isVisible;
  final double visibilityPercentage;
  final DateTime lastSeen;
  final int viewCount;
  final Duration viewDuration;

  const VisibilityInfo({
    required this.isVisible,
    required this.visibilityPercentage,
    required this.lastSeen,
    this.viewCount = 0,
    this.viewDuration = Duration.zero,
  });

  /// Create VisibilityInfo from Map
  factory VisibilityInfo.fromMap(Map<String, dynamic> data) {
    return VisibilityInfo(
      isVisible: data['isVisible'] ?? false,
      visibilityPercentage: (data['visibilityPercentage'] ?? 0.0).toDouble(),
      lastSeen: DateTime.parse(data['lastSeen']),
      viewCount: data['viewCount'] ?? 0,
      viewDuration: Duration(milliseconds: data['viewDuration'] ?? 0),
    );
  }

  /// Convert VisibilityInfo to Map
  Map<String, dynamic> toMap() {
    return {
      'isVisible': isVisible,
      'visibilityPercentage': visibilityPercentage,
      'lastSeen': lastSeen.toIso8601String(),
      'viewCount': viewCount,
      'viewDuration': viewDuration.inMilliseconds,
    };
  }

  /// Create a copy with updated fields
  VisibilityInfo copyWith({
    bool? isVisible,
    double? visibilityPercentage,
    DateTime? lastSeen,
    int? viewCount,
    Duration? viewDuration,
  }) {
    return VisibilityInfo(
      isVisible: isVisible ?? this.isVisible,
      visibilityPercentage: visibilityPercentage ?? this.visibilityPercentage,
      lastSeen: lastSeen ?? this.lastSeen,
      viewCount: viewCount ?? this.viewCount,
      viewDuration: viewDuration ?? this.viewDuration,
    );
  }

  /// Get formatted visibility percentage
  String get formattedVisibilityPercentage {
    return '${(visibilityPercentage * 100).toStringAsFixed(1)}%';
  }

  /// Get formatted view duration
  String get formattedViewDuration {
    if (viewDuration.inHours > 0) {
      return '${viewDuration.inHours}ч ${viewDuration.inMinutes % 60}м';
    } else if (viewDuration.inMinutes > 0) {
      return '${viewDuration.inMinutes}м';
    } else {
      return '${viewDuration.inSeconds}с';
    }
  }

  @override
  List<Object?> get props =>
      [isVisible, visibilityPercentage, lastSeen, viewCount, viewDuration];

  @override
  String toString() {
    return 'VisibilityInfo(isVisible: $isVisible, visibilityPercentage: $visibilityPercentage, viewCount: $viewCount)';
  }
}
