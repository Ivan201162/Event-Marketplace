import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип рекомендации
enum RecommendationType { specialist, service, event, content, category }

/// Статус рекомендации
enum RecommendationStatus { active, inactive, expired, clicked, booked }

/// Модель рекомендации
class Recommendation {
  const Recommendation({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt, this.imageUrl,
    this.targetId, // ID специалиста, услуги, события и т.д.
    this.targetType,
    this.score,
    this.reason,
    this.metadata = const {},
    this.expiresAt,
    this.clickedAt,
    this.bookedAt,
    this.updatedAt,
  });

  /// Создать из Map
  factory Recommendation.fromMap(Map<String, dynamic> data) {
    return Recommendation(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      targetId: data['targetId'] as String?,
      targetType: data['targetType'] as String?,
      score: (data['score'] as num?)?.toDouble(),
      reason: data['reason'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] is Timestamp
              ? (data['expiresAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['expiresAt'].toString()))
          : null,
      clickedAt: data['clickedAt'] != null
          ? (data['clickedAt'] is Timestamp
              ? (data['clickedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['clickedAt'].toString()))
          : null,
      bookedAt: data['bookedAt'] != null
          ? (data['bookedAt'] is Timestamp
              ? (data['bookedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['bookedAt'].toString()))
          : null,
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
  factory Recommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return Recommendation.fromMap({'id': doc.id, ...data});
  }

  final String id;
  final String userId;
  final RecommendationType type;
  final RecommendationStatus status;
  final String title;
  final String description;
  final String? imageUrl;
  final String? targetId;
  final String? targetType;
  final double? score;
  final String? reason;
  final Map<String, dynamic> metadata;
  final DateTime? expiresAt;
  final DateTime? clickedAt;
  final DateTime? bookedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'status': status.name,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'targetId': targetId,
        'targetType': targetType,
        'score': score,
        'reason': reason,
        'metadata': metadata,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'clickedAt': clickedAt != null ? Timestamp.fromDate(clickedAt!) : null,
        'bookedAt': bookedAt != null ? Timestamp.fromDate(bookedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  Recommendation copyWith({
    String? id,
    String? userId,
    RecommendationType? type,
    RecommendationStatus? status,
    String? title,
    String? description,
    String? imageUrl,
    String? targetId,
    String? targetType,
    double? score,
    String? reason,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    DateTime? clickedAt,
    DateTime? bookedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Recommendation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        status: status ?? this.status,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        targetId: targetId ?? this.targetId,
        targetType: targetType ?? this.targetType,
        score: score ?? this.score,
        reason: reason ?? this.reason,
        metadata: metadata ?? this.metadata,
        expiresAt: expiresAt ?? this.expiresAt,
        clickedAt: clickedAt ?? this.clickedAt,
        bookedAt: bookedAt ?? this.bookedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Парсинг типа из строки
  static RecommendationType _parseType(String? type) {
    switch (type) {
      case 'specialist':
        return RecommendationType.specialist;
      case 'service':
        return RecommendationType.service;
      case 'event':
        return RecommendationType.event;
      case 'content':
        return RecommendationType.content;
      case 'category':
        return RecommendationType.category;
      default:
        return RecommendationType.specialist;
    }
  }

  /// Парсинг статуса из строки
  static RecommendationStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return RecommendationStatus.active;
      case 'inactive':
        return RecommendationStatus.inactive;
      case 'expired':
        return RecommendationStatus.expired;
      case 'clicked':
        return RecommendationStatus.clicked;
      case 'booked':
        return RecommendationStatus.booked;
      default:
        return RecommendationStatus.active;
    }
  }

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
      case RecommendationType.specialist:
        return 'Специалист';
      case RecommendationType.service:
        return 'Услуга';
      case RecommendationType.event:
        return 'Событие';
      case RecommendationType.content:
        return 'Контент';
      case RecommendationType.category:
        return 'Категория';
    }
  }

  /// Получить отображаемое название статуса
  String get statusDisplayName {
    switch (status) {
      case RecommendationStatus.active:
        return 'Активна';
      case RecommendationStatus.inactive:
        return 'Неактивна';
      case RecommendationStatus.expired:
        return 'Истекла';
      case RecommendationStatus.clicked:
        return 'Просмотрена';
      case RecommendationStatus.booked:
        return 'Забронирована';
    }
  }

  /// Проверить, активна ли рекомендация
  bool get isActive => status == RecommendationStatus.active;

  /// Проверить, истекла ли рекомендация
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Проверить, была ли рекомендация просмотрена
  bool get isClicked =>
      status == RecommendationStatus.clicked || clickedAt != null;

  /// Проверить, была ли рекомендация забронирована
  bool get isBooked =>
      status == RecommendationStatus.booked || bookedAt != null;

  /// Проверить, есть ли оценка
  bool get hasScore => score != null;

  /// Проверить, есть ли причина
  bool get hasReason => reason != null && reason!.isNotEmpty;

  /// Получить отформатированную оценку
  String get formattedScore {
    if (score == null) return '';
    return '${(score! * 100).toStringAsFixed(0)}%';
  }
}

/// Модель статистики рекомендаций
class RecommendationStats {
  const RecommendationStats({
    required this.userId,
    this.totalRecommendations = 0,
    this.activeRecommendations = 0,
    this.clickedRecommendations = 0,
    this.bookedRecommendations = 0,
    this.expiredRecommendations = 0,
    this.clickThroughRate = 0.0,
    this.conversionRate = 0.0,
    this.averageScore = 0.0,
    this.period,
    this.metadata = const {},
  });

  /// Создать из Map
  factory RecommendationStats.fromMap(Map<String, dynamic> data) {
    return RecommendationStats(
      userId: data['userId'] as String? ?? '',
      totalRecommendations: data['totalRecommendations'] as int? ?? 0,
      activeRecommendations: data['activeRecommendations'] as int? ?? 0,
      clickedRecommendations: data['clickedRecommendations'] as int? ?? 0,
      bookedRecommendations: data['bookedRecommendations'] as int? ?? 0,
      expiredRecommendations: data['expiredRecommendations'] as int? ?? 0,
      clickThroughRate: (data['clickThroughRate'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (data['conversionRate'] as num?)?.toDouble() ?? 0.0,
      averageScore: (data['averageScore'] as num?)?.toDouble() ?? 0.0,
      period: data['period'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  final String userId;
  final int totalRecommendations;
  final int activeRecommendations;
  final int clickedRecommendations;
  final int bookedRecommendations;
  final int expiredRecommendations;
  final double clickThroughRate;
  final double conversionRate;
  final double averageScore;
  final String? period;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'totalRecommendations': totalRecommendations,
        'activeRecommendations': activeRecommendations,
        'clickedRecommendations': clickedRecommendations,
        'bookedRecommendations': bookedRecommendations,
        'expiredRecommendations': expiredRecommendations,
        'clickThroughRate': clickThroughRate,
        'conversionRate': conversionRate,
        'averageScore': averageScore,
        'period': period,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  RecommendationStats copyWith({
    String? userId,
    int? totalRecommendations,
    int? activeRecommendations,
    int? clickedRecommendations,
    int? bookedRecommendations,
    int? expiredRecommendations,
    double? clickThroughRate,
    double? conversionRate,
    double? averageScore,
    String? period,
    Map<String, dynamic>? metadata,
  }) =>
      RecommendationStats(
        userId: userId ?? this.userId,
        totalRecommendations: totalRecommendations ?? this.totalRecommendations,
        activeRecommendations:
            activeRecommendations ?? this.activeRecommendations,
        clickedRecommendations:
            clickedRecommendations ?? this.clickedRecommendations,
        bookedRecommendations:
            bookedRecommendations ?? this.bookedRecommendations,
        expiredRecommendations:
            expiredRecommendations ?? this.expiredRecommendations,
        clickThroughRate: clickThroughRate ?? this.clickThroughRate,
        conversionRate: conversionRate ?? this.conversionRate,
        averageScore: averageScore ?? this.averageScore,
        period: period ?? this.period,
        metadata: metadata ?? this.metadata,
      );

  /// Получить процент кликов
  double get clickThroughPercentage {
    if (totalRecommendations == 0) return 0;
    return (clickedRecommendations / totalRecommendations) * 100;
  }

  /// Получить процент конверсии
  double get conversionPercentage {
    if (totalRecommendations == 0) return 0;
    return (bookedRecommendations / totalRecommendations) * 100;
  }

  /// Получить процент активных рекомендаций
  double get activePercentage {
    if (totalRecommendations == 0) return 0;
    return (activeRecommendations / totalRecommendations) * 100;
  }

  /// Получить процент истекших рекомендаций
  double get expiredPercentage {
    if (totalRecommendations == 0) return 0;
    return (expiredRecommendations / totalRecommendations) * 100;
  }

  /// Получить отформатированный CTR
  String get formattedClickThroughRate {
    return '${clickThroughRate.toStringAsFixed(2)}%';
  }

  /// Получить отформатированную конверсию
  String get formattedConversionRate {
    return '${conversionRate.toStringAsFixed(2)}%';
  }

  /// Получить отформатированную среднюю оценку
  String get formattedAverageScore {
    return '${(averageScore * 100).toStringAsFixed(0)}%';
  }
}
