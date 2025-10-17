import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отчета
class Report {
  const Report({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    this.parameters = const {},
    this.generatedBy,
    required this.createdAt,
    this.generatedAt,
    this.status = ReportStatus.pending,
    this.fileUrl,
    this.errorMessage,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory Report.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Report(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ReportType.custom,
      ),
      category: ReportCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => ReportCategory.general,
      ),
      parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
      generatedBy: data['generatedBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      generatedAt: data['generatedAt'] != null ? (data['generatedAt'] as Timestamp).toDate() : null,
      status: ReportStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      fileUrl: data['fileUrl'],
      errorMessage: data['errorMessage'],
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
    );
  }

  /// Создать из Map
  factory Report.fromMap(Map<String, dynamic> data) => Report(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        type: ReportType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => ReportType.custom,
        ),
        category: ReportCategory.values.firstWhere(
          (e) => e.toString().split('.').last == data['category'],
          orElse: () => ReportCategory.general,
        ),
        parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
        generatedBy: data['generatedBy'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        generatedAt:
            data['generatedAt'] != null ? (data['generatedAt'] as Timestamp).toDate() : null,
        status: ReportStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => ReportStatus.pending,
        ),
        fileUrl: data['fileUrl'],
        errorMessage: data['errorMessage'],
        metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      );
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final ReportCategory category;
  final Map<String, dynamic> parameters;
  final String? generatedBy;
  final DateTime createdAt;
  final DateTime? generatedAt;
  final ReportStatus status;
  final String? fileUrl;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'type': type.toString().split('.').last,
        'category': category.toString().split('.').last,
        'parameters': parameters,
        'generatedBy': generatedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'generatedAt': generatedAt != null ? Timestamp.fromDate(generatedAt!) : null,
        'status': status.toString().split('.').last,
        'fileUrl': fileUrl,
        'errorMessage': errorMessage,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  Report copyWith({
    String? id,
    String? name,
    String? description,
    ReportType? type,
    ReportCategory? category,
    Map<String, dynamic>? parameters,
    String? generatedBy,
    DateTime? createdAt,
    DateTime? generatedAt,
    ReportStatus? status,
    String? fileUrl,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) =>
      Report(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        category: category ?? this.category,
        parameters: parameters ?? this.parameters,
        generatedBy: generatedBy ?? this.generatedBy,
        createdAt: createdAt ?? this.createdAt,
        generatedAt: generatedAt ?? this.generatedAt,
        status: status ?? this.status,
        fileUrl: fileUrl ?? this.fileUrl,
        errorMessage: errorMessage ?? this.errorMessage,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, готов ли отчет
  bool get isReady => status == ReportStatus.completed && fileUrl != null;

  /// Проверить, есть ли ошибка
  bool get hasError => status == ReportStatus.failed;

  /// Проверить, генерируется ли отчет
  bool get isGenerating => status == ReportStatus.generating;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Report &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.category == category &&
        other.parameters == parameters &&
        other.generatedBy == generatedBy &&
        other.createdAt == createdAt &&
        other.generatedAt == generatedAt &&
        other.status == status &&
        other.fileUrl == fileUrl &&
        other.errorMessage == errorMessage &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        type,
        category,
        parameters,
        generatedBy,
        createdAt,
        generatedAt,
        status,
        fileUrl,
        errorMessage,
        metadata,
      );

  @override
  String toString() => 'Report(id: $id, name: $name, status: $status)';
}

/// Типы отчетов
enum ReportType {
  custom,
  bookings,
  payments,
  users,
  specialists,
  analytics,
  notifications,
  errors,
  performance,
}

/// Категории отчетов
enum ReportCategory {
  general,
  financial,
  operational,
  marketing,
  technical,
  user,
}

/// Статусы отчетов
enum ReportStatus {
  pending,
  generating,
  completed,
  failed,
}

/// Модель данных отчета
class ReportData {
  const ReportData({
    required this.reportId,
    required this.rows,
    required this.columns,
    required this.summary,
    required this.generatedAt,
    required this.totalRows,
  });

  /// Создать из документа Firestore
  factory ReportData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ReportData(
      reportId: doc.id,
      rows: List<Map<String, dynamic>>.from(data['rows'] ?? []),
      columns: List<String>.from(data['columns'] ?? []),
      summary: Map<String, dynamic>.from(data['summary'] ?? {}),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      totalRows: data['totalRows'] as int? ?? 0,
    );
  }

  /// Создать из Map
  factory ReportData.fromMap(Map<String, dynamic> data) => ReportData(
        reportId: data['reportId'] ?? '',
        rows: List<Map<String, dynamic>>.from(data['rows'] ?? []),
        columns: List<String>.from(data['columns'] ?? []),
        summary: Map<String, dynamic>.from(data['summary'] ?? {}),
        generatedAt: (data['generatedAt'] as Timestamp).toDate(),
        totalRows: data['totalRows'] as int? ?? 0,
      );
  final String reportId;
  final List<Map<String, dynamic>> rows;
  final List<String> columns;
  final Map<String, dynamic> summary;
  final DateTime generatedAt;
  final int totalRows;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'rows': rows,
        'columns': columns,
        'summary': summary,
        'generatedAt': Timestamp.fromDate(generatedAt),
        'totalRows': totalRows,
      };

  /// Получить значение ячейки
  dynamic getCellValue(int rowIndex, String columnName) {
    if (rowIndex >= rows.length) return null;
    return rows[rowIndex][columnName];
  }

  /// Получить строку данных
  Map<String, dynamic>? getRow(int index) {
    if (index >= rows.length) return null;
    return rows[index];
  }

  /// Получить все значения колонки
  List<dynamic> getColumnValues(String columnName) => rows.map((row) => row[columnName]).toList();

  /// Получить уникальные значения колонки
  List<dynamic> getUniqueColumnValues(String columnName) {
    final values = getColumnValues(columnName);
    return values.toSet().toList();
  }

  /// Подсчитать значения в колонке
  Map<dynamic, int> countColumnValues(String columnName) {
    final values = getColumnValues(columnName);
    final counts = <dynamic, int>{};

    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }

    return counts;
  }

  /// Получить статистику по числовой колонке
  Map<String, dynamic> getNumericColumnStats(String columnName) {
    final values = getColumnValues(columnName).whereType<num>().cast<num>().toList();

    if (values.isEmpty) {
      return {
        'count': 0,
        'min': null,
        'max': null,
        'sum': 0,
        'avg': 0,
      };
    }

    values.sort();

    return {
      'count': values.length,
      'min': values.first,
      'max': values.last,
      'sum': values.reduce((a, b) => a + b),
      'avg': values.reduce((a, b) => a + b) / values.length,
    };
  }

  @override
  String toString() =>
      'ReportData(reportId: $reportId, totalRows: $totalRows, columns: ${columns.length})';
}

/// Шаблон отчета
class ReportTemplate {
  const ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    this.defaultParameters = const {},
    this.requiredParameters = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory ReportTemplate.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ReportTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ReportType.custom,
      ),
      category: ReportCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => ReportCategory.general,
      ),
      defaultParameters: Map<String, dynamic>.from(data['defaultParameters'] ?? {}),
      requiredParameters: List<String>.from(data['requiredParameters'] ?? []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory ReportTemplate.fromMap(Map<String, dynamic> data) => ReportTemplate(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        type: ReportType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => ReportType.custom,
        ),
        category: ReportCategory.values.firstWhere(
          (e) => e.toString().split('.').last == data['category'],
          orElse: () => ReportCategory.general,
        ),
        defaultParameters: Map<String, dynamic>.from(data['defaultParameters'] ?? {}),
        requiredParameters: List<String>.from(data['requiredParameters'] ?? []),
        isActive: data['isActive'] as bool? ?? true,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final ReportCategory category;
  final Map<String, dynamic> defaultParameters;
  final List<String> requiredParameters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'type': type.toString().split('.').last,
        'category': category.toString().split('.').last,
        'defaultParameters': defaultParameters,
        'requiredParameters': requiredParameters,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создать копию с изменениями
  ReportTemplate copyWith({
    String? id,
    String? name,
    String? description,
    ReportType? type,
    ReportCategory? category,
    Map<String, dynamic>? defaultParameters,
    List<String>? requiredParameters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ReportTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        category: category ?? this.category,
        defaultParameters: defaultParameters ?? this.defaultParameters,
        requiredParameters: requiredParameters ?? this.requiredParameters,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Проверить, валидны ли параметры
  bool areParametersValid(Map<String, dynamic> parameters) {
    for (final requiredParam in requiredParameters) {
      if (!parameters.containsKey(requiredParam) || parameters[requiredParam] == null) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportTemplate &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.category == category &&
        other.defaultParameters == defaultParameters &&
        other.requiredParameters == requiredParameters &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        type,
        category,
        defaultParameters,
        requiredParameters,
        isActive,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'ReportTemplate(id: $id, name: $name, type: $type)';
}
