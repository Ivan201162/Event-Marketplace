import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/booking.dart';
import '../models/specialist_analytics.dart';

/// Сервис аналитики для специалистов
class SpecialistAnalyticsService {
  factory SpecialistAnalyticsService() => _instance;
  SpecialistAnalyticsService._internal();
  static final SpecialistAnalyticsService _instance = SpecialistAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить аналитику для специалиста
  Future<SpecialistAnalytics> getSpecialistAnalytics({
    required String specialistId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.logI('Получение аналитики для специалиста $specialistId', 'specialist_analytics_service');
      
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month - 3); // Последние 3 месяца
      final end = endDate ?? now;

      // Получаем все данные параллельно
      final futures = await Future.wait([
        _getProfileViews(specialistId, start, end),
        _getBookings(specialistId, start, end),
        _getCompletedBookings(specialistId, start, end),
        _getCancelledBookings(specialistId, start, end),
        _getReviews(specialistId, start, end),
        _getRevenue(specialistId, start, end),
      ]);

      final profileViews = futures[0] as List<ProfileView>;
      final bookings = futures[1] as List<Booking>;
      final completedBookings = futures[2] as List<Booking>;
      final cancelledBookings = futures[3] as List<Booking>;
      final reviews = futures[4] as List<ReviewAnalytics>;
      final revenue = futures[5] as RevenueAnalytics;

      // Рассчитываем метрики
      final totalBookings = bookings.length;
      final completedCount = completedBookings.length;
      final cancelledCount = cancelledBookings.length;
      final conversionRate = totalBookings > 0 ? (completedCount / totalBookings) * 100 : 0.0;
      final averageCheck = completedCount > 0 ? revenue.totalRevenue / completedCount : 0.0;

      // Рассчитываем тренды
      final viewsTrend = _calculateTrend(profileViews.map((v) => v.count).toList());
      final bookingsTrend = _calculateTrend(bookings.map((b) => 1).toList());
      final revenueTrend = _calculateTrend(revenue.monthlyRevenue.values.map((v) => v.toInt()).toList());

      return SpecialistAnalytics(
        specialistId: specialistId,
        period: AnalyticsPeriod(
          startDate: start,
          endDate: end,
        ),
        profileViews: ProfileViewsAnalytics(
          total: profileViews.fold(0, (total, view) => total + view.count),
          unique: profileViews.length,
          trend: viewsTrend,
          dailyViews: profileViews,
        ),
        bookings: BookingsAnalytics(
          total: totalBookings,
          completed: completedCount,
          cancelled: cancelledCount,
          conversionRate: conversionRate,
          trend: bookingsTrend,
        ),
        revenue: RevenueAnalytics(
          totalRevenue: revenue.totalRevenue,
          averageCheck: averageCheck,
          trend: revenueTrend,
          monthlyRevenue: revenue.monthlyRevenue,
        ),
        reviews: ReviewsAnalytics(
          total: reviews.length,
          averageRating: reviews.isNotEmpty 
              ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length 
              : 0.0,
          recentReviews: reviews.take(5).toList(),
        ),
        performance: PerformanceMetrics(
          responseTime: _calculateAverageResponseTime(bookings),
          customerSatisfaction: reviews.isNotEmpty 
              ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length 
              : 0.0,
          repeatCustomers: _calculateRepeatCustomers(completedBookings),
        ),
      );
    } catch (e) {
      AppLogger.logE('Ошибка получения аналитики специалиста: $e', 'specialist_analytics_service');
      rethrow;
    }
  }

  /// Получить просмотры профиля
  Future<List<ProfileView>> _getProfileViews(String specialistId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .doc('profile_views')
          .collection(specialistId)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ProfileView(
          date: (data['date'] as Timestamp).toDate(),
          count: (data['count'] ?? 0) as int,
          source: (data['source'] ?? 'unknown') as String,
        );
      }).toList();
    } catch (e) {
      AppLogger.logE('Ошибка получения просмотров профиля: $e', 'specialist_analytics_service');
      return [];
    }
  }

  /// Получить заявки
  Future<List<Booking>> _getBookings(String specialistId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();

      return snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList();
    } catch (e) {
      AppLogger.logE('Ошибка получения заявок: $e', 'specialist_analytics_service');
      return [];
    }
  }

  /// Получить завершенные заявки
  Future<List<Booking>> _getCompletedBookings(String specialistId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .where('updatedAt', isGreaterThanOrEqualTo: start)
          .where('updatedAt', isLessThanOrEqualTo: end)
          .get();

      return snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList();
    } catch (e) {
      AppLogger.logE('Ошибка получения завершенных заявок: $e', 'specialist_analytics_service');
      return [];
    }
  }

  /// Получить отмененные заявки
  Future<List<Booking>> _getCancelledBookings(String specialistId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.cancelled.name)
          .where('updatedAt', isGreaterThanOrEqualTo: start)
          .where('updatedAt', isLessThanOrEqualTo: end)
          .get();

      return snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList();
    } catch (e) {
      AppLogger.logE('Ошибка получения отмененных заявок: $e', 'specialist_analytics_service');
      return [];
    }
  }

  /// Получить отзывы
  Future<List<ReviewAnalytics>> _getReviews(String specialistId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ReviewAnalytics(
          id: doc.id,
          rating: (data['rating']?.toDouble() ?? 0.0) as double,
          comment: (data['comment'] ?? '') as String,
          customerName: (data['customerName'] ?? '') as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      AppLogger.logE('Ошибка получения отзывов: $e', 'specialist_analytics_service');
      return [];
    }
  }

  /// Получить данные о доходах
  Future<RevenueAnalytics> _getRevenue(String specialistId, DateTime start, DateTime end) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'paid')
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();

      var totalRevenue = 0.0;
      final monthlyRevenue = <String, double>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = ((data['amount'] ?? 0.0) as num).toDouble();
        final date = (data['createdAt'] as Timestamp).toDate();
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        totalRevenue += amount;
        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + amount;
      }

      return RevenueAnalytics(
        totalRevenue: totalRevenue,
        averageCheck: 0.0, // Будет рассчитано в основном методе
        trend: 0.0, // Будет рассчитано в основном методе
        monthlyRevenue: monthlyRevenue,
      );
    } catch (e) {
      AppLogger.logE('Ошибка получения данных о доходах: $e', 'specialist_analytics_service');
      return const RevenueAnalytics(
        totalRevenue: 0.0,
        averageCheck: 0.0,
        trend: 0.0,
        monthlyRevenue: {},
      );
    }
  }

  /// Рассчитать тренд
  double _calculateTrend(List<int> values) {
    if (values.length < 2) {
      return 0.0;
    }
    
    final firstHalf = values.take(values.length ~/ 2).reduce((a, b) => a + b);
    final secondHalf = values.skip(values.length ~/ 2).reduce((a, b) => a + b);
    
    if (firstHalf == 0) {
      return secondHalf > 0 ? 100.0 : 0.0;
    }
    
    return ((secondHalf - firstHalf) / firstHalf) * 100;
  }

  /// Рассчитать среднее время ответа
  double _calculateAverageResponseTime(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return 0.0;
    }
    
    var totalResponseTime = 0.0;
    var validBookings = 0;
    
    for (final booking in bookings) {
      if (booking.updatedAt != null && booking.createdAt != null) {
        final responseTime = booking.updatedAt!.difference(booking.createdAt!).inHours.toDouble();
        totalResponseTime += responseTime;
        validBookings++;
      }
    }
    
    return validBookings > 0 ? totalResponseTime / validBookings : 0.0;
  }

  /// Рассчитать количество постоянных клиентов
  int _calculateRepeatCustomers(List<Booking> completedBookings) {
    final customerIds = completedBookings.map((b) => b.customerId).toSet();
    return customerIds.length;
  }

  /// Записать просмотр профиля
  Future<void> recordProfileView({
    required String specialistId,
    required String source,
  }) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('analytics')
          .doc('profile_views')
          .collection(specialistId)
          .doc(dateKey)
          .set({
        'date': Timestamp.fromDate(today),
        'count': FieldValue.increment(1),
        'source': source,
      }, SetOptions(merge: true));
      
      AppLogger.logI('Записан просмотр профиля для специалиста $specialistId', 'specialist_analytics_service');
    } catch (e) {
      AppLogger.logE('Ошибка записи просмотра профиля: $e', 'specialist_analytics_service');
    }
  }
}