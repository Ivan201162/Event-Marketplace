import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для управления инцидентами
class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentType type;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String? assignedTo;
  final String? assignedToName;
  final String? reporterId;
  final String? reporterName;
  final String? reporterEmail;
  final List<String> affectedServices;
  final List<String> affectedUsers;
  final String? rootCause;
  final String? resolution;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final List<String> attachments;
  final DateTime? detectedAt;
  final DateTime? reportedAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.assignedToName,
    this.reporterId,
    this.reporterName,
    this.reporterEmail,
    required this.affectedServices,
    required this.affectedUsers,
    this.rootCause,
    this.resolution,
    required this.tags,
    required this.metadata,
    required this.attachments,
    this.detectedAt,
    this.reportedAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: IncidentType.fromString(map['type'] ?? 'technical'),
      severity: IncidentSeverity.fromString(map['severity'] ?? 'medium'),
      status: IncidentStatus.fromString(map['status'] ?? 'open'),
      priority: IncidentPriority.fromString(map['priority'] ?? 'medium'),
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      reporterId: map['reporterId'],
      reporterName: map['reporterName'],
      reporterEmail: map['reporterEmail'],
      affectedServices: List<String>.from(map['affectedServices'] ?? []),
      affectedUsers: List<String>.from(map['affectedUsers'] ?? []),
      rootCause: map['rootCause'],
      resolution: map['resolution'],
      tags: List<String>.from(map['tags'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      attachments: List<String>.from(map['attachments'] ?? []),
      detectedAt: map['detectedAt'] != null
          ? (map['detectedAt'] as Timestamp).toDate()
          : null,
      reportedAt: map['reportedAt'] != null
          ? (map['reportedAt'] as Timestamp).toDate()
          : null,
      acknowledgedAt: map['acknowledgedAt'] != null
          ? (map['acknowledgedAt'] as Timestamp).toDate()
          : null,
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      closedAt: map['closedAt'] != null
          ? (map['closedAt'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'severity': severity.value,
      'status': status.value,
      'priority': priority.value,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'affectedServices': affectedServices,
      'affectedUsers': affectedUsers,
      'rootCause': rootCause,
      'resolution': resolution,
      'tags': tags,
      'metadata': metadata,
      'attachments': attachments,
      'detectedAt': detectedAt != null ? Timestamp.fromDate(detectedAt!) : null,
      'reportedAt': reportedAt != null ? Timestamp.fromDate(reportedAt!) : null,
      'acknowledgedAt':
          acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  Incident copyWith({
    String? id,
    String? title,
    String? description,
    IncidentType? type,
    IncidentSeverity? severity,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? assignedTo,
    String? assignedToName,
    String? reporterId,
    String? reporterName,
    String? reporterEmail,
    List<String>? affectedServices,
    List<String>? affectedUsers,
    String? rootCause,
    String? resolution,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    DateTime? detectedAt,
    DateTime? reportedAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      affectedServices: affectedServices ?? this.affectedServices,
      affectedUsers: affectedUsers ?? this.affectedUsers,
      rootCause: rootCause ?? this.rootCause,
      resolution: resolution ?? this.resolution,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      detectedAt: detectedAt ?? this.detectedAt,
      reportedAt: reportedAt ?? this.reportedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() {
    return 'Incident(id: $id, title: $title, severity: $severity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Incident && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы инцидентов
enum IncidentType {
  technical('technical', 'Технический'),
  security('security', 'Безопасность'),
  performance('performance', 'Производительность'),
  availability('availability', 'Доступность'),
  data('data', 'Данные'),
  user('user', 'Пользовательский'),
  business('business', 'Бизнес'),
  compliance('compliance', 'Соответствие');

  const IncidentType(this.value, this.displayName);

  final String value;
  final String displayName;

  static IncidentType fromString(String value) {
    return IncidentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => IncidentType.technical,
    );
  }

  String get icon {
    switch (this) {
      case IncidentType.technical:
        return '⚙️';
      case IncidentType.security:
        return '🔒';
      case IncidentType.performance:
        return '📊';
      case IncidentType.availability:
        return '🌐';
      case IncidentType.data:
        return '💾';
      case IncidentType.user:
        return '👥';
      case IncidentType.business:
        return '💼';
      case IncidentType.compliance:
        return '📋';
    }
  }

  String get color {
    switch (this) {
      case IncidentType.technical:
        return 'blue';
      case IncidentType.security:
        return 'red';
      case IncidentType.performance:
        return 'orange';
      case IncidentType.availability:
        return 'green';
      case IncidentType.data:
        return 'purple';
      case IncidentType.user:
        return 'teal';
      case IncidentType.business:
        return 'brown';
      case IncidentType.compliance:
        return 'indigo';
    }
  }
}

/// Серьезность инцидентов
enum IncidentSeverity {
  critical('critical', 'Критический'),
  high('high', 'Высокий'),
  medium('medium', 'Средний'),
  low('low', 'Низкий'),
  info('info', 'Информационный');

  const IncidentSeverity(this.value, this.displayName);

  final String value;
  final String displayName;

  static IncidentSeverity fromString(String value) {
    return IncidentSeverity.values.firstWhere(
      (severity) => severity.value == value,
      orElse: () => IncidentSeverity.medium,
    );
  }

  String get icon {
    switch (this) {
      case IncidentSeverity.critical:
        return '🚨';
      case IncidentSeverity.high:
        return '🔴';
      case IncidentSeverity.medium:
        return '🟡';
      case IncidentSeverity.low:
        return '🟢';
      case IncidentSeverity.info:
        return 'ℹ️';
    }
  }

  String get color {
    switch (this) {
      case IncidentSeverity.critical:
        return 'red';
      case IncidentSeverity.high:
        return 'red';
      case IncidentSeverity.medium:
        return 'orange';
      case IncidentSeverity.low:
        return 'green';
      case IncidentSeverity.info:
        return 'blue';
    }
  }
}

/// Статусы инцидентов
enum IncidentStatus {
  open('open', 'Открыт'),
  acknowledged('acknowledged', 'Подтвержден'),
  investigating('investigating', 'Расследуется'),
  resolved('resolved', 'Решен'),
  closed('closed', 'Закрыт'),
  cancelled('cancelled', 'Отменен');

  const IncidentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static IncidentStatus fromString(String value) {
    return IncidentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => IncidentStatus.open,
    );
  }

  String get icon {
    switch (this) {
      case IncidentStatus.open:
        return '🔓';
      case IncidentStatus.acknowledged:
        return '👀';
      case IncidentStatus.investigating:
        return '🔍';
      case IncidentStatus.resolved:
        return '✅';
      case IncidentStatus.closed:
        return '🔒';
      case IncidentStatus.cancelled:
        return '❌';
    }
  }

  String get color {
    switch (this) {
      case IncidentStatus.open:
        return 'red';
      case IncidentStatus.acknowledged:
        return 'orange';
      case IncidentStatus.investigating:
        return 'blue';
      case IncidentStatus.resolved:
        return 'green';
      case IncidentStatus.closed:
        return 'grey';
      case IncidentStatus.cancelled:
        return 'grey';
    }
  }
}

/// Приоритеты инцидентов
enum IncidentPriority {
  p1('p1', 'P1 - Критический'),
  p2('p2', 'P2 - Высокий'),
  p3('p3', 'P3 - Средний'),
  p4('p4', 'P4 - Низкий'),
  p5('p5', 'P5 - Информационный');

  const IncidentPriority(this.value, this.displayName);

  final String value;
  final String displayName;

  static IncidentPriority fromString(String value) {
    return IncidentPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => IncidentPriority.p3,
    );
  }

  String get icon {
    switch (this) {
      case IncidentPriority.p1:
        return '🚨';
      case IncidentPriority.p2:
        return '🔴';
      case IncidentPriority.p3:
        return '🟡';
      case IncidentPriority.p4:
        return '🟢';
      case IncidentPriority.p5:
        return 'ℹ️';
    }
  }

  String get color {
    switch (this) {
      case IncidentPriority.p1:
        return 'red';
      case IncidentPriority.p2:
        return 'red';
      case IncidentPriority.p3:
        return 'orange';
      case IncidentPriority.p4:
        return 'green';
      case IncidentPriority.p5:
        return 'blue';
    }
  }
}

/// Модель для комментариев к инцидентам
class IncidentComment {
  final String id;
  final String incidentId;
  final String content;
  final String? parentId;
  final String authorId;
  final String authorName;
  final String? authorEmail;
  final CommentType type;
  final bool isInternal;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncidentComment({
    required this.id,
    required this.incidentId,
    required this.content,
    this.parentId,
    required this.authorId,
    required this.authorName,
    this.authorEmail,
    required this.type,
    required this.isInternal,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncidentComment.fromMap(Map<String, dynamic> map) {
    return IncidentComment(
      id: map['id'] ?? '',
      incidentId: map['incidentId'] ?? '',
      content: map['content'] ?? '',
      parentId: map['parentId'],
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorEmail: map['authorEmail'],
      type: CommentType.fromString(map['type'] ?? 'comment'),
      isInternal: map['isInternal'] ?? false,
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incidentId': incidentId,
      'content': content,
      'parentId': parentId,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'type': type.value,
      'isInternal': isInternal,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  IncidentComment copyWith({
    String? id,
    String? incidentId,
    String? content,
    String? parentId,
    String? authorId,
    String? authorName,
    String? authorEmail,
    CommentType? type,
    bool? isInternal,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncidentComment(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      type: type ?? this.type,
      isInternal: isInternal ?? this.isInternal,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'IncidentComment(id: $id, incidentId: $incidentId, authorName: $authorName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncidentComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы комментариев
enum CommentType {
  comment('comment', 'Комментарий'),
  update('update', 'Обновление'),
  resolution('resolution', 'Решение'),
  workaround('workaround', 'Обходное решение'),
  escalation('escalation', 'Эскалация'),
  notification('notification', 'Уведомление');

  const CommentType(this.value, this.displayName);

  final String value;
  final String displayName;

  static CommentType fromString(String value) {
    return CommentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CommentType.comment,
    );
  }

  String get icon {
    switch (this) {
      case CommentType.comment:
        return '💬';
      case CommentType.update:
        return '📝';
      case CommentType.resolution:
        return '✅';
      case CommentType.workaround:
        return '🔧';
      case CommentType.escalation:
        return '⬆️';
      case CommentType.notification:
        return '🔔';
    }
  }

  String get color {
    switch (this) {
      case CommentType.comment:
        return 'blue';
      case CommentType.update:
        return 'orange';
      case CommentType.resolution:
        return 'green';
      case CommentType.workaround:
        return 'purple';
      case CommentType.escalation:
        return 'red';
      case CommentType.notification:
        return 'teal';
    }
  }
}

/// Модель для SLA инцидентов
class IncidentSLA {
  final String id;
  final String incidentId;
  final SLAStatus status;
  final DateTime? acknowledgedDeadline;
  final DateTime? resolvedDeadline;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final bool acknowledgedOnTime;
  final bool resolvedOnTime;
  final String? breachReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncidentSLA({
    required this.id,
    required this.incidentId,
    required this.status,
    this.acknowledgedDeadline,
    this.resolvedDeadline,
    this.acknowledgedAt,
    this.resolvedAt,
    required this.acknowledgedOnTime,
    required this.resolvedOnTime,
    this.breachReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncidentSLA.fromMap(Map<String, dynamic> map) {
    return IncidentSLA(
      id: map['id'] ?? '',
      incidentId: map['incidentId'] ?? '',
      status: SLAStatus.fromString(map['status'] ?? 'active'),
      acknowledgedDeadline: map['acknowledgedDeadline'] != null
          ? (map['acknowledgedDeadline'] as Timestamp).toDate()
          : null,
      resolvedDeadline: map['resolvedDeadline'] != null
          ? (map['resolvedDeadline'] as Timestamp).toDate()
          : null,
      acknowledgedAt: map['acknowledgedAt'] != null
          ? (map['acknowledgedAt'] as Timestamp).toDate()
          : null,
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      acknowledgedOnTime: map['acknowledgedOnTime'] ?? true,
      resolvedOnTime: map['resolvedOnTime'] ?? true,
      breachReason: map['breachReason'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incidentId': incidentId,
      'status': status.value,
      'acknowledgedDeadline': acknowledgedDeadline != null
          ? Timestamp.fromDate(acknowledgedDeadline!)
          : null,
      'resolvedDeadline': resolvedDeadline != null
          ? Timestamp.fromDate(resolvedDeadline!)
          : null,
      'acknowledgedAt':
          acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'acknowledgedOnTime': acknowledgedOnTime,
      'resolvedOnTime': resolvedOnTime,
      'breachReason': breachReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  IncidentSLA copyWith({
    String? id,
    String? incidentId,
    SLAStatus? status,
    DateTime? acknowledgedDeadline,
    DateTime? resolvedDeadline,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    bool? acknowledgedOnTime,
    bool? resolvedOnTime,
    String? breachReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncidentSLA(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      status: status ?? this.status,
      acknowledgedDeadline: acknowledgedDeadline ?? this.acknowledgedDeadline,
      resolvedDeadline: resolvedDeadline ?? this.resolvedDeadline,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledgedOnTime: acknowledgedOnTime ?? this.acknowledgedOnTime,
      resolvedOnTime: resolvedOnTime ?? this.resolvedOnTime,
      breachReason: breachReason ?? this.breachReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'IncidentSLA(id: $id, incidentId: $incidentId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncidentSLA && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статусы SLA
enum SLAStatus {
  active('active', 'Активный'),
  breached('breached', 'Нарушен'),
  met('met', 'Выполнен'),
  cancelled('cancelled', 'Отменен');

  const SLAStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static SLAStatus fromString(String value) {
    return SLAStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SLAStatus.active,
    );
  }

  String get icon {
    switch (this) {
      case SLAStatus.active:
        return '⏱️';
      case SLAStatus.breached:
        return '🚨';
      case SLAStatus.met:
        return '✅';
      case SLAStatus.cancelled:
        return '❌';
    }
  }

  String get color {
    switch (this) {
      case SLAStatus.active:
        return 'blue';
      case SLAStatus.breached:
        return 'red';
      case SLAStatus.met:
        return 'green';
      case SLAStatus.cancelled:
        return 'grey';
    }
  }
}
