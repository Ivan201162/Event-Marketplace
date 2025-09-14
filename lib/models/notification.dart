import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель уведомления
class Notification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Создаёт уведомление из документа Firestore
  factory Notification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Notification(
      id: doc.id,
      userId: data['userId'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Преобразует уведомление в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Создаёт копию уведомления с обновлёнными полями
  Notification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Типы уведомлений
  static const String typeReview = 'review';
  static const String typeBooking = 'booking';
  static const String typePayment = 'payment';
  static const String typeReminder = 'reminder';
  static const String typeMessage = 'message';
  static const String typeMarketing = 'marketing';
  static const String typeSystem = 'system';

  /// Получает иконку для типа уведомления
  String get typeIcon {
    switch (type) {
      case typeReview:
        return '⭐';
      case typeBooking:
        return '📅';
      case typePayment:
        return '💳';
      case typeReminder:
        return '⏰';
      case typeMessage:
        return '💬';
      case typeMarketing:
        return '📢';
      case typeSystem:
        return '⚙️';
      default:
        return '🔔';
    }
  }

  /// Получает цвет для типа уведомления
  String get typeColor {
    switch (type) {
      case typeReview:
        return '#FFD700'; // Золотой
      case typeBooking:
        return '#4CAF50'; // Зелёный
      case typePayment:
        return '#2196F3'; // Синий
      case typeReminder:
        return '#FF9800'; // Оранжевый
      case typeMessage:
        return '#9C27B0'; // Фиолетовый
      case typeMarketing:
        return '#E91E63'; // Розовый
      case typeSystem:
        return '#607D8B'; // Серый
      default:
        return '#757575'; // Тёмно-серый
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Notification(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}

/// Расширение для работы с уведомлениями
extension NotificationExtension on List<Notification> {
  /// Получает непрочитанные уведомления
  List<Notification> get unread => where((n) => !n.isRead).toList();

  /// Получает уведомления по типу
  List<Notification> byType(String type) => where((n) => n.type == type).toList();

  /// Получает последние уведомления
  List<Notification> get recent => 
      toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Группирует уведомления по типу
  Map<String, List<Notification>> get groupedByType {
    final Map<String, List<Notification>> grouped = {};
    for (final notification in this) {
      grouped.putIfAbsent(notification.type, () => []).add(notification);
    }
    return grouped;
  }
}