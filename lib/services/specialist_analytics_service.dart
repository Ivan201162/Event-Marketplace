import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../models/review.dart';

/// Статистика доходов специалиста
class SpecialistIncomeStats {
  const SpecialistIncomeStats({
    required this.totalIncome,
    required this.monthlyIncome,
    required this.weeklyIncome,
    required this.averageBookingValue,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.completionRate,
    required this.incomeByMonth,
    required this.bookingsByMonth,
  });

  /// Создать из Map
  factory SpecialistIncomeStats.fromMap(Map<String, dynamic> data) =>
      SpecialistIncomeStats(
        totalIncome: (data['totalIncome'] as num?)?.toDouble() ?? 0.0,
        monthlyIncome: (data['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
        weeklyIncome: (data['weeklyIncome'] as num?)?.toDouble() ?? 0.0,
        averageBookingValue:
            (data['averageBookingValue'] as num?)?.toDouble() ?? 0.0,
        totalBookings: (data['totalBookings'] as int?) ?? 0,
        completedBookings: (data['completedBookings'] as int?) ?? 0,
        cancelledBookings: (data['cancelledBookings'] as int?) ?? 0,
        completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0.0,
        incomeByMonth: Map<String, double>.from(
          data['incomeByMonth'] as Map<String, dynamic>? ?? {},
        ),
        bookingsByMonth: Map<String, int>.from(
          data['bookingsByMonth'] as Map<String, dynamic>? ?? {},
        ),
      );
  final double totalIncome;
  final double monthlyIncome;
  final double weeklyIncome;
  final double averageBookingValue;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double completionRate;
  final Map<String, double> incomeByMonth;
  final Map<String, int> bookingsByMonth;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'totalIncome': totalIncome,
        'monthlyIncome': monthlyIncome,
        'weeklyIncome': weeklyIncome,
        'averageBookingValue': averageBookingValue,
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'completionRate': completionRate,
        'incomeByMonth': incomeByMonth,
        'bookingsByMonth': bookingsByMonth,
      };
}

/// Статистика отзывов специалиста
class SpecialistReviewStats {
  const SpecialistReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarReviews,
    required this.fourStarReviews,
    required this.threeStarReviews,
    required this.twoStarReviews,
    required this.oneStarReviews,
    required this.reviewsByMonth,
    required this.commonTags,
    required this.responseRate,
  });

  /// Создать из Map
  factory SpecialistReviewStats.fromMap(Map<String, dynamic> data) =>
      SpecialistReviewStats(
        averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
        totalReviews: (data['totalReviews'] as int?) ?? 0,
        fiveStarReviews: (data['fiveStarReviews'] as int?) ?? 0,
        fourStarReviews: (data['fourStarReviews'] as int?) ?? 0,
        threeStarReviews: (data['threeStarReviews'] as int?) ?? 0,
        twoStarReviews: (data['twoStarReviews'] as int?) ?? 0,
        oneStarReviews: (data['oneStarReviews'] as int?) ?? 0,
        reviewsByMonth: Map<String, int>.from(
          data['reviewsByMonth'] as Map<String, dynamic>? ?? {},
        ),
        commonTags:
            List<String>.from(data['commonTags'] as List<dynamic>? ?? []),
        responseRate: (data['responseRate'] as num?)?.toDouble() ?? 0.0,
      );
  final double averageRating;
  final int totalReviews;
  final int fiveStarReviews;
  final int fourStarReviews;
  final int threeStarReviews;
  final int twoStarReviews;
  final int oneStarReviews;
  final Map<String, int> reviewsByMonth;
  final List<String> commonTags;
  final double responseRate;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'fiveStarReviews': fiveStarReviews,
        'fourStarReviews': fourStarReviews,
        'threeStarReviews': threeStarReviews,
        'twoStarReviews': twoStarReviews,
        'oneStarReviews': oneStarReviews,
        'reviewsByMonth': reviewsByMonth,
        'commonTags': commonTags,
        'responseRate': responseRate,
      };
}

/// Общая аналитика специалиста
class SpecialistAnalytics {
  const SpecialistAnalytics({
    required this.specialistId,
    required this.incomeStats,
    required this.reviewStats,
    required this.lastUpdated,
    this.additionalMetrics = const {},
  });

  /// Создать из Map
  factory SpecialistAnalytics.fromMap(Map<String, dynamic> data) =>
      SpecialistAnalytics(
        specialistId: (data['specialistId'] as String?) ?? '',
        incomeStats: SpecialistIncomeStats.fromMap(
          data['incomeStats'] as Map<String, dynamic>? ?? {},
        ),
        reviewStats: SpecialistReviewStats.fromMap(
          data['reviewStats'] as Map<String, dynamic>? ?? {},
        ),
        lastUpdated:
            (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        additionalMetrics: Map<String, dynamic>.from(
          data['additionalMetrics'] as Map<String, dynamic>? ?? {},
        ),
      );
  final String specialistId;
  final SpecialistIncomeStats incomeStats;
  final SpecialistReviewStats reviewStats;
  final DateTime lastUpdated;
  final Map<String, dynamic> additionalMetrics;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'incomeStats': incomeStats.toMap(),
        'reviewStats': reviewStats.toMap(),
        'lastUpdated': Timestamp.fromDate(lastUpdated),
        'additionalMetrics': additionalMetrics,
      };
}

/// Сервис аналитики для специалистов
class SpecialistAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить аналитику специалиста
  Future<SpecialistAnalytics?> getSpecialistAnalytics(
    String specialistId,
  ) async {
    try {
      final doc = await _firestore
          .collection('specialist_analytics')
          .doc(specialistId)
          .get();

      if (!doc.exists) {
        // Создаем аналитику, если её нет
        return await _generateAnalytics(specialistId);
      }

      return SpecialistAnalytics.fromMap({
        'specialistId': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('Error getting specialist analytics: $e');
      return null;
    }
  }

  /// Сгенерировать аналитику для специалиста
  Future<SpecialistAnalytics> _generateAnalytics(String specialistId) async {
    try {
      // Получаем все бронирования специалиста
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final bookings = bookingsQuery.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .toList()
          .cast<Booking>();

      // Получаем все платежи специалиста
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final payments = paymentsQuery.docs
          .map((doc) => Payment.fromMap(doc.data()))
          .toList()
          .cast<Payment>();

      // Получаем все отзывы специалиста
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('targetId', isEqualTo: specialistId)
          .where('type', isEqualTo: 'specialist')
          .get();

      final reviews = reviewsQuery.docs
          .map((doc) => Review.fromMap(doc.data()))
          .toList()
          .cast<Review>();

      // Генерируем статистику доходов
      final incomeStats = _generateIncomeStats(bookings, payments);

      // Генерируем статистику отзывов
      final reviewStats = _generateReviewStats(reviews);

      final analytics = SpecialistAnalytics(
        specialistId: specialistId,
        incomeStats: incomeStats,
        reviewStats: reviewStats,
        lastUpdated: DateTime.now(),
      );

      // Сохраняем аналитику
      await _firestore
          .collection('specialist_analytics')
          .doc(specialistId)
          .set(analytics.toMap());

      return analytics;
    } catch (e) {
      debugPrint('Error generating analytics: $e');
      throw Exception('Ошибка генерации аналитики: $e');
    }
  }

  /// Генерировать статистику доходов
  SpecialistIncomeStats _generateIncomeStats(
    List<Booking> bookings,
    List<Payment> payments,
  ) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastWeek = now.subtract(const Duration(days: 7));

    // Общие показатели
    final totalIncome = payments
        .where((p) => p.status == PaymentStatus.completed)
        .fold(0, (sum, p) => sum + p.amount);

    final monthlyIncome = payments
        .where(
          (p) =>
              p.status == PaymentStatus.completed &&
              p.createdAt.isAfter(thisMonth),
        )
        .fold(0, (sum, p) => sum + p.amount);

    final weeklyIncome = payments
        .where(
          (p) =>
              p.status == PaymentStatus.completed &&
              p.createdAt.isAfter(lastWeek),
        )
        .fold(0, (sum, p) => sum + p.amount);

    final completedBookings =
        bookings.where((b) => b.status == BookingStatus.completed).length;

    final cancelledBookings =
        bookings.where((b) => b.status == BookingStatus.cancelled).length;

    final totalBookings = bookings.length;
    final completionRate =
        totalBookings > 0 ? completedBookings / totalBookings : 0.0;

    final averageBookingValue =
        completedBookings > 0 ? totalIncome / completedBookings : 0.0;

    // Доходы по месяцам
    final incomeByMonth = <String, double>{};
    final bookingsByMonth = <String, int>{};

    for (var i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';

      final monthIncome = payments
          .where(
            (p) =>
                p.status == PaymentStatus.completed &&
                p.createdAt.year == month.year &&
                p.createdAt.month == month.month,
          )
          .fold(0, (sum, p) => sum + p.amount);

      final monthBookings = bookings
          .where(
            (b) =>
                b.createdAt.year == month.year &&
                b.createdAt.month == month.month,
          )
          .length;

      incomeByMonth[monthKey] = monthIncome.toDouble();
      bookingsByMonth[monthKey] = monthBookings;
    }

    return SpecialistIncomeStats(
      totalIncome: totalIncome.toDouble(),
      monthlyIncome: monthlyIncome.toDouble(),
      weeklyIncome: weeklyIncome.toDouble(),
      averageBookingValue: averageBookingValue,
      totalBookings: totalBookings,
      completedBookings: completedBookings,
      cancelledBookings: cancelledBookings,
      completionRate: completionRate,
      incomeByMonth: incomeByMonth,
      bookingsByMonth: bookingsByMonth,
    );
  }

  /// Генерировать статистику отзывов
  SpecialistReviewStats _generateReviewStats(List<Review> reviews) {
    if (reviews.isEmpty) {
      return const SpecialistReviewStats(
        averageRating: 0,
        totalReviews: 0,
        fiveStarReviews: 0,
        fourStarReviews: 0,
        threeStarReviews: 0,
        twoStarReviews: 0,
        oneStarReviews: 0,
        reviewsByMonth: {},
        commonTags: [],
        responseRate: 0,
      );
    }

    final totalRating = reviews.fold(0, (sum, r) => sum + r.rating);
    final averageRating = totalRating / reviews.length;

    final fiveStar = reviews.where((r) => r.rating == 5).length;
    final fourStar = reviews.where((r) => r.rating == 4).length;
    final threeStar = reviews.where((r) => r.rating == 3).length;
    final twoStar = reviews.where((r) => r.rating == 2).length;
    final oneStar = reviews.where((r) => r.rating == 1).length;

    // Отзывы по месяцам
    final reviewsByMonth = <String, int>{};
    final now = DateTime.now();

    for (var i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';

      final monthReviews = reviews
          .where(
            (r) =>
                r.createdAt.year == month.year &&
                r.createdAt.month == month.month,
          )
          .length;

      reviewsByMonth[monthKey] = monthReviews;
    }

    // Популярные теги
    final tagCounts = <String, int>{};
    for (final review in reviews) {
      for (final tag in review.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final commonTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Процент ответов (заглушка)
    const responseRate = 0.85; // TODO(developer): Реальная логика

    return SpecialistReviewStats(
      averageRating: averageRating,
      totalReviews: reviews.length,
      fiveStarReviews: fiveStar,
      fourStarReviews: fourStar,
      threeStarReviews: threeStar,
      twoStarReviews: twoStar,
      oneStarReviews: oneStar,
      reviewsByMonth: reviewsByMonth,
      commonTags: commonTags.take(5).map((e) => e.key).toList(),
      responseRate: responseRate,
    );
  }

  /// Обновить аналитику специалиста
  Future<void> updateSpecialistAnalytics(String specialistId) async {
    try {
      final analytics = await _generateAnalytics(specialistId);
      await _firestore
          .collection('specialist_analytics')
          .doc(specialistId)
          .set(analytics.toMap());

      debugPrint('Updated analytics for specialist $specialistId');
    } catch (e) {
      debugPrint('Error updating specialist analytics: $e');
      throw Exception('Ошибка обновления аналитики: $e');
    }
  }

  /// Получить топ специалистов по доходу
  Future<List<Map<String, dynamic>>> getTopSpecialistsByIncome({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection('specialist_analytics')
          .orderBy('incomeStats.totalIncome', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('lastUpdated', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('lastUpdated', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => {
              'specialistId': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting top specialists: $e');
      return [];
    }
  }

  /// Получить топ специалистов по рейтингу
  Future<List<Map<String, dynamic>>> getTopSpecialistsByRating({
    int limit = 10,
    int minReviews = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_analytics')
          .where('reviewStats.totalReviews', isGreaterThanOrEqualTo: minReviews)
          .orderBy('reviewStats.totalReviews')
          .orderBy('reviewStats.averageRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'specialistId': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting top specialists by rating: $e');
      return [];
    }
  }

  /// Получить сравнительную аналитику
  Future<Map<String, dynamic>> getComparativeAnalytics(
    String specialistId,
  ) async {
    try {
      final specialistAnalytics = await getSpecialistAnalytics(specialistId);
      if (specialistAnalytics == null) {
        return {};
      }

      final topSpecialists = await getTopSpecialistsByIncome(limit: 100);
      final topByRating = await getTopSpecialistsByRating(limit: 100);

      // Вычисляем процентили
      final incomes = topSpecialists
          .map((s) => (s['incomeStats'] as Map)['totalIncome'] as double)
          .toList()
        ..sort();

      final ratings = topByRating
          .map((s) => (s['reviewStats'] as Map)['averageRating'] as double)
          .toList()
        ..sort();

      final specialistIncome = specialistAnalytics.incomeStats.totalIncome;
      final specialistRating = specialistAnalytics.reviewStats.averageRating;

      final incomePercentile = _calculatePercentile(incomes, specialistIncome);
      final ratingPercentile = _calculatePercentile(ratings, specialistRating);

      return {
        'incomePercentile': incomePercentile,
        'ratingPercentile': ratingPercentile,
        'totalSpecialists': topSpecialists.length,
        'averageIncome': incomes.isNotEmpty
            ? incomes.reduce((a, b) => a + b) / incomes.length
            : 0.0,
        'averageRating': ratings.isNotEmpty
            ? ratings.reduce((a, b) => a + b) / ratings.length
            : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting comparative analytics: $e');
      return {};
    }
  }

  /// Вычислить процентиль
  double _calculatePercentile(List<double> values, double target) {
    if (values.isEmpty) return 0;

    final sortedValues = List<double>.from(values)..sort();
    final index = sortedValues.indexWhere((v) => v >= target);

    if (index == -1) return 100;
    if (index == 0) return 0;

    return (index / sortedValues.length) * 100.0;
  }

  /// Получить статистику доходов по месяцам за последние 12 месяцев
  Future<Map<String, double>> getMonthlyIncomeStats(String specialistId) async {
    try {
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);

      // Получаем все завершенные платежи за последние 12 месяцев
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'completed')
          .where('type', whereIn: ['deposit', 'finalPayment'])
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo),
          )
          .orderBy('createdAt', descending: true)
          .get();

      final monthlyIncome = <String, double>{};

      for (final doc in paymentsSnapshot.docs) {
        final payment = Payment.fromDocument(doc);
        final monthKey =
            '${payment.createdAt.year}-${payment.createdAt.month.toString().padLeft(2, '0')}';
        monthlyIncome[monthKey] =
            (monthlyIncome[monthKey] ?? 0.0) + payment.amount;
      }

      return monthlyIncome;
    } catch (e) {
      debugPrint('Error getting monthly income stats: $e');
      return {};
    }
  }

  /// Получить статистику заказов по месяцам за последние 12 месяцев
  Future<Map<String, int>> getMonthlyBookingsStats(String specialistId) async {
    try {
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);

      // Получаем все завершенные бронирования за последние 12 месяцев
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'completed')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo),
          )
          .orderBy('createdAt', descending: true)
          .get();

      final monthlyBookings = <String, int>{};

      for (final doc in bookingsSnapshot.docs) {
        final booking = Booking.fromDocument(doc);
        final monthKey =
            '${booking.createdAt.year}-${booking.createdAt.month.toString().padLeft(2, '0')}';
        monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
      }

      return monthlyBookings;
    } catch (e) {
      debugPrint('Error getting monthly bookings stats: $e');
      return {};
    }
  }

  /// Получить статистику рейтинга по месяцам за последние 12 месяцев
  Future<Map<String, double>> getMonthlyRatingStats(String specialistId) async {
    try {
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);

      // Получаем все отзывы за последние 12 месяцев
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('isPublic', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(twelveMonthsAgo),
          )
          .orderBy('createdAt', descending: true)
          .get();

      final monthlyRatings = <String, List<double>>{};

      for (final doc in reviewsSnapshot.docs) {
        final review = Review.fromDocument(doc);
        final monthKey =
            '${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}';
        monthlyRatings[monthKey] = monthlyRatings[monthKey] ?? [];
        monthlyRatings[monthKey]!.add(review.rating);
      }

      // Вычисляем средний рейтинг для каждого месяца
      final monthlyAverageRating = <String, double>{};
      monthlyRatings.forEach((month, ratings) {
        if (ratings.isNotEmpty) {
          monthlyAverageRating[month] =
              ratings.reduce((a, b) => a + b) / ratings.length;
        }
      });

      return monthlyAverageRating;
    } catch (e) {
      debugPrint('Error getting monthly rating stats: $e');
      return {};
    }
  }
}
