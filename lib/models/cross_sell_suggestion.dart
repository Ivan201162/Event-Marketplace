import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель кросс-селл предложения
class CrossSellSuggestion {
  const CrossSellSuggestion({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    required this.suggestedItems,
    required this.status,
    this.message,
    required this.createdAt,
    this.viewedAt,
    this.respondedAt,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory CrossSellSuggestion.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CrossSellSuggestion(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      specialistId: data['specialistId'] ?? '',
      suggestedItems: (data['suggestedItems'] as List<dynamic>?)
              ?.map(
                (item) => CrossSellItem.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      status: CrossSellStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CrossSellStatus.pending,
      ),
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewedAt: data['viewedAt'] != null
          ? (data['viewedAt'] as Timestamp).toDate()
          : null,
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Создать из Map
  factory CrossSellSuggestion.fromMap(Map<String, dynamic> data) =>
      CrossSellSuggestion(
        id: data['id'] ?? '',
        bookingId: data['bookingId'] ?? '',
        customerId: data['customerId'] ?? '',
        specialistId: data['specialistId'] ?? '',
        suggestedItems: (data['suggestedItems'] as List<dynamic>?)
                ?.map(
                  (item) => CrossSellItem.fromMap(item as Map<String, dynamic>),
                )
                .toList() ??
            [],
        status: CrossSellStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => CrossSellStatus.pending,
        ),
        message: data['message'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        viewedAt: data['viewedAt'] != null
            ? (data['viewedAt'] as Timestamp).toDate()
            : null,
        respondedAt: data['respondedAt'] != null
            ? (data['respondedAt'] as Timestamp).toDate()
            : null,
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
      );
  final String id;
  final String bookingId;
  final String customerId;
  final String specialistId;
  final List<CrossSellItem> suggestedItems;
  final CrossSellStatus status;
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
        'suggestedItems': suggestedItems.map((item) => item.toMap()).toList(),
        'status': status.name,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
        'respondedAt':
            respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  CrossSellSuggestion copyWith({
    String? id,
    String? bookingId,
    String? customerId,
    String? specialistId,
    List<CrossSellItem>? suggestedItems,
    CrossSellStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? viewedAt,
    DateTime? respondedAt,
    Map<String, dynamic>? metadata,
  }) =>
      CrossSellSuggestion(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        suggestedItems: suggestedItems ?? this.suggestedItems,
        status: status ?? this.status,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        viewedAt: viewedAt ?? this.viewedAt,
        respondedAt: respondedAt ?? this.respondedAt,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, можно ли ответить на предложение
  bool get canRespond => status == CrossSellStatus.pending;

  /// Проверить, принято ли предложение
  bool get isAccepted => status == CrossSellStatus.accepted;

  /// Проверить, отклонено ли предложение
  bool get isRejected => status == CrossSellStatus.rejected;

  /// Получить общую стоимость предложения
  double get totalCost => suggestedItems.fold(
        0,
        (sum, item) => sum + (item.estimatedPrice ?? 0),
      );

  /// Получить количество предложенных услуг
  int get itemCount => suggestedItems.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrossSellSuggestion &&
        other.id == id &&
        other.bookingId == bookingId &&
        other.customerId == customerId &&
        other.specialistId == specialistId &&
        other.suggestedItems == suggestedItems &&
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
        suggestedItems,
        status,
        message,
        createdAt,
        viewedAt,
        respondedAt,
      );

  @override
  String toString() =>
      'CrossSellSuggestion(id: $id, bookingId: $bookingId, status: $status, itemCount: $itemCount)';
}

/// Элемент кросс-селл предложения
class CrossSellItem {
  const CrossSellItem({
    required this.id,
    required this.specialistId,
    required this.specialistName,
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.estimatedPrice,
    this.imageUrl,
    this.metadata,
  });

  /// Создать из Map
  factory CrossSellItem.fromMap(Map<String, dynamic> data) => CrossSellItem(
        id: data['id'] ?? '',
        specialistId: data['specialistId'] ?? '',
        specialistName: data['specialistName'] ?? '',
        categoryId: data['categoryId'] ?? '',
        categoryName: data['categoryName'] ?? '',
        description: data['description'],
        estimatedPrice: data['estimatedPrice']?.toDouble(),
        imageUrl: data['imageUrl'],
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(data['metadata'])
            : null,
      );
  final String id;
  final String specialistId;
  final String specialistName;
  final String categoryId;
  final String categoryName;
  final String? description;
  final double? estimatedPrice;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'description': description,
        'estimatedPrice': estimatedPrice,
        'imageUrl': imageUrl,
        'metadata': metadata,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrossSellItem &&
        other.id == id &&
        other.specialistId == specialistId &&
        other.specialistName == specialistName &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.description == description &&
        other.estimatedPrice == estimatedPrice &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => Object.hash(
        id,
        specialistId,
        specialistName,
        categoryId,
        categoryName,
        description,
        estimatedPrice,
        imageUrl,
      );

  @override
  String toString() =>
      'CrossSellItem(id: $id, specialistName: $specialistName, categoryName: $categoryName)';
}

/// Статус кросс-селл предложения
enum CrossSellStatus {
  pending,
  viewed,
  accepted,
  rejected,
  expired,
}

/// Расширение для статуса кросс-селл предложения
extension CrossSellStatusExtension on CrossSellStatus {
  String get displayName {
    switch (this) {
      case CrossSellStatus.pending:
        return 'Ожидает просмотра';
      case CrossSellStatus.viewed:
        return 'Просмотрено';
      case CrossSellStatus.accepted:
        return 'Принято';
      case CrossSellStatus.rejected:
        return 'Отклонено';
      case CrossSellStatus.expired:
        return 'Истекло';
    }
  }

  String get description {
    switch (this) {
      case CrossSellStatus.pending:
        return 'Предложение ожидает вашего внимания';
      case CrossSellStatus.viewed:
        return 'Предложение было просмотрено';
      case CrossSellStatus.accepted:
        return 'Предложение было принято';
      case CrossSellStatus.rejected:
        return 'Предложение было отклонено';
      case CrossSellStatus.expired:
        return 'Время действия предложения истекло';
    }
  }

  Color get color {
    switch (this) {
      case CrossSellStatus.pending:
        return Colors.orange;
      case CrossSellStatus.viewed:
        return Colors.blue;
      case CrossSellStatus.accepted:
        return Colors.green;
      case CrossSellStatus.rejected:
        return Colors.red;
      case CrossSellStatus.expired:
        return Colors.grey;
    }
  }
}
