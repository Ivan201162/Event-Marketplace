import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель метрики производительности
class PerformanceMetric {
  const PerformanceMetric({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
    required this.unit,
    this.description,
    this.metadata = const {},
    required this.timestamp,
    this.sessionId,
    this.userId,
    this.deviceId,
  });

  /// Создать из документа Firestore
  factory PerformanceMetric.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PerformanceMetric(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      value: (data['value'] as num).toDouble(),
      unit: data['unit'] ?? '',
      description: data['description'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      sessionId: data['sessionId'],
      userId: data['userId'],
      deviceId: data['deviceId'],
    );
  }

  /// Создать из Map
  factory PerformanceMetric.fromMap(Map<String, dynamic> data) =>
      PerformanceMetric(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        category: data['category'] ?? '',
        value: (data['value'] as num).toDouble(),
        unit: data['unit'] ?? '',
        description: data['description'],
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        sessionId: data['sessionId'],
        userId: data['userId'],
        deviceId: data['deviceId'],
      );
  final String id;
  final String name;
  final String category;
  final double value;
  final String unit;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? sessionId;
  final String? userId;
  final String? deviceId;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'value': value,
        'unit': unit,
        'description': description,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionId': sessionId,
        'userId': userId,
        'deviceId': deviceId,
      };

  /// Создать копию с изменениями
  PerformanceMetric copyWith({
    String? id,
    String? name,
    String? category,
    double? value,
    String? unit,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    String? sessionId,
    String? userId,
    String? deviceId,
  }) =>
      PerformanceMetric(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        description: description ?? this.description,
        metadata: metadata ?? this.metadata,
        timestamp: timestamp ?? this.timestamp,
        sessionId: sessionId ?? this.sessionId,
        userId: userId ?? this.userId,
        deviceId: deviceId ?? this.deviceId,
      );

  /// Получить значение в читаемом формате
  String get formattedValue {
    if (unit == 'ms' || unit == 'milliseconds') {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(2)}s';
      }
      return '${value.toStringAsFixed(0)}ms';
    } else if (unit == 'bytes') {
      const units = ['B', 'KB', 'MB', 'GB'];
      var size = value.toInt();
      var unitIndex = 0;

      while (size >= 1024 && unitIndex < units.length - 1) {
        size ~/= 1024;
        unitIndex++;
      }

      return '$size ${units[unitIndex]}';
    } else if (unit == 'count') {
      return value.toStringAsFixed(0);
    } else if (unit == 'percentage') {
      return '${value.toStringAsFixed(1)}%';
    } else {
      return '${value.toStringAsFixed(2)} $unit';
    }
  }

  /// Проверить, является ли метрика критической
  bool get isCritical {
    switch (category) {
      case 'memory':
        return value > 100 * 1024 * 1024; // > 100MB
      case 'cpu':
        return value > 80; // > 80%
      case 'network':
        return value > 5000; // > 5s
      case 'database':
        return value > 1000; // > 1s
      case 'ui':
        return value > 16; // > 16ms (60fps)
      default:
        return false;
    }
  }

  /// Получить цвет для отображения метрики
  String get statusColor {
    if (isCritical) return 'red';
    if (value > _getWarningThreshold()) return 'orange';
    return 'green';
  }

  double _getWarningThreshold() {
    switch (category) {
      case 'memory':
        return 50 * 1024 * 1024; // 50MB
      case 'cpu':
        return 60; // 60%
      case 'network':
        return 2000; // 2s
      case 'database':
        return 500; // 500ms
      case 'ui':
        return 8; // 8ms
      default:
        return value * 0.7;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformanceMetric &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.value == value &&
        other.unit == unit &&
        other.description == description &&
        other.metadata == metadata &&
        other.timestamp == timestamp &&
        other.sessionId == sessionId &&
        other.userId == userId &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        value,
        unit,
        description,
        metadata,
        timestamp,
        sessionId,
        userId,
        deviceId,
      );

  @override
  String toString() =>
      'PerformanceMetric(id: $id, name: $name, value: $formattedValue)';
}

/// Модель статистики производительности
class PerformanceStatistics {
  const PerformanceStatistics({
    required this.metricName,
    required this.category,
    required this.totalSamples,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    required this.medianValue,
    required this.p95Value,
    required this.p99Value,
    required this.periodStart,
    required this.periodEnd,
    required this.samples,
  });

  /// Создать из списка метрик
  factory PerformanceStatistics.fromMetrics(
    String metricName,
    String category,
    List<PerformanceMetric> metrics,
  ) {
    if (metrics.isEmpty) {
      return PerformanceStatistics(
        metricName: metricName,
        category: category,
        totalSamples: 0,
        minValue: 0,
        maxValue: 0,
        avgValue: 0,
        medianValue: 0,
        p95Value: 0,
        p99Value: 0,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
        samples: [],
      );
    }

    final values = metrics.map((m) => m.value).toList()..sort();
    final totalSamples = values.length;

    final minValue = values.first;
    final maxValue = values.last;
    final avgValue = values.reduce((a, b) => a + b) / totalSamples;

    final medianValue = totalSamples % 2 == 0
        ? (values[totalSamples ~/ 2 - 1] + values[totalSamples ~/ 2]) / 2
        : values[totalSamples ~/ 2];

    final p95Index = (totalSamples * 0.95).floor();
    final p99Index = (totalSamples * 0.99).floor();

    final p95Value = values[p95Index];
    final p99Value = values[p99Index];

    final periodStart =
        metrics.map((m) => m.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
    final periodEnd =
        metrics.map((m) => m.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    return PerformanceStatistics(
      metricName: metricName,
      category: category,
      totalSamples: totalSamples,
      minValue: minValue,
      maxValue: maxValue,
      avgValue: avgValue,
      medianValue: medianValue,
      p95Value: p95Value,
      p99Value: p99Value,
      periodStart: periodStart,
      periodEnd: periodEnd,
      samples: metrics,
    );
  }
  final String metricName;
  final String category;
  final int totalSamples;
  final double minValue;
  final double maxValue;
  final double avgValue;
  final double medianValue;
  final double p95Value;
  final double p99Value;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<PerformanceMetric> samples;

  /// Получить тренд (улучшение/ухудшение)
  String get trend {
    if (totalSamples < 2) return 'stable';

    final firstHalf =
        samples.take(totalSamples ~/ 2).map((m) => m.value).toList();
    final secondHalf =
        samples.skip(totalSamples ~/ 2).map((m) => m.value).toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final change = (secondAvg - firstAvg) / firstAvg;

    if (change > 0.1) return 'worsening';
    if (change < -0.1) return 'improving';
    return 'stable';
  }

  /// Проверить, есть ли проблемы с производительностью
  bool get hasPerformanceIssues => p95Value > _getCriticalThreshold();

  double _getCriticalThreshold() {
    switch (category) {
      case 'memory':
        return 100 * 1024 * 1024; // 100MB
      case 'cpu':
        return 80; // 80%
      case 'network':
        return 5000; // 5s
      case 'database':
        return 1000; // 1s
      case 'ui':
        return 16; // 16ms
      default:
        return avgValue * 2;
    }
  }

  @override
  String toString() =>
      'PerformanceStatistics(metricName: $metricName, avgValue: ${avgValue.toStringAsFixed(2)}, totalSamples: $totalSamples)';
}

/// Модель алерта производительности
class PerformanceAlert {
  const PerformanceAlert({
    required this.id,
    required this.metricName,
    required this.category,
    required this.threshold,
    required this.currentValue,
    required this.severity,
    required this.message,
    required this.triggeredAt,
    this.resolvedAt,
    this.isActive = true,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory PerformanceAlert.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PerformanceAlert(
      id: doc.id,
      metricName: data['metricName'] ?? '',
      category: data['category'] ?? '',
      threshold: (data['threshold'] as num).toDouble(),
      currentValue: (data['currentValue'] as num).toDouble(),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == data['severity'],
        orElse: () => AlertSeverity.warning,
      ),
      message: data['message'] ?? '',
      triggeredAt: (data['triggeredAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из Map
  factory PerformanceAlert.fromMap(Map<String, dynamic> data) =>
      PerformanceAlert(
        id: data['id'] ?? '',
        metricName: data['metricName'] ?? '',
        category: data['category'] ?? '',
        threshold: (data['threshold'] as num).toDouble(),
        currentValue: (data['currentValue'] as num).toDouble(),
        severity: AlertSeverity.values.firstWhere(
          (e) => e.toString().split('.').last == data['severity'],
          orElse: () => AlertSeverity.warning,
        ),
        message: data['message'] ?? '',
        triggeredAt: (data['triggeredAt'] as Timestamp).toDate(),
        resolvedAt: data['resolvedAt'] != null
            ? (data['resolvedAt'] as Timestamp).toDate()
            : null,
        isActive: data['isActive'] ?? true,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
  final String id;
  final String metricName;
  final String category;
  final double threshold;
  final double currentValue;
  final AlertSeverity severity;
  final String message;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'metricName': metricName,
        'category': category,
        'threshold': threshold,
        'currentValue': currentValue,
        'severity': severity.toString().split('.').last,
        'message': message,
        'triggeredAt': Timestamp.fromDate(triggeredAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'isActive': isActive,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  PerformanceAlert copyWith({
    String? id,
    String? metricName,
    String? category,
    double? threshold,
    double? currentValue,
    AlertSeverity? severity,
    String? message,
    DateTime? triggeredAt,
    DateTime? resolvedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) =>
      PerformanceAlert(
        id: id ?? this.id,
        metricName: metricName ?? this.metricName,
        category: category ?? this.category,
        threshold: threshold ?? this.threshold,
        currentValue: currentValue ?? this.currentValue,
        severity: severity ?? this.severity,
        message: message ?? this.message,
        triggeredAt: triggeredAt ?? this.triggeredAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        isActive: isActive ?? this.isActive,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, решен ли алерт
  bool get isResolved => resolvedAt != null;

  /// Получить продолжительность алерта
  Duration get duration {
    final endTime = resolvedAt ?? DateTime.now();
    return endTime.difference(triggeredAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformanceAlert &&
        other.id == id &&
        other.metricName == metricName &&
        other.category == category &&
        other.threshold == threshold &&
        other.currentValue == currentValue &&
        other.severity == severity &&
        other.message == message &&
        other.triggeredAt == triggeredAt &&
        other.resolvedAt == resolvedAt &&
        other.isActive == isActive &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        metricName,
        category,
        threshold,
        currentValue,
        severity,
        message,
        triggeredAt,
        resolvedAt,
        isActive,
        metadata,
      );

  @override
  String toString() =>
      'PerformanceAlert(id: $id, metricName: $metricName, severity: $severity)';
}

/// Уровни серьезности алертов
enum AlertSeverity {
  info,
  warning,
  error,
  critical,
}

/// Расширение для уровней серьезности
extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Информация';
      case AlertSeverity.warning:
        return 'Предупреждение';
      case AlertSeverity.error:
        return 'Ошибка';
      case AlertSeverity.critical:
        return 'Критично';
    }
  }

  String get description {
    switch (this) {
      case AlertSeverity.info:
        return 'Информационное сообщение';
      case AlertSeverity.warning:
        return 'Требует внимания';
      case AlertSeverity.error:
        return 'Серьезная проблема';
      case AlertSeverity.critical:
        return 'Критическая проблема';
    }
  }

  String get color {
    switch (this) {
      case AlertSeverity.info:
        return 'blue';
      case AlertSeverity.warning:
        return 'orange';
      case AlertSeverity.error:
        return 'red';
      case AlertSeverity.critical:
        return 'purple';
    }
  }
}
