import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус интеграции
enum IntegrationStatus { active, inactive, pending, error, disconnected }

/// Тип интеграции
enum IntegrationType {
  calendar,
  payment,
  notification,
  analytics,
  social,
  other
}

/// Модель внешней интеграции
class ExternalIntegration {
  const ExternalIntegration({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.status,
    this.description,
    this.config = const {},
    this.credentials = const {},
    this.lastSyncAt,
    this.errorMessage,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final IntegrationType type;
  final IntegrationStatus status;
  final String? description;
  final Map<String, dynamic> config;
  final Map<String, dynamic> credentials;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory ExternalIntegration.fromMap(Map<String, dynamic> data) {
    return ExternalIntegration(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      description: data['description'] as String?,
      config: Map<String, dynamic>.from(data['config'] ?? {}),
      credentials: Map<String, dynamic>.from(data['credentials'] ?? {}),
      lastSyncAt: data['lastSyncAt'] != null
          ? (data['lastSyncAt'] is Timestamp
              ? (data['lastSyncAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['lastSyncAt'].toString()))
          : null,
      errorMessage: data['errorMessage'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory ExternalIntegration.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return ExternalIntegration.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'type': type.name,
        'status': status.name,
        'description': description,
        'config': config,
        'credentials': credentials,
        'lastSyncAt':
            lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
        'errorMessage': errorMessage,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  ExternalIntegration copyWith({
    String? id,
    String? userId,
    String? name,
    IntegrationType? type,
    IntegrationStatus? status,
    String? description,
    Map<String, dynamic>? config,
    Map<String, dynamic>? credentials,
    DateTime? lastSyncAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ExternalIntegration(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        status: status ?? this.status,
        description: description ?? this.description,
        config: config ?? this.config,
        credentials: credentials ?? this.credentials,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        errorMessage: errorMessage ?? this.errorMessage,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static IntegrationType _parseType(String? type) {
    switch (type) {
      case 'calendar':
        return IntegrationType.calendar;
      case 'payment':
        return IntegrationType.payment;
      case 'notification':
        return IntegrationType.notification;
      case 'analytics':
        return IntegrationType.analytics;
      case 'social':
        return IntegrationType.social;
      case 'other':
        return IntegrationType.other;
      default:
        return IntegrationType.other;
    }
  }

  /// Парсинг статуса из строки
  static IntegrationStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return IntegrationStatus.active;
      case 'inactive':
        return IntegrationStatus.inactive;
      case 'pending':
        return IntegrationStatus.pending;
      case 'error':
        return IntegrationStatus.error;
      case 'disconnected':
        return IntegrationStatus.disconnected;
      default:
        return IntegrationStatus.inactive;
    }
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case IntegrationType.calendar:
        return 'Календарь';
      case IntegrationType.payment:
        return 'Платежи';
      case IntegrationType.notification:
        return 'Уведомления';
      case IntegrationType.analytics:
        return 'Аналитика';
      case IntegrationType.social:
        return 'Социальные сети';
      case IntegrationType.other:
        return 'Другое';
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case IntegrationStatus.active:
        return 'Активна';
      case IntegrationStatus.inactive:
        return 'Неактивна';
      case IntegrationStatus.pending:
        return 'Ожидает';
      case IntegrationStatus.error:
        return 'Ошибка';
      case IntegrationStatus.disconnected:
        return 'Отключена';
    }
  }

  /// Проверить, активна ли интеграция
  bool get isActive => status == IntegrationStatus.active;

  /// Проверить, есть ли ошибка
  bool get hasError => status == IntegrationStatus.error;

  /// Проверить, синхронизировалась ли интеграция недавно
  bool get isRecentlySynced {
    if (lastSyncAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastSyncAt!);
    return difference.inHours < 24; // Синхронизировалась в последние 24 часа
  }
}

/// Модель настроек интеграции
class IntegrationSettings {
  const IntegrationSettings({
    required this.userId,
    this.enabledIntegrations = const [],
    this.syncFrequency = 60, // минуты
    this.autoSync = true,
    this.notifications = true,
    this.errorReporting = true,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final List<String> enabledIntegrations;
  final int syncFrequency;
  final bool autoSync;
  final bool notifications;
  final bool errorReporting;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory IntegrationSettings.fromMap(Map<String, dynamic> data) {
    return IntegrationSettings(
      userId: data['userId'] as String? ?? '',
      enabledIntegrations: List<String>.from(data['enabledIntegrations'] ?? []),
      syncFrequency: data['syncFrequency'] as int? ?? 60,
      autoSync: data['autoSync'] as bool? ?? true,
      notifications: data['notifications'] as bool? ?? true,
      errorReporting: data['errorReporting'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'enabledIntegrations': enabledIntegrations,
        'syncFrequency': syncFrequency,
        'autoSync': autoSync,
        'notifications': notifications,
        'errorReporting': errorReporting,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  IntegrationSettings copyWith({
    String? userId,
    List<String>? enabledIntegrations,
    int? syncFrequency,
    bool? autoSync,
    bool? notifications,
    bool? errorReporting,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      IntegrationSettings(
        userId: userId ?? this.userId,
        enabledIntegrations: enabledIntegrations ?? this.enabledIntegrations,
        syncFrequency: syncFrequency ?? this.syncFrequency,
        autoSync: autoSync ?? this.autoSync,
        notifications: notifications ?? this.notifications,
        errorReporting: errorReporting ?? this.errorReporting,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Проверить, включена ли интеграция
  bool isIntegrationEnabled(String integrationId) {
    return enabledIntegrations.contains(integrationId);
  }

  /// Получить отформатированную частоту синхронизации
  String get formattedSyncFrequency {
    if (syncFrequency < 60) {
      return '$syncFrequency мин';
    } else if (syncFrequency < 1440) {
      final hours = syncFrequency ~/ 60;
      final minutes = syncFrequency % 60;
      if (minutes == 0) {
        return '$hours ч';
      } else {
        return '$hours ч $minutes мин';
      }
    } else {
      final days = syncFrequency ~/ 1440;
      return '$days дн';
    }
  }
}

/// Модель события интеграции
class IntegrationEvent {
  const IntegrationEvent({
    required this.id,
    required this.integrationId,
    required this.userId,
    required this.eventType,
    required this.eventData,
    this.status = 'pending',
    this.errorMessage,
    this.processedAt,
    required this.createdAt,
  });

  final String id;
  final String integrationId;
  final String userId;
  final String eventType;
  final Map<String, dynamic> eventData;
  final String status;
  final String? errorMessage;
  final DateTime? processedAt;
  final DateTime createdAt;

  /// Создать из Map
  factory IntegrationEvent.fromMap(Map<String, dynamic> data) {
    return IntegrationEvent(
      id: data['id'] as String? ?? '',
      integrationId: data['integrationId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      eventType: data['eventType'] as String? ?? '',
      eventData: Map<String, dynamic>.from(data['eventData'] ?? {}),
      status: data['status'] as String? ?? 'pending',
      errorMessage: data['errorMessage'] as String?,
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] is Timestamp
              ? (data['processedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['processedAt'].toString()))
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
    );
  }

  /// Создать из документа Firestore
  factory IntegrationEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return IntegrationEvent.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'integrationId': integrationId,
        'userId': userId,
        'eventType': eventType,
        'eventData': eventData,
        'status': status,
        'errorMessage': errorMessage,
        'processedAt':
            processedAt != null ? Timestamp.fromDate(processedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Копировать с изменениями
  IntegrationEvent copyWith({
    String? id,
    String? integrationId,
    String? userId,
    String? eventType,
    Map<String, dynamic>? eventData,
    String? status,
    String? errorMessage,
    DateTime? processedAt,
    DateTime? createdAt,
  }) =>
      IntegrationEvent(
        id: id ?? this.id,
        integrationId: integrationId ?? this.integrationId,
        userId: userId ?? this.userId,
        eventType: eventType ?? this.eventType,
        eventData: eventData ?? this.eventData,
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        processedAt: processedAt ?? this.processedAt,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Проверить, обработано ли событие
  bool get isProcessed => status == 'processed';

  /// Проверить, есть ли ошибка
  bool get hasError => status == 'error' || errorMessage != null;

  /// Проверить, ожидает ли событие обработки
  bool get isPending => status == 'pending';
}
