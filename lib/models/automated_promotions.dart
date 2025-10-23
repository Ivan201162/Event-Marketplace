import 'package:cloud_firestore/cloud_firestore.dart';

enum PromotionTrigger {
  userRegistration,
  firstPurchase,
  subscriptionExpiry,
  inactivity,
  holiday,
  seasonal,
  milestone,
  custom,
}

enum PromotionStatus { draft, active, completed, paused }

class AutomatedPromotion {
  final String id;
  final String name;
  final String description;
  final PromotionTrigger trigger;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> actions;
  final PromotionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? targetAudience;
  final Map<String, dynamic>? metadata;

  AutomatedPromotion({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.conditions,
    required this.actions,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.targetAudience,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trigger': trigger.name,
      'conditions': conditions,
      'actions': actions,
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

  factory AutomatedPromotion.fromMap(Map<String, dynamic> map) {
    return AutomatedPromotion(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      trigger:
          PromotionTrigger.values.byName(map['trigger'] ?? 'userRegistration'),
      conditions: map['conditions'] ?? {},
      actions: map['actions'] ?? {},
      status: PromotionStatus.values.byName(map['status'] ?? 'draft'),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      targetAudience: map['targetAudience'],
      metadata: map['metadata'],
    );
  }
}
