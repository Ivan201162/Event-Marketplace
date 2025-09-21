import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для управления зависимостями
class Dependency {
  const Dependency({
    required this.id,
    required this.name,
    required this.version,
    this.latestVersion,
    required this.type,
    required this.status,
    this.description,
    this.repositoryUrl,
    this.documentationUrl,
    required this.licenses,
    required this.authors,
    required this.metadata,
    required this.dependencies,
    required this.dependents,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory Dependency.fromMap(Map<String, dynamic> map) => Dependency(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        version: map['version'] as String? ?? '',
        latestVersion: map['latestVersion'] as String?,
        type: DependencyType.fromString(map['type'] as String? ?? 'package'),
        status: DependencyStatus.fromString(map['status'] as String? ?? 'active'),
        description: map['description'],
        repositoryUrl: map['repositoryUrl'],
        documentationUrl: map['documentationUrl'],
        licenses: List<String>.from(map['licenses'] ?? []),
        authors: List<String>.from(map['authors'] ?? []),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        dependencies: List<String>.from(map['dependencies'] ?? []),
        dependents: List<String>.from(map['dependents'] ?? []),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String name;
  final String version;
  final String? latestVersion;
  final DependencyType type;
  final DependencyStatus status;
  final String? description;
  final String? repositoryUrl;
  final String? documentationUrl;
  final List<String> licenses;
  final List<String> authors;
  final Map<String, dynamic> metadata;
  final List<String> dependencies;
  final List<String> dependents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'version': version,
        'latestVersion': latestVersion,
        'type': type.value,
        'status': status.value,
        'description': description,
        'repositoryUrl': repositoryUrl,
        'documentationUrl': documentationUrl,
        'licenses': licenses,
        'authors': authors,
        'metadata': metadata,
        'dependencies': dependencies,
        'dependents': dependents,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  Dependency copyWith({
    String? id,
    String? name,
    String? version,
    String? latestVersion,
    DependencyType? type,
    DependencyStatus? status,
    String? description,
    String? repositoryUrl,
    String? documentationUrl,
    List<String>? licenses,
    List<String>? authors,
    Map<String, dynamic>? metadata,
    List<String>? dependencies,
    List<String>? dependents,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      Dependency(
        id: id ?? this.id,
        name: name ?? this.name,
        version: version ?? this.version,
        latestVersion: latestVersion ?? this.latestVersion,
        type: type ?? this.type,
        status: status ?? this.status,
        description: description ?? this.description,
        repositoryUrl: repositoryUrl ?? this.repositoryUrl,
        documentationUrl: documentationUrl ?? this.documentationUrl,
        licenses: licenses ?? this.licenses,
        authors: authors ?? this.authors,
        metadata: metadata ?? this.metadata,
        dependencies: dependencies ?? this.dependencies,
        dependents: dependents ?? this.dependents,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'Dependency(id: $id, name: $name, version: $version, type: $type, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dependency && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы зависимостей
enum DependencyType {
  package('package', 'Пакет'),
  library('library', 'Библиотека'),
  framework('framework', 'Фреймворк'),
  tool('tool', 'Инструмент'),
  service('service', 'Сервис'),
  api('api', 'API'),
  database('database', 'База данных'),
  cache('cache', 'Кэш'),
  queue('queue', 'Очередь'),
  storage('storage', 'Хранилище');

  const DependencyType(this.value, this.displayName);

  final String value;
  final String displayName;

  static DependencyType fromString(String value) =>
      DependencyType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => DependencyType.package,
      );

  String get icon {
    switch (this) {
      case DependencyType.package:
        return '📦';
      case DependencyType.library:
        return '📚';
      case DependencyType.framework:
        return '🏗️';
      case DependencyType.tool:
        return '🔧';
      case DependencyType.service:
        return '⚙️';
      case DependencyType.api:
        return '🔌';
      case DependencyType.database:
        return '🗄️';
      case DependencyType.cache:
        return '💾';
      case DependencyType.queue:
        return '📋';
      case DependencyType.storage:
        return '💿';
    }
  }

  String get color {
    switch (this) {
      case DependencyType.package:
        return 'blue';
      case DependencyType.library:
        return 'green';
      case DependencyType.framework:
        return 'purple';
      case DependencyType.tool:
        return 'orange';
      case DependencyType.service:
        return 'teal';
      case DependencyType.api:
        return 'cyan';
      case DependencyType.database:
        return 'brown';
      case DependencyType.cache:
        return 'indigo';
      case DependencyType.queue:
        return 'pink';
      case DependencyType.storage:
        return 'grey';
    }
  }
}

/// Статусы зависимостей
enum DependencyStatus {
  active('active', 'Активна'),
  deprecated('deprecated', 'Устарела'),
  vulnerable('vulnerable', 'Уязвима'),
  outdated('outdated', 'Устарела'),
  blocked('blocked', 'Заблокирована'),
  testing('testing', 'Тестируется'),
  maintenance('maintenance', 'Обслуживание');

  const DependencyStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static DependencyStatus fromString(String value) =>
      DependencyStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => DependencyStatus.active,
      );

  String get icon {
    switch (this) {
      case DependencyStatus.active:
        return '✅';
      case DependencyStatus.deprecated:
        return '⚠️';
      case DependencyStatus.vulnerable:
        return '🚨';
      case DependencyStatus.outdated:
        return '🔄';
      case DependencyStatus.blocked:
        return '🚫';
      case DependencyStatus.testing:
        return '🧪';
      case DependencyStatus.maintenance:
        return '🔧';
    }
  }

  String get color {
    switch (this) {
      case DependencyStatus.active:
        return 'green';
      case DependencyStatus.deprecated:
        return 'orange';
      case DependencyStatus.vulnerable:
        return 'red';
      case DependencyStatus.outdated:
        return 'yellow';
      case DependencyStatus.blocked:
        return 'red';
      case DependencyStatus.testing:
        return 'blue';
      case DependencyStatus.maintenance:
        return 'purple';
    }
  }
}

/// Модель для обновления зависимостей
class DependencyUpdate {
  const DependencyUpdate({
    required this.id,
    required this.dependencyId,
    required this.currentVersion,
    required this.newVersion,
    required this.type,
    required this.priority,
    this.changelog,
    required this.breakingChanges,
    required this.securityFixes,
    required this.bugFixes,
    required this.newFeatures,
    required this.metadata,
    required this.releaseDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory DependencyUpdate.fromMap(Map<String, dynamic> map) =>
      DependencyUpdate(
        id: map['id'] ?? '',
        dependencyId: map['dependencyId'] ?? '',
        currentVersion: map['currentVersion'] ?? '',
        newVersion: map['newVersion'] ?? '',
        type: UpdateType.fromString(map['type'] ?? 'minor'),
        priority: UpdatePriority.fromString(map['priority'] ?? 'medium'),
        changelog: map['changelog'],
        breakingChanges: List<String>.from(map['breakingChanges'] ?? []),
        securityFixes: List<String>.from(map['securityFixes'] ?? []),
        bugFixes: List<String>.from(map['bugFixes'] ?? []),
        newFeatures: List<String>.from(map['newFeatures'] ?? []),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        releaseDate: (map['releaseDate'] as Timestamp).toDate(),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String dependencyId;
  final String currentVersion;
  final String newVersion;
  final UpdateType type;
  final UpdatePriority priority;
  final String? changelog;
  final List<String> breakingChanges;
  final List<String> securityFixes;
  final List<String> bugFixes;
  final List<String> newFeatures;
  final Map<String, dynamic> metadata;
  final DateTime releaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'dependencyId': dependencyId,
        'currentVersion': currentVersion,
        'newVersion': newVersion,
        'type': type.value,
        'priority': priority.value,
        'changelog': changelog,
        'breakingChanges': breakingChanges,
        'securityFixes': securityFixes,
        'bugFixes': bugFixes,
        'newFeatures': newFeatures,
        'metadata': metadata,
        'releaseDate': Timestamp.fromDate(releaseDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  DependencyUpdate copyWith({
    String? id,
    String? dependencyId,
    String? currentVersion,
    String? newVersion,
    UpdateType? type,
    UpdatePriority? priority,
    String? changelog,
    List<String>? breakingChanges,
    List<String>? securityFixes,
    List<String>? bugFixes,
    List<String>? newFeatures,
    Map<String, dynamic>? metadata,
    DateTime? releaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      DependencyUpdate(
        id: id ?? this.id,
        dependencyId: dependencyId ?? this.dependencyId,
        currentVersion: currentVersion ?? this.currentVersion,
        newVersion: newVersion ?? this.newVersion,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        changelog: changelog ?? this.changelog,
        breakingChanges: breakingChanges ?? this.breakingChanges,
        securityFixes: securityFixes ?? this.securityFixes,
        bugFixes: bugFixes ?? this.bugFixes,
        newFeatures: newFeatures ?? this.newFeatures,
        metadata: metadata ?? this.metadata,
        releaseDate: releaseDate ?? this.releaseDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'DependencyUpdate(id: $id, dependencyId: $dependencyId, currentVersion: $currentVersion, newVersion: $newVersion, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DependencyUpdate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы обновлений
enum UpdateType {
  patch('patch', 'Патч'),
  minor('minor', 'Минорное'),
  major('major', 'Мажорное'),
  breaking('breaking', 'Критическое');

  const UpdateType(this.value, this.displayName);

  final String value;
  final String displayName;

  static UpdateType fromString(String value) => UpdateType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => UpdateType.minor,
      );

  String get icon {
    switch (this) {
      case UpdateType.patch:
        return '🔧';
      case UpdateType.minor:
        return '🔄';
      case UpdateType.major:
        return '🚀';
      case UpdateType.breaking:
        return '💥';
    }
  }

  String get color {
    switch (this) {
      case UpdateType.patch:
        return 'green';
      case UpdateType.minor:
        return 'blue';
      case UpdateType.major:
        return 'purple';
      case UpdateType.breaking:
        return 'red';
    }
  }
}

/// Приоритеты обновлений
enum UpdatePriority {
  low('low', 'Низкий'),
  medium('medium', 'Средний'),
  high('high', 'Высокий'),
  critical('critical', 'Критический');

  const UpdatePriority(this.value, this.displayName);

  final String value;
  final String displayName;

  static UpdatePriority fromString(String value) =>
      UpdatePriority.values.firstWhere(
        (priority) => priority.value == value,
        orElse: () => UpdatePriority.medium,
      );

  String get icon {
    switch (this) {
      case UpdatePriority.low:
        return '🟢';
      case UpdatePriority.medium:
        return '🟡';
      case UpdatePriority.high:
        return '🟠';
      case UpdatePriority.critical:
        return '🔴';
    }
  }

  String get color {
    switch (this) {
      case UpdatePriority.low:
        return 'green';
      case UpdatePriority.medium:
        return 'yellow';
      case UpdatePriority.high:
        return 'orange';
      case UpdatePriority.critical:
        return 'red';
    }
  }
}

/// Модель для конфигурации управления зависимостями
class DependencyConfig {
  const DependencyConfig({
    required this.id,
    required this.enableAutoUpdates,
    required this.enableSecurityUpdates,
    required this.enableBreakingChangeNotifications,
    required this.allowedUpdateTypes,
    required this.allowedPriorities,
    required this.maxConcurrentUpdates,
    required this.updateRetryAttempts,
    required this.updateTimeout,
    required this.excludedDependencies,
    required this.requiredApprovals,
    required this.updatePolicies,
    required this.notificationSettings,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory DependencyConfig.fromMap(Map<String, dynamic> map) =>
      DependencyConfig(
        id: map['id'] ?? '',
        enableAutoUpdates: map['enableAutoUpdates'] ?? false,
        enableSecurityUpdates: map['enableSecurityUpdates'] ?? true,
        enableBreakingChangeNotifications:
            map['enableBreakingChangeNotifications'] ?? true,
        allowedUpdateTypes: (map['allowedUpdateTypes'] as List<dynamic>?)
                ?.map((e) => UpdateType.fromString(e as String))
                .toList() ??
            UpdateType.values,
        allowedPriorities: (map['allowedPriorities'] as List<dynamic>?)
                ?.map((e) => UpdatePriority.fromString(e as String))
                .toList() ??
            UpdatePriority.values,
        maxConcurrentUpdates: map['maxConcurrentUpdates'] ?? 3,
        updateRetryAttempts: map['updateRetryAttempts'] ?? 3,
        updateTimeout: Duration(seconds: map['updateTimeoutSeconds'] ?? 300),
        excludedDependencies:
            List<String>.from(map['excludedDependencies'] ?? []),
        requiredApprovals: List<String>.from(map['requiredApprovals'] ?? []),
        updatePolicies: Map<String, dynamic>.from(map['updatePolicies'] ?? {}),
        notificationSettings:
            Map<String, dynamic>.from(map['notificationSettings'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final bool enableAutoUpdates;
  final bool enableSecurityUpdates;
  final bool enableBreakingChangeNotifications;
  final List<UpdateType> allowedUpdateTypes;
  final List<UpdatePriority> allowedPriorities;
  final int maxConcurrentUpdates;
  final int updateRetryAttempts;
  final Duration updateTimeout;
  final List<String> excludedDependencies;
  final List<String> requiredApprovals;
  final Map<String, dynamic> updatePolicies;
  final Map<String, dynamic> notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'enableAutoUpdates': enableAutoUpdates,
        'enableSecurityUpdates': enableSecurityUpdates,
        'enableBreakingChangeNotifications': enableBreakingChangeNotifications,
        'allowedUpdateTypes': allowedUpdateTypes.map((e) => e.value).toList(),
        'allowedPriorities': allowedPriorities.map((e) => e.value).toList(),
        'maxConcurrentUpdates': maxConcurrentUpdates,
        'updateRetryAttempts': updateRetryAttempts,
        'updateTimeoutSeconds': updateTimeout.inSeconds,
        'excludedDependencies': excludedDependencies,
        'requiredApprovals': requiredApprovals,
        'updatePolicies': updatePolicies,
        'notificationSettings': notificationSettings,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  DependencyConfig copyWith({
    String? id,
    bool? enableAutoUpdates,
    bool? enableSecurityUpdates,
    bool? enableBreakingChangeNotifications,
    List<UpdateType>? allowedUpdateTypes,
    List<UpdatePriority>? allowedPriorities,
    int? maxConcurrentUpdates,
    int? updateRetryAttempts,
    Duration? updateTimeout,
    List<String>? excludedDependencies,
    List<String>? requiredApprovals,
    Map<String, dynamic>? updatePolicies,
    Map<String, dynamic>? notificationSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      DependencyConfig(
        id: id ?? this.id,
        enableAutoUpdates: enableAutoUpdates ?? this.enableAutoUpdates,
        enableSecurityUpdates:
            enableSecurityUpdates ?? this.enableSecurityUpdates,
        enableBreakingChangeNotifications: enableBreakingChangeNotifications ??
            this.enableBreakingChangeNotifications,
        allowedUpdateTypes: allowedUpdateTypes ?? this.allowedUpdateTypes,
        allowedPriorities: allowedPriorities ?? this.allowedPriorities,
        maxConcurrentUpdates: maxConcurrentUpdates ?? this.maxConcurrentUpdates,
        updateRetryAttempts: updateRetryAttempts ?? this.updateRetryAttempts,
        updateTimeout: updateTimeout ?? this.updateTimeout,
        excludedDependencies: excludedDependencies ?? this.excludedDependencies,
        requiredApprovals: requiredApprovals ?? this.requiredApprovals,
        updatePolicies: updatePolicies ?? this.updatePolicies,
        notificationSettings: notificationSettings ?? this.notificationSettings,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'DependencyConfig(id: $id, enableAutoUpdates: $enableAutoUpdates, enableSecurityUpdates: $enableSecurityUpdates)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DependencyConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
