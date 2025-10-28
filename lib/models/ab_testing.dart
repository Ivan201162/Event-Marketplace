import 'package:cloud_firestore/cloud_firestore.dart';

enum ABTestStatus { draft, active, completed, paused }

class ABTest {

  ABTest({
    required this.id,
    required this.name,
    required this.description,
    required this.variants,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt, required this.updatedAt, this.isActive = false,
    this.targetAudience,
    this.metadata,
  });

  factory ABTest.fromMap(Map<String, dynamic> map) {
    return ABTest(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      variants: (map['variants'] as List<dynamic>?)
              ?.map((v) => ABTestVariant.fromMap(v))
              .toList() ??
          [],
      status: ABTestStatus.values.byName(map['status'] ?? 'draft'),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      targetAudience: map['targetAudience'],
      metadata: map['metadata'],
    );
  }
  final String id;
  final String name;
  final String description;
  final List<ABTestVariant> variants;
  final ABTestStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? targetAudience;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'variants': variants.map((v) => v.toMap()).toList(),
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'targetAudience': targetAudience,
      'metadata': metadata,
    };
  }
}

class ABTestVariant {

  ABTestVariant({
    required this.name,
    required this.description,
    required this.trafficPercentage,
    required this.config,
  });

  factory ABTestVariant.fromMap(Map<String, dynamic> map) {
    return ABTestVariant(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      trafficPercentage: map['trafficPercentage'] ?? 0,
      config: map['config'] ?? {},
    );
  }
  final String name;
  final String description;
  final int trafficPercentage;
  final Map<String, dynamic> config;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'trafficPercentage': trafficPercentage,
      'config': config,
    };
  }
}

class ABTestAssignment {

  ABTestAssignment({
    required this.id,
    required this.userId,
    required this.testName,
    required this.variant,
    required this.assignedAt,
    this.isActive = true,
  });

  factory ABTestAssignment.fromMap(Map<String, dynamic> map) {
    return ABTestAssignment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      testName: map['testName'] ?? '',
      variant: map['variant'] ?? '',
      assignedAt: (map['assignedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
  final String id;
  final String userId;
  final String testName;
  final String variant;
  final DateTime assignedAt;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'testName': testName,
      'variant': variant,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'isActive': isActive,
    };
  }
}

class ABTestEvent {

  ABTestEvent({
    required this.id,
    required this.userId,
    required this.testName,
    required this.variant,
    required this.eventName,
    required this.timestamp, this.eventData,
  });

  factory ABTestEvent.fromMap(Map<String, dynamic> map) {
    return ABTestEvent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      testName: map['testName'] ?? '',
      variant: map['variant'] ?? '',
      eventName: map['eventName'] ?? '',
      eventData: map['eventData'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String userId;
  final String testName;
  final String variant;
  final String eventName;
  final Map<String, dynamic>? eventData;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'testName': testName,
      'variant': variant,
      'eventName': eventName,
      'eventData': eventData,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class VariantResult {

  VariantResult({
    required this.variantName,
    required this.userCount,
    required this.events,
    required this.conversionRate,
  });
  final String variantName;
  final int userCount;
  final Map<String, int> events;
  final double conversionRate;
}

class ABTestResults {

  ABTestResults({
    required this.testId,
    required this.testName,
    required this.totalUsers,
    required this.variantResults,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
  });
  final String testId;
  final String testName;
  final int totalUsers;
  final List<VariantResult> variantResults;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
}
