import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель метрики мониторинга
class MonitoringMetric {
  final String id;
  final String name;
  final String description;
  final MetricType type;
  final String category;
  final double value;
  final String unit;
  final Map<String, dynamic> tags;
  final DateTime timestamp;
  final String? source;
  final Map<String, dynamic> metadata;

  const MonitoringMetric({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.value,
    required this.unit,
    this.tags = const {},
    required this.timestamp,
    this.source,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory MonitoringMetric.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonitoringMetric(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: MetricType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => MetricType.gauge),
      category: data['category'] ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
      tags: Map<String, dynamic>.from(data['tags'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      source: data['source'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из Map
  factory MonitoringMetric.fromMap(Map<String, dynamic> data) {
    return MonitoringMetric(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: MetricType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => MetricType.gauge),
      category: data['category'] ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
      tags: Map<String, dynamic>.from(data['tags'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      source: data['source'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category,
      'value': value,
      'unit': unit,
      'tags': tags,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source,
      'metadata': metadata,
    };
  }

  /// Создать копию с изменениями
  MonitoringMetric copyWith({
    String? id,
    String? name,
    String? description,
    MetricType? type,
    String? category,
    double? value,
    String? unit,
    Map<String, dynamic>? tags,
    DateTime? timestamp,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return MonitoringMetric(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Получить форматированное значение
  String get formattedValue {
    switch (type) {
      case MetricType.counter:
        return '${value.toInt()}';
      case MetricType.gauge:
        return '${value.toStringAsFixed(2)} $unit';
      case MetricType.histogram:
        return '${value.toStringAsFixed(2)} $unit';
      case MetricType.timer:
        return '${(value / 1000).toStringAsFixed(2)}s';
      case MetricType.rate:
        return '${(value * 100).toStringAsFixed(2)}%';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringMetric &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.category == category &&
        other.value == value &&
        other.unit == unit &&
        other.tags == tags &&
        other.timestamp == timestamp &&
        other.source == source &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      type,
      category,
      value,
      unit,
      tags,
      timestamp,
      source,
      metadata,
    );
  }

  @override
  String toString() {
    return 'MonitoringMetric(id: $id, name: $name, value: $formattedValue)';
  }
}

/// Модель алерта
class MonitoringAlert {
  final String id;
  final String name;
  final String description;
  final AlertSeverity severity;
  final AlertStatus status;
  final String metricName;
  final String condition;
  final double threshold;
  final String operator;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final DateTime? resolvedAt;
  final String? triggeredBy;
  final String? resolvedBy;
  final Map<String, dynamic> metadata;
  final List<String> notificationChannels;

  const MonitoringAlert({
    required this.id,
    required this.name,
    required this.description,
    required this.severity,
    this.status = AlertStatus.active,
    required this.metricName,
    required this.condition,
    required this.threshold,
    required this.operator,
    required this.createdAt,
    this.triggeredAt,
    this.resolvedAt,
    this.triggeredBy,
    this.resolvedBy,
    this.metadata = const {},
    this.notificationChannels = const [],
  });

  /// Создать из документа Firestore
  factory MonitoringAlert.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonitoringAlert(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      severity: AlertSeverity.values.firstWhere(
          (e) => e.toString().split('.').last == data['severity'],
          orElse: () => AlertSeverity.medium),
      status: AlertStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => AlertStatus.active),
      metricName: data['metricName'] ?? '',
      condition: data['condition'] ?? '',
      threshold: (data['threshold'] as num?)?.toDouble() ?? 0.0,
      operator: data['operator'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      triggeredAt: data['triggeredAt'] != null
          ? (data['triggeredAt'] as Timestamp).toDate()
          : null,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      triggeredBy: data['triggeredBy'],
      resolvedBy: data['resolvedBy'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      notificationChannels:
          List<String>.from(data['notificationChannels'] ?? []),
    );
  }

  /// Создать из Map
  factory MonitoringAlert.fromMap(Map<String, dynamic> data) {
    return MonitoringAlert(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      severity: AlertSeverity.values.firstWhere(
          (e) => e.toString().split('.').last == data['severity'],
          orElse: () => AlertSeverity.medium),
      status: AlertStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => AlertStatus.active),
      metricName: data['metricName'] ?? '',
      condition: data['condition'] ?? '',
      threshold: (data['threshold'] as num?)?.toDouble() ?? 0.0,
      operator: data['operator'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      triggeredAt: data['triggeredAt'] != null
          ? (data['triggeredAt'] as Timestamp).toDate()
          : null,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      triggeredBy: data['triggeredBy'],
      resolvedBy: data['resolvedBy'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      notificationChannels:
          List<String>.from(data['notificationChannels'] ?? []),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'severity': severity.toString().split('.').last,
      'status': status.toString().split('.').last,
      'metricName': metricName,
      'condition': condition,
      'threshold': threshold,
      'operator': operator,
      'createdAt': Timestamp.fromDate(createdAt),
      'triggeredAt':
          triggeredAt != null ? Timestamp.fromDate(triggeredAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'triggeredBy': triggeredBy,
      'resolvedBy': resolvedBy,
      'metadata': metadata,
      'notificationChannels': notificationChannels,
    };
  }

  /// Создать копию с изменениями
  MonitoringAlert copyWith({
    String? id,
    String? name,
    String? description,
    AlertSeverity? severity,
    AlertStatus? status,
    String? metricName,
    String? condition,
    double? threshold,
    String? operator,
    DateTime? createdAt,
    DateTime? triggeredAt,
    DateTime? resolvedAt,
    String? triggeredBy,
    String? resolvedBy,
    Map<String, dynamic>? metadata,
    List<String>? notificationChannels,
  }) {
    return MonitoringAlert(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      metricName: metricName ?? this.metricName,
      condition: condition ?? this.condition,
      threshold: threshold ?? this.threshold,
      operator: operator ?? this.operator,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      metadata: metadata ?? this.metadata,
      notificationChannels: notificationChannels ?? this.notificationChannels,
    );
  }

  /// Проверить, сработал ли алерт
  bool get isTriggered => status == AlertStatus.triggered;

  /// Проверить, решен ли алерт
  bool get isResolved => status == AlertStatus.resolved;

  /// Проверить, активен ли алерт
  bool get isActive => status == AlertStatus.active;

  /// Получить продолжительность срабатывания
  Duration? get triggerDuration {
    if (triggeredAt == null) return null;
    final endTime = resolvedAt ?? DateTime.now();
    return endTime.difference(triggeredAt!);
  }

  /// Получить условие алерта в читаемом формате
  String get formattedCondition {
    return '$metricName $operator $threshold';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringAlert &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.severity == severity &&
        other.status == status &&
        other.metricName == metricName &&
        other.condition == condition &&
        other.threshold == threshold &&
        other.operator == operator &&
        other.createdAt == createdAt &&
        other.triggeredAt == triggeredAt &&
        other.resolvedAt == resolvedAt &&
        other.triggeredBy == triggeredBy &&
        other.resolvedBy == resolvedBy &&
        other.metadata == metadata &&
        other.notificationChannels == notificationChannels;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      severity,
      status,
      metricName,
      condition,
      threshold,
      operator,
      createdAt,
      triggeredAt,
      resolvedAt,
      triggeredBy,
      resolvedBy,
      metadata,
      notificationChannels,
    );
  }

  @override
  String toString() {
    return 'MonitoringAlert(id: $id, name: $name, status: $status)';
  }
}

/// Модель дашборда мониторинга
class MonitoringDashboard {
  final String id;
  final String name;
  final String description;
  final List<String> metricIds;
  final List<String> alertIds;
  final DashboardLayout layout;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final Map<String, dynamic> settings;

  const MonitoringDashboard({
    required this.id,
    required this.name,
    required this.description,
    this.metricIds = const [],
    this.alertIds = const [],
    this.layout = DashboardLayout.grid,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.settings = const {},
  });

  /// Создать из документа Firestore
  factory MonitoringDashboard.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonitoringDashboard(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      metricIds: List<String>.from(data['metricIds'] ?? []),
      alertIds: List<String>.from(data['alertIds'] ?? []),
      layout: DashboardLayout.values.firstWhere(
          (e) => e.toString().split('.').last == data['layout'],
          orElse: () => DashboardLayout.grid),
      isPublic: data['isPublic'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  /// Создать из Map
  factory MonitoringDashboard.fromMap(Map<String, dynamic> data) {
    return MonitoringDashboard(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      metricIds: List<String>.from(data['metricIds'] ?? []),
      alertIds: List<String>.from(data['alertIds'] ?? []),
      layout: DashboardLayout.values.firstWhere(
          (e) => e.toString().split('.').last == data['layout'],
          orElse: () => DashboardLayout.grid),
      isPublic: data['isPublic'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'metricIds': metricIds,
      'alertIds': alertIds,
      'layout': layout.toString().split('.').last,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'settings': settings,
    };
  }

  /// Создать копию с изменениями
  MonitoringDashboard copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? metricIds,
    List<String>? alertIds,
    DashboardLayout? layout,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? settings,
  }) {
    return MonitoringDashboard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      metricIds: metricIds ?? this.metricIds,
      alertIds: alertIds ?? this.alertIds,
      layout: layout ?? this.layout,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
    );
  }

  /// Получить количество метрик
  int get metricCount => metricIds.length;

  /// Получить количество алертов
  int get alertCount => alertIds.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringDashboard &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.metricIds == metricIds &&
        other.alertIds == alertIds &&
        other.layout == layout &&
        other.isPublic == isPublic &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.settings == settings;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      metricIds,
      alertIds,
      layout,
      isPublic,
      createdAt,
      updatedAt,
      createdBy,
      settings,
    );
  }

  @override
  String toString() {
    return 'MonitoringDashboard(id: $id, name: $name, metrics: $metricCount, alerts: $alertCount)';
  }
}

/// Типы метрик
enum MetricType {
  counter,
  gauge,
  histogram,
  timer,
  rate,
}

/// Расширение для типов метрик
extension MetricTypeExtension on MetricType {
  String get displayName {
    switch (this) {
      case MetricType.counter:
        return 'Счетчик';
      case MetricType.gauge:
        return 'Измеритель';
      case MetricType.histogram:
        return 'Гистограмма';
      case MetricType.timer:
        return 'Таймер';
      case MetricType.rate:
        return 'Процент';
    }
  }

  String get description {
    switch (this) {
      case MetricType.counter:
        return 'Монотонно возрастающий счетчик';
      case MetricType.gauge:
        return 'Значение, которое может увеличиваться и уменьшаться';
      case MetricType.histogram:
        return 'Распределение значений';
      case MetricType.timer:
        return 'Время выполнения операции';
      case MetricType.rate:
        return 'Процентное соотношение';
    }
  }

  String get icon {
    switch (this) {
      case MetricType.counter:
        return '🔢';
      case MetricType.gauge:
        return '📊';
      case MetricType.histogram:
        return '📈';
      case MetricType.timer:
        return '⏱️';
      case MetricType.rate:
        return '📉';
    }
  }
}

/// Серьезность алертов
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Расширение для серьезности алертов
extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Низкая';
      case AlertSeverity.medium:
        return 'Средняя';
      case AlertSeverity.high:
        return 'Высокая';
      case AlertSeverity.critical:
        return 'Критическая';
    }
  }

  String get color {
    switch (this) {
      case AlertSeverity.low:
        return 'green';
      case AlertSeverity.medium:
        return 'yellow';
      case AlertSeverity.high:
        return 'orange';
      case AlertSeverity.critical:
        return 'red';
    }
  }

  String get icon {
    switch (this) {
      case AlertSeverity.low:
        return '🟢';
      case AlertSeverity.medium:
        return '🟡';
      case AlertSeverity.high:
        return '🟠';
      case AlertSeverity.critical:
        return '🔴';
    }
  }
}

/// Статусы алертов
enum AlertStatus {
  active,
  triggered,
  resolved,
  disabled,
}

/// Расширение для статусов алертов
extension AlertStatusExtension on AlertStatus {
  String get displayName {
    switch (this) {
      case AlertStatus.active:
        return 'Активен';
      case AlertStatus.triggered:
        return 'Сработал';
      case AlertStatus.resolved:
        return 'Решен';
      case AlertStatus.disabled:
        return 'Отключен';
    }
  }

  String get color {
    switch (this) {
      case AlertStatus.active:
        return 'blue';
      case AlertStatus.triggered:
        return 'red';
      case AlertStatus.resolved:
        return 'green';
      case AlertStatus.disabled:
        return 'grey';
    }
  }

  String get icon {
    switch (this) {
      case AlertStatus.active:
        return '🔵';
      case AlertStatus.triggered:
        return '🔴';
      case AlertStatus.resolved:
        return '🟢';
      case AlertStatus.disabled:
        return '⚫';
    }
  }
}

/// Макеты дашбордов
enum DashboardLayout {
  grid,
  list,
  custom,
}

/// Расширение для макетов дашбордов
extension DashboardLayoutExtension on DashboardLayout {
  String get displayName {
    switch (this) {
      case DashboardLayout.grid:
        return 'Сетка';
      case DashboardLayout.list:
        return 'Список';
      case DashboardLayout.custom:
        return 'Пользовательский';
    }
  }

  String get description {
    switch (this) {
      case DashboardLayout.grid:
        return 'Элементы расположены в виде сетки';
      case DashboardLayout.list:
        return 'Элементы расположены в виде списка';
      case DashboardLayout.custom:
        return 'Пользовательское расположение элементов';
    }
  }

  String get icon {
    switch (this) {
      case DashboardLayout.grid:
        return '⊞';
      case DashboardLayout.list:
        return '☰';
      case DashboardLayout.custom:
        return '⚙️';
    }
  }
}
