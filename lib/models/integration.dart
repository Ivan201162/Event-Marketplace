import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель интеграции
class Integration {
  const Integration({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    this.config = const {},
    this.permissions = const [],
    this.iconUrl,
    this.websiteUrl,
    this.documentationUrl,
    this.isEnabled = false,
    this.isRequired = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Integration.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Integration(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: IntegrationType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => IntegrationType.other,
      ),
      status: IntegrationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => IntegrationStatus.disconnected,
      ),
      config: Map<String, dynamic>.from((data['config'] as Map<dynamic, dynamic>?) ?? {}),
      permissions: List<String>.from((data['permissions'] as List<dynamic>?) ?? []),
      iconUrl: data['iconUrl'] as String?,
      websiteUrl: data['websiteUrl'] as String?,
      documentationUrl: data['documentationUrl'] as String?,
      isEnabled: data['isEnabled'] as bool? ?? false,
      isRequired: data['isRequired'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String name;
  final String description;
  final IntegrationType type;
  final IntegrationStatus status;
  final Map<String, dynamic> config;
  final List<String> permissions;
  final String? iconUrl;
  final String? websiteUrl;
  final String? documentationUrl;
  final bool isEnabled;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'status': status.name,
    'config': config,
    'permissions': permissions,
    'iconUrl': iconUrl,
    'websiteUrl': websiteUrl,
    'documentationUrl': documentationUrl,
    'isEnabled': isEnabled,
    'isRequired': isRequired,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  Integration copyWith({
    String? id,
    String? name,
    String? description,
    IntegrationType? type,
    IntegrationStatus? status,
    Map<String, dynamic>? config,
    List<String>? permissions,
    String? iconUrl,
    String? websiteUrl,
    String? documentationUrl,
    bool? isEnabled,
    bool? isRequired,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Integration(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    config: config ?? this.config,
    permissions: permissions ?? this.permissions,
    iconUrl: iconUrl ?? this.iconUrl,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    documentationUrl: documentationUrl ?? this.documentationUrl,
    isEnabled: isEnabled ?? this.isEnabled,
    isRequired: isRequired ?? this.isRequired,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Получить цвет статуса
  Color get statusColor {
    switch (status) {
      case IntegrationStatus.connected:
        return Colors.green;
      case IntegrationStatus.disconnected:
        return Colors.grey;
      case IntegrationStatus.error:
        return Colors.red;
      case IntegrationStatus.pending:
        return Colors.orange;
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case IntegrationStatus.connected:
        return 'Подключено';
      case IntegrationStatus.disconnected:
        return 'Отключено';
      case IntegrationStatus.error:
        return 'Ошибка';
      case IntegrationStatus.pending:
        return 'Ожидает';
    }
  }

  /// Получить иконку типа
  IconData get typeIcon {
    switch (type) {
      case IntegrationType.maps:
        return Icons.map;
      case IntegrationType.social:
        return Icons.share;
      case IntegrationType.payment:
        return Icons.payment;
      case IntegrationType.calendar:
        return Icons.calendar_today;
      case IntegrationType.email:
        return Icons.email;
      case IntegrationType.sms:
        return Icons.sms;
      case IntegrationType.analytics:
        return Icons.analytics;
      case IntegrationType.storage:
        return Icons.cloud;
      case IntegrationType.other:
        return Icons.extension;
    }
  }

  /// Получить цвет типа
  Color get typeColor {
    switch (type) {
      case IntegrationType.maps:
        return Colors.blue;
      case IntegrationType.social:
        return Colors.purple;
      case IntegrationType.payment:
        return Colors.green;
      case IntegrationType.calendar:
        return Colors.orange;
      case IntegrationType.email:
        return Colors.red;
      case IntegrationType.sms:
        return Colors.cyan;
      case IntegrationType.analytics:
        return Colors.indigo;
      case IntegrationType.storage:
        return Colors.teal;
      case IntegrationType.other:
        return Colors.grey;
    }
  }
}

/// Типы интеграций
enum IntegrationType { maps, social, payment, calendar, email, sms, analytics, storage, other }

/// Статусы интеграций
enum IntegrationStatus { connected, disconnected, error, pending }

/// Модель настроек интеграции
class IntegrationSettings {
  const IntegrationSettings({
    required this.integrationId,
    required this.userId,
    this.settings = const {},
    this.isEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IntegrationSettings.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return IntegrationSettings(
      integrationId: data['integrationId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      settings: Map<String, dynamic>.from((data['settings'] as Map<dynamic, dynamic>?) ?? {}),
      isEnabled: data['isEnabled'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String integrationId;
  final String userId;
  final Map<String, dynamic> settings;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
    'integrationId': integrationId,
    'userId': userId,
    'settings': settings,
    'isEnabled': isEnabled,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  IntegrationSettings copyWith({
    String? integrationId,
    String? userId,
    Map<String, dynamic>? settings,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => IntegrationSettings(
    integrationId: integrationId ?? this.integrationId,
    userId: userId ?? this.userId,
    settings: settings ?? this.settings,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Модель события интеграции
class IntegrationEvent {
  const IntegrationEvent({
    required this.id,
    required this.integrationId,
    required this.userId,
    required this.type,
    this.data = const {},
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IntegrationEvent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return IntegrationEvent(
      id: doc.id,
      integrationId: data['integrationId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: IntegrationEventType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => IntegrationEventType.other,
      ),
      data: Map<String, dynamic>.from((data['data'] as Map<dynamic, dynamic>?) ?? {}),
      status: IntegrationEventStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => IntegrationEventStatus.pending,
      ),
      errorMessage: data['errorMessage'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String integrationId;
  final String userId;
  final IntegrationEventType type;
  final Map<String, dynamic> data;
  final IntegrationEventStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'integrationId': integrationId,
    'userId': userId,
    'type': type.name,
    'data': data,
    'status': status.name,
    'errorMessage': errorMessage,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  IntegrationEvent copyWith({
    String? id,
    String? integrationId,
    String? userId,
    IntegrationEventType? type,
    Map<String, dynamic>? data,
    IntegrationEventStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => IntegrationEvent(
    id: id ?? this.id,
    integrationId: integrationId ?? this.integrationId,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    data: data ?? this.data,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Типы событий интеграции
enum IntegrationEventType { connect, disconnect, sync, error, other }

/// Статусы событий интеграции
enum IntegrationEventStatus { pending, success, failed }

/// Модель геолокации
class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) => LocationData(
    latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    accuracy: (map['accuracy'] as num?)?.toDouble(),
    altitude: (map['altitude'] as num?)?.toDouble(),
    speed: (map['speed'] as num?)?.toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int? ?? 0),
  );
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'altitude': altitude,
    'speed': speed,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };
}

/// Модель адреса
class AddressData {
  const AddressData({
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.formattedAddress,
  });

  factory AddressData.fromMap(Map<String, dynamic> map) => AddressData(
    street: map['street'] as String?,
    city: map['city'] as String?,
    state: map['state'] as String?,
    country: map['country'] as String?,
    postalCode: map['postalCode'] as String?,
    formattedAddress: map['formattedAddress'] as String?,
  );
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? formattedAddress;

  Map<String, dynamic> toMap() => {
    'street': street,
    'city': city,
    'state': state,
    'country': country,
    'postalCode': postalCode,
    'formattedAddress': formattedAddress,
  };
}
