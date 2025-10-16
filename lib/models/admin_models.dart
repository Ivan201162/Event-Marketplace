import 'package:cloud_firestore/cloud_firestore.dart';

/// Роли пользователей в системе
enum UserRole {
  user,
  admin,
  superAdmin,
}

/// Действия администратора
enum AdminAction {
  create,
  update,
  delete,
  activate,
  deactivate,
  approve,
  reject,
  export,
  import,
  sendNotification,
  updatePricing,
  createCampaign,
  updateCampaign,
  deleteCampaign,
  createPromotion,
  updatePromotion,
  deletePromotion,
  createPartner,
  updatePartner,
  deletePartner,
  updateReferralSettings,
  sendBulkNotification,
  updateSubscriptionPlan,
  createSubscriptionPlan,
  deleteSubscriptionPlan,
}

/// Статус админ-действия
enum AdminActionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

/// Модель лога действий администратора
class AdminLog {
  final String id;
  final String adminId;
  final String adminEmail;
  final AdminAction action;
  final String target;
  final String? targetId;
  final String? description;
  final AdminActionStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? errorMessage;

  AdminLog({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.action,
    required this.target,
    this.targetId,
    this.description,
    this.status = AdminActionStatus.completed,
    required this.timestamp,
    this.metadata,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'adminEmail': adminEmail,
      'action': action.name,
      'target': target,
      'targetId': targetId,
      'description': description,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'errorMessage': errorMessage,
    };
  }

  factory AdminLog.fromMap(Map<String, dynamic> map) {
    return AdminLog(
      id: map['id'] ?? '',
      adminId: map['adminId'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      action:
          AdminAction.values.byName(map['action'] ?? AdminAction.create.name),
      target: map['target'] ?? '',
      targetId: map['targetId'],
      description: map['description'],
      status: AdminActionStatus.values
          .byName(map['status'] ?? AdminActionStatus.completed.name),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'],
      errorMessage: map['errorMessage'],
    );
  }
}

/// Модель маркетинговой кампании
class MarketingCampaign {
  final String id;
  final String name;
  final String description;
  final MarketingCampaignType type;
  final MarketingCampaignStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final String? targetAudience;
  final Map<String, dynamic>? settings;
  final double? budget;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  MarketingCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.status = MarketingCampaignStatus.draft,
    required this.startDate,
    required this.endDate,
    this.targetAudience,
    this.settings,
    this.budget,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetAudience': targetAudience,
      'settings': settings,
      'budget': budget,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  factory MarketingCampaign.fromMap(Map<String, dynamic> map) {
    return MarketingCampaign(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: MarketingCampaignType.values
          .byName(map['type'] ?? MarketingCampaignType.promotion.name),
      status: MarketingCampaignStatus.values
          .byName(map['status'] ?? MarketingCampaignStatus.draft.name),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      targetAudience: map['targetAudience'],
      settings: map['settings'],
      budget: map['budget']?.toDouble(),
      createdBy: map['createdBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }
}

/// Типы маркетинговых кампаний
enum MarketingCampaignType {
  promotion,
  advertisement,
  referral,
  subscription,
  notification,
  email,
  push,
  seasonal,
  abTest,
}

/// Статусы маркетинговых кампаний
enum MarketingCampaignStatus {
  draft,
  scheduled,
  active,
  paused,
  completed,
  cancelled,
  expired,
}

/// Модель рассылки
class MarketingNewsletter {
  final String id;
  final String title;
  final String subject;
  final String content;
  final NewsletterType type;
  final NewsletterStatus status;
  final String? targetSegment;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int? totalRecipients;
  final int? deliveredCount;
  final int? openedCount;
  final int? clickedCount;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  MarketingNewsletter({
    required this.id,
    required this.title,
    required this.subject,
    required this.content,
    required this.type,
    this.status = NewsletterStatus.draft,
    this.targetSegment,
    this.scheduledAt,
    this.sentAt,
    this.totalRecipients,
    this.deliveredCount,
    this.openedCount,
    this.clickedCount,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'content': content,
      'type': type.name,
      'status': status.name,
      'targetSegment': targetSegment,
      'scheduledAt':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'totalRecipients': totalRecipients,
      'deliveredCount': deliveredCount,
      'openedCount': openedCount,
      'clickedCount': clickedCount,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  factory MarketingNewsletter.fromMap(Map<String, dynamic> map) {
    return MarketingNewsletter(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      content: map['content'] ?? '',
      type: NewsletterType.values
          .byName(map['type'] ?? NewsletterType.email.name),
      status: NewsletterStatus.values
          .byName(map['status'] ?? NewsletterStatus.draft.name),
      targetSegment: map['targetSegment'],
      scheduledAt: map['scheduledAt'] != null
          ? (map['scheduledAt'] as Timestamp).toDate()
          : null,
      sentAt:
          map['sentAt'] != null ? (map['sentAt'] as Timestamp).toDate() : null,
      totalRecipients: map['totalRecipients'],
      deliveredCount: map['deliveredCount'],
      openedCount: map['openedCount'],
      clickedCount: map['clickedCount'],
      createdBy: map['createdBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'],
    );
  }
}

/// Типы рассылок
enum NewsletterType {
  email,
  push,
  sms,
  inApp,
}

/// Статусы рассылок
enum NewsletterStatus {
  draft,
  scheduled,
  sending,
  sent,
  failed,
  cancelled,
}

/// Модель сегмента пользователей
class UserSegment {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> criteria;
  final int userCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  UserSegment({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    this.userCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'criteria': criteria,
      'userCount': userCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  factory UserSegment.fromMap(Map<String, dynamic> map) {
    return UserSegment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      criteria: map['criteria'] ?? {},
      userCount: map['userCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'],
    );
  }
}

/// Модель финансовой аналитики
class FinancialAnalytics {
  final String id;
  final DateTime date;
  final String period; // daily, weekly, monthly
  final double totalRevenue;
  final double subscriptionRevenue;
  final double promotionRevenue;
  final double advertisementRevenue;
  final double partnerCommission;
  final int totalTransactions;
  final int newSubscriptions;
  final int activeUsers;
  final double arpu; // Average Revenue Per User
  final double ltv; // Lifetime Value
  final Map<String, dynamic>? metadata;

  FinancialAnalytics({
    required this.id,
    required this.date,
    required this.period,
    required this.totalRevenue,
    required this.subscriptionRevenue,
    required this.promotionRevenue,
    required this.advertisementRevenue,
    required this.partnerCommission,
    required this.totalTransactions,
    required this.newSubscriptions,
    required this.activeUsers,
    required this.arpu,
    required this.ltv,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'period': period,
      'totalRevenue': totalRevenue,
      'subscriptionRevenue': subscriptionRevenue,
      'promotionRevenue': promotionRevenue,
      'advertisementRevenue': advertisementRevenue,
      'partnerCommission': partnerCommission,
      'totalTransactions': totalTransactions,
      'newSubscriptions': newSubscriptions,
      'activeUsers': activeUsers,
      'arpu': arpu,
      'ltv': ltv,
      'metadata': metadata,
    };
  }

  factory FinancialAnalytics.fromMap(Map<String, dynamic> map) {
    return FinancialAnalytics(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      period: map['period'] ?? 'daily',
      totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
      subscriptionRevenue: (map['subscriptionRevenue'] ?? 0.0).toDouble(),
      promotionRevenue: (map['promotionRevenue'] ?? 0.0).toDouble(),
      advertisementRevenue: (map['advertisementRevenue'] ?? 0.0).toDouble(),
      partnerCommission: (map['partnerCommission'] ?? 0.0).toDouble(),
      totalTransactions: map['totalTransactions'] ?? 0,
      newSubscriptions: map['newSubscriptions'] ?? 0,
      activeUsers: map['activeUsers'] ?? 0,
      arpu: (map['arpu'] ?? 0.0).toDouble(),
      ltv: (map['ltv'] ?? 0.0).toDouble(),
      metadata: map['metadata'],
    );
  }
}
