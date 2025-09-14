import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы метрик
enum MetricType {
  bookings,      // Заявки
  payments,      // Платежи
  reviews,       // Отзывы
  users,         // Пользователи
  revenue,       // Доходы
  conversion,    // Конверсия
}

/// Периоды для аналитики
enum AnalyticsPeriod {
  day,      // День
  week,     // Неделя
  month,    // Месяц
  quarter,  // Квартал
  year,     // Год
}

/// Модель метрики
class Metric {
  final String id;
  final String name;
  final MetricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? userId;
  final String? category;

  const Metric({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
    this.userId,
    this.category,
  });

  /// Создать из документа Firestore
  factory Metric.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Metric(
      id: doc.id,
      name: data['name'] ?? '',
      type: _parseMetricType(data['type']),
      value: (data['value'] as num).toDouble(),
      unit: data['unit'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      metadata: data['metadata'],
      userId: data['userId'],
      category: data['category'],
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'userId': userId,
      'category': category,
    };
  }

  /// Парсинг типа метрики
  static MetricType _parseMetricType(dynamic typeData) {
    if (typeData == null) return MetricType.bookings;
    
    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'payments':
        return MetricType.payments;
      case 'reviews':
        return MetricType.reviews;
      case 'users':
        return MetricType.users;
      case 'revenue':
        return MetricType.revenue;
      case 'conversion':
        return MetricType.conversion;
      case 'bookings':
      default:
        return MetricType.bookings;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Metric && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Metric(id: $id, name: $name, value: $value $unit)';
  }
}

/// Модель отчета
class Report {
  final String id;
  final String title;
  final String description;
  final ReportType type;
  final AnalyticsPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? userId;
  final bool isPublic;

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.createdAt,
    this.userId,
    this.isPublic = false,
  });

  /// Создать из документа Firestore
  factory Report.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: _parseReportType(data['type']),
      period: _parseAnalyticsPeriod(data['period']),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      data: data['data'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'],
      isPublic: data['isPublic'] ?? false,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'period': period.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'isPublic': isPublic,
    };
  }

  /// Парсинг типа отчета
  static ReportType _parseReportType(dynamic typeData) {
    if (typeData == null) return ReportType.summary;
    
    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'financial':
        return ReportType.financial;
      case 'performance':
        return ReportType.performance;
      case 'user_activity':
        return ReportType.userActivity;
      case 'custom':
        return ReportType.custom;
      case 'summary':
      default:
        return ReportType.summary;
    }
  }

  /// Парсинг периода аналитики
  static AnalyticsPeriod _parseAnalyticsPeriod(dynamic periodData) {
    if (periodData == null) return AnalyticsPeriod.month;
    
    final periodString = periodData.toString().toLowerCase();
    switch (periodString) {
      case 'day':
        return AnalyticsPeriod.day;
      case 'week':
        return AnalyticsPeriod.week;
      case 'quarter':
        return AnalyticsPeriod.quarter;
      case 'year':
        return AnalyticsPeriod.year;
      case 'month':
      default:
        return AnalyticsPeriod.month;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Report && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Report(id: $id, title: $title, type: $type)';
  }
}

/// Типы отчетов
enum ReportType {
  summary,        // Сводный отчет
  financial,      // Финансовый отчет
  performance,    // Отчет по производительности
  userActivity,   // Активность пользователей
  custom,         // Пользовательский отчет
}

/// Модель дашборда
class Dashboard {
  final String id;
  final String title;
  final String description;
  final List<DashboardWidget> widgets;
  final String? userId;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dashboard({
    required this.id,
    required this.title,
    required this.description,
    required this.widgets,
    this.userId,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory Dashboard.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dashboard(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      widgets: (data['widgets'] as List<dynamic>?)
          ?.map((w) => DashboardWidget.fromMap(w as Map<String, dynamic>))
          .toList() ?? [],
      userId: data['userId'],
      isPublic: data['isPublic'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'widgets': widgets.map((w) => w.toMap()).toList(),
      'userId': userId,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dashboard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Dashboard(id: $id, title: $title, widgets: ${widgets.length})';
  }
}

/// Виджет дашборда
class DashboardWidget {
  final String id;
  final String title;
  final WidgetType type;
  final Map<String, dynamic> config;
  final int position;
  final int size;

  const DashboardWidget({
    required this.id,
    required this.title,
    required this.type,
    required this.config,
    required this.position,
    this.size = 1,
  });

  /// Создать из Map
  factory DashboardWidget.fromMap(Map<String, dynamic> map) {
    return DashboardWidget(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: _parseWidgetType(map['type']),
      config: map['config'] ?? {},
      position: map['position'] ?? 0,
      size: map['size'] ?? 1,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'config': config,
      'position': position,
      'size': size,
    };
  }

  /// Парсинг типа виджета
  static WidgetType _parseWidgetType(dynamic typeData) {
    if (typeData == null) return WidgetType.metric;
    
    final typeString = typeData.toString().toLowerCase();
    switch (typeString) {
      case 'chart':
        return WidgetType.chart;
      case 'table':
        return WidgetType.table;
      case 'kpi':
        return WidgetType.kpi;
      case 'metric':
      default:
        return WidgetType.metric;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardWidget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DashboardWidget(id: $id, title: $title, type: $type)';
  }
}

/// Типы виджетов
enum WidgetType {
  metric,  // Метрика
  chart,   // График
  table,   // Таблица
  kpi,     // KPI
}

/// Статистика по периодам
class PeriodStatistics {
  final AnalyticsPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, double> metrics;
  final List<Metric> detailedMetrics;

  const PeriodStatistics({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.metrics,
    required this.detailedMetrics,
  });

  /// Получить метрику по имени
  double getMetric(String name) {
    return metrics[name] ?? 0.0;
  }

  /// Получить процентное изменение по сравнению с предыдущим периодом
  double getPercentageChange(String metricName, PeriodStatistics? previousPeriod) {
    if (previousPeriod == null) return 0.0;
    
    final currentValue = getMetric(metricName);
    final previousValue = previousPeriod.getMetric(metricName);
    
    if (previousValue == 0) return currentValue > 0 ? 100.0 : 0.0;
    
    return ((currentValue - previousValue) / previousValue) * 100;
  }
}

/// KPI (Ключевые показатели эффективности)
class KPI {
  final String name;
  final double value;
  final String unit;
  final double target;
  final double previousValue;
  final String description;

  const KPI({
    required this.name,
    required this.value,
    required this.unit,
    required this.target,
    required this.previousValue,
    required this.description,
  });

  /// Получить процент выполнения цели
  double get targetAchievement {
    if (target == 0) return 0.0;
    return (value / target) * 100;
  }

  /// Получить процентное изменение
  double get percentageChange {
    if (previousValue == 0) return value > 0 ? 100.0 : 0.0;
    return ((value - previousValue) / previousValue) * 100;
  }

  /// Проверить, достигнута ли цель
  bool get isTargetAchieved => value >= target;

  /// Получить статус KPI
  KPIStatus get status {
    if (isTargetAchieved) return KPIStatus.excellent;
    if (targetAchievement >= 80) return KPIStatus.good;
    if (targetAchievement >= 60) return KPIStatus.average;
    return KPIStatus.poor;
  }
}

/// Статусы KPI
enum KPIStatus {
  excellent,  // Отлично
  good,       // Хорошо
  average,    // Средне
  poor,       // Плохо
}
