import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
// import '../models/user.dart';
import '../models/booking.dart';
// import '../models/review.dart';

/// Сервис для управления бейджами и достижениями
class BadgeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить все бейджи пользователя
  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final querySnapshot = await _db
          .collection('badges')
          .where('userId', isEqualTo: userId)
          .orderBy('earnedAt', descending: true)
          .get();

      return querySnapshot.docs.map(Badge.fromDocument).toList();
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }

  /// Проверить и выдать бейджи после создания бронирования
  Future<void> checkBookingBadges(
    String customerId,
    String specialistId,
  ) async {
    try {
      // Проверяем бейджи для заказчика
      await _checkCustomerBookingBadges(customerId);

      // Проверяем бейджи для специалиста
      await _checkSpecialistBookingBadges(specialistId);
    } catch (e) {
      print('Error checking booking badges: $e');
    }
  }

  /// Проверить и выдать бейджи после создания отзыва
  Future<void> checkReviewBadges(
    String customerId,
    String specialistId,
    int rating,
  ) async {
    try {
      // Проверяем бейджи для заказчика
      await _checkCustomerReviewBadges(customerId);

      // Проверяем бейджи для специалиста
      await _checkSpecialistReviewBadges(specialistId, rating);
    } catch (e) {
      print('Error checking review badges: $e');
    }
  }

  /// Проверить бейджи заказчика после бронирования
  Future<void> _checkCustomerBookingBadges(String customerId) async {
    // Получаем количество бронирований заказчика
    final bookingsSnapshot =
        await _db.collection('bookings').where('customerId', isEqualTo: customerId).get();

    final bookingCount = bookingsSnapshot.docs.length;

    // Проверяем бейджи
    if (bookingCount == 1) {
      await _awardBadge(customerId, BadgeType.firstEvent);
    } else if (bookingCount == 5) {
      await _awardBadge(customerId, BadgeType.eventOrganizer);
    } else if (bookingCount >= 10) {
      await _awardBadge(customerId, BadgeType.regularCustomer);
    }

    // Проверяем бейдж "Ранняя пташка" (бронирование за месяц)
    final recentBookings = bookingsSnapshot.docs.map(Booking.fromDocument).where((booking) {
      final daysUntilEvent = booking.eventDate.difference(DateTime.now()).inDays;
      return daysUntilEvent >= 30;
    }).length;

    if (recentBookings >= 3) {
      await _awardBadge(customerId, BadgeType.earlyBird);
    }
  }

  /// Проверить бейджи специалиста после бронирования
  Future<void> _checkSpecialistBookingBadges(String specialistId) async {
    // Получаем количество успешных бронирований специалиста
    final bookingsSnapshot = await _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: 'completed')
        .get();

    final completedBookings = bookingsSnapshot.docs.length;

    // Проверяем бейджи
    if (completedBookings == 1) {
      await _awardBadge(specialistId, BadgeType.firstBooking);
    } else if (completedBookings == 10) {
      await _awardBadge(specialistId, BadgeType.tenBookings);
    } else if (completedBookings == 50) {
      await _awardBadge(specialistId, BadgeType.fiftyBookings);
    } else if (completedBookings == 100) {
      await _awardBadge(specialistId, BadgeType.hundredBookings);
    }

    // Проверяем бейдж "Популярный специалист"
    final uniqueCustomers =
        bookingsSnapshot.docs.map((doc) => doc.data()['customerId'] as String).toSet().length;

    if (uniqueCustomers >= 20) {
      await _awardBadge(specialistId, BadgeType.popularSpecialist);
    }
  }

  /// Проверить бейджи заказчика после отзыва
  Future<void> _checkCustomerReviewBadges(String customerId) async {
    // Получаем количество отзывов заказчика
    final reviewsSnapshot =
        await _db.collection('reviews').where('customerId', isEqualTo: customerId).get();

    final reviewCount = reviewsSnapshot.docs.length;

    // Проверяем бейдж "Активный рецензент"
    if (reviewCount >= 5) {
      await _awardBadge(customerId, BadgeType.reviewWriter);
    }
  }

  /// Проверить бейджи специалиста после отзыва
  Future<void> _checkSpecialistReviewBadges(
    String specialistId,
    int rating,
  ) async {
    // Получаем средний рейтинг специалиста
    final reviewsSnapshot =
        await _db.collection('reviews').where('specialistId', isEqualTo: specialistId).get();

    if (reviewsSnapshot.docs.isEmpty) return;

    final totalRating =
        reviewsSnapshot.docs.map((doc) => doc.data()['rating'] as int).reduce((a, b) => a + b);

    final averageRating = totalRating / reviewsSnapshot.docs.length;

    // Проверяем бейджи рейтинга
    if (averageRating >= 4.8 && reviewsSnapshot.docs.length >= 10) {
      await _awardBadge(specialistId, BadgeType.fiveStarRating);
    }

    // Проверяем бейдж "Мастер качества"
    final excellentReviews = reviewsSnapshot.docs.where((doc) => doc.data()['rating'] == 5).length;

    if (excellentReviews >= reviewsSnapshot.docs.length * 0.9 &&
        reviewsSnapshot.docs.length >= 20) {
      await _awardBadge(specialistId, BadgeType.qualityMaster);
    }

    // Проверяем бейдж "Любимец клиентов" (повторные заказы)
    final repeatCustomers = await _getRepeatCustomers(specialistId);
    if (repeatCustomers >= 10) {
      await _awardBadge(specialistId, BadgeType.customerFavorite);
    }
  }

  /// Получить количество повторных клиентов
  Future<int> _getRepeatCustomers(String specialistId) async {
    final bookingsSnapshot =
        await _db.collection('bookings').where('specialistId', isEqualTo: specialistId).get();

    final customerBookings = <String, int>{};

    for (final doc in bookingsSnapshot.docs) {
      final customerId = doc.data()['customerId'] as String;
      customerBookings[customerId] = (customerBookings[customerId] ?? 0) + 1;
    }

    return customerBookings.values.where((bookingCount) => bookingCount > 1).length;
  }

  /// Выдать бейдж пользователю
  Future<void> _awardBadge(String userId, BadgeType badgeType) async {
    try {
      // Проверяем, есть ли уже такой бейдж
      final existingBadge = await _db
          .collection('badges')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: badgeType.name)
          .get();

      if (existingBadge.docs.isNotEmpty) {
        return; // Бейдж уже есть
      }

      // Создаём новый бейдж
      final badgeInfo = badgeType.info;
      final badge = Badge(
        id: '', // Будет установлен Firestore
        userId: userId,
        type: badgeType,
        title: badgeInfo.title,
        description: badgeInfo.description,
        icon: badgeInfo.icon,
        color: badgeInfo.color,
        earnedAt: DateTime.now(),
        metadata: {},
      );

      await _db.collection('badges').add(badge.toMap());

      print('Badge awarded: ${badgeType.name} to user $userId');
    } catch (e) {
      print('Error awarding badge: $e');
    }
  }

  /// Получить статистику бейджей пользователя
  Future<BadgeStats> getBadgeStats(String userId) async {
    try {
      final badges = await getUserBadges(userId);

      return BadgeStats(
        totalBadges: badges.length,
        earnedBadges: badges.length,
        availableBadges: 0, // await getAvailableBadges().then((available) => available.length),
        badgesByCategory: {
          BadgeCategory.specialist: badges.byCategory(BadgeCategory.specialist).length,
          BadgeCategory.customer: badges.byCategory(BadgeCategory.customer).length,
          BadgeCategory.general: badges.byCategory(BadgeCategory.general).length,
        },
        specialistBadges: badges.byCategory(BadgeCategory.specialist).length,
        customerBadges: badges.byCategory(BadgeCategory.customer).length,
        generalBadges: badges.byCategory(BadgeCategory.general).length,
        recentBadges: badges.recent.take(5).toList(),
      );
    } catch (e) {
      print('Error getting badge stats: $e');
      return BadgeStats.empty;
    }
  }

  /// Получить топ пользователей по бейджам
  Future<List<BadgeLeaderboardEntry>> getBadgeLeaderboard({
    int limit = 10,
  }) async {
    try {
      // Получаем всех пользователей с бейджами
      final badgesSnapshot = await _db.collection('badges').get();

      final userBadgeCounts = <String, int>{};

      for (final doc in badgesSnapshot.docs) {
        final userId = doc.data()['userId'] as String;
        userBadgeCounts[userId] = (userBadgeCounts[userId] ?? 0) + 1;
      }

      // Сортируем по количеству бейджей
      final sortedUsers = userBadgeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Получаем информацию о пользователях
      final leaderboard = <BadgeLeaderboardEntry>[];

      for (final entry in sortedUsers.take(limit)) {
        try {
          final userDoc = await _db.collection('users').doc(entry.key).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            leaderboard.add(
              BadgeLeaderboardEntry(
                userId: entry.key,
                userName: userData?['name'] as String? ?? 'Пользователь',
                userAvatar: userData?['avatarUrl'] as String?,
                badgeCount: entry.value,
                rank: leaderboard.length + 1,
                recentBadges: [],
              ),
            );
          }
        } catch (e) {
          print('Error getting user info for leaderboard: $e');
        }
      }

      return leaderboard;
    } catch (e) {
      print('Error getting badge leaderboard: $e');
      return [];
    }
  }

  /// Скрыть/показать бейдж
  Future<void> toggleBadgeVisibility(String badgeId, bool isVisible) async {
    try {
      await _db.collection('badges').doc(badgeId).update({
        'isVisible': isVisible,
      });
    } catch (e) {
      print('Error toggling badge visibility: $e');
    }
  }
}
