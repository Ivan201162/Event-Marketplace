import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';

/// Сервис для работы с админ-панелью
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить всех пользователей
  Future<List<ManagedUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map(ManagedUser.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения пользователей: $e');
    }
  }

  /// Получить всех пользователей с пагинацией
  Future<List<ManagedUser>> getUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
    UserStatus? statusFilter,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(ManagedUser.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения пользователей: $e');
    }
  }

  /// Обновить статус пользователя
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления статуса: $e');
    }
  }

  /// Заблокировать пользователя
  Future<void> banUser(String userId, String reason) async {
    await updateUserStatus(userId, UserStatus.suspended);
  }

  /// Разблокировать пользователя
  Future<void> unbanUser(String userId) async {
    await updateUserStatus(userId, UserStatus.active);
  }

  /// Получить статистику пользователей
  Future<Map<String, int>> getUserStats() async {
    try {
      final stats = <String, int>{};

      final totalUsers = await _firestore.collection('users').count().get();
      stats['total'] = totalUsers.count ?? 0;

      for (final status in UserStatus.values) {
        final count = await _firestore
            .collection('users')
            .where('status', isEqualTo: status.name)
            .count()
            .get();
        stats[status.name] = count.count ?? 0;
      }

      return stats;
    } catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Получить все события
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения событий: $e');
    }
  }

  /// Получить все бронирования
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения бронирований: $e');
    }
  }

  /// Получить пользователей с фильтром
  Future<List<ManagedUser>> getUsersWithFilter({
    UserStatus? status,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      var users = snapshot.docs.map(ManagedUser.fromDocument).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        users = users
            .where((user) =>
                user.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                user.email.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      return users;
    } catch (e) {
      throw Exception('Ошибка получения пользователей с фильтром: $e');
    }
  }

  /// Получить события с фильтром
  Future<List<Map<String, dynamic>>> getEventsWithFilter({
    String? status,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection('events')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      var events = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        events = events
            .where((event) =>
                event['title']
                        ?.toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()) ==
                    true ||
                event['description']
                        ?.toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()) ==
                    true)
            .toList();
      }

      return events;
    } catch (e) {
      throw Exception('Ошибка получения событий с фильтром: $e');
    }
  }

  /// Получить статистику админ-панели
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final stats = <String, dynamic>{};

      // Статистика пользователей
      final userStats = await getUserStats();
      stats['users'] = userStats;

      // Статистика событий
      final eventCount = await _firestore.collection('events').count().get();
      stats['totalEvents'] = eventCount.count ?? 0;

      // Статистика бронирований
      final bookingCount =
          await _firestore.collection('bookings').count().get();
      stats['totalBookings'] = bookingCount.count ?? 0;

      return stats;
    } catch (e) {
      throw Exception('Ошибка получения статистики админ-панели: $e');
    }
  }

  /// Получить логи админ-панели
  Future<List<Map<String, dynamic>>> getAdminLogs({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения логов: $e');
    }
  }

  /// Получить пользователя по ID
  Future<ManagedUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return ManagedUser.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения пользователя: $e');
    }
  }

  /// Получить событие по ID
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения события: $e');
    }
  }

  /// Получить бронирование по ID
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения бронирования: $e');
    }
  }

  /// Проверить, является ли пользователь админом
  Future<bool> isUserAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin' || data['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Ошибка проверки прав админа: $e');
    }
  }

  /// Получить настройки админ-панели
  Future<Map<String, dynamic>> getAdminSettings() async {
    try {
      final doc =
          await _firestore.collection('admin_settings').doc('main').get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      throw Exception('Ошибка получения настроек: $e');
    }
  }

  /// Верифицировать пользователя
  Future<void> verifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка верификации пользователя: $e');
    }
  }

  /// Скрыть событие
  Future<void> hideEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'isHidden': true,
        'hiddenAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка скрытия события: $e');
    }
  }

  /// Показать событие
  Future<void> showEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'isHidden': false,
        'shownAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка показа события: $e');
    }
  }

  /// Удалить событие
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления события: $e');
    }
  }
}
