/// Расширенная модель заявки
class EnhancedOrder {
  const EnhancedOrder({
    required this.id,
    required this.customerId,
    required this.specialistId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.budget,
    this.deadline,
    this.location,
    this.category,
    this.priority = OrderPriority.medium,
    this.comments = const [],
    this.timeline = const [],
    this.attachments = const [],
    this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  /// Создать из Map
  factory EnhancedOrder.fromMap(Map<String, dynamic> map) => EnhancedOrder(
        id: map['id'] as String,
        customerId: map['customerId'] as String,
        specialistId: map['specialistId'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        status: OrderStatus.fromString(map['status'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        budget: (map['budget'] as num?)?.toDouble(),
        deadline: map['deadline'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
            : null,
        location: map['location'] as String?,
        category: map['category'] as String?,
        priority:
            OrderPriority.fromString(map['priority'] as String? ?? 'medium'),
        comments: (map['comments'] as List?)
                ?.map(
                  (comment) =>
                      OrderComment.fromMap(comment as Map<String, dynamic>),
                )
                .toList() ??
            [],
        timeline: (map['timeline'] as List?)
                ?.map(
                  (event) =>
                      OrderTimelineEvent.fromMap(event as Map<String, dynamic>),
                )
                .toList() ??
            [],
        attachments: (map['attachments'] as List?)
                ?.map(
                  (attachment) => OrderAttachment.fromMap(
                    attachment as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
        updatedAt: map['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
            : null,
        completedAt: map['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
            : null,
        cancelledAt: map['cancelledAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['cancelledAt'] as int)
            : null,
        cancellationReason: map['cancellationReason'] as String?,
      );

  /// Уникальный идентификатор
  final String id;

  /// ID заказчика
  final String customerId;

  /// ID специалиста
  final String specialistId;

  /// Заголовок заявки
  final String title;

  /// Описание заявки
  final String description;

  /// Статус заявки
  final OrderStatus status;

  /// Дата создания
  final DateTime createdAt;

  /// Бюджет
  final double? budget;

  /// Дедлайн
  final DateTime? deadline;

  /// Местоположение
  final String? location;

  /// Категория
  final String? category;

  /// Приоритет
  final OrderPriority priority;

  /// Комментарии
  final List<OrderComment> comments;

  /// Таймлайн
  final List<OrderTimelineEvent> timeline;

  /// Вложения
  final List<OrderAttachment> attachments;

  /// Дата обновления
  final DateTime? updatedAt;

  /// Дата завершения
  final DateTime? completedAt;

  /// Дата отмены
  final DateTime? cancelledAt;

  /// Причина отмены
  final String? cancellationReason;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'specialistId': specialistId,
        'title': title,
        'description': description,
        'status': status.value,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'budget': budget,
        'deadline': deadline?.millisecondsSinceEpoch,
        'location': location,
        'category': category,
        'priority': priority.value,
        'comments': comments.map((comment) => comment.toMap()).toList(),
        'timeline': timeline.map((event) => event.toMap()).toList(),
        'attachments':
            attachments.map((attachment) => attachment.toMap()).toList(),
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
        'cancellationReason': cancellationReason,
      };

  /// Создать копию с изменениями
  EnhancedOrder copyWith({
    String? id,
    String? customerId,
    String? specialistId,
    String? title,
    String? description,
    OrderStatus? status,
    DateTime? createdAt,
    double? budget,
    DateTime? deadline,
    String? location,
    String? category,
    OrderPriority? priority,
    List<OrderComment>? comments,
    List<OrderTimelineEvent>? timeline,
    List<OrderAttachment>? attachments,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) =>
      EnhancedOrder(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        specialistId: specialistId ?? this.specialistId,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        budget: budget ?? this.budget,
        deadline: deadline ?? this.deadline,
        location: location ?? this.location,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        comments: comments ?? this.comments,
        timeline: timeline ?? this.timeline,
        attachments: attachments ?? this.attachments,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt ?? this.completedAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        cancellationReason: cancellationReason ?? this.cancellationReason,
      );
}

/// Статус заявки
enum OrderStatus {
  pending('pending'),
  accepted('accepted'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.accepted:
        return 'Принята';
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.completed:
        return 'Завершена';
      case OrderStatus.cancelled:
        return 'Отменена';
    }
  }

  String get color {
    switch (this) {
      case OrderStatus.pending:
        return '#FFA500';
      case OrderStatus.accepted:
        return '#007BFF';
      case OrderStatus.inProgress:
        return '#28A745';
      case OrderStatus.completed:
        return '#6C757D';
      case OrderStatus.cancelled:
        return '#DC3545';
    }
  }
}

/// Приоритет заявки
enum OrderPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const OrderPriority(this.value);
  final String value;

  static OrderPriority fromString(String value) {
    switch (value) {
      case 'low':
        return OrderPriority.low;
      case 'medium':
        return OrderPriority.medium;
      case 'high':
        return OrderPriority.high;
      case 'urgent':
        return OrderPriority.urgent;
      default:
        return OrderPriority.medium;
    }
  }

  String get displayName {
    switch (this) {
      case OrderPriority.low:
        return 'Низкий';
      case OrderPriority.medium:
        return 'Средний';
      case OrderPriority.high:
        return 'Высокий';
      case OrderPriority.urgent:
        return 'Срочный';
    }
  }

  String get color {
    switch (this) {
      case OrderPriority.low:
        return '#28A745';
      case OrderPriority.medium:
        return '#FFC107';
      case OrderPriority.high:
        return '#FD7E14';
      case OrderPriority.urgent:
        return '#DC3545';
    }
  }
}

/// Комментарий к заявке
class OrderComment {
  const OrderComment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.isInternal = false,
    this.attachments = const [],
  });

  factory OrderComment.fromMap(Map<String, dynamic> map) => OrderComment(
        id: map['id'] as String,
        authorId: map['authorId'] as String,
        text: map['text'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        isInternal: (map['isInternal'] as bool?) ?? false,
        attachments: (map['attachments'] as List?)
                ?.map(
                  (attachment) => OrderAttachment.fromMap(
                    attachment as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
      );

  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final bool isInternal;
  final List<OrderAttachment> attachments;

  Map<String, dynamic> toMap() => {
        'id': id,
        'authorId': authorId,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isInternal': isInternal,
        'attachments':
            attachments.map((attachment) => attachment.toMap()).toList(),
      };
}

/// Событие в таймлайне заявки
class OrderTimelineEvent {
  const OrderTimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.authorId,
    this.metadata = const {},
  });

  factory OrderTimelineEvent.fromMap(Map<String, dynamic> map) =>
      OrderTimelineEvent(
        id: map['id'] as String,
        type: OrderTimelineEventType.fromString(map['type'] as String),
        title: map['title'] as String,
        description: map['description'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        authorId: map['authorId'] as String,
        metadata: Map<String, dynamic>.from((map['metadata'] as Map?) ?? {}),
      );

  final String id;
  final OrderTimelineEventType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final String authorId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.value,
        'title': title,
        'description': description,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'authorId': authorId,
        'metadata': metadata,
      };
}

/// Тип события в таймлайне
enum OrderTimelineEventType {
  created('created'),
  accepted('accepted'),
  started('started'),
  milestone('milestone'),
  completed('completed'),
  cancelled('cancelled'),
  comment('comment');

  const OrderTimelineEventType(this.value);
  final String value;

  static OrderTimelineEventType fromString(String value) {
    switch (value) {
      case 'created':
        return OrderTimelineEventType.created;
      case 'accepted':
        return OrderTimelineEventType.accepted;
      case 'started':
        return OrderTimelineEventType.started;
      case 'milestone':
        return OrderTimelineEventType.milestone;
      case 'completed':
        return OrderTimelineEventType.completed;
      case 'cancelled':
        return OrderTimelineEventType.cancelled;
      case 'comment':
        return OrderTimelineEventType.comment;
      default:
        return OrderTimelineEventType.comment;
    }
  }

  String get icon {
    switch (this) {
      case OrderTimelineEventType.created:
        return '📝';
      case OrderTimelineEventType.accepted:
        return '✅';
      case OrderTimelineEventType.started:
        return '🚀';
      case OrderTimelineEventType.milestone:
        return '🎯';
      case OrderTimelineEventType.completed:
        return '🏆';
      case OrderTimelineEventType.cancelled:
        return '❌';
      case OrderTimelineEventType.comment:
        return '💬';
    }
  }
}

/// Вложение к заявке
class OrderAttachment {
  const OrderAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory OrderAttachment.fromMap(Map<String, dynamic> map) => OrderAttachment(
        id: map['id'] as String,
        name: map['name'] as String,
        url: map['url'] as String,
        type: OrderAttachmentType.fromString(map['type'] as String),
        size: map['size'] as int,
        uploadedAt:
            DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'] as int),
        uploadedBy: map['uploadedBy'] as String,
      );

  final String id;
  final String name;
  final String url;
  final OrderAttachmentType type;
  final int size;
  final DateTime uploadedAt;
  final String uploadedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'url': url,
        'type': type.value,
        'size': size,
        'uploadedAt': uploadedAt.millisecondsSinceEpoch,
        'uploadedBy': uploadedBy,
      };
}

/// Тип вложения
enum OrderAttachmentType {
  image('image'),
  video('video'),
  document('document'),
  audio('audio');

  const OrderAttachmentType(this.value);
  final String value;

  static OrderAttachmentType fromString(String value) {
    switch (value) {
      case 'image':
        return OrderAttachmentType.image;
      case 'video':
        return OrderAttachmentType.video;
      case 'document':
        return OrderAttachmentType.document;
      case 'audio':
        return OrderAttachmentType.audio;
      default:
        return OrderAttachmentType.document;
    }
  }

  String get icon {
    switch (this) {
      case OrderAttachmentType.image:
        return '🖼️';
      case OrderAttachmentType.video:
        return '🎥';
      case OrderAttachmentType.document:
        return '📄';
      case OrderAttachmentType.audio:
        return '🎵';
    }
  }
}
