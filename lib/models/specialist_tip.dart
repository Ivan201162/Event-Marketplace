import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель совета для специалиста
class SpecialistTip {
  const SpecialistTip({
    required this.id,
    required this.userId,
    required this.field,
    required this.title,
    required this.message,
    required this.action,
    required this.priority, required this.createdAt, this.actionRoute,
    this.isCompleted = false,
    this.completedAt,
  });

  /// Создание из Firestore документа
  factory SpecialistTip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistTip(
      id: doc.id,
      userId: data['userId'] ?? '',
      field: data['field'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      action: data['action'] ?? '',
      actionRoute: data['actionRoute'],
      priority: TipPriority.values.firstWhere(
        (priority) => priority.value == data['priority'],
        orElse: () => TipPriority.medium,
      ),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String userId;
  final String field;
  final String title;
  final String message;
  final String action;
  final String? actionRoute;
  final TipPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'field': field,
        'title': title,
        'message': message,
        'action': action,
        'actionRoute': actionRoute,
        'priority': priority.value,
        'isCompleted': isCompleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  /// Копирование с изменениями
  SpecialistTip copyWith({
    String? id,
    String? userId,
    String? field,
    String? title,
    String? message,
    String? action,
    String? actionRoute,
    TipPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) =>
      SpecialistTip(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        field: field ?? this.field,
        title: title ?? this.title,
        message: message ?? this.message,
        action: action ?? this.action,
        actionRoute: actionRoute ?? this.actionRoute,
        priority: priority ?? this.priority,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistTip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SpecialistTip(id: $id, field: $field, title: $title, priority: $priority)';
}

/// Приоритет совета
enum TipPriority {
  low('low', 'Низкий', 1),
  medium('medium', 'Средний', 2),
  high('high', 'Высокий', 3),
  critical('critical', 'Критический', 4);

  const TipPriority(this.value, this.displayName, this.level);

  final String value;
  final String displayName;
  final int level;

  /// Получить цвет приоритета
  Color get color {
    switch (this) {
      case TipPriority.low:
        return Colors.green;
      case TipPriority.medium:
        return Colors.orange;
      case TipPriority.high:
        return Colors.red;
      case TipPriority.critical:
        return Colors.purple;
    }
  }

  /// Получить иконку приоритета
  IconData get icon {
    switch (this) {
      case TipPriority.low:
        return Icons.info_outline;
      case TipPriority.medium:
        return Icons.warning_outlined;
      case TipPriority.high:
        return Icons.error_outline;
      case TipPriority.critical:
        return Icons.priority_high;
    }
  }
}

/// Поля профиля специалиста
enum SpecialistField {
  name('name', 'Имя'),
  description('description', 'Описание'),
  category('category', 'Категория'),
  price('price', 'Цены'),
  portfolio('portfolio', 'Портфолио'),
  availability('availability', 'Доступность'),
  location('location', 'Местоположение'),
  contact('contact', 'Контакты'),
  reviews('reviews', 'Отзывы'),
  verification('verification', 'Верификация');

  const SpecialistField(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// Модель статистики профиля специалиста
class ProfileStats {
  const ProfileStats({
    required this.userId,
    required this.completionPercentage,
    required this.totalFields,
    required this.completedFields,
    required this.missingFields,
    required this.weakFields,
    required this.lastUpdated,
  });

  /// Создание из Firestore документа
  factory ProfileStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ProfileStats(
      userId: doc.id,
      completionPercentage: data['completionPercentage'] ?? 0,
      totalFields: data['totalFields'] ?? 0,
      completedFields: data['completedFields'] ?? 0,
      missingFields: List<String>.from(data['missingFields'] ?? []),
      weakFields: List<String>.from(data['weakFields'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
  final String userId;
  final int completionPercentage;
  final int totalFields;
  final int completedFields;
  final List<String> missingFields;
  final List<String> weakFields;
  final DateTime lastUpdated;

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toFirestore() => {
        'completionPercentage': completionPercentage,
        'totalFields': totalFields,
        'completedFields': completedFields,
        'missingFields': missingFields,
        'weakFields': weakFields,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileStats && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'ProfileStats(userId: $userId, completion: $completionPercentage%)';
}
