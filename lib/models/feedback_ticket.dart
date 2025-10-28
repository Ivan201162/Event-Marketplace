import 'package:cloud_firestore/cloud_firestore.dart';

/// Категории тикетов обратной связи
enum TicketCategory {
  bug, // Ошибка
  feature, // Предложение
  complaint, // Жалоба
  payment, // Платеж
}

/// Статусы тикетов
enum TicketStatus {
  open, // Открыт
  inProgress, // В работе
  resolved, // Решен
  closed, // Закрыт
}

/// Модель тикета обратной связи
class FeedbackTicket {
  const FeedbackTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.userId,
    this.adminId,
    this.priority = TicketPriority.medium,
    this.tags = const [],
  });

  /// Создать из документа Firestore
  factory FeedbackTicket.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return FeedbackTicket.fromMap(data, doc.id);
  }

  /// Создать из Map
  factory FeedbackTicket.fromMap(Map<String, dynamic> data, [String? id]) {
    return FeedbackTicket(
      id: id ?? data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: TicketCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => TicketCategory.bug,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TicketStatus.open,
      ),
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
      attachments: List<String>.from(data['attachments'] ?? []),
      userId: data['userId'],
      adminId: data['adminId'],
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TicketPriority.medium,
      ),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  final String id;
  final String title;
  final String description;
  final TicketCategory category;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> attachments; // URLs файлов
  final String? userId;
  final String? adminId;
  final TicketPriority priority;
  final List<String> tags;

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'attachments': attachments,
      'userId': userId,
      'adminId': adminId,
      'priority': priority.name,
      'tags': tags,
    };
  }

  /// Копировать с изменениями
  FeedbackTicket copyWith({
    String? id,
    String? title,
    String? description,
    TicketCategory? category,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    String? userId,
    String? adminId,
    TicketPriority? priority,
    List<String>? tags,
  }) {
    return FeedbackTicket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
    );
  }

  /// Парсинг временных полей
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'FeedbackTicket(id: $id, title: $title, status: $status)';
}

/// Приоритеты тикетов
enum TicketPriority {
  low, // Низкий
  medium, // Средний
  high, // Высокий
  urgent, // Срочный
}

/// Модель сообщения в тикете
class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.createdAt,
    this.attachments = const [],
    this.isRead = false,
  });

  /// Создать из Map
  factory TicketMessage.fromMap(Map<String, dynamic> data, [String? id]) {
    return TicketMessage(
      id: id ?? data['id'] ?? '',
      ticketId: data['ticketId'] ?? '',
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      senderType: MessageSenderType.values.firstWhere(
        (e) => e.name == data['senderType'],
        orElse: () => MessageSenderType.user,
      ),
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      attachments: List<String>.from(data['attachments'] ?? []),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  final String id;
  final String ticketId;
  final String content;
  final String senderId;
  final MessageSenderType senderType;
  final DateTime createdAt;
  final List<String> attachments;
  final bool isRead;

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'content': content,
      'senderId': senderId,
      'senderType': senderType.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachments': attachments,
      'isRead': isRead,
    };
  }

  /// Парсинг временных полей
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Типы отправителей сообщений
enum MessageSenderType {
  user, // Пользователь
  admin, // Администратор
  system, // Система
}
