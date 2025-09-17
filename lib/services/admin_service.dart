import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';

/// Сервис для работы с админ-панелью
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить всех пользователей с пагинацией
  Future<List<ManagedUser>> getUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
    UserStatus? statusFilter,
  }) async {
    try {
      Query query = _firestore
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
      return snapshot.docs.map((doc) => ManagedUser.fromDocument(doc)).toList();
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
      stats['total'] = totalUsers.count;

      for (final status in UserStatus.values) {
        final count = await _firestore
            .collection('users')
            .where('status', isEqualTo: status.name)
            .count()
            .get();
        stats[status.name] = count.count;
      }

      return stats;
    } catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }
}
