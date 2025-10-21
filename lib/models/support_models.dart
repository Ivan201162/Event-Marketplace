import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус тикета поддержки
enum TicketStatus { open, inProgress, waitingForUser, resolved, closed }

/// Приоритет тикета поддержки
enum TicketPriority { low, medium, high, urgent }

/// Категория тикета поддержки
enum TicketCategory { technical, billing, account, feature, bug, other }

/// Модель сообщения поддержки
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType, // 'user' или 'support'
    required this.message,
    this.attachments = const [],
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ticketId;
  final String senderId;
  final String senderType;
  final String message;
  final List<String> attachments;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory SupportMessage.fromMap(Map<String, dynamic> data) {
    return SupportMessage(
      id: data['id'] as String? ?? '',
      ticketId: data['ticketId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderType: data['senderType'] as String? ?? 'user',
      message: data['message'] as String? ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      isRead: data['isRead'] as bool? ?? false,
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
  factory SupportMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return SupportMessage.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'ticketId': ticketId,
    'senderId': senderId,
    'senderType': senderType,
    'message': message,
    'attachments': attachments,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  /// Копировать с изменениями
  SupportMessage copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? senderType,
    String? message,
    List<String>? attachments,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SupportMessage(
    id: id ?? this.id,
    ticketId: ticketId ?? this.ticketId,
    senderId: senderId ?? this.senderId,
    senderType: senderType ?? this.senderType,
    message: message ?? this.message,
    attachments: attachments ?? this.attachments,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Проверить, является ли сообщение от пользователя
  bool get isFromUser => senderType == 'user';

  /// Проверить, является ли сообщение от поддержки
  bool get isFromSupport => senderType == 'support';

  /// Проверить, есть ли вложения
  bool get hasAttachments => attachments.isNotEmpty;
}

/// Модель элемента FAQ
class FAQItem {
  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
    this.views = 0,
    this.isPublished = true,
    this.order = 0,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> tags;
  final int views;
  final bool isPublished;
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory FAQItem.fromMap(Map<String, dynamic> data) {
    return FAQItem(
      id: data['id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      category: data['category'] as String? ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      views: data['views'] as int? ?? 0,
      isPublished: data['isPublished'] as bool? ?? true,
      order: data['order'] as int? ?? 0,
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
  factory FAQItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return FAQItem.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'question': question,
    'answer': answer,
    'category': category,
    'tags': tags,
    'views': views,
    'isPublished': isPublished,
    'order': order,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  /// Копировать с изменениями
  FAQItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    List<String>? tags,
    int? views,
    bool? isPublished,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FAQItem(
    id: id ?? this.id,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    views: views ?? this.views,
    isPublished: isPublished ?? this.isPublished,
    order: order ?? this.order,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Проверить, опубликован ли элемент FAQ
  bool get isPublished => isPublished;

  /// Проверить, есть ли теги
  bool get hasTags => tags.isNotEmpty;
}

/// Модель статистики поддержки
class SupportStats {
  const SupportStats({
    required this.userId,
    this.totalTickets = 0,
    this.openTickets = 0,
    this.resolvedTickets = 0,
    this.closedTickets = 0,
    this.averageResponseTime = 0.0,
    this.satisfactionRating = 0.0,
    this.lastTicketAt,
    this.period,
  });

  final String userId;
  final int totalTickets;
  final int openTickets;
  final int resolvedTickets;
  final int closedTickets;
  final double averageResponseTime;
  final double satisfactionRating;
  final DateTime? lastTicketAt;
  final String? period;

  /// Создать из Map
  factory SupportStats.fromMap(Map<String, dynamic> data) {
    return SupportStats(
      userId: data['userId'] as String? ?? '',
      totalTickets: data['totalTickets'] as int? ?? 0,
      openTickets: data['openTickets'] as int? ?? 0,
      resolvedTickets: data['resolvedTickets'] as int? ?? 0,
      closedTickets: data['closedTickets'] as int? ?? 0,
      averageResponseTime: (data['averageResponseTime'] as num?)?.toDouble() ?? 0.0,
      satisfactionRating: (data['satisfactionRating'] as num?)?.toDouble() ?? 0.0,
      lastTicketAt: data['lastTicketAt'] != null
          ? (data['lastTicketAt'] is Timestamp
                ? (data['lastTicketAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['lastTicketAt'].toString()))
          : null,
      period: data['period'] as String?,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'totalTickets': totalTickets,
    'openTickets': openTickets,
    'resolvedTickets': resolvedTickets,
    'closedTickets': closedTickets,
    'averageResponseTime': averageResponseTime,
    'satisfactionRating': satisfactionRating,
    'lastTicketAt': lastTicketAt != null ? Timestamp.fromDate(lastTicketAt!) : null,
    'period': period,
  };

  /// Копировать с изменениями
  SupportStats copyWith({
    String? userId,
    int? totalTickets,
    int? openTickets,
    int? resolvedTickets,
    int? closedTickets,
    double? averageResponseTime,
    double? satisfactionRating,
    DateTime? lastTicketAt,
    String? period,
  }) => SupportStats(
    userId: userId ?? this.userId,
    totalTickets: totalTickets ?? this.totalTickets,
    openTickets: openTickets ?? this.openTickets,
    resolvedTickets: resolvedTickets ?? this.resolvedTickets,
    closedTickets: closedTickets ?? this.closedTickets,
    averageResponseTime: averageResponseTime ?? this.averageResponseTime,
    satisfactionRating: satisfactionRating ?? this.satisfactionRating,
    lastTicketAt: lastTicketAt ?? this.lastTicketAt,
    period: period ?? this.period,
  );

  /// Получить процент решенных тикетов
  double get resolutionRate {
    if (totalTickets == 0) return 0.0;
    return (resolvedTickets / totalTickets) * 100;
  }

  /// Получить процент закрытых тикетов
  double get closureRate {
    if (totalTickets == 0) return 0.0;
    return (closedTickets / totalTickets) * 100;
  }

  /// Получить отформатированное время ответа
  String get formattedResponseTime {
    if (averageResponseTime < 60) {
      return '${averageResponseTime.toStringAsFixed(0)} мин';
    } else if (averageResponseTime < 1440) {
      final hours = averageResponseTime / 60;
      return '${hours.toStringAsFixed(1)} ч';
    } else {
      final days = averageResponseTime / 1440;
      return '${days.toStringAsFixed(1)} дн';
    }
  }

  /// Получить отформатированный рейтинг удовлетворенности
  String get formattedSatisfactionRating {
    return '${satisfactionRating.toStringAsFixed(1)}/5.0';
  }
}
