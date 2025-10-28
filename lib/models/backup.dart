import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель бэкапа
class Backup {
  const Backup({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.createdAt, this.status = BackupStatus.pending,
    this.collections = const [],
    this.filters = const {},
    this.createdBy,
    this.completedAt,
    this.fileUrl,
    this.fileSize,
    this.errorMessage,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory Backup.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Backup(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: BackupType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => BackupType.full,
      ),
      status: BackupStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => BackupStatus.pending,
      ),
      collections:
          List<String>.from(data['collections'] as List<dynamic>? ?? []),
      filters: Map<String, dynamic>.from(
          data['filters'] as Map<dynamic, dynamic>? ?? {},),
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      fileUrl: data['fileUrl'] as String?,
      fileSize: data['fileSize'] as int?,
      errorMessage: data['errorMessage'] as String?,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map<dynamic, dynamic>)
          : null,
    );
  }

  /// Создать из Map
  factory Backup.fromMap(Map<String, dynamic> data) => Backup(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        type: BackupType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => BackupType.full,
        ),
        status: BackupStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => BackupStatus.pending,
        ),
        collections:
            List<String>.from(data['collections'] as List<dynamic>? ?? []),
        filters: Map<String, dynamic>.from(
            data['filters'] as Map<dynamic, dynamic>? ?? {},),
        createdBy: data['createdBy'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        completedAt: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
        fileUrl: data['fileUrl'] as String?,
        fileSize: data['fileSize'] as int?,
        errorMessage: data['errorMessage'] as String?,
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(
                data['metadata'] as Map<dynamic, dynamic>,)
            : null,
      );
  final String id;
  final String name;
  final String description;
  final BackupType type;
  final BackupStatus status;
  final List<String> collections;
  final Map<String, dynamic> filters;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? fileUrl;
  final int? fileSize;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'type': type.toString().split('.').last,
        'status': status.toString().split('.').last,
        'collections': collections,
        'filters': filters,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'errorMessage': errorMessage,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  Backup copyWith({
    String? id,
    String? name,
    String? description,
    BackupType? type,
    BackupStatus? status,
    List<String>? collections,
    Map<String, dynamic>? filters,
    String? createdBy,
    DateTime? createdAt,
    DateTime? completedAt,
    String? fileUrl,
    int? fileSize,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) =>
      Backup(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        status: status ?? this.status,
        collections: collections ?? this.collections,
        filters: filters ?? this.filters,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
        fileUrl: fileUrl ?? this.fileUrl,
        fileSize: fileSize ?? this.fileSize,
        errorMessage: errorMessage ?? this.errorMessage,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, завершен ли бэкап
  bool get isCompleted => status == BackupStatus.completed && fileUrl != null;

  /// Проверить, есть ли ошибка
  bool get hasError => status == BackupStatus.failed;

  /// Проверить, выполняется ли бэкап
  bool get isInProgress => status == BackupStatus.inProgress;

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
    if (fileSize == null) return 'Неизвестно';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = fileSize!;
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }

    return '$size ${units[unitIndex]}';
  }

  /// Получить продолжительность выполнения
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Backup &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.status == status &&
        other.collections == collections &&
        other.filters == filters &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.fileUrl == fileUrl &&
        other.fileSize == fileSize &&
        other.errorMessage == errorMessage &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        type,
        status,
        collections,
        filters,
        createdBy,
        createdAt,
        completedAt,
        fileUrl,
        fileSize,
        errorMessage,
        metadata,
      );

  @override
  String toString() => 'Backup(id: $id, name: $name, status: $status)';
}

/// Типы бэкапов
enum BackupType { full, incremental, differential, selective }

/// Статусы бэкапов
enum BackupStatus { pending, inProgress, completed, failed, cancelled }

/// Модель восстановления
class Restore {
  const Restore({
    required this.id,
    required this.backupId,
    required this.name,
    required this.description,
    required this.type,
    required this.createdAt, this.status = RestoreStatus.pending,
    this.collections = const [],
    this.options = const {},
    this.createdBy,
    this.completedAt,
    this.errorMessage,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory Restore.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Restore(
      id: doc.id,
      backupId: data['backupId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: RestoreType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => RestoreType.full,
      ),
      status: RestoreStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => RestoreStatus.pending,
      ),
      collections:
          List<String>.from(data['collections'] as List<dynamic>? ?? []),
      options: Map<String, dynamic>.from(
          data['options'] as Map<dynamic, dynamic>? ?? {},),
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      errorMessage: data['errorMessage'] as String?,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map<dynamic, dynamic>)
          : null,
    );
  }

  /// Создать из Map
  factory Restore.fromMap(Map<String, dynamic> data) => Restore(
        id: data['id'] as String? ?? '',
        backupId: data['backupId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        type: RestoreType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => RestoreType.full,
        ),
        status: RestoreStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => RestoreStatus.pending,
        ),
        collections:
            List<String>.from(data['collections'] as List<dynamic>? ?? []),
        options: Map<String, dynamic>.from(
            data['options'] as Map<dynamic, dynamic>? ?? {},),
        createdBy: data['createdBy'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        completedAt: data['completedAt'] != null
            ? (data['completedAt'] as Timestamp).toDate()
            : null,
        errorMessage: data['errorMessage'] as String?,
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(
                data['metadata'] as Map<dynamic, dynamic>,)
            : null,
      );
  final String id;
  final String backupId;
  final String name;
  final String description;
  final RestoreType type;
  final RestoreStatus status;
  final List<String> collections;
  final Map<String, dynamic> options;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'backupId': backupId,
        'name': name,
        'description': description,
        'type': type.toString().split('.').last,
        'status': status.toString().split('.').last,
        'collections': collections,
        'options': options,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'errorMessage': errorMessage,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  Restore copyWith({
    String? id,
    String? backupId,
    String? name,
    String? description,
    RestoreType? type,
    RestoreStatus? status,
    List<String>? collections,
    Map<String, dynamic>? options,
    String? createdBy,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) =>
      Restore(
        id: id ?? this.id,
        backupId: backupId ?? this.backupId,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        status: status ?? this.status,
        collections: collections ?? this.collections,
        options: options ?? this.options,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
        errorMessage: errorMessage ?? this.errorMessage,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, завершено ли восстановление
  bool get isCompleted => status == RestoreStatus.completed;

  /// Проверить, есть ли ошибка
  bool get hasError => status == RestoreStatus.failed;

  /// Проверить, выполняется ли восстановление
  bool get isInProgress => status == RestoreStatus.inProgress;

  /// Получить продолжительность выполнения
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restore &&
        other.id == id &&
        other.backupId == backupId &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.status == status &&
        other.collections == collections &&
        other.options == options &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.errorMessage == errorMessage &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        backupId,
        name,
        description,
        type,
        status,
        collections,
        options,
        createdBy,
        createdAt,
        completedAt,
        errorMessage,
        metadata,
      );

  @override
  String toString() => 'Restore(id: $id, name: $name, status: $status)';
}

/// Типы восстановления
enum RestoreType { full, selective, pointInTime }

/// Статусы восстановления
enum RestoreStatus { pending, inProgress, completed, failed, cancelled }

/// Статистика бэкапов
class BackupStatistics {
  const BackupStatistics({
    required this.totalBackups,
    required this.successfulBackups,
    required this.failedBackups,
    required this.totalSize,
    required this.lastBackup,
    required this.backupsByType,
    required this.backupsByStatus,
  });
  final int totalBackups;
  final int successfulBackups;
  final int failedBackups;
  final int totalSize;
  final DateTime lastBackup;
  final Map<String, int> backupsByType;
  final Map<String, int> backupsByStatus;

  /// Процент успешных бэкапов
  double get successRate {
    if (totalBackups == 0) return 0;
    return (successfulBackups / totalBackups) * 100;
  }

  /// Процент неудачных бэкапов
  double get failureRate {
    if (totalBackups == 0) return 0;
    return (failedBackups / totalBackups) * 100;
  }

  /// Получить общий размер в читаемом формате
  String get formattedTotalSize {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = totalSize;
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }

    return '$size ${units[unitIndex]}';
  }

  @override
  String toString() =>
      'BackupStatistics(totalBackups: $totalBackups, successRate: ${successRate.toStringAsFixed(1)}%)';
}
