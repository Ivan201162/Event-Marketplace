import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для управления релизами
class Release {
  const Release({
    required this.id,
    required this.version,
    required this.name,
    this.description,
    required this.type,
    required this.status,
    this.branch,
    this.commitHash,
    required this.features,
    required this.bugFixes,
    required this.breakingChanges,
    required this.dependencies,
    required this.metadata,
    required this.tags,
    required this.isPreRelease,
    required this.isDraft,
    this.releaseNotes,
    this.downloadUrl,
    this.changelogUrl,
    this.scheduledDate,
    this.releasedDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory Release.fromMap(Map<String, dynamic> map) => Release(
        id: map['id'] as String? ?? '',
        version: map['version'] as String? ?? '',
        name: map['name'] as String? ?? '',
        description: map['description'] as String?,
        type: ReleaseType.fromString(map['type'] as String? ?? 'patch'),
        status: ReleaseStatus.fromString(map['status'] as String? ?? 'draft'),
        branch: map['branch'] as String?,
        commitHash: map['commitHash'] as String?,
        features: List<String>.from(map['features'] as List<dynamic>? ?? []),
        bugFixes: List<String>.from(map['bugFixes'] as List<dynamic>? ?? []),
        breakingChanges:
            List<String>.from(map['breakingChanges'] as List<dynamic>? ?? []),
        dependencies:
            List<String>.from(map['dependencies'] as List<dynamic>? ?? []),
        metadata: Map<String, dynamic>.from(
            map['metadata'] as Map<dynamic, dynamic>? ?? {}),
        tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
        isPreRelease: map['isPreRelease'] as bool? ?? false,
        isDraft: map['isDraft'] as bool? ?? true,
        releaseNotes: map['releaseNotes'],
        downloadUrl: map['downloadUrl'],
        changelogUrl: map['changelogUrl'],
        scheduledDate: map['scheduledDate'] != null
            ? (map['scheduledDate'] as Timestamp).toDate()
            : null,
        releasedDate: map['releasedDate'] != null
            ? (map['releasedDate'] as Timestamp).toDate()
            : null,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String version;
  final String name;
  final String? description;
  final ReleaseType type;
  final ReleaseStatus status;
  final String? branch;
  final String? commitHash;
  final List<String> features;
  final List<String> bugFixes;
  final List<String> breakingChanges;
  final List<String> dependencies;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final bool isPreRelease;
  final bool isDraft;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? changelogUrl;
  final DateTime? scheduledDate;
  final DateTime? releasedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'version': version,
        'name': name,
        'description': description,
        'type': type.value,
        'status': status.value,
        'branch': branch,
        'commitHash': commitHash,
        'features': features,
        'bugFixes': bugFixes,
        'breakingChanges': breakingChanges,
        'dependencies': dependencies,
        'metadata': metadata,
        'tags': tags,
        'isPreRelease': isPreRelease,
        'isDraft': isDraft,
        'releaseNotes': releaseNotes,
        'downloadUrl': downloadUrl,
        'changelogUrl': changelogUrl,
        'scheduledDate':
            scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
        'releasedDate':
            releasedDate != null ? Timestamp.fromDate(releasedDate!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  Release copyWith({
    String? id,
    String? version,
    String? name,
    String? description,
    ReleaseType? type,
    ReleaseStatus? status,
    String? branch,
    String? commitHash,
    List<String>? features,
    List<String>? bugFixes,
    List<String>? breakingChanges,
    List<String>? dependencies,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isPreRelease,
    bool? isDraft,
    String? releaseNotes,
    String? downloadUrl,
    String? changelogUrl,
    DateTime? scheduledDate,
    DateTime? releasedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      Release(
        id: id ?? this.id,
        version: version ?? this.version,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        status: status ?? this.status,
        branch: branch ?? this.branch,
        commitHash: commitHash ?? this.commitHash,
        features: features ?? this.features,
        bugFixes: bugFixes ?? this.bugFixes,
        breakingChanges: breakingChanges ?? this.breakingChanges,
        dependencies: dependencies ?? this.dependencies,
        metadata: metadata ?? this.metadata,
        tags: tags ?? this.tags,
        isPreRelease: isPreRelease ?? this.isPreRelease,
        isDraft: isDraft ?? this.isDraft,
        releaseNotes: releaseNotes ?? this.releaseNotes,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        changelogUrl: changelogUrl ?? this.changelogUrl,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        releasedDate: releasedDate ?? this.releasedDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'Release(id: $id, version: $version, name: $name, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Release && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы релизов
enum ReleaseType {
  major('major', 'Мажорный'),
  minor('minor', 'Минорный'),
  patch('patch', 'Патч'),
  hotfix('hotfix', 'Хотфикс'),
  alpha('alpha', 'Альфа'),
  beta('beta', 'Бета'),
  rc('rc', 'Release Candidate');

  const ReleaseType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ReleaseType fromString(String value) => ReleaseType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => ReleaseType.patch,
      );

  String get icon {
    switch (this) {
      case ReleaseType.major:
        return '🚀';
      case ReleaseType.minor:
        return '✨';
      case ReleaseType.patch:
        return '🔧';
      case ReleaseType.hotfix:
        return '🚨';
      case ReleaseType.alpha:
        return '🧪';
      case ReleaseType.beta:
        return '🔬';
      case ReleaseType.rc:
        return '🎯';
    }
  }

  String get color {
    switch (this) {
      case ReleaseType.major:
        return 'red';
      case ReleaseType.minor:
        return 'blue';
      case ReleaseType.patch:
        return 'green';
      case ReleaseType.hotfix:
        return 'orange';
      case ReleaseType.alpha:
        return 'purple';
      case ReleaseType.beta:
        return 'teal';
      case ReleaseType.rc:
        return 'indigo';
    }
  }
}

/// Статусы релизов
enum ReleaseStatus {
  draft('draft', 'Черновик'),
  scheduled('scheduled', 'Запланирован'),
  inProgress('inProgress', 'В процессе'),
  testing('testing', 'Тестирование'),
  ready('ready', 'Готов'),
  released('released', 'Выпущен'),
  cancelled('cancelled', 'Отменен'),
  failed('failed', 'Ошибка');

  const ReleaseStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static ReleaseStatus fromString(String value) =>
      ReleaseStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ReleaseStatus.draft,
      );

  String get icon {
    switch (this) {
      case ReleaseStatus.draft:
        return '📝';
      case ReleaseStatus.scheduled:
        return '📅';
      case ReleaseStatus.inProgress:
        return '⚙️';
      case ReleaseStatus.testing:
        return '🧪';
      case ReleaseStatus.ready:
        return '✅';
      case ReleaseStatus.released:
        return '🎉';
      case ReleaseStatus.cancelled:
        return '❌';
      case ReleaseStatus.failed:
        return '💥';
    }
  }

  String get color {
    switch (this) {
      case ReleaseStatus.draft:
        return 'grey';
      case ReleaseStatus.scheduled:
        return 'blue';
      case ReleaseStatus.inProgress:
        return 'orange';
      case ReleaseStatus.testing:
        return 'purple';
      case ReleaseStatus.ready:
        return 'green';
      case ReleaseStatus.released:
        return 'green';
      case ReleaseStatus.cancelled:
        return 'red';
      case ReleaseStatus.failed:
        return 'red';
    }
  }
}

/// Модель для плана релиза
class ReleasePlan {
  const ReleasePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.type,
    required this.releaseIds,
    required this.milestones,
    required this.requirements,
    this.targetDate,
    this.actualDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory ReleasePlan.fromMap(Map<String, dynamic> map) => ReleasePlan(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        version: map['version'] ?? '',
        type: ReleaseType.fromString(map['type'] ?? 'patch'),
        releaseIds: List<String>.from(map['releaseIds'] ?? []),
        milestones: List<String>.from(map['milestones'] ?? []),
        requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
        targetDate: map['targetDate'] != null
            ? (map['targetDate'] as Timestamp).toDate()
            : null,
        actualDate: map['actualDate'] != null
            ? (map['actualDate'] as Timestamp).toDate()
            : null,
        status: PlanStatus.fromString(map['status'] ?? 'draft'),
        notes: map['notes'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String name;
  final String description;
  final String version;
  final ReleaseType type;
  final List<String> releaseIds;
  final List<String> milestones;
  final Map<String, dynamic> requirements;
  final DateTime? targetDate;
  final DateTime? actualDate;
  final PlanStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'version': version,
        'type': type.value,
        'releaseIds': releaseIds,
        'milestones': milestones,
        'requirements': requirements,
        'targetDate':
            targetDate != null ? Timestamp.fromDate(targetDate!) : null,
        'actualDate':
            actualDate != null ? Timestamp.fromDate(actualDate!) : null,
        'status': status.value,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  ReleasePlan copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    ReleaseType? type,
    List<String>? releaseIds,
    List<String>? milestones,
    Map<String, dynamic>? requirements,
    DateTime? targetDate,
    DateTime? actualDate,
    PlanStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      ReleasePlan(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        version: version ?? this.version,
        type: type ?? this.type,
        releaseIds: releaseIds ?? this.releaseIds,
        milestones: milestones ?? this.milestones,
        requirements: requirements ?? this.requirements,
        targetDate: targetDate ?? this.targetDate,
        actualDate: actualDate ?? this.actualDate,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'ReleasePlan(id: $id, name: $name, version: $version, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReleasePlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статусы планов
enum PlanStatus {
  draft('draft', 'Черновик'),
  active('active', 'Активный'),
  completed('completed', 'Завершен'),
  cancelled('cancelled', 'Отменен'),
  onHold('onHold', 'Приостановлен');

  const PlanStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static PlanStatus fromString(String value) => PlanStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => PlanStatus.draft,
      );

  String get icon {
    switch (this) {
      case PlanStatus.draft:
        return '📝';
      case PlanStatus.active:
        return '🔄';
      case PlanStatus.completed:
        return '✅';
      case PlanStatus.cancelled:
        return '❌';
      case PlanStatus.onHold:
        return '⏸️';
    }
  }

  String get color {
    switch (this) {
      case PlanStatus.draft:
        return 'grey';
      case PlanStatus.active:
        return 'blue';
      case PlanStatus.completed:
        return 'green';
      case PlanStatus.cancelled:
        return 'red';
      case PlanStatus.onHold:
        return 'orange';
    }
  }
}

/// Модель для деплоя
class Deployment {
  const Deployment({
    required this.id,
    required this.releaseId,
    required this.environment,
    required this.status,
    this.buildUrl,
    this.deployUrl,
    required this.config,
    required this.logs,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory Deployment.fromMap(Map<String, dynamic> map) => Deployment(
        id: map['id'] ?? '',
        releaseId: map['releaseId'] ?? '',
        environment: map['environment'] ?? '',
        status: DeploymentStatus.fromString(map['status'] ?? 'pending'),
        buildUrl: map['buildUrl'],
        deployUrl: map['deployUrl'],
        config: Map<String, dynamic>.from(map['config'] ?? {}),
        logs: List<String>.from(map['logs'] ?? []),
        startedAt: map['startedAt'] != null
            ? (map['startedAt'] as Timestamp).toDate()
            : null,
        completedAt: map['completedAt'] != null
            ? (map['completedAt'] as Timestamp).toDate()
            : null,
        errorMessage: map['errorMessage'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String releaseId;
  final String environment;
  final DeploymentStatus status;
  final String? buildUrl;
  final String? deployUrl;
  final Map<String, dynamic> config;
  final List<String> logs;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'releaseId': releaseId,
        'environment': environment,
        'status': status.value,
        'buildUrl': buildUrl,
        'deployUrl': deployUrl,
        'config': config,
        'logs': logs,
        'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'errorMessage': errorMessage,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  Deployment copyWith({
    String? id,
    String? releaseId,
    String? environment,
    DeploymentStatus? status,
    String? buildUrl,
    String? deployUrl,
    Map<String, dynamic>? config,
    List<String>? logs,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      Deployment(
        id: id ?? this.id,
        releaseId: releaseId ?? this.releaseId,
        environment: environment ?? this.environment,
        status: status ?? this.status,
        buildUrl: buildUrl ?? this.buildUrl,
        deployUrl: deployUrl ?? this.deployUrl,
        config: config ?? this.config,
        logs: logs ?? this.logs,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'Deployment(id: $id, releaseId: $releaseId, environment: $environment, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deployment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статусы деплоя
enum DeploymentStatus {
  pending('pending', 'Ожидает'),
  inProgress('inProgress', 'В процессе'),
  completed('completed', 'Завершен'),
  failed('failed', 'Ошибка'),
  cancelled('cancelled', 'Отменен'),
  rolledBack('rolledBack', 'Откачен');

  const DeploymentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static DeploymentStatus fromString(String value) =>
      DeploymentStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => DeploymentStatus.pending,
      );

  String get icon {
    switch (this) {
      case DeploymentStatus.pending:
        return '⏳';
      case DeploymentStatus.inProgress:
        return '⚙️';
      case DeploymentStatus.completed:
        return '✅';
      case DeploymentStatus.failed:
        return '❌';
      case DeploymentStatus.cancelled:
        return '🚫';
      case DeploymentStatus.rolledBack:
        return '↩️';
    }
  }

  String get color {
    switch (this) {
      case DeploymentStatus.pending:
        return 'grey';
      case DeploymentStatus.inProgress:
        return 'blue';
      case DeploymentStatus.completed:
        return 'green';
      case DeploymentStatus.failed:
        return 'red';
      case DeploymentStatus.cancelled:
        return 'orange';
      case DeploymentStatus.rolledBack:
        return 'purple';
    }
  }
}
