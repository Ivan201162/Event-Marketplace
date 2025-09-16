import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/booking.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Сервис для администрирования
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Коллекции
  static const String _usersCollection = 'users';
  static const String _eventsCollection = 'events';
  static const String _bookingsCollection = 'bookings';
  static const String _adminLogsCollection = 'admin_logs';

  /// Получить всех пользователей
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    });
  }

  /// Получить всех пользователей с фильтрацией
  Stream<List<AppUser>> getUsersWithFilter({
    bool? isBanned,
    bool? isVerified,
    String? searchQuery,
  }) {
    Query query = _firestore.collection(_usersCollection);

    if (isBanned != null) {
      query = query.where('isBanned', isEqualTo: isBanned);
    }

    if (isVerified != null) {
      query = query.where('isVerified', isEqualTo: isVerified);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<AppUser> users = snapshot.docs
          .map((doc) => AppUser.fromDocument(doc))
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        users = users.where((user) {
          return user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 user.email.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return users;
    });
  }

  /// Получить все события
  Stream<List<Event>> getAllEvents() {
    return _firestore
        .collection(_eventsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromDocument(doc)).toList();
    });
  }

  /// Получить все события с фильтрацией
  Stream<List<Event>> getEventsWithFilter({
    bool? isHidden,
    String? searchQuery,
  }) {
    Query query = _firestore.collection(_eventsCollection);

    if (isHidden != null) {
      query = query.where('isHidden', isEqualTo: isHidden);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Event> events = snapshot.docs
          .map((doc) => Event.fromDocument(doc))
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        events = events.where((event) {
          return event.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 event.description.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return events;
    });
  }

  /// Получить все бронирования
  Stream<List<Booking>> getAllBookings() {
    return _firestore
        .collection(_bookingsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList();
    });
  }

  /// Заблокировать пользователя (soft-ban)
  Future<void> banUser(String userId, String reason) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Banning user: $userId');

      await _firestore.collection(_usersCollection).doc(userId).update({
        'isBanned': true,
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAdminAction('ban_user', {
        'userId': userId,
        'reason': reason,
      });

      SafeLog.info('AdminService: User banned successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error banning user', e, stackTrace);
      rethrow;
    }
  }

  /// Разблокировать пользователя
  Future<void> unbanUser(String userId) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Unbanning user: $userId');

      await _firestore.collection(_usersCollection).doc(userId).update({
        'isBanned': false,
        'banReason': FieldValue.delete(),
        'bannedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAdminAction('unban_user', {
        'userId': userId,
      });

      SafeLog.info('AdminService: User unbanned successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error unbanning user', e, stackTrace);
      rethrow;
    }
  }

  /// Верифицировать пользователя
  Future<void> verifyUser(String userId) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Verifying user: $userId');

      await _firestore.collection(_usersCollection).doc(userId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAdminAction('verify_user', {
        'userId': userId,
      });

      SafeLog.info('AdminService: User verified successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error verifying user', e, stackTrace);
      rethrow;
    }
  }

  /// Скрыть событие (soft-hide)
  Future<void> hideEvent(String eventId, String reason) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Hiding event: $eventId');

      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'isHidden': true,
        'hideReason': reason,
        'hiddenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAdminAction('hide_event', {
        'eventId': eventId,
        'reason': reason,
      });

      SafeLog.info('AdminService: Event hidden successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error hiding event', e, stackTrace);
      rethrow;
    }
  }

  /// Показать событие
  Future<void> showEvent(String eventId) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Showing event: $eventId');

      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'isHidden': false,
        'hideReason': FieldValue.delete(),
        'hiddenAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAdminAction('show_event', {
        'eventId': eventId,
      });

      SafeLog.info('AdminService: Event shown successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error showing event', e, stackTrace);
      rethrow;
    }
  }

  /// Удалить событие
  Future<void> deleteEvent(String eventId) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Deleting event: $eventId');

      await _firestore.collection(_eventsCollection).doc(eventId).delete();

      await _logAdminAction('delete_event', {
        'eventId': eventId,
      });

      SafeLog.info('AdminService: Event deleted successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error deleting event', e, stackTrace);
      rethrow;
    }
  }

  /// Удалить пользователя
  Future<void> deleteUser(String userId) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Deleting user: $userId');

      // Удаляем пользователя
      await _firestore.collection(_usersCollection).doc(userId).delete();

      // Удаляем события пользователя
      final userEvents = await _firestore
          .collection(_eventsCollection)
          .where('organizerId', isEqualTo: userId)
          .get();

      for (final doc in userEvents.docs) {
        await doc.reference.delete();
      }

      // Удаляем бронирования пользователя
      final userBookings = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in userBookings.docs) {
        await doc.reference.delete();
      }

      await _logAdminAction('delete_user', {
        'userId': userId,
      });

      SafeLog.info('AdminService: User deleted successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error deleting user', e, stackTrace);
      rethrow;
    }
  }

  /// Получить статистику админ-панели
  Stream<Map<String, dynamic>> getAdminStats() {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      try {
        SafeLog.info('AdminService: Getting admin stats');

        // Получаем статистику пользователей
        final usersQuery = await _firestore.collection(_usersCollection).get();
        final totalUsers = usersQuery.docs.length;
        final activeUsers = usersQuery.docs
            .where((doc) => !(doc.data()['isBanned'] ?? false))
            .length;
        final bannedUsers = usersQuery.docs
            .where((doc) => doc.data()['isBanned'] ?? false)
            .length;
        final verifiedUsers = usersQuery.docs
            .where((doc) => doc.data()['isVerified'] ?? false)
            .length;

        // Получаем статистику событий
        final eventsQuery = await _firestore.collection(_eventsCollection).get();
        final totalEvents = eventsQuery.docs.length;
        final activeEvents = eventsQuery.docs
            .where((doc) => !(doc.data()['isHidden'] ?? false))
            .length;
        final hiddenEvents = eventsQuery.docs
            .where((doc) => doc.data()['isHidden'] ?? false)
            .length;

        // Получаем статистику бронирований
        final bookingsQuery = await _firestore.collection(_bookingsCollection).get();
        final totalBookings = bookingsQuery.docs.length;

        // Получаем статистику за неделю
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        final newUsersThisWeek = usersQuery.docs
            .where((doc) {
              final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
              return createdAt.isAfter(weekAgo);
            })
            .length;

        final newEventsThisWeek = eventsQuery.docs
            .where((doc) {
              final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
              return createdAt.isAfter(weekAgo);
            })
            .length;

        final stats = {
          'totalUsers': totalUsers,
          'activeUsers': activeUsers,
          'bannedUsers': bannedUsers,
          'verifiedUsers': verifiedUsers,
          'totalEvents': totalEvents,
          'activeEvents': activeEvents,
          'hiddenEvents': hiddenEvents,
          'totalBookings': totalBookings,
          'newUsersThisWeek': newUsersThisWeek,
          'newEventsThisWeek': newEventsThisWeek,
          'completedEvents': 0, // TODO: Implement completed events logic
        };

        SafeLog.info('AdminService: Admin stats calculated');

        return stats;
      } catch (e, stackTrace) {
        SafeLog.error('AdminService: Error getting admin stats', e, stackTrace);
        return {};
      }
    });
  }

  /// Получить логи админ-действий
  Stream<List<Map<String, dynamic>>> getAdminLogs({int limit = 100}) {
    return _firestore
        .collection(_adminLogsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Логировать админ-действие
  Future<void> _logAdminAction(String action, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_adminLogsCollection).add({
        'action': action,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error logging admin action', e, stackTrace);
    }
  }

  /// Получить пользователя по ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        return AppUser.fromDocument(doc);
      }
      return null;
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error getting user by ID', e, stackTrace);
      return null;
    }
  }

  /// Получить событие по ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      if (doc.exists) {
        return Event.fromDocument(doc);
      }
      return null;
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error getting event by ID', e, stackTrace);
      return null;
    }
  }

  /// Получить бронирование по ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromDocument(doc);
      }
      return null;
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error getting booking by ID', e, stackTrace);
      return null;
    }
  }

  /// Проверить, является ли пользователь админом
  Future<bool> isUserAdmin(String userId) async {
    try {
      final user = await getUserById(userId);
      return user?.role == UserRole.admin;
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error checking admin status', e, stackTrace);
      return false;
    }
  }

  /// Получить настройки админ-панели
  Future<Map<String, dynamic>> getAdminSettings() async {
    try {
      final doc = await _firestore.collection('admin_settings').doc('main').get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error getting admin settings', e, stackTrace);
      return {};
    }
  }

  /// Обновить настройки админ-панели
  Future<void> updateAdminSettings(Map<String, dynamic> settings) async {
    if (!FeatureFlags.adminPanelEnabled) {
      throw Exception('Админ-панель отключена');
    }

    try {
      SafeLog.info('AdminService: Updating admin settings');

      await _firestore.collection('admin_settings').doc('main').set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _logAdminAction('update_settings', {
        'settings': settings,
      });

      SafeLog.info('AdminService: Admin settings updated successfully');
    } catch (e, stackTrace) {
      SafeLog.error('AdminService: Error updating admin settings', e, stackTrace);
      rethrow;
    }
  }
}
