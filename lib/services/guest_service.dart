import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/event.dart';
import '../models/guest.dart';

/// Сервис для работы с гостями мероприятий
class GuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить гостей события
  Stream<List<Guest>> getEventGuests(String eventId) {
    if (!FeatureFlags.guestModeEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('guests')
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Guest.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Добавить гостя к событию
  Future<String> addGuest({
    required String eventId,
    required String name,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    if (!FeatureFlags.guestModeEnabled) {
      throw Exception('Гостевой режим отключен');
    }

    try {
      final guest = Guest(
        id: '', // Будет установлен Firestore
        eventId: eventId,
        name: name,
        email: email,
        phone: phone,
        avatar: avatar,
        status: GuestStatus.invited,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('guests').add(guest.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding guest: $e');
      throw Exception('Ошибка добавления гостя: $e');
    }
  }

  /// Обновить статус гостя
  Future<void> updateGuestStatus(String guestId, GuestStatus status) async {
    if (!FeatureFlags.guestModeEnabled) {
      throw Exception('Гостевой режим отключен');
    }

    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating guest status: $e');
      throw Exception('Ошибка обновления статуса гостя: $e');
    }
  }

  /// Удалить гостя
  Future<void> removeGuest(String guestId) async {
    if (!FeatureFlags.guestModeEnabled) {
      throw Exception('Гостевой режим отключен');
    }

    try {
      await _firestore.collection('guests').doc(guestId).delete();
    } catch (e) {
      debugPrint('Error removing guest: $e');
      throw Exception('Ошибка удаления гостя: $e');
    }
  }

  /// Получить гостя по ID
  Future<Guest?> getGuestById(String guestId) async {
    if (!FeatureFlags.guestModeEnabled) {
      return null;
    }

    try {
      final doc = await _firestore.collection('guests').doc(guestId).get();
      if (!doc.exists) {
        return null;
      }

      return Guest.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('Error getting guest: $e');
      return null;
    }
  }

  /// Создать гостевой доступ к событию
  Future<GuestEventAccess> createGuestAccess({
    required String eventId,
    int maxUses = 1,
    Duration? expiresIn,
  }) async {
    if (!FeatureFlags.guestModeEnabled) {
      throw Exception('Гостевой режим отключен');
    }

    try {
      final accessCode = _generateAccessCode();
      final qrCode = _generateQRCode(eventId, accessCode);
      final expiresAt = DateTime.now().add(expiresIn ?? const Duration(days: 7));

      final guestAccess = GuestEventAccess(
        id: '', // Будет установлен Firestore
        eventId: eventId,
        accessCode: accessCode,
        qrCode: qrCode,
        expiresAt: expiresAt,
        isActive: true,
        maxUses: maxUses,
        currentUses: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('guest_access').add(guestAccess.toMap());

      return guestAccess.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating guest access: $e');
      throw Exception('Ошибка создания гостевого доступа: $e');
    }
  }

  /// Получить событие по коду доступа
  Future<Event?> getEventByAccessCode(String accessCode) async {
    if (!FeatureFlags.guestModeEnabled) {
      return null;
    }

    try {
      final accessQuery = await _firestore
          .collection('guest_access')
          .where('accessCode', isEqualTo: accessCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (accessQuery.docs.isEmpty) {
        return null;
      }

      final access = GuestEventAccess.fromMap({
        'id': accessQuery.docs.first.id,
        ...accessQuery.docs.first.data(),
      });

      // Проверяем срок действия
      if (access.expiresAt.isBefore(DateTime.now())) {
        return null;
      }

      // Проверяем количество использований
      if (access.currentUses >= access.maxUses) {
        return null;
      }

      // Получаем событие
      final eventDoc = await _firestore.collection('events').doc(access.eventId).get();

      if (!eventDoc.exists) {
        return null;
      }

      return Event.fromMap({
        'id': eventDoc.id,
        ...eventDoc.data()!,
      });
    } catch (e) {
      debugPrint('Error getting event by access code: $e');
      return null;
    }
  }

  /// Использовать код доступа
  Future<bool> useAccessCode(String accessCode) async {
    if (!FeatureFlags.guestModeEnabled) {
      return false;
    }

    try {
      final accessQuery = await _firestore
          .collection('guest_access')
          .where('accessCode', isEqualTo: accessCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (accessQuery.docs.isEmpty) {
        return false;
      }

      final accessDoc = accessQuery.docs.first;
      final access = GuestEventAccess.fromMap({
        'id': accessDoc.id,
        ...accessDoc.data(),
      });

      // Проверяем срок действия
      if (access.expiresAt.isBefore(DateTime.now())) {
        return false;
      }

      // Проверяем количество использований
      if (access.currentUses >= access.maxUses) {
        return false;
      }

      // Увеличиваем счетчик использований
      await _firestore.collection('guest_access').doc(accessDoc.id).update({
        'currentUses': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error using access code: $e');
      return false;
    }
  }

  /// Получить приветствия гостей
  Stream<List<GuestGreeting>> getGuestGreetings(String eventId) {
    if (!FeatureFlags.guestModeEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('guest_greetings')
        .where('eventId', isEqualTo: eventId)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => GuestGreeting.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Добавить приветствие от гостя
  Future<String> addGuestGreeting({
    required String eventId,
    required String guestId,
    required String guestName,
    String? guestAvatar,
    required GreetingType type,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
  }) async {
    if (!FeatureFlags.guestModeEnabled) {
      throw Exception('Гостевой режим отключен');
    }

    try {
      final greeting = GuestGreeting(
        id: '', // Будет установлен Firestore
        eventId: eventId,
        guestId: guestId,
        guestName: guestName,
        guestAvatar: guestAvatar,
        type: type,
        text: text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        createdAt: DateTime.now(),
        likedBy: [],
        likesCount: 0,
        isPublic: true,
      );

      final docRef = await _firestore.collection('guest_greetings').add(greeting.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding guest greeting: $e');
      throw Exception('Ошибка добавления приветствия: $e');
    }
  }

  /// Лайкнуть приветствие
  Future<void> toggleGreetingLike(String greetingId, String userId) async {
    if (!FeatureFlags.guestModeEnabled) {
      throw Exception('Гостевой режим отключен');
    }

    try {
      final greetingRef = _firestore.collection('guest_greetings').doc(greetingId);

      await _firestore.runTransaction((transaction) async {
        final greetingDoc = await transaction.get(greetingRef);
        if (!greetingDoc.exists) {
          throw Exception('Приветствие не найдено');
        }

        final greeting = GuestGreeting.fromMap({
          'id': greetingDoc.id,
          ...greetingDoc.data()!,
        });

        final isLiked = greeting.likedBy.contains(userId);
        final newLikedBy = List<String>.from(greeting.likedBy);

        if (isLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        transaction.update(greetingRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikedBy.length,
        });
      });
    } catch (e) {
      debugPrint('Error toggling greeting like: $e');
      throw Exception('Ошибка изменения лайка: $e');
    }
  }

  /// Получить статистику гостей
  Future<Map<String, int>> getGuestStats(String eventId) async {
    if (!FeatureFlags.guestModeEnabled) {
      return {};
    }

    try {
      final guestsQuery =
          await _firestore.collection('guests').where('eventId', isEqualTo: eventId).get();

      final stats = <String, int>{
        'total': 0,
        'invited': 0,
        'confirmed': 0,
        'declined': 0,
        'attended': 0,
        'noShow': 0,
      };

      for (final doc in guestsQuery.docs) {
        final guest = Guest.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[guest.status.name] = (stats[guest.status.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting guest stats: $e');
      return {};
    }
  }

  /// Генерировать код доступа
  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();

    for (var i = 0; i < 8; i++) {
      code.write(chars[random % chars.length]);
    }

    return code.toString();
  }

  /// Генерировать QR код (заглушка)
  String _generateQRCode(String eventId, String accessCode) {
    // В реальном приложении здесь будет генерация QR кода
    return 'QR_${eventId}_$accessCode';
  }

  /// Создать событие для гостя
  Future<String> createGuestEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    String? organizerName,
    String? organizerEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final eventData = {
        'title': title,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'location': location,
        'organizerName': organizerName,
        'organizerEmail': organizerEmail,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGuestEvent': true,
      };

      final docRef = await _firestore.collection('events').add(eventData);
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания события для гостя: $e');
    }
  }

  /// Получить события организатора
  Future<List<Map<String, dynamic>>> getOrganizerEvents(
    String organizerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения событий организатора: $e');
    }
  }

  /// Зарегистрировать гостя
  Future<void> checkInGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': 'checked_in',
        'checkedInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка регистрации гостя: $e');
    }
  }

  /// Отменить регистрацию гостя
  Future<void> checkOutGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': 'checked_out',
        'checkedOutAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка отмены регистрации гостя: $e');
    }
  }

  /// Отменить гостя
  Future<void> cancelGuest(String guestId) async {
    try {
      await _firestore.collection('guests').doc(guestId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка отмены гостя: $e');
    }
  }

  /// Получить событие гостя
  Future<Map<String, dynamic>?> getGuestEvent(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения события гостя: $e');
    }
  }

  /// Зарегистрировать гостя на событие
  Future<String> registerGuest({
    required String eventId,
    required String guestName,
    required String guestEmail,
    String? guestPhone,
    String? notes,
  }) async {
    try {
      final guestData = {
        'eventId': eventId,
        'guestName': guestName,
        'guestEmail': guestEmail,
        'guestPhone': guestPhone,
        'notes': notes,
        'status': 'registered',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('guests').add(guestData);
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка регистрации гостя: $e');
    }
  }
}
