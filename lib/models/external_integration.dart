import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель внешней интеграции
class ExternalIntegration {
  const ExternalIntegration({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.status = IntegrationStatus.inactive,
    required this.baseUrl,
    this.headers = const {},
    this.configuration = const {},
    this.authType = AuthenticationType.none,
    this.credentials = const {},
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastSyncAt,
    this.lastError,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory ExternalIntegration.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ExternalIntegration(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: IntegrationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => IntegrationType.api,
      ),
      status: IntegrationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => IntegrationStatus.inactive,
      ),
      baseUrl: data['baseUrl'] as String? ?? '',
      headers: Map<String, String>.from((data['headers'] as Map<dynamic, dynamic>?) ?? {}),
      configuration: Map<String, dynamic>.from(
        (data['configuration'] as Map<dynamic, dynamic>?) ?? {},
      ),
      authType: AuthenticationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['authType'],
        orElse: () => AuthenticationType.none,
      ),
      credentials: Map<String, String>.from((data['credentials'] as Map<dynamic, dynamic>?) ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String?,
      lastSyncAt: data['lastSyncAt'] != null ? (data['lastSyncAt'] as Timestamp).toDate() : null,
      lastError: data['lastError'] as String?,
      metadata: Map<String, dynamic>.from((data['metadata'] as Map<dynamic, dynamic>?) ?? {}),
    );
  }

  /// Создать из Map
  factory ExternalIntegration.fromMap(Map<String, dynamic> data) => ExternalIntegration(
    id: data['id'] as String? ?? '',
    name: data['name'] as String? ?? '',
    description: data['description'] as String? ?? '',
    type: IntegrationType.values.firstWhere(
      (e) => e.toString().split('.').last == data['type'],
      orElse: () => IntegrationType.api,
    ),
    status: IntegrationStatus.values.firstWhere(
      (e) => e.toString().split('.').last == data['status'],
      orElse: () => IntegrationStatus.inactive,
    ),
    baseUrl: data['baseUrl'] as String? ?? '',
    headers: Map<String, String>.from((data['headers'] as Map<dynamic, dynamic>?) ?? {}),
    configuration: Map<String, dynamic>.from(
      (data['configuration'] as Map<dynamic, dynamic>?) ?? {},
    ),
    authType: AuthenticationType.values.firstWhere(
      (e) => e.toString().split('.').last == data['authType'],
      orElse: () => AuthenticationType.none,
    ),
    credentials: Map<String, String>.from((data['credentials'] as Map<dynamic, dynamic>?) ?? {}),
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    createdBy: data['createdBy'] as String?,
    lastSyncAt: data['lastSyncAt'] != null ? (data['lastSyncAt'] as Timestamp).toDate() : null,
    lastError: data['lastError'] as String?,
    metadata: Map<String, dynamic>.from((data['metadata'] as Map<dynamic, dynamic>?) ?? {}),
  );
  final String id;
  final String name;
  final String description;
  final IntegrationType type;
  final IntegrationStatus status;
  final String baseUrl;
  final Map<String, String> headers;
  final Map<String, dynamic> configuration;
  final AuthenticationType authType;
  final Map<String, String> credentials;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final DateTime? lastSyncAt;
  final String? lastError;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'baseUrl': baseUrl,
    'headers': headers,
    'configuration': configuration,
    'authType': authType.toString().split('.').last,
    'credentials': credentials,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'createdBy': createdBy,
    'lastSyncAt': lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
    'lastError': lastError,
    'metadata': metadata,
  };

  /// Создать копию с изменениями
  ExternalIntegration copyWith({
    String? id,
    String? name,
    String? description,
    IntegrationType? type,
    IntegrationStatus? status,
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? configuration,
    AuthenticationType? authType,
    Map<String, String>? credentials,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    DateTime? lastSyncAt,
    String? lastError,
    Map<String, dynamic>? metadata,
  }) => ExternalIntegration(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    baseUrl: baseUrl ?? this.baseUrl,
    headers: headers ?? this.headers,
    configuration: configuration ?? this.configuration,
    authType: authType ?? this.authType,
    credentials: credentials ?? this.credentials,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: lastError ?? this.lastError,
    metadata: metadata ?? this.metadata,
  );

  /// Проверить, активна ли интеграция
  bool get isActive => status == IntegrationStatus.active;

  /// Проверить, есть ли ошибка
  bool get hasError => lastError != null;

  /// Получить время с последней синхронизации
  Duration? get timeSinceLastSync {
    if (lastSyncAt == null) return null;
    return DateTime.now().difference(lastSyncAt!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExternalIntegration &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.status == status &&
        other.baseUrl == baseUrl &&
        other.headers == headers &&
        other.configuration == configuration &&
        other.authType == authType &&
        other.credentials == credentials &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.lastSyncAt == lastSyncAt &&
        other.lastError == lastError &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    type,
    status,
    baseUrl,
    headers,
    configuration,
    authType,
    credentials,
    createdAt,
    updatedAt,
    createdBy,
    lastSyncAt,
    lastError,
    metadata,
  );

  @override
  String toString() => 'ExternalIntegration(id: $id, name: $name, type: $type, status: $status)';
}

/// Модель синхронизации данных
class DataSync {
  const DataSync({
    required this.id,
    required this.integrationId,
    required this.direction,
    this.status = SyncStatus.pending,
    required this.dataType,
    this.totalRecords = 0,
    this.syncedRecords = 0,
    this.failedRecords = 0,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory DataSync.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return DataSync(
      id: doc.id,
      integrationId: data['integrationId'] as String? ?? '',
      direction: SyncDirection.values.firstWhere(
        (e) => e.toString().split('.').last == data['direction'] as String?,
        orElse: () => SyncDirection.bidirectional,
      ),
      status: SyncStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'] as String?,
        orElse: () => SyncStatus.pending,
      ),
      dataType: data['dataType'] as String? ?? '',
      totalRecords: data['totalRecords'] as int? ?? 0,
      syncedRecords: data['syncedRecords'] as int? ?? 0,
      failedRecords: data['failedRecords'] as int? ?? 0,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      errorMessage: data['errorMessage'] as String?,
      metadata: Map<String, dynamic>.from((data['metadata'] as Map<dynamic, dynamic>?) ?? {}),
    );
  }

  /// Создать из Map
  factory DataSync.fromMap(Map<String, dynamic> data) => DataSync(
    id: data['id'] as String? ?? '',
    integrationId: data['integrationId'] as String? ?? '',
    direction: SyncDirection.values.firstWhere(
      (e) => e.toString().split('.').last == data['direction'],
      orElse: () => SyncDirection.bidirectional,
    ),
    status: SyncStatus.values.firstWhere(
      (e) => e.toString().split('.').last == data['status'],
      orElse: () => SyncStatus.pending,
    ),
    dataType: data['dataType'] as String? ?? '',
    totalRecords: data['totalRecords'] as int? ?? 0,
    syncedRecords: data['syncedRecords'] as int? ?? 0,
    failedRecords: data['failedRecords'] as int? ?? 0,
    startedAt: (data['startedAt'] as Timestamp).toDate(),
    completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
    errorMessage: data['errorMessage'] as String?,
    metadata: Map<String, dynamic>.from((data['metadata'] as Map<dynamic, dynamic>?) ?? {}),
  );
  final String id;
  final String integrationId;
  final SyncDirection direction;
  final SyncStatus status;
  final String dataType;
  final int totalRecords;
  final int syncedRecords;
  final int failedRecords;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'integrationId': integrationId,
    'direction': direction.toString().split('.').last,
    'status': status.toString().split('.').last,
    'dataType': dataType,
    'totalRecords': totalRecords,
    'syncedRecords': syncedRecords,
    'failedRecords': failedRecords,
    'startedAt': Timestamp.fromDate(startedAt),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'errorMessage': errorMessage,
    'metadata': metadata,
  };

  /// Создать копию с изменениями
  DataSync copyWith({
    String? id,
    String? integrationId,
    SyncDirection? direction,
    SyncStatus? status,
    String? dataType,
    int? totalRecords,
    int? syncedRecords,
    int? failedRecords,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) => DataSync(
    id: id ?? this.id,
    integrationId: integrationId ?? this.integrationId,
    direction: direction ?? this.direction,
    status: status ?? this.status,
    dataType: dataType ?? this.dataType,
    totalRecords: totalRecords ?? this.totalRecords,
    syncedRecords: syncedRecords ?? this.syncedRecords,
    failedRecords: failedRecords ?? this.failedRecords,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    errorMessage: errorMessage ?? this.errorMessage,
    metadata: metadata ?? this.metadata,
  );

  /// Проверить, завершена ли синхронизация
  bool get isCompleted => status == SyncStatus.completed;

  /// Проверить, есть ли ошибка
  bool get hasError => status == SyncStatus.failed;

  /// Проверить, выполняется ли синхронизация
  bool get isInProgress => status == SyncStatus.inProgress;

  /// Получить процент выполнения
  double get progressPercentage {
    if (totalRecords == 0) return 0;
    return (syncedRecords / totalRecords) * 100;
  }

  /// Получить продолжительность синхронизации
  Duration? get duration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataSync &&
        other.id == id &&
        other.integrationId == integrationId &&
        other.direction == direction &&
        other.status == status &&
        other.dataType == dataType &&
        other.totalRecords == totalRecords &&
        other.syncedRecords == syncedRecords &&
        other.failedRecords == failedRecords &&
        other.startedAt == startedAt &&
        other.completedAt == completedAt &&
        other.errorMessage == errorMessage &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
    id,
    integrationId,
    direction,
    status,
    dataType,
    totalRecords,
    syncedRecords,
    failedRecords,
    startedAt,
    completedAt,
    errorMessage,
    metadata,
  );

  @override
  String toString() =>
      'DataSync(id: $id, dataType: $dataType, status: $status, progress: ${progressPercentage.toStringAsFixed(1)}%)';
}

/// Типы интеграций
enum IntegrationType {
  api,
  webhook,
  sftp,
  email,
  sms,
  payment,
  calendar,
  social,
  analytics,
  crm,
  erp,
  other,
}

/// Расширение для типов интеграций
extension IntegrationTypeExtension on IntegrationType {
  String get displayName {
    switch (this) {
      case IntegrationType.api:
        return 'API';
      case IntegrationType.webhook:
        return 'Webhook';
      case IntegrationType.sftp:
        return 'SFTP';
      case IntegrationType.email:
        return 'Email';
      case IntegrationType.sms:
        return 'SMS';
      case IntegrationType.payment:
        return 'Платежи';
      case IntegrationType.calendar:
        return 'Календарь';
      case IntegrationType.social:
        return 'Социальные сети';
      case IntegrationType.analytics:
        return 'Аналитика';
      case IntegrationType.crm:
        return 'CRM';
      case IntegrationType.erp:
        return 'ERP';
      case IntegrationType.other:
        return 'Другое';
    }
  }

  String get description {
    switch (this) {
      case IntegrationType.api:
        return 'REST API интеграция';
      case IntegrationType.webhook:
        return 'Webhook для получения уведомлений';
      case IntegrationType.sftp:
        return 'SFTP для обмена файлами';
      case IntegrationType.email:
        return 'Email сервис';
      case IntegrationType.sms:
        return 'SMS сервис';
      case IntegrationType.payment:
        return 'Платежная система';
      case IntegrationType.calendar:
        return 'Календарный сервис';
      case IntegrationType.social:
        return 'Социальные сети';
      case IntegrationType.analytics:
        return 'Аналитический сервис';
      case IntegrationType.crm:
        return 'CRM система';
      case IntegrationType.erp:
        return 'ERP система';
      case IntegrationType.other:
        return 'Другая интеграция';
    }
  }

  String get icon {
    switch (this) {
      case IntegrationType.api:
        return '🔌';
      case IntegrationType.webhook:
        return '🪝';
      case IntegrationType.sftp:
        return '📁';
      case IntegrationType.email:
        return '📧';
      case IntegrationType.sms:
        return '📱';
      case IntegrationType.payment:
        return '💳';
      case IntegrationType.calendar:
        return '📅';
      case IntegrationType.social:
        return '👥';
      case IntegrationType.analytics:
        return '📊';
      case IntegrationType.crm:
        return '👤';
      case IntegrationType.erp:
        return '🏢';
      case IntegrationType.other:
        return '🔗';
    }
  }
}

/// Статусы интеграций
enum IntegrationStatus { active, inactive, error, maintenance, deprecated }

/// Расширение для статусов интеграций
extension IntegrationStatusExtension on IntegrationStatus {
  String get displayName {
    switch (this) {
      case IntegrationStatus.active:
        return 'Активна';
      case IntegrationStatus.inactive:
        return 'Неактивна';
      case IntegrationStatus.error:
        return 'Ошибка';
      case IntegrationStatus.maintenance:
        return 'Обслуживание';
      case IntegrationStatus.deprecated:
        return 'Устарела';
    }
  }

  String get color {
    switch (this) {
      case IntegrationStatus.active:
        return 'green';
      case IntegrationStatus.inactive:
        return 'grey';
      case IntegrationStatus.error:
        return 'red';
      case IntegrationStatus.maintenance:
        return 'orange';
      case IntegrationStatus.deprecated:
        return 'purple';
    }
  }
}

/// Типы аутентификации
enum AuthenticationType { none, apiKey, basic, bearer, oauth2, custom }

/// Расширение для типов аутентификации
extension AuthenticationTypeExtension on AuthenticationType {
  String get displayName {
    switch (this) {
      case AuthenticationType.none:
        return 'Без аутентификации';
      case AuthenticationType.apiKey:
        return 'API ключ';
      case AuthenticationType.basic:
        return 'Basic Auth';
      case AuthenticationType.bearer:
        return 'Bearer Token';
      case AuthenticationType.oauth2:
        return 'OAuth 2.0';
      case AuthenticationType.custom:
        return 'Пользовательская';
    }
  }
}

/// Направления синхронизации
enum SyncDirection { inbound, outbound, bidirectional }

/// Расширение для направлений синхронизации
extension SyncDirectionExtension on SyncDirection {
  String get displayName {
    switch (this) {
      case SyncDirection.inbound:
        return 'Входящая';
      case SyncDirection.outbound:
        return 'Исходящая';
      case SyncDirection.bidirectional:
        return 'Двунаправленная';
    }
  }
}

/// Статусы синхронизации
enum SyncStatus { pending, inProgress, completed, failed, cancelled }

/// Расширение для статусов синхронизации
extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Ожидает';
      case SyncStatus.inProgress:
        return 'В процессе';
      case SyncStatus.completed:
        return 'Завершена';
      case SyncStatus.failed:
        return 'Ошибка';
      case SyncStatus.cancelled:
        return 'Отменена';
    }
  }

  String get color {
    switch (this) {
      case SyncStatus.pending:
        return 'orange';
      case SyncStatus.inProgress:
        return 'blue';
      case SyncStatus.completed:
        return 'green';
      case SyncStatus.failed:
        return 'red';
      case SyncStatus.cancelled:
        return 'grey';
    }
  }
}
