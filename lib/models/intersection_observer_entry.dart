import 'package:equatable/equatable.dart';

/// Intersection observer entry model
class IntersectionObserverEntry extends Equatable {
  final String targetId;
  final bool isIntersecting;
  final double intersectionRatio;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const IntersectionObserverEntry({
    required this.targetId,
    required this.isIntersecting,
    required this.intersectionRatio,
    required this.timestamp,
    this.metadata,
  });

  /// Create IntersectionObserverEntry from Map
  factory IntersectionObserverEntry.fromMap(Map<String, dynamic> data) {
    return IntersectionObserverEntry(
      targetId: data['targetId'] ?? '',
      isIntersecting: data['isIntersecting'] ?? false,
      intersectionRatio: (data['intersectionRatio'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(data['timestamp']),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert IntersectionObserverEntry to Map
  Map<String, dynamic> toMap() {
    return {
      'targetId': targetId,
      'isIntersecting': isIntersecting,
      'intersectionRatio': intersectionRatio,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  IntersectionObserverEntry copyWith({
    String? targetId,
    bool? isIntersecting,
    double? intersectionRatio,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return IntersectionObserverEntry(
      targetId: targetId ?? this.targetId,
      isIntersecting: isIntersecting ?? this.isIntersecting,
      intersectionRatio: intersectionRatio ?? this.intersectionRatio,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted intersection ratio
  String get formattedIntersectionRatio {
    return '${(intersectionRatio * 100).toStringAsFixed(1)}%';
  }

  @override
  List<Object?> get props => [targetId, isIntersecting, intersectionRatio, timestamp, metadata];

  @override
  String toString() {
    return 'IntersectionObserverEntry(targetId: $targetId, isIntersecting: $isIntersecting, intersectionRatio: $intersectionRatio)';
  }
}
