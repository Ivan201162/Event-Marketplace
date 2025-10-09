import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель приглашения специалиста в заявку
class SpecialistInvitation {
  const SpecialistInvitation({
    required this.id,
    required this.orderId,
    required this.specialistId,
    required this.customerId,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.responseMessage,
    this.respondedAt,
    this.metadata,
  });

  factory SpecialistInvitation.fromMap(Map<String, dynamic> map) =>
      SpecialistInvitation(
        id: map['id'] as String,
        orderId: map['orderId'] as String,
        specialistId: map['specialistId'] as String,
        customerId: map['customerId'] as String,
        message: map['message'] as String,
        status: InvitationStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => InvitationStatus.pending,
        ),
        createdAt: _parseTimestamp(map['createdAt']),
        updatedAt: _parseTimestamp(map['updatedAt']),
        expiresAt:
            map['expiresAt'] != null ? _parseTimestamp(map['expiresAt']) : null,
        responseMessage: map['responseMessage'] as String?,
        respondedAt: map['respondedAt'] != null
            ? _parseTimestamp(map['respondedAt'])
            : null,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  factory SpecialistInvitation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistInvitation.fromMap({...data, 'id': doc.id});
  }
  final String id;
  final String orderId;
  final String specialistId;
  final String customerId;
  final String message;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final String? responseMessage;
  final DateTime? respondedAt;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'specialistId': specialistId,
        'customerId': customerId,
        'message': message,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        if (responseMessage != null) 'responseMessage': responseMessage,
        if (respondedAt != null)
          'respondedAt': Timestamp.fromDate(respondedAt!),
        if (metadata != null) 'metadata': metadata,
      };

  SpecialistInvitation copyWith({
    String? id,
    String? orderId,
    String? specialistId,
    String? customerId,
    String? message,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? responseMessage,
    DateTime? respondedAt,
    Map<String, dynamic>? metadata,
  }) =>
      SpecialistInvitation(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        message: message ?? this.message,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        responseMessage: responseMessage ?? this.responseMessage,
        respondedAt: respondedAt ?? this.respondedAt,
        metadata: metadata ?? this.metadata,
      );

  static DateTime _parseTimestamp(timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }

  /// Проверить, истекло ли приглашение
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Проверить, можно ли ответить на приглашение
  bool get canRespond => status == InvitationStatus.pending && !isExpired;

  @override
  String toString() =>
      'SpecialistInvitation(id: $id, orderId: $orderId, specialistId: $specialistId, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статус приглашения
enum InvitationStatus {
  pending('Ожидает ответа'),
  accepted('Принято'),
  declined('Отклонено'),
  expired('Истекло'),
  cancelled('Отменено');

  const InvitationStatus(this.displayName);
  final String displayName;
}

/// Шаблон приглашения
class InvitationTemplate {
  const InvitationTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.message,
    required this.tags,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvitationTemplate.fromMap(Map<String, dynamic> map) =>
      InvitationTemplate(
        id: map['id'] as String,
        userId: map['userId'] as String,
        name: map['name'] as String,
        message: map['message'] as String,
        tags: List<String>.from(map['tags'] ?? []),
        isDefault: map['isDefault'] as bool? ?? false,
        createdAt: _parseTimestamp(map['createdAt']),
        updatedAt: _parseTimestamp(map['updatedAt']),
      );

  factory InvitationTemplate.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return InvitationTemplate.fromMap({...data, 'id': doc.id});
  }
  final String id;
  final String userId;
  final String name;
  final String message;
  final List<String> tags;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'message': message,
        'tags': tags,
        'isDefault': isDefault,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static DateTime _parseTimestamp(timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }
}

/// Статистика приглашений
class InvitationStats {
  const InvitationStats({
    required this.specialistId,
    required this.totalInvitations,
    required this.acceptedInvitations,
    required this.declinedInvitations,
    required this.pendingInvitations,
    required this.expiredInvitations,
    required this.acceptanceRate,
    required this.responseRate,
    required this.lastUpdated,
  });

  factory InvitationStats.fromMap(Map<String, dynamic> map) => InvitationStats(
        specialistId: map['specialistId'] as String,
        totalInvitations: map['totalInvitations'] as int,
        acceptedInvitations: map['acceptedInvitations'] as int,
        declinedInvitations: map['declinedInvitations'] as int,
        pendingInvitations: map['pendingInvitations'] as int,
        expiredInvitations: map['expiredInvitations'] as int,
        acceptanceRate: (map['acceptanceRate'] as num).toDouble(),
        responseRate: (map['responseRate'] as num).toDouble(),
        lastUpdated: _parseTimestamp(map['lastUpdated']),
      );
  final String specialistId;
  final int totalInvitations;
  final int acceptedInvitations;
  final int declinedInvitations;
  final int pendingInvitations;
  final int expiredInvitations;
  final double acceptanceRate;
  final double responseRate;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'totalInvitations': totalInvitations,
        'acceptedInvitations': acceptedInvitations,
        'declinedInvitations': declinedInvitations,
        'pendingInvitations': pendingInvitations,
        'expiredInvitations': expiredInvitations,
        'acceptanceRate': acceptanceRate,
        'responseRate': responseRate,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  static DateTime _parseTimestamp(timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    return DateTime.now();
  }
}
