import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип метрики
enum MetricType { counter, gauge, histogram, summary }

/// Модель метрики производительности
class PerformanceMetric {
  const PerformanceMetric({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.labels = const {},
    this.timestamp,
    this.description,
    this.unit,
    this.metadata = const {},
  });

  final String id;
  final String name;
  final MetricType type;
  final double value;
  final Map<String, String> labels;
  final DateTime? timestamp;
  final String? description;
  final String? unit;
  final Map<String, dynamic> metadata;

  /// Создать из Map
  factory PerformanceMetric.fromMap(Map<String, dynamic> data) {
    return PerformanceMetric(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: _parseType(data['type']),
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      labels: Map<String, String>.from(data['labels'] ?? {}),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.tryParse(data['timestamp'].toString()))
          : null,
      description: data['description'] as String?,
      unit: data['unit'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из документа Firestore
  factory PerformanceMetric.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return PerformanceMetric.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'value': value,
    'labels': labels,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    'description': description,
    'unit': unit,
    'metadata': metadata,
  };

  /// Копировать с изменениями
  PerformanceMetric copyWith({
    String? id,
    String? name,
    MetricType? type,
    double? value,
    Map<String, String>? labels,
    DateTime? timestamp,
    String? description,
    String? unit,
    Map<String, dynamic>? metadata,
  }) => PerformanceMetric(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    value: value ?? this.value,
    labels: labels ?? this.labels,
    timestamp: timestamp ?? this.timestamp,
    description: description ?? this.description,
    unit: unit ?? this.unit,
    metadata: metadata ?? this.metadata,
  );

  /// Парсинг типа из строки
  static MetricType _parseType(String? type) {
    switch (type) {
      case 'counter':
        return MetricType.counter;
      case 'gauge':
        return MetricType.gauge;
      case 'histogram':
        return MetricType.histogram;
      case 'summary':
        return MetricType.summary;
      default:
        return MetricType.gauge;
    }
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case MetricType.counter:
        return 'Счетчик';
      case MetricType.gauge:
        return 'Измеритель';
      case MetricType.histogram:
        return 'Гистограмма';
      case MetricType.summary:
        return 'Сводка';
    }
  }

  /// Получить отформатированное значение
  String get formattedValue {
    if (unit != null) {
      return '${value.toStringAsFixed(2)} $unit';
    }
    return value.toStringAsFixed(2);
  }

  /// Проверить, является ли метрика счетчиком
  bool get isCounter => type == MetricType.counter;

  /// Проверить, является ли метрика измерителем
  bool get isGauge => type == MetricType.gauge;

  /// Проверить, является ли метрика гистограммой
  bool get isHistogram => type == MetricType.histogram;

  /// Проверить, является ли метрика сводкой
  bool get isSummary => type == MetricType.summary;
}

/// Модель события мониторинга
class MonitoringEvent {
  const MonitoringEvent({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.message,
    this.source,
    this.userId,
    this.sessionId,
    this.tags = const {},
    this.data = const {},
    this.timestamp,
    this.resolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.metadata = const {},
  });

  final String id;
  final String eventType;
  final String severity;
  final String message;
  final String? source;
  final String? userId;
  final String? sessionId;
  final Map<String, String> tags;
  final Map<String, dynamic> data;
  final DateTime? timestamp;
  final bool resolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final Map<String, dynamic> metadata;

  /// Создать из Map
  factory MonitoringEvent.fromMap(Map<String, dynamic> data) {
    return MonitoringEvent(
      id: data['id'] as String? ?? '',
      eventType: data['eventType'] as String? ?? '',
      severity: data['severity'] as String? ?? 'info',
      message: data['message'] as String? ?? '',
      source: data['source'] as String?,
      userId: data['userId'] as String?,
      sessionId: data['sessionId'] as String?,
      tags: Map<String, String>.from(data['tags'] ?? {}),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.tryParse(data['timestamp'].toString()))
          : null,
      resolved: data['resolved'] as bool? ?? false,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] is Timestamp
                ? (data['resolvedAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['resolvedAt'].toString()))
          : null,
      resolvedBy: data['resolvedBy'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из документа Firestore
  factory MonitoringEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return MonitoringEvent.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'eventType': eventType,
    'severity': severity,
    'message': message,
    'source': source,
    'userId': userId,
    'sessionId': sessionId,
    'tags': tags,
    'data': data,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    'resolved': resolved,
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'resolvedBy': resolvedBy,
    'metadata': metadata,
  };

  /// Копировать с изменениями
  MonitoringEvent copyWith({
    String? id,
    String? eventType,
    String? severity,
    String? message,
    String? source,
    String? userId,
    String? sessionId,
    Map<String, String>? tags,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? resolved,
    DateTime? resolvedAt,
    String? resolvedBy,
    Map<String, dynamic>? metadata,
  }) => MonitoringEvent(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    severity: severity ?? this.severity,
    message: message ?? this.message,
    source: source ?? this.source,
    userId: userId ?? this.userId,
    sessionId: sessionId ?? this.sessionId,
    tags: tags ?? this.tags,
    data: data ?? this.data,
    timestamp: timestamp ?? this.timestamp,
    resolved: resolved ?? this.resolved,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    resolvedBy: resolvedBy ?? this.resolvedBy,
    metadata: metadata ?? this.metadata,
  );

  /// Получить отображаемое название серьезности
  String get severityDisplayName {
    switch (severity) {
      case 'debug':
        return 'Отладка';
      case 'info':
        return 'Информация';
      case 'warning':
        return 'Предупреждение';
      case 'error':
        return 'Ошибка';
      case 'critical':
        return 'Критическая';
      default:
        return 'Неизвестно';
    }
  }

  /// Получить цвет для серьезности
  String get severityColor {
    switch (severity) {
      case 'debug':
        return 'blue';
      case 'info':
        return 'green';
      case 'warning':
        return 'orange';
      case 'error':
        return 'red';
      case 'critical':
        return 'purple';
      default:
        return 'gray';
    }
  }

  /// Проверить, является ли событие критическим
  bool get isCritical => severity == 'critical';

  /// Проверить, является ли событие ошибкой
  bool get isError => severity == 'error';

  /// Проверить, является ли событие предупреждением
  bool get isWarning => severity == 'warning';

  /// Проверить, является ли событие информационным
  bool get isInfo => severity == 'info';

  /// Проверить, является ли событие отладочным
  bool get isDebug => severity == 'debug';

  /// Проверить, решено ли событие
  bool get isResolved => resolved;

  /// Проверить, есть ли теги
  bool get hasTags => tags.isNotEmpty;

  /// Проверить, есть ли данные
  bool get hasData => data.isNotEmpty;
}

/// Модель статистики мониторинга
class MonitoringStats {
  const MonitoringStats({
    required this.period,
    this.totalEvents = 0,
    this.errorEvents = 0,
    this.warningEvents = 0,
    this.infoEvents = 0,
    this.debugEvents = 0,
    this.criticalEvents = 0,
    this.resolvedEvents = 0,
    this.unresolvedEvents = 0,
    this.averageResponseTime = 0.0,
    this.uptime = 100.0,
    this.errorRate = 0.0,
    this.metadata = const {},
  });

  final String period;
  final int totalEvents;
  final int errorEvents;
  final int warningEvents;
  final int infoEvents;
  final int debugEvents;
  final int criticalEvents;
  final int resolvedEvents;
  final int unresolvedEvents;
  final double averageResponseTime;
  final double uptime;
  final double errorRate;
  final Map<String, dynamic> metadata;

  /// Создать из Map
  factory MonitoringStats.fromMap(Map<String, dynamic> data) {
    return MonitoringStats(
      period: data['period'] as String? ?? '',
      totalEvents: data['totalEvents'] as int? ?? 0,
      errorEvents: data['errorEvents'] as int? ?? 0,
      warningEvents: data['warningEvents'] as int? ?? 0,
      infoEvents: data['infoEvents'] as int? ?? 0,
      debugEvents: data['debugEvents'] as int? ?? 0,
      criticalEvents: data['criticalEvents'] as int? ?? 0,
      resolvedEvents: data['resolvedEvents'] as int? ?? 0,
      unresolvedEvents: data['unresolvedEvents'] as int? ?? 0,
      averageResponseTime: (data['averageResponseTime'] as num?)?.toDouble() ?? 0.0,
      uptime: (data['uptime'] as num?)?.toDouble() ?? 100.0,
      errorRate: (data['errorRate'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'period': period,
    'totalEvents': totalEvents,
    'errorEvents': errorEvents,
    'warningEvents': warningEvents,
    'infoEvents': infoEvents,
    'debugEvents': debugEvents,
    'criticalEvents': criticalEvents,
    'resolvedEvents': resolvedEvents,
    'unresolvedEvents': unresolvedEvents,
    'averageResponseTime': averageResponseTime,
    'uptime': uptime,
    'errorRate': errorRate,
    'metadata': metadata,
  };

  /// Копировать с изменениями
  MonitoringStats copyWith({
    String? period,
    int? totalEvents,
    int? errorEvents,
    int? warningEvents,
    int? infoEvents,
    int? debugEvents,
    int? criticalEvents,
    int? resolvedEvents,
    int? unresolvedEvents,
    double? averageResponseTime,
    double? uptime,
    double? errorRate,
    Map<String, dynamic>? metadata,
  }) => MonitoringStats(
    period: period ?? this.period,
    totalEvents: totalEvents ?? this.totalEvents,
    errorEvents: errorEvents ?? this.errorEvents,
    warningEvents: warningEvents ?? this.warningEvents,
    infoEvents: infoEvents ?? this.infoEvents,
    debugEvents: debugEvents ?? this.debugEvents,
    criticalEvents: criticalEvents ?? this.criticalEvents,
    resolvedEvents: resolvedEvents ?? this.resolvedEvents,
    unresolvedEvents: unresolvedEvents ?? this.unresolvedEvents,
    averageResponseTime: averageResponseTime ?? this.averageResponseTime,
    uptime: uptime ?? this.uptime,
    errorRate: errorRate ?? this.errorRate,
    metadata: metadata ?? this.metadata,
  );

  /// Получить процент ошибок
  double get errorPercentage {
    if (totalEvents == 0) return 0.0;
    return (errorEvents / totalEvents) * 100;
  }

  /// Получить процент предупреждений
  double get warningPercentage {
    if (totalEvents == 0) return 0.0;
    return (warningEvents / totalEvents) * 100;
  }

  /// Получить процент решенных событий
  double get resolutionRate {
    if (totalEvents == 0) return 0.0;
    return (resolvedEvents / totalEvents) * 100;
  }

  /// Получить отформатированное время ответа
  String get formattedResponseTime {
    if (averageResponseTime < 1000) {
      return '${averageResponseTime.toStringAsFixed(0)} мс';
    } else {
      final seconds = averageResponseTime / 1000;
      return '${seconds.toStringAsFixed(2)} с';
    }
  }

  /// Получить отформатированный процент времени работы
  String get formattedUptime {
    return '${uptime.toStringAsFixed(2)}%';
  }

  /// Получить отформатированный процент ошибок
  String get formattedErrorRate {
    return '${errorRate.toStringAsFixed(2)}%';
  }
}
