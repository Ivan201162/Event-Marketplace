import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель версии приложения
class AppVersion {
  const AppVersion({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.type,
    this.description,
    this.features = const [],
    this.bugFixes = const [],
    this.breakingChanges = const [],
    this.isForced = false,
    this.isAvailable = true,
    this.downloadUrl,
    this.releaseNotes,
    required this.releaseDate,
    this.expirationDate,
    this.metadata = const {},
    this.createdBy,
  });

  /// Создать из документа Firestore
  factory AppVersion.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppVersion(
      id: doc.id,
      version: data['version'] as String? ?? '',
      buildNumber: data['buildNumber'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      type: VersionType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] as String?),
        orElse: () => VersionType.release,
      ),
      description: data['description'] as String?,
      features: List<String>.from(data['features'] as List<dynamic>? ?? []),
      bugFixes: List<String>.from(data['bugFixes'] as List<dynamic>? ?? []),
      breakingChanges:
          List<String>.from(data['breakingChanges'] as List<dynamic>? ?? []),
      isForced: data['isForced'] as bool? ?? false,
      isAvailable: data['isAvailable'] as bool? ?? true,
      downloadUrl: data['downloadUrl'] as String?,
      releaseNotes: data['releaseNotes'] as String?,
      releaseDate: (data['releaseDate'] as Timestamp).toDate(),
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdBy: data['createdBy'],
    );
  }

  /// Создать из Map
  factory AppVersion.fromMap(Map<String, dynamic> data) => AppVersion(
        id: data['id'] ?? '',
        version: data['version'] ?? '',
        buildNumber: data['buildNumber'] ?? '',
        platform: data['platform'] ?? '',
        type: VersionType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => VersionType.release,
        ),
        description: data['description'],
        features: List<String>.from(data['features'] ?? []),
        bugFixes: List<String>.from(data['bugFixes'] ?? []),
        breakingChanges: List<String>.from(data['breakingChanges'] ?? []),
        isForced: data['isForced'] ?? false,
        isAvailable: data['isAvailable'] ?? true,
        downloadUrl: data['downloadUrl'],
        releaseNotes: data['releaseNotes'],
        releaseDate: (data['releaseDate'] as Timestamp).toDate(),
        expirationDate: data['expirationDate'] != null
            ? (data['expirationDate'] as Timestamp).toDate()
            : null,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        createdBy: data['createdBy'],
      );
  final String id;
  final String version;
  final String buildNumber;
  final String platform;
  final VersionType type;
  final String? description;
  final List<String> features;
  final List<String> bugFixes;
  final List<String> breakingChanges;
  final bool isForced;
  final bool isAvailable;
  final String? downloadUrl;
  final String? releaseNotes;
  final DateTime releaseDate;
  final DateTime? expirationDate;
  final Map<String, dynamic> metadata;
  final String? createdBy;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'version': version,
        'buildNumber': buildNumber,
        'platform': platform,
        'type': type.toString().split('.').last,
        'description': description,
        'features': features,
        'bugFixes': bugFixes,
        'breakingChanges': breakingChanges,
        'isForced': isForced,
        'isAvailable': isAvailable,
        'downloadUrl': downloadUrl,
        'releaseNotes': releaseNotes,
        'releaseDate': Timestamp.fromDate(releaseDate),
        'expirationDate':
            expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
        'metadata': metadata,
        'createdBy': createdBy,
      };

  /// Создать копию с изменениями
  AppVersion copyWith({
    String? id,
    String? version,
    String? buildNumber,
    String? platform,
    VersionType? type,
    String? description,
    List<String>? features,
    List<String>? bugFixes,
    List<String>? breakingChanges,
    bool? isForced,
    bool? isAvailable,
    String? downloadUrl,
    String? releaseNotes,
    DateTime? releaseDate,
    DateTime? expirationDate,
    Map<String, dynamic>? metadata,
    String? createdBy,
  }) =>
      AppVersion(
        id: id ?? this.id,
        version: version ?? this.version,
        buildNumber: buildNumber ?? this.buildNumber,
        platform: platform ?? this.platform,
        type: type ?? this.type,
        description: description ?? this.description,
        features: features ?? this.features,
        bugFixes: bugFixes ?? this.bugFixes,
        breakingChanges: breakingChanges ?? this.breakingChanges,
        isForced: isForced ?? this.isForced,
        isAvailable: isAvailable ?? this.isAvailable,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        releaseNotes: releaseNotes ?? this.releaseNotes,
        releaseDate: releaseDate ?? this.releaseDate,
        expirationDate: expirationDate ?? this.expirationDate,
        metadata: metadata ?? this.metadata,
        createdBy: createdBy ?? this.createdBy,
      );

  /// Проверить, является ли версия принудительной
  bool get isForcedUpdate => isForced;

  /// Проверить, доступна ли версия
  bool get isCurrentlyAvailable =>
      isAvailable &&
      (expirationDate == null || DateTime.now().isBefore(expirationDate!));

  /// Проверить, является ли версия критической
  bool get isCritical => type == VersionType.critical || isForced;

  /// Получить полный номер версии
  String get fullVersion => '$version ($buildNumber)';

  /// Получить краткое описание изменений
  String get shortDescription {
    final changes = <String>[];
    if (features.isNotEmpty) changes.add('${features.length} новых функций');
    if (bugFixes.isNotEmpty) changes.add('${bugFixes.length} исправлений');
    if (breakingChanges.isNotEmpty) {
      changes.add('${breakingChanges.length} критических изменений');
    }
    return changes.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppVersion &&
        other.id == id &&
        other.version == version &&
        other.buildNumber == buildNumber &&
        other.platform == platform &&
        other.type == type &&
        other.description == description &&
        other.features == features &&
        other.bugFixes == bugFixes &&
        other.breakingChanges == breakingChanges &&
        other.isForced == isForced &&
        other.isAvailable == isAvailable &&
        other.downloadUrl == downloadUrl &&
        other.releaseNotes == releaseNotes &&
        other.releaseDate == releaseDate &&
        other.expirationDate == expirationDate &&
        other.metadata == metadata &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        version,
        buildNumber,
        platform,
        type,
        description,
        features,
        bugFixes,
        breakingChanges,
        isForced,
        isAvailable,
        downloadUrl,
        releaseNotes,
        releaseDate,
        expirationDate,
        metadata,
        createdBy,
      );

  @override
  String toString() =>
      'AppVersion(id: $id, version: $version, platform: $platform, type: $type)';
}

/// Модель обновления приложения
class AppUpdate {
  const AppUpdate({
    required this.id,
    required this.currentVersion,
    required this.targetVersion,
    required this.platform,
    this.status = UpdateStatus.pending,
    this.errorMessage,
    this.progress = 0.0,
    required this.startedAt,
    this.completedAt,
    this.userId,
    this.deviceId,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory AppUpdate.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppUpdate(
      id: doc.id,
      currentVersion: data['currentVersion'] ?? '',
      targetVersion: data['targetVersion'] ?? '',
      platform: data['platform'] ?? '',
      status: UpdateStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => UpdateStatus.pending,
      ),
      errorMessage: data['errorMessage'],
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      userId: data['userId'],
      deviceId: data['deviceId'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из Map
  factory AppUpdate.fromMap(Map<String, dynamic> data) => AppUpdate(
        id: data['id'] ?? '',
        currentVersion: data['currentVersion'] ?? '',
        targetVersion: data['targetVersion'] ?? '',
        platform: data['platform'] ?? '',
        status: UpdateStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => UpdateStatus.pending,
        ),
        errorMessage: data['errorMessage'],
        progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
        startedAt: (data['startedAt'] as Timestamp).toDate(),
        completedAt: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
        userId: data['userId'],
        deviceId: data['deviceId'],
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
  final String id;
  final String currentVersion;
  final String targetVersion;
  final String platform;
  final UpdateStatus status;
  final String? errorMessage;
  final double progress;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? userId;
  final String? deviceId;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'currentVersion': currentVersion,
        'targetVersion': targetVersion,
        'platform': platform,
        'status': status.toString().split('.').last,
        'errorMessage': errorMessage,
        'progress': progress,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'userId': userId,
        'deviceId': deviceId,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  AppUpdate copyWith({
    String? id,
    String? currentVersion,
    String? targetVersion,
    String? platform,
    UpdateStatus? status,
    String? errorMessage,
    double? progress,
    DateTime? startedAt,
    DateTime? completedAt,
    String? userId,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) =>
      AppUpdate(
        id: id ?? this.id,
        currentVersion: currentVersion ?? this.currentVersion,
        targetVersion: targetVersion ?? this.targetVersion,
        platform: platform ?? this.platform,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        progress: progress ?? this.progress,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        userId: userId ?? this.userId,
        deviceId: deviceId ?? this.deviceId,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, завершено ли обновление
  bool get isCompleted => status == UpdateStatus.completed;

  /// Проверить, есть ли ошибка
  bool get hasError => status == UpdateStatus.failed;

  /// Проверить, выполняется ли обновление
  bool get isInProgress => status == UpdateStatus.inProgress;

  /// Получить продолжительность обновления
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUpdate &&
        other.id == id &&
        other.currentVersion == currentVersion &&
        other.targetVersion == targetVersion &&
        other.platform == platform &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.progress == progress &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.userId == userId &&
        other.deviceId == deviceId &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        currentVersion,
        targetVersion,
        platform,
        status,
        errorMessage,
        progress,
        startedAt,
        completedAt,
        userId,
        deviceId,
        metadata,
      );

  @override
  String toString() =>
      'AppUpdate(id: $id, currentVersion: $currentVersion, targetVersion: $targetVersion, status: $status)';
}

/// Модель статистики версий
class VersionStatistics {
  const VersionStatistics({
    required this.version,
    required this.platform,
    required this.totalUsers,
    required this.activeUsers,
    required this.crashCount,
    required this.crashRate,
    required this.averageSessionDuration,
    required this.totalSessions,
    required this.lastUpdated,
  });

  /// Создать из документа Firestore
  factory VersionStatistics.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return VersionStatistics(
      version: data['version'] ?? '',
      platform: data['platform'] ?? '',
      totalUsers: data['totalUsers'] ?? 0,
      activeUsers: data['activeUsers'] ?? 0,
      crashCount: data['crashCount'] ?? 0,
      crashRate: (data['crashRate'] as num?)?.toDouble() ?? 0.0,
      averageSessionDuration:
          (data['averageSessionDuration'] as num?)?.toDouble() ?? 0.0,
      totalSessions: data['totalSessions'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory VersionStatistics.fromMap(Map<String, dynamic> data) =>
      VersionStatistics(
        version: data['version'] ?? '',
        platform: data['platform'] ?? '',
        totalUsers: data['totalUsers'] ?? 0,
        activeUsers: data['activeUsers'] ?? 0,
        crashCount: data['crashCount'] ?? 0,
        crashRate: (data['crashRate'] as num?)?.toDouble() ?? 0.0,
        averageSessionDuration:
            (data['averageSessionDuration'] as num?)?.toDouble() ?? 0.0,
        totalSessions: data['totalSessions'] ?? 0,
        lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      );
  final String version;
  final String platform;
  final int totalUsers;
  final int activeUsers;
  final int crashCount;
  final double crashRate;
  final double averageSessionDuration;
  final int totalSessions;
  final DateTime lastUpdated;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'version': version,
        'platform': platform,
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'crashCount': crashCount,
        'crashRate': crashRate,
        'averageSessionDuration': averageSessionDuration,
        'totalSessions': totalSessions,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  /// Получить процент активных пользователей
  double get activeUserPercentage {
    if (totalUsers == 0) return 0;
    return (activeUsers / totalUsers) * 100;
  }

  /// Получить среднее время сессии в читаемом формате
  String get formattedSessionDuration {
    final minutes = (averageSessionDuration / 60).round();
    if (minutes < 60) {
      return '$minutesм';
    }
    final hours = (minutes / 60).round();
    return '$hoursч ${minutes % 60}м';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VersionStatistics &&
        other.version == version &&
        other.platform == platform &&
        other.totalUsers == totalUsers &&
        other.activeUsers == activeUsers &&
        other.crashCount == crashCount &&
        other.crashRate == crashRate &&
        other.averageSessionDuration == averageSessionDuration &&
        other.totalSessions == totalSessions &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(
        version,
        platform,
        totalUsers,
        activeUsers,
        crashCount,
        crashRate,
        averageSessionDuration,
        totalSessions,
        lastUpdated,
      );

  @override
  String toString() =>
      'VersionStatistics(version: $version, platform: $platform, totalUsers: $totalUsers)';
}

/// Типы версий
enum VersionType {
  development,
  beta,
  release,
  critical,
  hotfix,
}

/// Расширение для типов версий
extension VersionTypeExtension on VersionType {
  String get displayName {
    switch (this) {
      case VersionType.development:
        return 'Разработка';
      case VersionType.beta:
        return 'Бета';
      case VersionType.release:
        return 'Релиз';
      case VersionType.critical:
        return 'Критическая';
      case VersionType.hotfix:
        return 'Горячее исправление';
    }
  }

  String get description {
    switch (this) {
      case VersionType.development:
        return 'Версия в разработке';
      case VersionType.beta:
        return 'Бета-версия для тестирования';
      case VersionType.release:
        return 'Стабильная релизная версия';
      case VersionType.critical:
        return 'Критическое обновление безопасности';
      case VersionType.hotfix:
        return 'Быстрое исправление критических ошибок';
    }
  }

  String get color {
    switch (this) {
      case VersionType.development:
        return 'orange';
      case VersionType.beta:
        return 'blue';
      case VersionType.release:
        return 'green';
      case VersionType.critical:
        return 'red';
      case VersionType.hotfix:
        return 'purple';
    }
  }

  String get icon {
    switch (this) {
      case VersionType.development:
        return '🔧';
      case VersionType.beta:
        return '🧪';
      case VersionType.release:
        return '✅';
      case VersionType.critical:
        return '🚨';
      case VersionType.hotfix:
        return '🔨';
    }
  }
}

/// Статусы обновления
enum UpdateStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

/// Расширение для статусов обновления
extension UpdateStatusExtension on UpdateStatus {
  String get displayName {
    switch (this) {
      case UpdateStatus.pending:
        return 'Ожидает';
      case UpdateStatus.inProgress:
        return 'В процессе';
      case UpdateStatus.completed:
        return 'Завершено';
      case UpdateStatus.failed:
        return 'Ошибка';
      case UpdateStatus.cancelled:
        return 'Отменено';
    }
  }

  String get color {
    switch (this) {
      case UpdateStatus.pending:
        return 'orange';
      case UpdateStatus.inProgress:
        return 'blue';
      case UpdateStatus.completed:
        return 'green';
      case UpdateStatus.failed:
        return 'red';
      case UpdateStatus.cancelled:
        return 'grey';
    }
  }

  String get icon {
    switch (this) {
      case UpdateStatus.pending:
        return '⏳';
      case UpdateStatus.inProgress:
        return '🔄';
      case UpdateStatus.completed:
        return '✅';
      case UpdateStatus.failed:
        return '❌';
      case UpdateStatus.cancelled:
        return '🚫';
    }
  }
}
