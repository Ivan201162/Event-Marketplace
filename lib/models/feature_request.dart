import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Тип пользователя
enum UserType {
  customer,
  specialist,
  admin,
}

/// Приоритет предложения
enum FeaturePriority {
  low,
  medium,
  high,
  critical,
}

/// Статус предложения
enum FeatureStatus {
  submitted,
  underReview,
  approved,
  inDevelopment,
  completed,
  rejected,
  duplicate,
}

/// Категория предложения
enum FeatureCategory {
  ui,
  functionality,
  performance,
  security,
  integration,
  mobile,
  web,
  api,
  other,
}

/// Модель предложения по функционалу
class FeatureRequest {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final UserType userType;
  final String title;
  final String description;
  final FeatureCategory category;
  final FeaturePriority priority;
  final FeatureStatus status;
  final List<String> tags;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final int votes;
  final List<String> voters;
  final String? adminComment;
  final String? assignedTo;
  final DateTime? estimatedCompletion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeatureRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.userType,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.tags,
    required this.attachments,
    required this.metadata,
    required this.votes,
    required this.voters,
    this.adminComment,
    this.assignedTo,
    this.estimatedCompletion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory FeatureRequest.fromMap(Map<String, dynamic> data) {
    return FeatureRequest(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'],
      userType: UserType.values.firstWhere(
        (e) => e.name == data['userType'],
        orElse: () => UserType.customer,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: FeatureCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => FeatureCategory.other,
      ),
      priority: FeaturePriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => FeaturePriority.medium,
      ),
      status: FeatureStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FeatureStatus.submitted,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      votes: data['votes'] ?? 0,
      voters: List<String>.from(data['voters'] ?? []),
      adminComment: data['adminComment'],
      assignedTo: data['assignedTo'],
      estimatedCompletion: data['estimatedCompletion'] != null
          ? (data['estimatedCompletion'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userType': userType.name,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'tags': tags,
      'attachments': attachments,
      'metadata': metadata,
      'votes': votes,
      'voters': voters,
      'adminComment': adminComment,
      'assignedTo': assignedTo,
      'estimatedCompletion': estimatedCompletion != null
          ? Timestamp.fromDate(estimatedCompletion!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Копировать с изменениями
  FeatureRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    UserType? userType,
    String? title,
    String? description,
    FeatureCategory? category,
    FeaturePriority? priority,
    FeatureStatus? status,
    List<String>? tags,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    int? votes,
    List<String>? voters,
    String? adminComment,
    String? assignedTo,
    DateTime? estimatedCompletion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeatureRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userType: userType ?? this.userType,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      votes: votes ?? this.votes,
      voters: voters ?? this.voters,
      adminComment: adminComment ?? this.adminComment,
      assignedTo: assignedTo ?? this.assignedTo,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Получить цвет статуса
  Color get statusColor {
    switch (status) {
      case FeatureStatus.submitted:
        return Colors.blue;
      case FeatureStatus.underReview:
        return Colors.orange;
      case FeatureStatus.approved:
        return Colors.green;
      case FeatureStatus.inDevelopment:
        return Colors.purple;
      case FeatureStatus.completed:
        return Colors.green[700]!;
      case FeatureStatus.rejected:
        return Colors.red;
      case FeatureStatus.duplicate:
        return Colors.grey;
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case FeatureStatus.submitted:
        return 'Отправлено';
      case FeatureStatus.underReview:
        return 'На рассмотрении';
      case FeatureStatus.approved:
        return 'Одобрено';
      case FeatureStatus.inDevelopment:
        return 'В разработке';
      case FeatureStatus.completed:
        return 'Завершено';
      case FeatureStatus.rejected:
        return 'Отклонено';
      case FeatureStatus.duplicate:
        return 'Дубликат';
    }
  }

  /// Получить цвет приоритета
  Color get priorityColor {
    switch (priority) {
      case FeaturePriority.low:
        return Colors.grey;
      case FeaturePriority.medium:
        return Colors.blue;
      case FeaturePriority.high:
        return Colors.orange;
      case FeaturePriority.critical:
        return Colors.red;
    }
  }

  /// Получить текст приоритета
  String get priorityText {
    switch (priority) {
      case FeaturePriority.low:
        return 'Низкий';
      case FeaturePriority.medium:
        return 'Средний';
      case FeaturePriority.high:
        return 'Высокий';
      case FeaturePriority.critical:
        return 'Критический';
    }
  }

  /// Получить текст категории
  String get categoryText {
    switch (category) {
      case FeatureCategory.ui:
        return 'Пользовательский интерфейс';
      case FeatureCategory.functionality:
        return 'Функциональность';
      case FeatureCategory.performance:
        return 'Производительность';
      case FeatureCategory.security:
        return 'Безопасность';
      case FeatureCategory.integration:
        return 'Интеграция';
      case FeatureCategory.mobile:
        return 'Мобильное приложение';
      case FeatureCategory.web:
        return 'Веб-версия';
      case FeatureCategory.api:
        return 'API';
      case FeatureCategory.other:
        return 'Другое';
    }
  }

  /// Проверить, может ли пользователь голосовать
  bool canVote(String userId) {
    return !voters.contains(userId);
  }

  /// Проверить, может ли пользователь редактировать
  bool canEdit(String userId) {
    return this.userId == userId && status == FeatureStatus.submitted;
  }

  /// Проверить, может ли пользователь удалить
  bool canDelete(String userId) {
    return this.userId == userId &&
        (status == FeatureStatus.submitted || status == FeatureStatus.rejected);
  }
}

/// Модель статистики предложений
class FeatureRequestStats {
  final int totalRequests;
  final int submittedRequests;
  final int underReviewRequests;
  final int approvedRequests;
  final int inDevelopmentRequests;
  final int completedRequests;
  final int rejectedRequests;
  final Map<FeatureCategory, int> categoryStats;
  final Map<FeaturePriority, int> priorityStats;
  final Map<UserType, int> userTypeStats;
  final int totalVotes;
  final double averageVotesPerRequest;

  const FeatureRequestStats({
    required this.totalRequests,
    required this.submittedRequests,
    required this.underReviewRequests,
    required this.approvedRequests,
    required this.inDevelopmentRequests,
    required this.completedRequests,
    required this.rejectedRequests,
    required this.categoryStats,
    required this.priorityStats,
    required this.userTypeStats,
    required this.totalVotes,
    required this.averageVotesPerRequest,
  });

  /// Создать из Map
  factory FeatureRequestStats.fromMap(Map<String, dynamic> data) {
    return FeatureRequestStats(
      totalRequests: data['totalRequests'] ?? 0,
      submittedRequests: data['submittedRequests'] ?? 0,
      underReviewRequests: data['underReviewRequests'] ?? 0,
      approvedRequests: data['approvedRequests'] ?? 0,
      inDevelopmentRequests: data['inDevelopmentRequests'] ?? 0,
      completedRequests: data['completedRequests'] ?? 0,
      rejectedRequests: data['rejectedRequests'] ?? 0,
      categoryStats: Map<FeatureCategory, int>.from(
        (data['categoryStats'] as Map?)?.map(
              (key, value) => MapEntry(
                FeatureCategory.values.firstWhere(
                  (e) => e.name == key,
                  orElse: () => FeatureCategory.other,
                ),
                value as int,
              ),
            ) ??
            {},
      ),
      priorityStats: Map<FeaturePriority, int>.from(
        (data['priorityStats'] as Map?)?.map(
              (key, value) => MapEntry(
                FeaturePriority.values.firstWhere(
                  (e) => e.name == key,
                  orElse: () => FeaturePriority.medium,
                ),
                value as int,
              ),
            ) ??
            {},
      ),
      userTypeStats: Map<UserType, int>.from(
        (data['userTypeStats'] as Map?)?.map(
              (key, value) => MapEntry(
                UserType.values.firstWhere(
                  (e) => e.name == key,
                  orElse: () => UserType.customer,
                ),
                value as int,
              ),
            ) ??
            {},
      ),
      totalVotes: data['totalVotes'] ?? 0,
      averageVotesPerRequest:
          (data['averageVotesPerRequest'] ?? 0.0).toDouble(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'totalRequests': totalRequests,
      'submittedRequests': submittedRequests,
      'underReviewRequests': underReviewRequests,
      'approvedRequests': approvedRequests,
      'inDevelopmentRequests': inDevelopmentRequests,
      'completedRequests': completedRequests,
      'rejectedRequests': rejectedRequests,
      'categoryStats': categoryStats.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'priorityStats': priorityStats.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'userTypeStats': userTypeStats.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'totalVotes': totalVotes,
      'averageVotesPerRequest': averageVotesPerRequest,
    };
  }
}
