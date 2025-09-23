import 'package:cloud_firestore/cloud_firestore.dart';

enum GuestAccessStatus { active, expired, revoked }

class GuestAccess {
  final String id;
  final String eventId;
  final String organizerId;
  final String? guestName;
  final String? guestEmail;
  final String accessCode;
  final GuestAccessStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final Map<String, dynamic>? metadata;

  GuestAccess({
    required this.id,
    required this.eventId,
    required this.organizerId,
    this.guestName,
    this.guestEmail,
    required this.accessCode,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.lastUsedAt,
    required this.usageCount,
    this.metadata,
  });

  factory GuestAccess.fromMap(Map<String, dynamic> map, String id) {
    return GuestAccess(
      id: id,
      eventId: map['eventId'] as String,
      organizerId: map['organizerId'] as String,
      guestName: map['guestName'] as String?,
      guestEmail: map['guestEmail'] as String?,
      accessCode: map['accessCode'] as String,
      status: GuestAccessStatus.values.firstWhere(
        (e) => e.toString() == 'GuestAccessStatus.${map['status']}',
        orElse: () => GuestAccessStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiresAt: map['expiresAt'] != null 
          ? (map['expiresAt'] as Timestamp).toDate() 
          : null,
      lastUsedAt: map['lastUsedAt'] != null 
          ? (map['lastUsedAt'] as Timestamp).toDate() 
          : null,
      usageCount: map['usageCount'] as int,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'organizerId': organizerId,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'accessCode': accessCode,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
      'usageCount': usageCount,
      'metadata': metadata,
    };
  }

  /// Проверить, активен ли доступ
  bool get isActive {
    if (status != GuestAccessStatus.active) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Проверить, истек ли доступ
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Получить статус в читаемом формате
  String getStatusText() {
    switch (status) {
      case GuestAccessStatus.active:
        return isExpired ? 'Истек' : 'Активен';
      case GuestAccessStatus.expired:
        return 'Истек';
      case GuestAccessStatus.revoked:
        return 'Отозван';
    }
  }

  /// Получить цвет статуса
  String getStatusColor() {
    switch (status) {
      case GuestAccessStatus.active:
        return isExpired ? 'orange' : 'green';
      case GuestAccessStatus.expired:
        return 'red';
      case GuestAccessStatus.revoked:
        return 'grey';
    }
  }

  /// Создать ссылку для гостевого доступа
  String getGuestLink() {
    return 'https://event-marketplace.app/guest/${accessCode}';
  }
}
