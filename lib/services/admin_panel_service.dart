import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_panel.dart';
import '../models/booking.dart';
import '../models/payment_extended.dart';
import '../models/review.dart';
import '../models/user.dart';

/// Сервис для админ-панели
class AdminPanelService {
  factory AdminPanelService() => _instance;
  AdminPanelService._internal();
  static final AdminPanelService _instance = AdminPanelService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Проверить, является ли пользователь администратором
  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists && (doc.data()?['isActive'] ?? false);
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Получить информацию об администраторе
  Future<AdminPanel?> getAdminInfo(String userId) async {
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      if (doc.exists) {
        return AdminPanel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      // TODO(developer): Log error properly
      return null;
    }
  }

  /// Проверить разрешение администратора
  Future<bool> hasPermission(String userId, AdminPermission permission) async {
    try {
      final adminInfo = await getAdminInfo(userId);
      if (adminInfo == null) return false;

      // Супер-администратор имеет все права
      if (adminInfo.role == AdminRole.superAdmin) return true;

      return adminInfo.permissions.contains(permission.name);
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Получить статистику
  Future<AdminStats> getStats() async {
    try {
      // Получаем данные параллельно
      final futures = await Future.wait([
        _firestore.collection('users').get(),
        _firestore.collection('specialists').get(),
        _firestore.collection('bookings').get(),
        _firestore.collection('payments').get(),
        _firestore.collection('reviews').get(),
      ]);

      final usersSnapshot = futures[0] as QuerySnapshot;
      final specialistsSnapshot = futures[1] as QuerySnapshot;
      final bookingsSnapshot = futures[2] as QuerySnapshot;
      final paymentsSnapshot = futures[3] as QuerySnapshot;
      final reviewsSnapshot = futures[4] as QuerySnapshot;

      // Подсчитываем статистику
      final totalUsers = usersSnapshot.docs.length;
      final totalSpecialists = specialistsSnapshot.docs.length;
      final totalBookings = bookingsSnapshot.docs.length;
      final totalPayments = paymentsSnapshot.docs.length;
      final totalReviews = reviewsSnapshot.docs.length;

      // Активные пользователи (за последние 30 дней)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeUsers = usersSnapshot.docs.where((doc) {
        final lastLogin =
            (doc.data()! as Map<String, dynamic>)['lastLogin'] as Timestamp?;
        return lastLogin != null && lastLogin.toDate().isAfter(thirtyDaysAgo);
      }).length;

      // Ожидающие бронирования
      final pendingBookings = bookingsSnapshot.docs.where((doc) {
        final status =
            (doc.data()! as Map<String, dynamic>)['status'] as String?;
        return status == 'pending';
      }).length;

      // Ожидающие отзывы (не модерированные)
      final pendingReviews = reviewsSnapshot.docs.where((doc) {
        final isModerated =
            (doc.data()! as Map<String, dynamic>)['isModerated'] as bool?;
        return isModerated != true;
      }).length;

      // Заблокированные пользователи
      final bannedUsers = usersSnapshot.docs.where((doc) {
        final isBanned =
            (doc.data()! as Map<String, dynamic>)['isBanned'] as bool?;
        return isBanned ?? false;
      }).length;

      // Общий доход
      var totalRevenue = 0;
      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'completed') {
          final paidAmount = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
          totalRevenue += paidAmount;
        }
      }

      return AdminStats(
        totalUsers: totalUsers,
        totalSpecialists: totalSpecialists,
        totalBookings: totalBookings,
        totalPayments: totalPayments,
        totalReviews: totalReviews,
        totalRevenue: totalRevenue,
        activeUsers: activeUsers,
        pendingBookings: pendingBookings,
        pendingReviews: pendingReviews,
        bannedUsers: bannedUsers,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // TODO(developer): Log error properly
      return AdminStats.empty();
    }
  }

  /// Получить всех пользователей
  Stream<List<AppUser>> getAllUsers() => _firestore
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(AppUser.fromDocument).toList());

  /// Получить всех специалистов
  Stream<List<AppUser>> getAllSpecialists() => _firestore
      .collection('users')
      .where('role', isEqualTo: 'specialist')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(AppUser.fromDocument).toList());

  /// Получить все бронирования
  Stream<List<Booking>> getAllBookings() => _firestore
      .collection('bookings')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Booking.fromDocument).toList());

  /// Получить все платежи
  Stream<List<PaymentExtended>> getAllPayments() => _firestore
      .collection('payments')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(PaymentExtended.fromDocument).toList(),
      );

  /// Получить все отзывы
  Stream<List<Review>> getAllReviews() => _firestore
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Review.fromDocument).toList());

  /// Заблокировать пользователя
  Future<bool> banUser(String userId, String adminId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'banReason': reason,
        'bannedAt': Timestamp.fromDate(DateTime.now()),
        'bannedBy': adminId,
      });

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.userBanned,
        targetId: userId,
        targetType: 'user',
        description: 'Пользователь заблокирован: $reason',
      );

      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Разблокировать пользователя
  Future<bool> unbanUser(String userId, String adminId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'banReason': null,
        'bannedAt': null,
        'bannedBy': null,
      });

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.userUnbanned,
        targetId: userId,
        targetType: 'user',
        description: 'Пользователь разблокирован',
      );

      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Верифицировать специалиста
  Future<bool> verifySpecialist(String specialistId, String adminId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'isVerified': true,
        'verifiedAt': Timestamp.fromDate(DateTime.now()),
        'verifiedBy': adminId,
      });

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.specialistVerified,
        targetId: specialistId,
        targetType: 'specialist',
        description: 'Специалист верифицирован',
      );

      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Отменить верификацию специалиста
  Future<bool> unverifySpecialist(
    String specialistId,
    String adminId,
    String reason,
  ) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'isVerified': false,
        'verifiedAt': null,
        'verifiedBy': null,
        'unverifyReason': reason,
      });

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.specialistUnverified,
        targetId: specialistId,
        targetType: 'specialist',
        description: 'Верификация специалиста отменена: $reason',
      );

      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Модерировать отзыв
  Future<bool> moderateReview(
    String reviewId,
    String adminId,
    bool approved,
    String? comment,
  ) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isModerated': true,
        'isApproved': approved,
        'moderatedAt': Timestamp.fromDate(DateTime.now()),
        'moderatedBy': adminId,
        'moderationComment': comment,
      });

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.reviewModerated,
        targetId: reviewId,
        targetType: 'review',
        description:
            'Отзыв ${approved ? 'одобрен' : 'отклонен'}: ${comment ?? 'без комментария'}',
      );

      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Отменить бронирование
  Future<bool> cancelBooking(
    String bookingId,
    String adminId,
    String reason,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'cancelledBy': adminId,
        'cancelReason': reason,
      });

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.bookingCancelled,
        targetId: bookingId,
        targetType: 'booking',
        description: 'Бронирование отменено: $reason',
      );

      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Получить действия администратора
  Stream<List<AdminAction>> getAdminActions({int limit = 100}) => _firestore
      .collection('admin_actions')
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(AdminAction.fromDocument).toList());

  /// Получить уведомления администратора
  Stream<List<AdminNotification>> getAdminNotifications() => _firestore
      .collection('admin_notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(AdminNotification.fromDocument).toList(),
      );

  /// Отметить уведомление как прочитанное
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Получить настройки админ-панели
  Future<AdminSettings> getAdminSettings() async {
    try {
      final doc =
          await _firestore.collection('admin_settings').doc('main').get();
      if (doc.exists) {
        return AdminSettings.fromMap(doc.data()!);
      }
      return AdminSettings(lastUpdated: DateTime.now());
    } catch (e) {
      // TODO(developer): Log error properly
      return AdminSettings(lastUpdated: DateTime.now());
    }
  }

  /// Обновить настройки админ-панели
  Future<bool> updateAdminSettings(
    AdminSettings settings,
    String adminId,
  ) async {
    try {
      final updatedSettings = settings.copyWith(lastUpdated: DateTime.now());
      await _firestore
          .collection('admin_settings')
          .doc('main')
          .set(updatedSettings.toMap());

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.settingsUpdated,
        targetId: 'main',
        targetType: 'settings',
        description: 'Настройки админ-панели обновлены',
      );

      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Создать уведомление для администратора
  Future<bool> createAdminNotification({
    required String title,
    required String message,
    required AdminNotificationType type,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = AdminNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        targetId: targetId,
        targetType: targetType,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('admin_notifications')
          .doc(notification.id)
          .set(notification.toMap());
      return true;
    } catch (e) {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// Логировать действие администратора
  Future<void> _logAdminAction({
    required String adminId,
    required AdminActionType type,
    required String targetId,
    required String targetType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final adminInfo = await getAdminInfo(adminId);
      final adminName = adminInfo?.adminName ?? 'Неизвестный';

      final action = AdminAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        adminId: adminId,
        adminName: adminName,
        type: type,
        targetId: targetId,
        targetType: targetType,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('admin_actions')
          .doc(action.id)
          .set(action.toMap());
    } catch (e) {
      // TODO(developer): Log error properly
    }
  }

  /// Экспортировать данные
  Future<Map<String, dynamic>> exportData({
    required String adminId,
    required List<String> collections,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final exportData = <String, dynamic>{};

      for (final collection in collections) {
        Query<Map<String, dynamic>> query = _firestore.collection(collection);

        if (startDate != null) {
          query = query.where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          );
        }

        if (endDate != null) {
          query = query.where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
        }

        final snapshot = await query.get();
        exportData[collection] =
            snapshot.docs.map((doc) => doc.data()).toList();
      }

      await _logAdminAction(
        adminId: adminId,
        type: AdminActionType.other,
        targetId: 'export',
        targetType: 'data',
        description: 'Экспорт данных: ${collections.join(', ')}',
        metadata: {
          'collections': collections,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      );

      return exportData;
    } catch (e) {
      // TODO(developer): Log error properly
      return {};
    }
  }
}
