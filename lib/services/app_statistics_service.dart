import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/booking.dart';
import '../models/specialist.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../models/payment.dart';
import 'firebase_analytics_service.dart';

/// Сервис для сбора и анализа статистики приложения
class AppStatisticsService {
  factory AppStatisticsService() => _instance;
  AppStatisticsService._internal();
  static final AppStatisticsService _instance = AppStatisticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalyticsService _analytics = FirebaseAnalyticsService();

  /// Сбор общей статистики приложения
  Future<Map<String, dynamic>> getAppStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month - 1);
      final end = endDate ?? now;

      AppLogger.logI('Сбор статистики с $start по $end', 'app_statistics_service');

      // Параллельный сбор различных метрик
      final results = await Future.wait([
        _getUserStatistics(start, end),
        _getSpecialistStatistics(start, end),
        _getBookingStatistics(start, end),
        _getPaymentStatistics(start, end),
        _getReviewStatistics(start, end),
        _getRevenueStatistics(start, end),
        _getCategoryStatistics(start, end),
        _getLocationStatistics(start, end),
      ]);

      final statistics = <String, dynamic>{
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'users': results[0],
        'specialists': results[1],
        'bookings': results[2],
        'payments': results[3],
        'reviews': results[4],
        'revenue': results[5],
        'categories': results[6],
        'locations': results[7],
        'generated_at': now.toIso8601String(),
      };

      // Отправка статистики в Firebase Analytics
      await _analytics.logEvent(
        name: 'app_statistics_generated',
        parameters: {
          'period_days': end.difference(start).inDays,
          'total_users': statistics['users']['total'],
          'total_specialists': statistics['specialists']['total'],
          'total_bookings': statistics['bookings']['total'],
          'total_revenue': statistics['revenue']['total'],
        },
      );

      AppLogger.logI('Статистика собрана успешно', 'app_statistics_service');
      return statistics;
    } catch (e) {
      AppLogger.logE('Ошибка сбора статистики: $e', 'app_statistics_service');
      rethrow;
    }
  }

  /// Статистика пользователей
  Future<Map<String, dynamic>> _getUserStatistics(DateTime start, DateTime end) async {
    final usersQuery = _firestore
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final usersSnapshot = await usersQuery.get();
    final users = usersSnapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();

    final totalUsers = users.length;
    final newUsers = users.where((user) => user.createdAt.isAfter(start)).length;
    final activeUsers = users.where((user) => user.lastLoginAt?.isAfter(start) ?? false).length;

    // Группировка по типам пользователей
    final userTypes = <String, int>{};
    for (final user in users) {
      final type = user.role.name;
      userTypes[type] = (userTypes[type] ?? 0) + 1;
    }

    return {
      'total': totalUsers,
      'new': newUsers,
      'active': activeUsers,
      'types': userTypes,
      'retention_rate': totalUsers > 0 ? (activeUsers / totalUsers * 100).toStringAsFixed(2) : '0.00',
    };
  }

  /// Статистика специалистов
  Future<Map<String, dynamic>> _getSpecialistStatistics(DateTime start, DateTime end) async {
    final specialistsQuery = _firestore
        .collection('specialists')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final specialistsSnapshot = await specialistsQuery.get();
    final specialists = specialistsSnapshot.docs.map((doc) => Specialist.fromMap(doc.data())).toList();

    final totalSpecialists = specialists.length;
    final newSpecialists = specialists.where((s) => s.createdAt.isAfter(start)).length;
    final activeSpecialists = specialists.where((s) => s.isAvailable).length;

    // Группировка по категориям
    final categories = <String, int>{};
    for (final specialist in specialists) {
      for (final category in specialist.categories) {
        categories[category.name] = (categories[category.name] ?? 0) + 1;
      }
    }

    // Группировка по уровням опыта
    final experienceLevels = <String, int>{};
    for (final specialist in specialists) {
      final level = specialist.experienceLevel.name;
      experienceLevels[level] = (experienceLevels[level] ?? 0) + 1;
    }

    return {
      'total': totalSpecialists,
      'new': newSpecialists,
      'active': activeSpecialists,
      'categories': categories,
      'experience_levels': experienceLevels,
      'active_rate': totalSpecialists > 0 ? (activeSpecialists / totalSpecialists * 100).toStringAsFixed(2) : '0.00',
    };
  }

  /// Статистика заявок
  Future<Map<String, dynamic>> _getBookingStatistics(DateTime start, DateTime end) async {
    final bookingsQuery = _firestore
        .collection('bookings')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final bookingsSnapshot = await bookingsQuery.get();
    final bookings = bookingsSnapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();

    final totalBookings = bookings.length;
    final pendingBookings = bookings.where((b) => b.status == BookingStatus.pending).length;
    final acceptedBookings = bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final completedBookings = bookings.where((b) => b.status == BookingStatus.completed).length;
    final cancelledBookings = bookings.where((b) => b.status == BookingStatus.cancelled).length;

    // Группировка по сервисам
    final services = <String, int>{};
    for (final booking in bookings) {
      final serviceId = booking.serviceId ?? 'unknown';
      services[serviceId] = (services[serviceId] ?? 0) + 1;
    }

    // Группировка по статусам
    final statuses = <String, int>{
      'pending': pendingBookings,
      'confirmed': acceptedBookings,
      'completed': completedBookings,
      'cancelled': cancelledBookings,
    };

    return {
      'total': totalBookings,
      'statuses': statuses,
      'services': services,
      'completion_rate': totalBookings > 0 ? (completedBookings / totalBookings * 100).toStringAsFixed(2) : '0.00',
      'cancellation_rate': totalBookings > 0 ? (cancelledBookings / totalBookings * 100).toStringAsFixed(2) : '0.00',
    };
  }

  /// Статистика платежей
  Future<Map<String, dynamic>> _getPaymentStatistics(DateTime start, DateTime end) async {
    final paymentsQuery = _firestore
        .collection('payments')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final paymentsSnapshot = await paymentsQuery.get();
    final payments = paymentsSnapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList();

    final totalPayments = payments.length;
    final successfulPayments = payments.where((p) => p.status == PaymentStatus.completed).length;
    final failedPayments = payments.where((p) => p.status == PaymentStatus.failed).length;
    final pendingPayments = payments.where((p) => p.status == PaymentStatus.pending).length;

    // Группировка по методам оплаты
    final methods = <String, int>{};
    for (final payment in payments) {
      final method = payment.paymentMethod ?? 'unknown';
      methods[method] = (methods[method] ?? 0) + 1;
    }

    // Группировка по статусам
    final statuses = <String, int>{
      'completed': successfulPayments,
      'failed': failedPayments,
      'pending': pendingPayments,
    };

    return {
      'total': totalPayments,
      'statuses': statuses,
      'methods': methods,
      'success_rate': totalPayments > 0 ? (successfulPayments / totalPayments * 100).toStringAsFixed(2) : '0.00',
    };
  }

  /// Статистика отзывов
  Future<Map<String, dynamic>> _getReviewStatistics(DateTime start, DateTime end) async {
    final reviewsQuery = _firestore
        .collection('reviews')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final reviewsSnapshot = await reviewsQuery.get();
    final reviews = reviewsSnapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();

    final totalReviews = reviews.length;
    final averageRating = reviews.isNotEmpty 
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length 
        : 0.0;

    // Распределение по рейтингам
    final ratingDistribution = <int, int>{};
    for (final review in reviews) {
      final rating = review.rating.round();
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
    }

    return {
      'total': totalReviews,
      'average_rating': averageRating.toStringAsFixed(2),
      'rating_distribution': ratingDistribution,
    };
  }

  /// Статистика доходов
  Future<Map<String, dynamic>> _getRevenueStatistics(DateTime start, DateTime end) async {
    final paymentsQuery = _firestore
        .collection('payments')
        .where('status', isEqualTo: PaymentStatus.completed.name)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final paymentsSnapshot = await paymentsQuery.get();
    final payments = paymentsSnapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList();

    final totalRevenue = payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
    final averagePayment = payments.isNotEmpty ? totalRevenue / payments.length : 0.0;

    // Доходы по месяцам
    final monthlyRevenue = <String, double>{};
    for (final payment in payments) {
      final month = '${payment.createdAt.year}-${payment.createdAt.month.toString().padLeft(2, '0')}';
      monthlyRevenue[month] = (monthlyRevenue[month] ?? 0.0) + payment.amount;
    }

    return {
      'total': totalRevenue,
      'average_payment': averagePayment,
      'monthly_revenue': monthlyRevenue,
      'payment_count': payments.length,
    };
  }

  /// Статистика по категориям
  Future<Map<String, dynamic>> _getCategoryStatistics(DateTime start, DateTime end) async {
    final bookingsQuery = _firestore
        .collection('bookings')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final bookingsSnapshot = await bookingsQuery.get();
    final bookings = bookingsSnapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();

    final categoryStats = <String, Map<String, dynamic>>{};
    
    for (final booking in bookings) {
      final serviceId = booking.serviceId ?? 'unknown';
      if (!categoryStats.containsKey(serviceId)) {
        categoryStats[serviceId] = {
          'bookings': 0,
          'revenue': 0.0,
          'average_rating': 0.0,
          'completion_rate': 0.0,
        };
      }
      
      final stats = categoryStats[serviceId]!;
      stats['bookings'] = (stats['bookings'] as int) + 1;
      
      // Добавляем доход если заявка завершена
      if (booking.status == BookingStatus.completed) {
        stats['revenue'] = (stats['revenue'] as double) + booking.totalPrice;
      }
    }

    // Вычисляем средние значения
    for (final category in categoryStats.keys) {
      final stats = categoryStats[category]!;
      final bookingsCount = stats['bookings'] as int;
      final revenue = stats['revenue'] as double;
      
      stats['average_revenue'] = bookingsCount > 0 ? revenue / bookingsCount : 0.0;
    }

    return categoryStats;
  }

  /// Статистика по локациям
  Future<Map<String, dynamic>> _getLocationStatistics(DateTime start, DateTime end) async {
    final usersQuery = _firestore
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    final usersSnapshot = await usersQuery.get();
    final users = usersSnapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();

    final locationStats = <String, int>{};
    for (final user in users) {
      // Используем дополнительную информацию о локации если есть
      final location = user.additionalData?['location'] as String?;
      if (location != null && location.isNotEmpty) {
        locationStats[location] = (locationStats[location] ?? 0) + 1;
      }
    }

    return {
      'total_locations': locationStats.length,
      'distribution': locationStats,
      'top_locations': _getTopLocations(locationStats, 10),
    };
  }

  /// Получить топ локаций
  List<Map<String, dynamic>> _getTopLocations(Map<String, int> locations, int limit) {
    final sortedLocations = locations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedLocations.take(limit).map((entry) => {
      'location': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// Сбор статистики в реальном времени
  Future<void> collectRealTimeStatistics() async {
    try {
      final statistics = await getAppStatistics();
      
      // Сохранение в Firestore для быстрого доступа
      await _firestore.collection('statistics').doc('realtime').set({
        'data': statistics,
        'updated_at': FieldValue.serverTimestamp(),
      });

      AppLogger.logI('Статистика в реальном времени обновлена', 'app_statistics_service');
    } catch (e) {
      AppLogger.logE('Ошибка сбора статистики в реальном времени: $e', 'app_statistics_service');
    }
  }

  /// Получить статистику для дашборда
  Future<Map<String, dynamic>> getDashboardStatistics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = today.subtract(const Duration(days: 30));

      final results = await Future.wait([
        getAppStatistics(startDate: today, endDate: now),
        getAppStatistics(startDate: weekAgo, endDate: now),
        getAppStatistics(startDate: monthAgo, endDate: now),
      ]);

      return {
        'today': results[0],
        'week': results[1],
        'month': results[2],
        'generated_at': now.toIso8601String(),
      };
    } catch (e) {
      AppLogger.logE('Ошибка получения статистики дашборда: $e', 'app_statistics_service');
      rethrow;
    }
  }
}
