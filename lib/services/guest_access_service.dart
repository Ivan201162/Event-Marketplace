import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/guest_access.dart';

/// Сервис для работы с гостевым доступом
class GuestAccessService {
  static final GuestAccessService _instance = GuestAccessService._internal();
  factory GuestAccessService() => _instance;
  GuestAccessService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать гостевой доступ для мероприятия
  Future<GuestAccess?> createGuestAccess({
    required String eventId,
    required String organizerId,
    String? guestName,
    String? guestEmail,
    Duration? expirationDuration,
  }) async {
    try {
      AppLogger.logI('Создание гостевого доступа для мероприятия $eventId', 'guest_access_service');

      final accessCode = _generateAccessCode();
      final now = DateTime.now();
      final expiresAt = expirationDuration != null 
          ? now.add(expirationDuration) 
          : now.add(const Duration(days: 30)); // По умолчанию 30 дней

      final guestAccessId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

      final guestAccess = GuestAccess(
        id: guestAccessId,
        eventId: eventId,
        organizerId: organizerId,
        guestName: guestName,
        guestEmail: guestEmail,
        accessCode: accessCode,
        status: GuestAccessStatus.active,
        createdAt: now,
        expiresAt: expiresAt,
        usageCount: 0,
        metadata: {
          'createdBy': organizerId,
          'eventTitle': null, // TODO: Получить название мероприятия
        },
      );

      await _firestore
          .collection('guest_access')
          .doc(guestAccessId)
          .set(guestAccess.toMap());

      AppLogger.logI('Гостевой доступ создан: $accessCode', 'guest_access_service');
      return guestAccess;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка создания гостевого доступа', 'guest_access_service', e, stackTrace);
      return null;
    }
  }

  /// Получить гостевой доступ по коду
  Future<GuestAccess?> getGuestAccessByCode(String accessCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('guest_access')
          .where('accessCode', isEqualTo: accessCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final guestAccess = GuestAccess.fromMap(doc.data(), doc.id);

      // Проверяем, не истек ли доступ
      if (guestAccess.isExpired) {
        // Обновляем статус на истекший
        await _firestore
            .collection('guest_access')
            .doc(doc.id)
            .update({'status': 'expired'});
        return null;
      }

      return guestAccess;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения гостевого доступа', 'guest_access_service', e, stackTrace);
      return null;
    }
  }

  /// Использовать гостевой доступ
  Future<bool> useGuestAccess(String accessCode, {String? guestName, String? guestEmail}) async {
    try {
      final guestAccess = await getGuestAccessByCode(accessCode);
      if (guestAccess == null) {
        return false;
      }

      // Обновляем статистику использования
      await _firestore.collection('guest_access').doc(guestAccess.id).update({
        'lastUsedAt': FieldValue.serverTimestamp(),
        'usageCount': FieldValue.increment(1),
        if (guestName != null) 'guestName': guestName,
        if (guestEmail != null) 'guestEmail': guestEmail,
      });

      AppLogger.logI('Гостевой доступ использован: $accessCode', 'guest_access_service');
      return true;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка использования гостевого доступа', 'guest_access_service', e, stackTrace);
      return false;
    }
  }

  /// Получить все гостевые доступы для мероприятия
  Future<List<GuestAccess>> getEventGuestAccesses(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('guest_access')
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GuestAccess.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения гостевых доступов мероприятия', 'guest_access_service', e, stackTrace);
      return [];
    }
  }

  /// Получить все гостевые доступы организатора
  Future<List<GuestAccess>> getOrganizerGuestAccesses(String organizerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('guest_access')
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GuestAccess.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения гостевых доступов организатора', 'guest_access_service', e, stackTrace);
      return [];
    }
  }

  /// Обновить статус гостевого доступа
  Future<bool> updateGuestAccessStatus(String guestAccessId, GuestAccessStatus status) async {
    try {
      await _firestore.collection('guest_access').doc(guestAccessId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.logI('Статус гостевого доступа обновлен: $guestAccessId -> $status', 'guest_access_service');
      return true;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка обновления статуса гостевого доступа', 'guest_access_service', e, stackTrace);
      return false;
    }
  }

  /// Удалить гостевой доступ
  Future<bool> deleteGuestAccess(String guestAccessId) async {
    try {
      await _firestore.collection('guest_access').doc(guestAccessId).delete();
      AppLogger.logI('Гостевой доступ удален: $guestAccessId', 'guest_access_service');
      return true;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка удаления гостевого доступа', 'guest_access_service', e, stackTrace);
      return false;
    }
  }

  /// Продлить срок действия гостевого доступа
  Future<bool> extendGuestAccess(String guestAccessId, Duration extension) async {
    try {
      final doc = await _firestore.collection('guest_access').doc(guestAccessId).get();
      if (!doc.exists) return false;

      final guestAccess = GuestAccess.fromMap(doc.data()!, doc.id);
      final newExpiresAt = (guestAccess.expiresAt ?? DateTime.now()).add(extension);

      await _firestore.collection('guest_access').doc(guestAccessId).update({
        'expiresAt': Timestamp.fromDate(newExpiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.logI('Срок действия гостевого доступа продлен: $guestAccessId', 'guest_access_service');
      return true;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка продления гостевого доступа', 'guest_access_service', e, stackTrace);
      return false;
    }
  }

  /// Генерировать уникальный код доступа
  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Проверить, существует ли код доступа
  Future<bool> isAccessCodeExists(String accessCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('guest_access')
          .where('accessCode', isEqualTo: accessCode)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      AppLogger.logE('Ошибка проверки кода доступа', 'guest_access_service', e);
      return false;
    }
  }

  /// Получить статистику использования гостевого доступа
  Future<Map<String, dynamic>> getGuestAccessStats(String guestAccessId) async {
    try {
      final doc = await _firestore.collection('guest_access').doc(guestAccessId).get();
      if (!doc.exists) return {};

      final guestAccess = GuestAccess.fromMap(doc.data()!, doc.id);
      
      return {
        'usageCount': guestAccess.usageCount,
        'lastUsedAt': guestAccess.lastUsedAt,
        'isActive': guestAccess.isActive,
        'daysRemaining': guestAccess.expiresAt != null 
            ? guestAccess.expiresAt!.difference(DateTime.now()).inDays 
            : null,
      };
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения статистики гостевого доступа', 'guest_access_service', e, stackTrace);
      return {};
    }
  }
}