import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/feature_flags.dart';

/// Сервис для режима гостя мероприятия
class GuestModeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать гостевой доступ к мероприятию
  Future<GuestAccess> createGuestAccess({
    required String eventId,
    required String organizerId,
    required String guestName,
    required String guestEmail,
    String? guestPhone,
    String? invitationMessage,
    DateTime? expiresAt,
  }) async {
    if (!FeatureFlags.guestModeEnabled) {
      throw Exception('Режим гостя мероприятия отключен');
    }

    try {
      // Создаем гостевой доступ
      final guestAccess = GuestAccess(
        id: '',
        eventId: eventId,
        organizerId: organizerId,
        guestName: guestName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        invitationMessage: invitationMessage,
        accessCode: _generateAccessCode(),
        status: GuestAccessStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
        accessCount: 0,
        metadata: {},
      );

      // Сохраняем в Firestore
      final docRef =
          await _firestore.collection('guest_access').add(guestAccess.toMap());

      // Отправляем приглашение
      await _sendInvitation(docRef.id, guestAccess);

      return guestAccess.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания гостевого доступа: $e');
    }
  }

  /// Активировать гостевой доступ
  Future<GuestAccess> activateGuestAccess({
    required String accessCode,
    required String guestName,
    String? guestPhone,
  }) async {
    try {
      // Находим гостевой доступ по коду
      final snapshot = await _firestore
          .collection('guest_access')
          .where('accessCode', isEqualTo: accessCode)
          .where('status', isEqualTo: GuestAccessStatus.pending.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Неверный код доступа или доступ уже активирован');
      }

      final doc = snapshot.docs.first;
      final guestAccess = GuestAccess.fromDocument(doc);

      // Проверяем срок действия
      if (guestAccess.expiresAt.isBefore(DateTime.now())) {
        throw Exception('Срок действия кода доступа истек');
      }

      // Активируем доступ
      await _firestore.collection('guest_access').doc(doc.id).update({
        'status': GuestAccessStatus.active.name,
        'activatedAt': Timestamp.fromDate(DateTime.now()),
        'guestName': guestName,
        'guestPhone': guestPhone,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return guestAccess.copyWith(
        id: doc.id,
        status: GuestAccessStatus.active,
        activatedAt: DateTime.now(),
        guestName: guestName,
        guestPhone: guestPhone,
      );
    } catch (e) {
      throw Exception('Ошибка активации гостевого доступа: $e');
    }
  }

  /// Получить информацию о мероприятии для гостя
  Future<GuestEventInfo> getGuestEventInfo(String accessCode) async {
    try {
      final snapshot = await _firestore
          .collection('guest_access')
          .where('accessCode', isEqualTo: accessCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Неверный код доступа');
      }

      final guestAccess = GuestAccess.fromDocument(snapshot.docs.first);

      if (guestAccess.status != GuestAccessStatus.active) {
        throw Exception('Доступ не активирован');
      }

      // Получаем информацию о мероприятии
      final eventDoc =
          await _firestore.collection('events').doc(guestAccess.eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Мероприятие не найдено');
      }

      final eventData = eventDoc.data();

      // Обновляем статистику доступа
      await _updateAccessStats(snapshot.docs.first.id);

      return GuestEventInfo(
        eventId: guestAccess.eventId,
        eventTitle: eventData['title'] ?? '',
        eventDescription: eventData['description'] ?? '',
        eventDate: (eventData['date'] as Timestamp).toDate(),
        eventLocation: eventData['location'] ?? '',
        organizerName: eventData['organizerName'] ?? '',
        guestAccess: guestAccess,
        eventDetails: Map<String, dynamic>.from(eventData),
      );
    } catch (e) {
      throw Exception('Ошибка получения информации о мероприятии: $e');
    }
  }

  /// Получить список гостевых доступов для мероприятия
  Future<List<GuestAccess>> getEventGuestAccesses(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('guest_access')
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(GuestAccess.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения списка гостевых доступов: $e');
    }
  }

  /// Отозвать гостевой доступ
  Future<void> revokeGuestAccess(String guestAccessId) async {
    try {
      await _firestore.collection('guest_access').doc(guestAccessId).update({
        'status': GuestAccessStatus.revoked.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка отзыва гостевого доступа: $e');
    }
  }

  /// Продлить срок действия гостевого доступа
  Future<void> extendGuestAccess({
    required String guestAccessId,
    required DateTime newExpiresAt,
  }) async {
    try {
      await _firestore.collection('guest_access').doc(guestAccessId).update({
        'expiresAt': Timestamp.fromDate(newExpiresAt),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка продления гостевого доступа: $e');
    }
  }

  // Приватные методы

  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();

    for (var i = 0; i < 8; i++) {
      code.write(chars[(random + i) % chars.length]);
    }

    return code.toString();
  }

  Future<void> _sendInvitation(
    String guestAccessId,
    GuestAccess guestAccess,
  ) async {
    try {
      // TODO: Отправить email с кодом доступа
      // TODO: Отправить SMS с кодом доступа (если указан телефон)
    } catch (e) {
      // Игнорируем ошибки отправки
    }
  }

  Future<void> _updateAccessStats(String guestAccessId) async {
    try {
      await _firestore.collection('guest_access').doc(guestAccessId).update({
        'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
        'accessCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Игнорируем ошибки обновления статистики
    }
  }
}

/// Модель гостевого доступа
class GuestAccess {
  const GuestAccess({
    required this.id,
    required this.eventId,
    required this.organizerId,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
    this.invitationMessage,
    required this.accessCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.activatedAt,
    required this.expiresAt,
    this.lastAccessedAt,
    required this.accessCount,
    required this.metadata,
  });

  /// Создать из документа Firestore
  factory GuestAccess.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GuestAccess(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      organizerId: data['organizerId'] ?? '',
      guestName: data['guestName'] ?? '',
      guestEmail: data['guestEmail'] ?? '',
      guestPhone: data['guestPhone'],
      invitationMessage: data['invitationMessage'],
      accessCode: data['accessCode'] ?? '',
      status: GuestAccessStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GuestAccessStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      activatedAt: data['activatedAt'] != null
          ? (data['activatedAt'] as Timestamp).toDate()
          : null,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      lastAccessedAt: data['lastAccessedAt'] != null
          ? (data['lastAccessedAt'] as Timestamp).toDate()
          : null,
      accessCount: data['accessCount'] ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String eventId;
  final String organizerId;
  final String guestName;
  final String guestEmail;
  final String? guestPhone;
  final String? invitationMessage;
  final String accessCode;
  final GuestAccessStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? activatedAt;
  final DateTime expiresAt;
  final DateTime? lastAccessedAt;
  final int accessCount;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'organizerId': organizerId,
        'guestName': guestName,
        'guestEmail': guestEmail,
        'guestPhone': guestPhone,
        'invitationMessage': invitationMessage,
        'accessCode': accessCode,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'activatedAt':
            activatedAt != null ? Timestamp.fromDate(activatedAt!) : null,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'lastAccessedAt':
            lastAccessedAt != null ? Timestamp.fromDate(lastAccessedAt!) : null,
        'accessCount': accessCount,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  GuestAccess copyWith({
    String? id,
    String? eventId,
    String? organizerId,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? invitationMessage,
    String? accessCode,
    GuestAccessStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? activatedAt,
    DateTime? expiresAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    Map<String, dynamic>? metadata,
  }) =>
      GuestAccess(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        organizerId: organizerId ?? this.organizerId,
        guestName: guestName ?? this.guestName,
        guestEmail: guestEmail ?? this.guestEmail,
        guestPhone: guestPhone ?? this.guestPhone,
        invitationMessage: invitationMessage ?? this.invitationMessage,
        accessCode: accessCode ?? this.accessCode,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        activatedAt: activatedAt ?? this.activatedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
        accessCount: accessCount ?? this.accessCount,
        metadata: metadata ?? this.metadata,
      );
}

/// Информация о мероприятии для гостя
class GuestEventInfo {
  const GuestEventInfo({
    required this.eventId,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventDate,
    required this.eventLocation,
    required this.organizerName,
    required this.guestAccess,
    required this.eventDetails,
  });
  final String eventId;
  final String eventTitle;
  final String eventDescription;
  final DateTime eventDate;
  final String eventLocation;
  final String organizerName;
  final GuestAccess guestAccess;
  final Map<String, dynamic> eventDetails;
}

/// Статусы гостевого доступа
enum GuestAccessStatus {
  pending, // Ожидает активации
  active, // Активен
  expired, // Истек
  revoked, // Отозван
}
