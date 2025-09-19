import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для KPI метрик
class KPIMetric {
  const KPIMetric({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.unit,
    required this.value,
    this.target,
    this.previousValue,
    this.change,
    this.changePercentage,
    required this.status,
    required this.timestamp,
    this.lastUpdated,
    this.dataSource,
    required this.metadata,
    required this.tags,
    required this.isActive,
    required this.createdBy,
    required this.updatedBy,
  });

  factory KPIMetric.fromMap(Map<String, dynamic> map) => KPIMetric(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        type: MetricType.fromString(map['type'] ?? 'counter'),
        category: MetricCategory.fromString(map['category'] ?? 'business'),
        unit: map['unit'] ?? '',
        value: (map['value'] ?? 0.0).toDouble(),
        target: map['target']?.toDouble(),
        previousValue: map['previousValue']?.toDouble(),
        change: map['change']?.toDouble(),
        changePercentage: map['changePercentage']?.toDouble(),
        status: MetricStatus.fromString(map['status'] ?? 'normal'),
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        lastUpdated: map['lastUpdated'] != null
            ? (map['lastUpdated'] as Timestamp).toDate()
            : null,
        dataSource: map['dataSource'],
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        tags: List<String>.from(map['tags'] ?? []),
        isActive: map['isActive'] ?? true,
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String name;
  final String description;
  final MetricType type;
  final MetricCategory category;
  final String unit;
  final double value;
  final double? target;
  final double? previousValue;
  final double? change;
  final double? changePercentage;
  final MetricStatus status;
  final DateTime timestamp;
  final DateTime? lastUpdated;
  final String? dataSource;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final bool isActive;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.value,
        'category': category.value,
        'unit': unit,
        'value': value,
        'target': target,
        'previousValue': previousValue,
        'change': change,
        'changePercentage': changePercentage,
        'status': status.value,
        'timestamp': Timestamp.fromDate(timestamp),
        'lastUpdated':
            lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
        'dataSource': dataSource,
        'metadata': metadata,
        'tags': tags,
        'isActive': isActive,
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  KPIMetric copyWith({
    String? id,
    String? name,
    String? description,
    MetricType? type,
    MetricCategory? category,
    String? unit,
    double? value,
    double? target,
    double? previousValue,
    double? change,
    double? changePercentage,
    MetricStatus? status,
    DateTime? timestamp,
    DateTime? lastUpdated,
    String? dataSource,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
  }) =>
      KPIMetric(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        category: category ?? this.category,
        unit: unit ?? this.unit,
        value: value ?? this.value,
        target: target ?? this.target,
        previousValue: previousValue ?? this.previousValue,
        change: change ?? this.change,
        changePercentage: changePercentage ?? this.changePercentage,
        status: status ?? this.status,
        timestamp: timestamp ?? this.timestamp,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        dataSource: dataSource ?? this.dataSource,
        metadata: metadata ?? this.metadata,
        tags: tags ?? this.tags,
        isActive: isActive ?? this.isActive,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'KPIMetric(id: $id, name: $name, value: $value, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KPIMetric && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы метрик
enum MetricType {
  counter('counter', 'Счетчик'),
  gauge('gauge', 'Измеритель'),
  histogram('histogram', 'Гистограмма'),
  timer('timer', 'Таймер'),
  rate('rate', 'Скорость'),
  percentage('percentage', 'Процент'),
  ratio('ratio', 'Соотношение'),
  average('average', 'Среднее'),
  sum('sum', 'Сумма'),
  min('min', 'Минимум'),
  max('max', 'Максимум');

  const MetricType(this.value, this.displayName);

  final String value;
  final String displayName;

  static MetricType fromString(String value) => MetricType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => MetricType.counter,
      );

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
      case MetricType.percentage:
        return '📊';
      case MetricType.ratio:
        return '⚖️';
      case MetricType.average:
        return '📊';
      case MetricType.sum:
        return '➕';
      case MetricType.min:
        return '📉';
      case MetricType.max:
        return '📈';
    }
  }

  String get color {
    switch (this) {
      case MetricType.counter:
        return 'blue';
      case MetricType.gauge:
        return 'green';
      case MetricType.histogram:
        return 'purple';
      case MetricType.timer:
        return 'orange';
      case MetricType.rate:
        return 'red';
      case MetricType.percentage:
        return 'teal';
      case MetricType.ratio:
        return 'indigo';
      case MetricType.average:
        return 'cyan';
      case MetricType.sum:
        return 'lime';
      case MetricType.min:
        return 'pink';
      case MetricType.max:
        return 'brown';
    }
  }
}

/// Категории метрик
enum MetricCategory {
  business('business', 'Бизнес'),
  technical('technical', 'Технические'),
  user('user', 'Пользователи'),
  performance('performance', 'Производительность'),
  security('security', 'Безопасность'),
  financial('financial', 'Финансовые'),
  operational('operational', 'Операционные'),
  quality('quality', 'Качество'),
  compliance('compliance', 'Соответствие'),
  innovation('innovation', 'Инновации');

  const MetricCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static MetricCategory fromString(String value) =>
      MetricCategory.values.firstWhere(
        (category) => category.value == value,
        orElse: () => MetricCategory.business,
      );

  String get icon {
    switch (this) {
      case MetricCategory.business:
        return '💼';
      case MetricCategory.technical:
        return '⚙️';
      case MetricCategory.user:
        return '👥';
      case MetricCategory.performance:
        return '🚀';
      case MetricCategory.security:
        return '🔒';
      case MetricCategory.financial:
        return '💰';
      case MetricCategory.operational:
        return '🔧';
      case MetricCategory.quality:
        return '⭐';
      case MetricCategory.compliance:
        return '📋';
      case MetricCategory.innovation:
        return '💡';
    }
  }

  String get color {
    switch (this) {
      case MetricCategory.business:
        return 'blue';
      case MetricCategory.technical:
        return 'green';
      case MetricCategory.user:
        return 'purple';
      case MetricCategory.performance:
        return 'orange';
      case MetricCategory.security:
        return 'red';
      case MetricCategory.financial:
        return 'yellow';
      case MetricCategory.operational:
        return 'teal';
      case MetricCategory.quality:
        return 'indigo';
      case MetricCategory.compliance:
        return 'cyan';
      case MetricCategory.innovation:
        return 'lime';
    }
  }
}

/// Статусы метрик
enum MetricStatus {
  normal('normal', 'Норма'),
  warning('warning', 'Предупреждение'),
  critical('critical', 'Критический'),
  error('error', 'Ошибка'),
  unknown('unknown', 'Неизвестно');

  const MetricStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static MetricStatus fromString(String value) =>
      MetricStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => MetricStatus.normal,
      );

  String get icon {
    switch (this) {
      case MetricStatus.normal:
        return '✅';
      case MetricStatus.warning:
        return '⚠️';
      case MetricStatus.critical:
        return '🚨';
      case MetricStatus.error:
        return '❌';
      case MetricStatus.unknown:
        return '❓';
    }
  }

  String get color {
    switch (this) {
      case MetricStatus.normal:
        return 'green';
      case MetricStatus.warning:
        return 'orange';
      case MetricStatus.critical:
        return 'red';
      case MetricStatus.error:
        return 'red';
      case MetricStatus.unknown:
        return 'grey';
    }
  }
}

/// Модель для дашборда KPI
class KPIDashboard {
  const KPIDashboard({
    required this.id,
    required this.name,
    required this.description,
    required this.metricIds,
    required this.layout,
    required this.tags,
    required this.isPublic,
    required this.isDefault,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory KPIDashboard.fromMap(Map<String, dynamic> map) => KPIDashboard(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        metricIds: List<String>.from(map['metricIds'] ?? []),
        layout: DashboardLayout.fromString(map['layout'] ?? 'grid'),
        tags: List<String>.from(map['tags'] ?? []),
        isPublic: map['isPublic'] ?? false,
        isDefault: map['isDefault'] ?? false,
        settings: Map<String, dynamic>.from(map['settings'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String name;
  final String description;
  final List<String> metricIds;
  final DashboardLayout layout;
  final List<String> tags;
  final bool isPublic;
  final bool isDefault;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'metricIds': metricIds,
        'layout': layout.value,
        'tags': tags,
        'isPublic': isPublic,
        'isDefault': isDefault,
        'settings': settings,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  KPIDashboard copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? metricIds,
    DashboardLayout? layout,
    List<String>? tags,
    bool? isPublic,
    bool? isDefault,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      KPIDashboard(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        metricIds: metricIds ?? this.metricIds,
        layout: layout ?? this.layout,
        tags: tags ?? this.tags,
        isPublic: isPublic ?? this.isPublic,
        isDefault: isDefault ?? this.isDefault,
        settings: settings ?? this.settings,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'KPIDashboard(id: $id, name: $name, metricIds: ${metricIds.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KPIDashboard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы макетов дашборда
enum DashboardLayout {
  grid('grid', 'Сетка'),
  list('list', 'Список'),
  chart('chart', 'График'),
  table('table', 'Таблица'),
  mixed('mixed', 'Смешанный');

  const DashboardLayout(this.value, this.displayName);

  final String value;
  final String displayName;

  static DashboardLayout fromString(String value) =>
      DashboardLayout.values.firstWhere(
        (layout) => layout.value == value,
        orElse: () => DashboardLayout.grid,
      );

  String get icon {
    switch (this) {
      case DashboardLayout.grid:
        return '⊞';
      case DashboardLayout.list:
        return '☰';
      case DashboardLayout.chart:
        return '📊';
      case DashboardLayout.table:
        return '⊞';
      case DashboardLayout.mixed:
        return '🔀';
    }
  }
}

/// Модель для отчета KPI
class KPIReport {
  const KPIReport({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.metricIds,
    required this.dashboardIds,
    required this.startDate,
    required this.endDate,
    this.template,
    required this.filters,
    required this.settings,
    required this.status,
    this.fileUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory KPIReport.fromMap(Map<String, dynamic> map) => KPIReport(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        type: ReportType.fromString(map['type'] ?? 'summary'),
        metricIds: List<String>.from(map['metricIds'] ?? []),
        dashboardIds: List<String>.from(map['dashboardIds'] ?? []),
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        template: map['template'],
        filters: Map<String, dynamic>.from(map['filters'] ?? {}),
        settings: Map<String, dynamic>.from(map['settings'] ?? {}),
        status: ReportStatus.fromString(map['status'] ?? 'draft'),
        fileUrl: map['fileUrl'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final List<String> metricIds;
  final List<String> dashboardIds;
  final DateTime startDate;
  final DateTime endDate;
  final String? template;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> settings;
  final ReportStatus status;
  final String? fileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.value,
        'metricIds': metricIds,
        'dashboardIds': dashboardIds,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'template': template,
        'filters': filters,
        'settings': settings,
        'status': status.value,
        'fileUrl': fileUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  KPIReport copyWith({
    String? id,
    String? name,
    String? description,
    ReportType? type,
    List<String>? metricIds,
    List<String>? dashboardIds,
    DateTime? startDate,
    DateTime? endDate,
    String? template,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? settings,
    ReportStatus? status,
    String? fileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      KPIReport(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        metricIds: metricIds ?? this.metricIds,
        dashboardIds: dashboardIds ?? this.dashboardIds,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        template: template ?? this.template,
        filters: filters ?? this.filters,
        settings: settings ?? this.settings,
        status: status ?? this.status,
        fileUrl: fileUrl ?? this.fileUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'KPIReport(id: $id, name: $name, type: $type, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KPIReport && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы отчетов
enum ReportType {
  summary('summary', 'Сводный'),
  detailed('detailed', 'Детальный'),
  comparative('comparative', 'Сравнительный'),
  trend('trend', 'Трендовый'),
  custom('custom', 'Пользовательский');

  const ReportType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ReportType fromString(String value) => ReportType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => ReportType.summary,
      );

  String get icon {
    switch (this) {
      case ReportType.summary:
        return '📋';
      case ReportType.detailed:
        return '📊';
      case ReportType.comparative:
        return '⚖️';
      case ReportType.trend:
        return '📈';
      case ReportType.custom:
        return '🎨';
    }
  }
}

/// Статусы отчетов
enum ReportStatus {
  draft('draft', 'Черновик'),
  generating('generating', 'Генерируется'),
  ready('ready', 'Готов'),
  failed('failed', 'Ошибка'),
  archived('archived', 'Архивирован');

  const ReportStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static ReportStatus fromString(String value) =>
      ReportStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ReportStatus.draft,
      );

  String get icon {
    switch (this) {
      case ReportStatus.draft:
        return '📝';
      case ReportStatus.generating:
        return '⏳';
      case ReportStatus.ready:
        return '✅';
      case ReportStatus.failed:
        return '❌';
      case ReportStatus.archived:
        return '📦';
    }
  }

  String get color {
    switch (this) {
      case ReportStatus.draft:
        return 'grey';
      case ReportStatus.generating:
        return 'blue';
      case ReportStatus.ready:
        return 'green';
      case ReportStatus.failed:
        return 'red';
      case ReportStatus.archived:
        return 'brown';
    }
  }
}
