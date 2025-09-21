import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель предложения по увеличению бюджета
class BudgetSuggestion {
  const BudgetSuggestion({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.suggestions,
    required this.status,
    this.message,
    required this.createdAt,
    this.viewedAt,
    this.respondedAt,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory BudgetSuggestion.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return BudgetSuggestion(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      suggestions: (data['suggestions'] as List<dynamic>?)
              ?.map(
                (item) =>
                    BudgetSuggestionItem.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      status: BudgetSuggestionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BudgetSuggestionStatus.pending,
      ),
      message: data['message'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewedAt: data['viewedAt'] != null
          ? (data['viewedAt'] as Timestamp).toDate()
          : null,
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map<dynamic, dynamic>)
          : null,
    );
  }

  /// Создать из Map
  factory BudgetSuggestion.fromMap(Map<String, dynamic> data) =>
      BudgetSuggestion(
        id: data['id'] as String? ?? '',
        bookingId: data['bookingId'] as String? ?? '',
        customerId: data['customerId'] as String? ?? '',
        specialistId: data['specialistId'] as String? ?? '',
        suggestions: (data['suggestions'] as List<dynamic>?)
                ?.map(
                  (item) => BudgetSuggestionItem.fromMap(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
        status: BudgetSuggestionStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => BudgetSuggestionStatus.pending,
        ),
        message: data['message'] as String?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        viewedAt: data['viewedAt'] != null
            ? (data['viewedAt'] as Timestamp).toDate()
            : null,
        respondedAt: data['respondedAt'] != null
            ? (data['respondedAt'] as Timestamp).toDate()
            : null,
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'] as Map<dynamic, dynamic>)
            : null,
      );
  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final List<BudgetSuggestionItem> suggestions;
  final BudgetSuggestionStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? viewedAt;
  final DateTime? respondedAt;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'customerId': customerId,
        'specialistId': specialistId,
        'suggestions': suggestions.map((item) => item.toMap()).toList(),
        'status': status.name,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
        'respondedAt':
            respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  BudgetSuggestion copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    List<BudgetSuggestionItem>? suggestions,
    BudgetSuggestionStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? viewedAt,
    DateTime? respondedAt,
    Map<String, dynamic>? metadata,
  }) =>
      BudgetSuggestion(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        suggestions: suggestions ?? this.suggestions,
        status: status ?? this.status,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        viewedAt: viewedAt ?? this.viewedAt,
        respondedAt: respondedAt ?? this.respondedAt,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, можно ли ответить на предложение
  bool get canRespond => status == BudgetSuggestionStatus.pending;

  /// Проверить, принято ли предложение
  bool get isAccepted => status == BudgetSuggestionStatus.accepted;

  /// Проверить, отклонено ли предложение
  bool get isRejected => status == BudgetSuggestionStatus.rejected;

  /// Получить общую стоимость предложения
  double get totalCost => suggestions.fold(
        0,
        (sum, item) => sum + (item.estimatedPrice ?? 0),
      );

  /// Получить количество предложений
  int get suggestionCount => suggestions.length;

  /// Получить минимальную стоимость
  double get minCost {
    if (suggestions.isEmpty) return 0;
    return suggestions
        .map((s) => s.estimatedPrice ?? 0)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Получить максимальную стоимость
  double get maxCost {
    if (suggestions.isEmpty) return 0;
    return suggestions
        .map((s) => s.estimatedPrice ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetSuggestion &&
        other.id == id &&
        other.bookingId == bookingId &&
        other.customerId == customerId &&
        other.specialistId == specialistId &&
        other.suggestions == suggestions &&
        other.status == status &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.viewedAt == viewedAt &&
        other.respondedAt == respondedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        bookingId,
        customerId,
        specialistId,
        suggestions,
        status,
        message,
        createdAt,
        viewedAt,
        respondedAt,
      );

  @override
  String toString() =>
      'BudgetSuggestion(id: $id, bookingId: $bookingId, status: $status, suggestionCount: $suggestionCount)';
}

/// Элемент предложения по бюджету
class BudgetSuggestionItem {
  const BudgetSuggestionItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    this.specialistId,
    this.specialistName,
    required this.description,
    this.estimatedPrice,
    this.reason,
    this.metadata,
  });

  /// Создать из Map
  factory BudgetSuggestionItem.fromMap(Map<String, dynamic> data) =>
      BudgetSuggestionItem(
        id: data['id'] as String? ?? '',
        categoryId: data['categoryId'] as String? ?? '',
        categoryName: data['categoryName'] as String? ?? '',
        specialistId: data['specialistId'],
        specialistName: data['specialistName'],
        description: data['description'] ?? '',
        estimatedPrice: data['estimatedPrice']?.toDouble(),
        reason: data['reason'],
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
      );
  final String id;
  final String categoryId;
  final String categoryName;
  final String? specialistId;
  final String? specialistName;
  final String description;
  final double? estimatedPrice;
  final String? reason;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'description': description,
        'estimatedPrice': estimatedPrice,
        'reason': reason,
        'metadata': metadata,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetSuggestionItem &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.specialistId == specialistId &&
        other.specialistName == specialistName &&
        other.description == description &&
        other.estimatedPrice == estimatedPrice &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(
        id,
        categoryId,
        categoryName,
        specialistId,
        specialistName,
        description,
        estimatedPrice,
        reason,
      );

  @override
  String toString() =>
      'BudgetSuggestionItem(id: $id, categoryName: $categoryName, estimatedPrice: $estimatedPrice)';
}

/// Статус предложения по бюджету
enum BudgetSuggestionStatus {
  pending,
  viewed,
  accepted,
  rejected,
  expired,
}

/// Расширение для статуса предложения по бюджету
extension BudgetSuggestionStatusExtension on BudgetSuggestionStatus {
  String get displayName {
    switch (this) {
      case BudgetSuggestionStatus.pending:
        return 'Ожидает просмотра';
      case BudgetSuggestionStatus.viewed:
        return 'Просмотрено';
      case BudgetSuggestionStatus.accepted:
        return 'Принято';
      case BudgetSuggestionStatus.rejected:
        return 'Отклонено';
      case BudgetSuggestionStatus.expired:
        return 'Истекло';
    }
  }

  String get description {
    switch (this) {
      case BudgetSuggestionStatus.pending:
        return 'Предложение ожидает вашего внимания';
      case BudgetSuggestionStatus.viewed:
        return 'Предложение было просмотрено';
      case BudgetSuggestionStatus.accepted:
        return 'Предложение было принято';
      case BudgetSuggestionStatus.rejected:
        return 'Предложение было отклонено';
      case BudgetSuggestionStatus.expired:
        return 'Время действия предложения истекло';
    }
  }

  Color get color {
    switch (this) {
      case BudgetSuggestionStatus.pending:
        return Colors.orange;
      case BudgetSuggestionStatus.viewed:
        return Colors.blue;
      case BudgetSuggestionStatus.accepted:
        return Colors.green;
      case BudgetSuggestionStatus.rejected:
        return Colors.red;
      case BudgetSuggestionStatus.expired:
        return Colors.grey;
    }
  }
}
