import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель A/B теста
class ABTest {
  const ABTest({
    required this.id,
    required this.name,
    required this.description,
    this.status = ABTestStatus.draft,
    this.variants = const [],
    required this.targeting,
    required this.metrics,
    required this.startDate,
    this.endDate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory ABTest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ABTest(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      status: ABTestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ABTestStatus.draft,
      ),
      variants: (data['variants'] as List<dynamic>?)
              ?.map((v) => ABTestVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      targeting: ABTestTargeting.fromMap(
        (data['targeting'] as Map<String, dynamic>?) ?? {},
      ),
      metrics: ABTestMetrics.fromMap(
        (data['metrics'] as Map<String, dynamic>?) ?? {},
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp?)?.toDate()
          : null,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(
        (data['metadata'] as Map<dynamic, dynamic>?) ?? {},
      ),
    );
  }

  /// Создать из Map
  factory ABTest.fromMap(Map<String, dynamic> data) => ABTest(
        id: (data['id'] as String?) ?? '',
        name: (data['name'] as String?) ?? '',
        description: (data['description'] as String?) ?? '',
        status: ABTestStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => ABTestStatus.draft,
        ),
        variants: (data['variants'] as List<dynamic>?)
                ?.map((v) => ABTestVariant.fromMap(v as Map<String, dynamic>))
                .toList() ??
            [],
        targeting: ABTestTargeting.fromMap(
          (data['targeting'] as Map<String, dynamic>?) ?? {},
        ),
        metrics: ABTestMetrics.fromMap(
          (data['metrics'] as Map<String, dynamic>?) ?? {},
        ),
        startDate:
            (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endDate: data['endDate'] != null
            ? (data['endDate'] as Timestamp?)?.toDate()
            : null,
        createdBy: data['createdBy'] as String?,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata: Map<String, dynamic>.from(
          (data['metadata'] as Map<dynamic, dynamic>?) ?? {},
        ),
      );
  final String id;
  final String name;
  final String description;
  final ABTestStatus status;
  final List<ABTestVariant> variants;
  final ABTestTargeting targeting;
  final ABTestMetrics metrics;
  final DateTime startDate;
  final DateTime? endDate;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'status': status.toString().split('.').last,
        'variants': variants.map((v) => v.toMap()).toList(),
        'targeting': targeting.toMap(),
        'metrics': metrics.toMap(),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  ABTest copyWith({
    String? id,
    String? name,
    String? description,
    ABTestStatus? status,
    List<ABTestVariant>? variants,
    ABTestTargeting? targeting,
    ABTestMetrics? metrics,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      ABTest(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        status: status ?? this.status,
        variants: variants ?? this.variants,
        targeting: targeting ?? this.targeting,
        metrics: metrics ?? this.metrics,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, активен ли тест
  bool get isActive => status == ABTestStatus.running;

  /// Проверить, завершен ли тест
  bool get isCompleted => status == ABTestStatus.completed;

  /// Проверить, можно ли запустить тест
  bool get canStart => status == ABTestStatus.draft && variants.length >= 2;

  /// Получить продолжительность теста
  Duration? get duration {
    if (endDate == null) return null;
    return endDate!.difference(startDate);
  }

  /// Получить процент завершения
  double get completionPercentage {
    if (endDate == null) return 0;
    final total = endDate!.difference(startDate).inDays;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total * 100).clamp(0, 100);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ABTest &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.status == status &&
        other.variants == variants &&
        other.targeting == targeting &&
        other.metrics == metrics &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        status,
        variants,
        targeting,
        metrics,
        startDate,
        endDate,
        createdBy,
        createdAt,
        updatedAt,
        metadata,
      );

  @override
  String toString() => 'ABTest(id: $id, name: $name, status: $status)';
}

/// Модель варианта A/B теста
class ABTestVariant {
  const ABTestVariant({
    required this.id,
    required this.name,
    required this.description,
    required this.trafficPercentage,
    this.configuration = const {},
    this.isControl = false,
    required this.createdAt,
  });

  /// Создать из Map
  factory ABTestVariant.fromMap(Map<String, dynamic> data) => ABTestVariant(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        trafficPercentage:
            (data['trafficPercentage'] as num?)?.toDouble() ?? 0.0,
        configuration:
            Map<String, dynamic>.from(data['configuration'] as Map? ?? {}),
        isControl: data['isControl'] as bool? ?? false,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final String id;
  final String name;
  final String description;
  final double trafficPercentage;
  final Map<String, dynamic> configuration;
  final bool isControl;
  final DateTime createdAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'trafficPercentage': trafficPercentage,
        'configuration': configuration,
        'isControl': isControl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Создать копию с изменениями
  ABTestVariant copyWith({
    String? id,
    String? name,
    String? description,
    double? trafficPercentage,
    Map<String, dynamic>? configuration,
    bool? isControl,
    DateTime? createdAt,
  }) =>
      ABTestVariant(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        trafficPercentage: trafficPercentage ?? this.trafficPercentage,
        configuration: configuration ?? this.configuration,
        isControl: isControl ?? this.isControl,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ABTestVariant &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.trafficPercentage == trafficPercentage &&
        other.configuration == configuration &&
        other.isControl == isControl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        trafficPercentage,
        configuration,
        isControl,
        createdAt,
      );

  @override
  String toString() =>
      'ABTestVariant(id: $id, name: $name, trafficPercentage: $trafficPercentage%)';
}

/// Модель таргетинга A/B теста
class ABTestTargeting {
  const ABTestTargeting({
    this.userIds = const [],
    this.userSegments = const [],
    this.platforms = const [],
    this.appVersions = const [],
    this.customFilters = const {},
    this.trafficPercentage = 100.0,
    this.startTime,
    this.endTime,
  });

  /// Создать из Map
  factory ABTestTargeting.fromMap(Map<String, dynamic> data) => ABTestTargeting(
        userIds: List<String>.from(data['userIds'] as List? ?? []),
        userSegments: List<String>.from(data['userSegments'] as List? ?? []),
        platforms: List<String>.from(data['platforms'] as List? ?? []),
        appVersions: List<String>.from(data['appVersions'] as List? ?? []),
        customFilters:
            Map<String, dynamic>.from(data['customFilters'] as Map? ?? {}),
        trafficPercentage:
            (data['trafficPercentage'] as num?)?.toDouble() ?? 100.0,
        startTime: data['startTime'] != null
            ? (data['startTime'] as Timestamp?)?.toDate()
            : null,
        endTime: data['endTime'] != null
            ? (data['endTime'] as Timestamp?)?.toDate()
            : null,
      );
  final List<String> userIds;
  final List<String> userSegments;
  final List<String> platforms;
  final List<String> appVersions;
  final Map<String, dynamic> customFilters;
  final double trafficPercentage;
  final DateTime? startTime;
  final DateTime? endTime;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'userIds': userIds,
        'userSegments': userSegments,
        'platforms': platforms,
        'appVersions': appVersions,
        'customFilters': customFilters,
        'trafficPercentage': trafficPercentage,
        'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      };

  /// Создать копию с изменениями
  ABTestTargeting copyWith({
    List<String>? userIds,
    List<String>? userSegments,
    List<String>? platforms,
    List<String>? appVersions,
    Map<String, dynamic>? customFilters,
    double? trafficPercentage,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      ABTestTargeting(
        userIds: userIds ?? this.userIds,
        userSegments: userSegments ?? this.userSegments,
        platforms: platforms ?? this.platforms,
        appVersions: appVersions ?? this.appVersions,
        customFilters: customFilters ?? this.customFilters,
        trafficPercentage: trafficPercentage ?? this.trafficPercentage,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ABTestTargeting &&
        other.userIds == userIds &&
        other.userSegments == userSegments &&
        other.platforms == platforms &&
        other.appVersions == appVersions &&
        other.customFilters == customFilters &&
        other.trafficPercentage == trafficPercentage &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(
        userIds,
        userSegments,
        platforms,
        appVersions,
        customFilters,
        trafficPercentage,
        startTime,
        endTime,
      );

  @override
  String toString() =>
      'ABTestTargeting(trafficPercentage: $trafficPercentage%, platforms: $platforms)';
}

/// Модель метрик A/B теста
class ABTestMetrics {
  const ABTestMetrics({
    required this.primaryMetric,
    this.secondaryMetrics = const [],
    this.minimumDetectableEffect = 0.05,
    this.significanceLevel = 0.05,
    this.power = 0.8,
    this.minimumSampleSize = 1000,
    this.customMetrics = const {},
  });

  /// Создать из Map
  factory ABTestMetrics.fromMap(Map<String, dynamic> data) => ABTestMetrics(
        primaryMetric: data['primaryMetric'] as String? ?? '',
        secondaryMetrics:
            List<String>.from(data['secondaryMetrics'] as List? ?? []),
        minimumDetectableEffect:
            (data['minimumDetectableEffect'] as num?)?.toDouble() ?? 0.05,
        significanceLevel:
            (data['significanceLevel'] as num?)?.toDouble() ?? 0.05,
        power: (data['power'] as num?)?.toDouble() ?? 0.8,
        minimumSampleSize: data['minimumSampleSize'] as int? ?? 1000,
        customMetrics:
            Map<String, dynamic>.from(data['customMetrics'] as Map? ?? {}),
      );
  final String primaryMetric;
  final List<String> secondaryMetrics;
  final double minimumDetectableEffect;
  final double significanceLevel;
  final double power;
  final int minimumSampleSize;
  final Map<String, dynamic> customMetrics;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'primaryMetric': primaryMetric,
        'secondaryMetrics': secondaryMetrics,
        'minimumDetectableEffect': minimumDetectableEffect,
        'significanceLevel': significanceLevel,
        'power': power,
        'minimumSampleSize': minimumSampleSize,
        'customMetrics': customMetrics,
      };

  /// Создать копию с изменениями
  ABTestMetrics copyWith({
    String? primaryMetric,
    List<String>? secondaryMetrics,
    double? minimumDetectableEffect,
    double? significanceLevel,
    double? power,
    int? minimumSampleSize,
    Map<String, dynamic>? customMetrics,
  }) =>
      ABTestMetrics(
        primaryMetric: primaryMetric ?? this.primaryMetric,
        secondaryMetrics: secondaryMetrics ?? this.secondaryMetrics,
        minimumDetectableEffect:
            minimumDetectableEffect ?? this.minimumDetectableEffect,
        significanceLevel: significanceLevel ?? this.significanceLevel,
        power: power ?? this.power,
        minimumSampleSize: minimumSampleSize ?? this.minimumSampleSize,
        customMetrics: customMetrics ?? this.customMetrics,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ABTestMetrics &&
        other.primaryMetric == primaryMetric &&
        other.secondaryMetrics == secondaryMetrics &&
        other.minimumDetectableEffect == minimumDetectableEffect &&
        other.significanceLevel == significanceLevel &&
        other.power == power &&
        other.minimumSampleSize == minimumSampleSize &&
        other.customMetrics == customMetrics;
  }

  @override
  int get hashCode => Object.hash(
        primaryMetric,
        secondaryMetrics,
        minimumDetectableEffect,
        significanceLevel,
        power,
        minimumSampleSize,
        customMetrics,
      );

  @override
  String toString() =>
      'ABTestMetrics(primaryMetric: $primaryMetric, minimumSampleSize: $minimumSampleSize)';
}

/// Модель участия пользователя в A/B тесте
class ABTestParticipation {
  const ABTestParticipation({
    required this.id,
    required this.testId,
    required this.userId,
    required this.variantId,
    required this.assignedAt,
    this.convertedAt,
    this.events = const {},
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory ABTestParticipation.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ABTestParticipation(
      id: doc.id,
      testId: data['testId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      variantId: data['variantId'] as String? ?? '',
      assignedAt:
          (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      convertedAt: data['convertedAt'] != null
          ? (data['convertedAt'] as Timestamp?)?.toDate()
          : null,
      events: Map<String, dynamic>.from(data['events'] as Map? ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Создать из Map
  factory ABTestParticipation.fromMap(Map<String, dynamic> data) =>
      ABTestParticipation(
        id: data['id'] as String? ?? '',
        testId: data['testId'] as String? ?? '',
        userId: data['userId'] as String? ?? '',
        variantId: data['variantId'] as String? ?? '',
        assignedAt:
            (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        convertedAt: data['convertedAt'] != null
            ? (data['convertedAt'] as Timestamp?)?.toDate()
            : null,
        events: Map<String, dynamic>.from(data['events'] as Map? ?? {}),
        metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      );
  final String id;
  final String testId;
  final String userId;
  final String variantId;
  final DateTime assignedAt;
  final DateTime? convertedAt;
  final Map<String, dynamic> events;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'testId': testId,
        'userId': userId,
        'variantId': variantId,
        'assignedAt': Timestamp.fromDate(assignedAt),
        'convertedAt':
            convertedAt != null ? Timestamp.fromDate(convertedAt!) : null,
        'events': events,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  ABTestParticipation copyWith({
    String? id,
    String? testId,
    String? userId,
    String? variantId,
    DateTime? assignedAt,
    DateTime? convertedAt,
    Map<String, dynamic>? events,
    Map<String, dynamic>? metadata,
  }) =>
      ABTestParticipation(
        id: id ?? this.id,
        testId: testId ?? this.testId,
        userId: userId ?? this.userId,
        variantId: variantId ?? this.variantId,
        assignedAt: assignedAt ?? this.assignedAt,
        convertedAt: convertedAt ?? this.convertedAt,
        events: events ?? this.events,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, конвертирован ли пользователь
  bool get isConverted => convertedAt != null;

  /// Получить время до конверсии
  Duration? get timeToConversion {
    if (convertedAt == null) return null;
    return convertedAt!.difference(assignedAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ABTestParticipation &&
        other.id == id &&
        other.testId == testId &&
        other.userId == userId &&
        other.variantId == variantId &&
        other.assignedAt == assignedAt &&
        other.convertedAt == convertedAt &&
        other.events == events &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        testId,
        userId,
        variantId,
        assignedAt,
        convertedAt,
        events,
        metadata,
      );

  @override
  String toString() =>
      'ABTestParticipation(id: $id, testId: $testId, variantId: $variantId)';
}

/// Статусы A/B тестов
enum ABTestStatus {
  draft,
  running,
  paused,
  completed,
  cancelled,
}

/// Расширение для статусов
extension ABTestStatusExtension on ABTestStatus {
  String get displayName {
    switch (this) {
      case ABTestStatus.draft:
        return 'Черновик';
      case ABTestStatus.running:
        return 'Запущен';
      case ABTestStatus.paused:
        return 'Приостановлен';
      case ABTestStatus.completed:
        return 'Завершен';
      case ABTestStatus.cancelled:
        return 'Отменен';
    }
  }

  String get description {
    switch (this) {
      case ABTestStatus.draft:
        return 'Тест в разработке';
      case ABTestStatus.running:
        return 'Тест активен';
      case ABTestStatus.paused:
        return 'Тест приостановлен';
      case ABTestStatus.completed:
        return 'Тест завершен';
      case ABTestStatus.cancelled:
        return 'Тест отменен';
    }
  }

  String get color {
    switch (this) {
      case ABTestStatus.draft:
        return 'grey';
      case ABTestStatus.running:
        return 'green';
      case ABTestStatus.paused:
        return 'orange';
      case ABTestStatus.completed:
        return 'blue';
      case ABTestStatus.cancelled:
        return 'red';
    }
  }
}
