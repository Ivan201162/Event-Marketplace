import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель тикета поддержки
class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String description;
  final SupportCategory category;
  final SupportPriority priority;
  final SupportStatus status;
  final List<SupportMessage> messages;
  final List<String> attachments;
  final String? assignedTo;
  final String? assignedToName;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.messages = const [],
    this.attachments = const [],
    this.assignedTo,
    this.assignedToName,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SupportTicket(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      category: SupportCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => SupportCategory.general,
      ),
      priority: SupportPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => SupportPriority.medium,
      ),
      status: SupportStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => SupportStatus.open,
      ),
      messages: (data['messages'] as List<dynamic>?)
              ?.map((e) => SupportMessage.fromMap(e))
              .toList() ??
          [],
      attachments: List<String>.from(data['attachments'] ?? []),
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'messages': messages.map((e) => e.toMap()).toList(),
      'attachments': attachments,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? subject,
    String? description,
    SupportCategory? category,
    SupportPriority? priority,
    SupportStatus? status,
    List<SupportMessage>? messages,
    List<String>? attachments,
    String? assignedTo,
    String? assignedToName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      attachments: attachments ?? this.attachments,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Получить цвет статуса
  Color get statusColor {
    switch (status) {
      case SupportStatus.open:
        return Colors.orange;
      case SupportStatus.inProgress:
        return Colors.blue;
      case SupportStatus.pending:
        return Colors.yellow;
      case SupportStatus.resolved:
        return Colors.green;
      case SupportStatus.closed:
        return Colors.grey;
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case SupportStatus.open:
        return 'Открыт';
      case SupportStatus.inProgress:
        return 'В работе';
      case SupportStatus.pending:
        return 'Ожидает';
      case SupportStatus.resolved:
        return 'Решён';
      case SupportStatus.closed:
        return 'Закрыт';
    }
  }

  /// Получить цвет приоритета
  Color get priorityColor {
    switch (priority) {
      case SupportPriority.low:
        return Colors.green;
      case SupportPriority.medium:
        return Colors.orange;
      case SupportPriority.high:
        return Colors.red;
      case SupportPriority.critical:
        return Colors.purple;
    }
  }

  /// Получить текст приоритета
  String get priorityText {
    switch (priority) {
      case SupportPriority.low:
        return 'Низкий';
      case SupportPriority.medium:
        return 'Средний';
      case SupportPriority.high:
        return 'Высокий';
      case SupportPriority.critical:
        return 'Критический';
    }
  }

  /// Получить иконку категории
  IconData get categoryIcon {
    switch (category) {
      case SupportCategory.general:
        return Icons.help_outline;
      case SupportCategory.technical:
        return Icons.bug_report;
      case SupportCategory.billing:
        return Icons.payment;
      case SupportCategory.feature:
        return Icons.lightbulb;
      case SupportCategory.account:
        return Icons.person;
      case SupportCategory.booking:
        return Icons.event;
      case SupportCategory.payment:
        return Icons.credit_card;
      case SupportCategory.other:
        return Icons.more_horiz;
    }
  }

  /// Получить текст категории
  String get categoryText {
    switch (category) {
      case SupportCategory.general:
        return 'Общие вопросы';
      case SupportCategory.technical:
        return 'Технические проблемы';
      case SupportCategory.billing:
        return 'Биллинг';
      case SupportCategory.feature:
        return 'Предложения';
      case SupportCategory.account:
        return 'Аккаунт';
      case SupportCategory.booking:
        return 'Бронирование';
      case SupportCategory.payment:
        return 'Платежи';
      case SupportCategory.other:
        return 'Другое';
    }
  }
}

/// Категории поддержки
enum SupportCategory {
  general,
  technical,
  billing,
  feature,
  account,
  booking,
  payment,
  other,
}

/// Расширение для SupportCategory
extension SupportCategoryExtension on SupportCategory {
  String get categoryText {
    switch (this) {
      case SupportCategory.general:
        return 'Общие вопросы';
      case SupportCategory.technical:
        return 'Техническая поддержка';
      case SupportCategory.billing:
        return 'Биллинг';
      case SupportCategory.feature:
        return 'Функции';
      case SupportCategory.account:
        return 'Аккаунт';
      case SupportCategory.booking:
        return 'Бронирование';
      case SupportCategory.payment:
        return 'Платежи';
      case SupportCategory.other:
        return 'Другое';
    }
  }

  IconData get categoryIcon {
    switch (this) {
      case SupportCategory.general:
        return Icons.help_outline;
      case SupportCategory.technical:
        return Icons.build;
      case SupportCategory.billing:
        return Icons.payment;
      case SupportCategory.feature:
        return Icons.lightbulb_outline;
      case SupportCategory.account:
        return Icons.person;
      case SupportCategory.booking:
        return Icons.calendar_today;
      case SupportCategory.payment:
        return Icons.credit_card;
      case SupportCategory.other:
        return Icons.more_horiz;
    }
  }
}

/// Приоритеты поддержки
enum SupportPriority {
  low,
  medium,
  high,
  critical,
}

/// Статусы поддержки
enum SupportStatus {
  open,
  inProgress,
  pending,
  resolved,
  closed,
}

/// Сообщение в тикете поддержки
class SupportMessage {
  final String id;
  final String ticketId;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final bool isFromSupport;
  final String content;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.isFromSupport,
    required this.content,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id'] ?? '',
      ticketId: map['ticketId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorEmail: map['authorEmail'] ?? '',
      isFromSupport: map['isFromSupport'] ?? false,
      content: map['content'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'isFromSupport': isFromSupport,
      'content': content,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SupportMessage copyWith({
    String? id,
    String? ticketId,
    String? authorId,
    String? authorName,
    String? authorEmail,
    bool? isFromSupport,
    String? content,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      isFromSupport: isFromSupport ?? this.isFromSupport,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// FAQ элемент
class FAQItem {
  final String id;
  final String question;
  final String answer;
  final SupportCategory category;
  final List<String> tags;
  final int viewsCount;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
    this.viewsCount = 0,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FAQItem(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      category: SupportCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => SupportCategory.general,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      viewsCount: data['viewsCount'] ?? 0,
      isPublished: data['isPublished'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category.name,
      'tags': tags,
      'viewsCount': viewsCount,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FAQItem copyWith({
    String? id,
    String? question,
    String? answer,
    SupportCategory? category,
    List<String>? tags,
    int? viewsCount,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FAQItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      viewsCount: viewsCount ?? this.viewsCount,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Статистика поддержки
class SupportStats {
  final int totalTickets;
  final int openTickets;
  final int inProgressTickets;
  final int resolvedTickets;
  final int closedTickets;
  final double averageResolutionTime; // в часах
  final Map<SupportCategory, int> ticketsByCategory;
  final Map<SupportPriority, int> ticketsByPriority;
  final List<String> topIssues;

  const SupportStats({
    required this.totalTickets,
    required this.openTickets,
    required this.inProgressTickets,
    required this.resolvedTickets,
    required this.closedTickets,
    required this.averageResolutionTime,
    required this.ticketsByCategory,
    required this.ticketsByPriority,
    required this.topIssues,
  });

  factory SupportStats.empty() {
    return const SupportStats(
      totalTickets: 0,
      openTickets: 0,
      inProgressTickets: 0,
      resolvedTickets: 0,
      closedTickets: 0,
      averageResolutionTime: 0.0,
      ticketsByCategory: {},
      ticketsByPriority: {},
      topIssues: [],
    );
  }
}
