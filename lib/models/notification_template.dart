import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель шаблона уведомления
class NotificationTemplate {
  const NotificationTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.body,
    required this.type,
    required this.channel,
    this.variables = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory NotificationTemplate.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return NotificationTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.general,
      ),
      channel: NotificationChannel.values.firstWhere(
        (e) => e.toString().split('.').last == data['channel'],
        orElse: () => NotificationChannel.push,
      ),
      variables: Map<String, String>.from(data['variables'] ?? {}),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory NotificationTemplate.fromMap(Map<String, dynamic> data) => NotificationTemplate(
    id: data['id'] ?? '',
    name: data['name'] ?? '',
    title: data['title'] ?? '',
    body: data['body'] ?? '',
    type: NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == data['type'],
      orElse: () => NotificationType.general,
    ),
    channel: NotificationChannel.values.firstWhere(
      (e) => e.toString().split('.').last == data['channel'],
      orElse: () => NotificationChannel.push,
    ),
    variables: Map<String, String>.from(data['variables'] ?? {}),
    isActive: data['isActive'] as bool? ?? true,
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    updatedAt: (data['updatedAt'] as Timestamp).toDate(),
  );
  final String id;
  final String name;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationChannel channel;
  final Map<String, String> variables;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'name': name,
    'title': title,
    'body': body,
    'type': type.toString().split('.').last,
    'channel': channel.toString().split('.').last,
    'variables': variables,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Создать копию с изменениями
  NotificationTemplate copyWith({
    String? id,
    String? name,
    String? title,
    String? body,
    NotificationType? type,
    NotificationChannel? channel,
    Map<String, String>? variables,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NotificationTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    title: title ?? this.title,
    body: body ?? this.body,
    type: type ?? this.type,
    channel: channel ?? this.channel,
    variables: variables ?? this.variables,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Заменить переменные в тексте
  String replaceVariables(Map<String, String> values) {
    var result = body;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// Заменить переменные в заголовке
  String replaceTitleVariables(Map<String, String> values) {
    var result = title;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationTemplate &&
        other.id == id &&
        other.name == name &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.channel == channel &&
        other.variables == variables &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, title, body, type, channel, variables, isActive, createdAt, updatedAt);

  @override
  String toString() => 'NotificationTemplate(id: $id, name: $name, type: $type)';
}

/// Типы уведомлений
enum NotificationType {
  general,
  booking,
  payment,
  message,
  review,
  reminder,
  promotion,
  system,
  security,
  cancellation,
}

/// Каналы уведомлений
enum NotificationChannel { push, email, sms, inApp }

/// Модель отправленного уведомления
class SentNotification {
  const SentNotification({
    required this.id,
    required this.templateId,
    this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.channel,
    this.data = const {},
    this.status = NotificationStatus.pending,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.errorMessage,
  });

  /// Создать из документа Firestore
  factory SentNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SentNotification(
      id: doc.id,
      templateId: data['templateId'] ?? '',
      userId: data['userId'],
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.general,
      ),
      channel: NotificationChannel.values.firstWhere(
        (e) => e.toString().split('.').last == data['channel'],
        orElse: () => NotificationChannel.push,
      ),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => NotificationStatus.pending,
      ),
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      deliveredAt: data['deliveredAt'] != null ? (data['deliveredAt'] as Timestamp).toDate() : null,
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
      errorMessage: data['errorMessage'],
    );
  }

  /// Создать из Map
  factory SentNotification.fromMap(Map<String, dynamic> data) => SentNotification(
    id: data['id'] ?? '',
    templateId: data['templateId'] ?? '',
    userId: data['userId'],
    title: data['title'] ?? '',
    body: data['body'] ?? '',
    type: NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == data['type'],
      orElse: () => NotificationType.general,
    ),
    channel: NotificationChannel.values.firstWhere(
      (e) => e.toString().split('.').last == data['channel'],
      orElse: () => NotificationChannel.push,
    ),
    data: Map<String, dynamic>.from(data['data'] ?? {}),
    status: NotificationStatus.values.firstWhere(
      (e) => e.toString().split('.').last == data['status'],
      orElse: () => NotificationStatus.pending,
    ),
    sentAt: (data['sentAt'] as Timestamp).toDate(),
    deliveredAt: data['deliveredAt'] != null ? (data['deliveredAt'] as Timestamp).toDate() : null,
    readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
    errorMessage: data['errorMessage'],
  );
  final String id;
  final String templateId;
  final String? userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationChannel channel;
  final Map<String, dynamic> data;
  final NotificationStatus status;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorMessage;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'templateId': templateId,
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.toString().split('.').last,
    'channel': channel.toString().split('.').last,
    'data': data,
    'status': status.toString().split('.').last,
    'sentAt': Timestamp.fromDate(sentAt),
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    'errorMessage': errorMessage,
  };

  /// Создать копию с изменениями
  SentNotification copyWith({
    String? id,
    String? templateId,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationChannel? channel,
    Map<String, dynamic>? data,
    NotificationStatus? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? errorMessage,
  }) => SentNotification(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    body: body ?? this.body,
    type: type ?? this.type,
    channel: channel ?? this.channel,
    data: data ?? this.data,
    status: status ?? this.status,
    sentAt: sentAt ?? this.sentAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    readAt: readAt ?? this.readAt,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  /// Проверить, доставлено ли уведомление
  bool get isDelivered => status == NotificationStatus.delivered;

  /// Проверить, прочитано ли уведомление
  bool get isRead => readAt != null;

  /// Проверить, есть ли ошибка
  bool get hasError => status == NotificationStatus.failed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SentNotification &&
        other.id == id &&
        other.templateId == templateId &&
        other.userId == userId &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.channel == channel &&
        other.data == data &&
        other.status == status &&
        other.sentAt == sentAt &&
        other.deliveredAt == deliveredAt &&
        other.readAt == readAt &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    userId,
    title,
    body,
    type,
    channel,
    data,
    status,
    sentAt,
    deliveredAt,
    readAt,
    errorMessage,
  );

  @override
  String toString() => 'SentNotification(id: $id, title: $title, status: $status)';
}

/// Статусы уведомлений
enum NotificationStatus { pending, sent, delivered, failed, read }

/// Статистика уведомлений
class NotificationStatistics {
  const NotificationStatistics({
    required this.totalSent,
    required this.totalDelivered,
    required this.totalRead,
    required this.totalFailed,
    required this.sentByType,
    required this.sentByChannel,
    required this.deliveryRate,
    required this.readRate,
    required this.periodStart,
    required this.periodEnd,
  });
  final int totalSent;
  final int totalDelivered;
  final int totalRead;
  final int totalFailed;
  final Map<String, int> sentByType;
  final Map<String, int> sentByChannel;
  final double deliveryRate;
  final double readRate;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Процент доставленных уведомлений
  double get deliveryPercentage {
    if (totalSent == 0) return 0;
    return (totalDelivered / totalSent) * 100;
  }

  /// Процент прочитанных уведомлений
  double get readPercentage {
    if (totalDelivered == 0) return 0;
    return (totalRead / totalDelivered) * 100;
  }

  /// Процент неудачных отправок
  double get failurePercentage {
    if (totalSent == 0) return 0;
    return (totalFailed / totalSent) * 100;
  }

  @override
  String toString() =>
      'NotificationStatistics(totalSent: $totalSent, deliveryRate: ${deliveryRate.toStringAsFixed(2)}%)';
}
