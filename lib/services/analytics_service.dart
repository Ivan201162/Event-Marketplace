import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics.dart';
import '../models/booking.dart';
import '../models/review.dart';

/// Сервис для работы с аналитикой
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получает аналитику специалиста
  Future<SpecialistAnalytics?> getSpecialistAnalytics(String specialistId) async {
    try {
      final doc = await _firestore
          .collection('analytics')
          .doc(specialistId)
          .get();

      if (!doc.exists) {
        // Создаем аналитику если не существует
        await _createInitialAnalytics(specialistId);
        return await getSpecialistAnalytics(specialistId);
      }

      return SpecialistAnalytics.fromDocument(doc);
    } catch (e) {
      throw Exception('Ошибка получения аналитики: $e');
    }
  }

  /// Обновляет аналитику после завершения бронирования
  Future<void> updateAnalyticsAfterBooking(Booking booking) async {
    try {
      final specialistId = booking.specialistId;
      if (specialistId == null) return;

      await _updateBookingStats(specialistId, booking);
      await _updateMonthlyStats(specialistId, booking);
      await _updateServiceStats(specialistId, booking);
      await _updateRevenueStats(specialistId, booking);
      await _updateRatingStats(specialistId);
      
      // Обновляем время последнего обновления
      await _firestore.collection('analytics').doc(specialistId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка обновления аналитики: $e');
    }
  }

  /// Обновляет аналитику после создания отзыва
  Future<void> updateAnalyticsAfterReview(String specialistId) async {
    try {
      await _updateRatingStats(specialistId);
      
      await _firestore.collection('analytics').doc(specialistId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка обновления аналитики после отзыва: $e');
    }
  }

  /// Получает статистику по месяцам
  Future<List<MonthlyStat>> getMonthlyStats(String specialistId, {int months = 12}) async {
    try {
      final analytics = await getSpecialistAnalytics(specialistId);
      if (analytics == null) return [];

      final now = DateTime.now();
      final filteredStats = analytics.monthlyStats.where((stat) {
        final statDate = DateTime(stat.year, stat.month);
        final cutoffDate = DateTime(now.year, now.month - months);
        return statDate.isAfter(cutoffDate) || statDate.isAtSameMomentAs(cutoffDate);
      }).toList();

      filteredStats.sort((a, b) => 
        DateTime(a.year, a.month).compareTo(DateTime(b.year, b.month)));

      return filteredStats;
    } catch (e) {
      throw Exception('Ошибка получения месячной статистики: $e');
    }
  }

  /// Получает топ услуги
  Future<List<ServiceStat>> getTopServices(String specialistId, {int limit = 5}) async {
    try {
      final analytics = await getSpecialistAnalytics(specialistId);
      if (analytics == null) return [];

      final services = List<ServiceStat>.from(analytics.topServices);
      services.sort((a, b) => b.bookingCount.compareTo(a.bookingCount));

      return services.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка получения топ услуг: $e');
    }
  }

  /// Получает сравнение с предыдущим периодом
  Future<Map<String, double>> getComparisonWithPreviousPeriod(
    String specialistId, {
    int currentMonths = 3,
  }) async {
    try {
      final analytics = await getSpecialistAnalytics(specialistId);
      if (analytics == null) return {};

      final now = DateTime.now();
      
      // Текущий период
      final currentPeriodStart = DateTime(now.year, now.month - currentMonths + 1);
      final currentStats = analytics.monthlyStats.where((stat) {
        final statDate = DateTime(stat.year, stat.month);
        return statDate.isAfter(currentPeriodStart) || 
               statDate.isAtSameMomentAs(currentPeriodStart);
      }).toList();

      // Предыдущий период
      final previousPeriodStart = DateTime(now.year, now.month - currentMonths * 2 + 1);
      final previousPeriodEnd = DateTime(now.year, now.month - currentMonths);
      final previousStats = analytics.monthlyStats.where((stat) {
        final statDate = DateTime(stat.year, stat.month);
        return statDate.isAfter(previousPeriodStart) && 
               statDate.isBefore(previousPeriodEnd);
      }).toList();

      // Вычисляем изменения
      final currentBookings = currentStats.fold<int>(0, (sum, stat) => sum + stat.bookings);
      final previousBookings = previousStats.fold<int>(0, (sum, stat) => sum + stat.bookings);
      
      final currentRevenue = currentStats.fold<double>(0, (sum, stat) => sum + stat.revenue);
      final previousRevenue = previousStats.fold<double>(0, (sum, stat) => sum + stat.revenue);

      final currentRating = currentStats.isNotEmpty 
          ? currentStats.fold<double>(0, (sum, stat) => sum + stat.averageRating) / currentStats.length
          : 0.0;
      final previousRating = previousStats.isNotEmpty
          ? previousStats.fold<double>(0, (sum, stat) => sum + stat.averageRating) / previousStats.length
          : 0.0;

      return {
        'bookingsChange': _calculatePercentageChange(previousBookings.toDouble(), currentBookings.toDouble()),
        'revenueChange': _calculatePercentageChange(previousRevenue, currentRevenue),
        'ratingChange': _calculatePercentageChange(previousRating, currentRating),
      };
    } catch (e) {
      throw Exception('Ошибка получения сравнения: $e');
    }
  }

  /// Создает начальную аналитику для специалиста
  Future<void> _createInitialAnalytics(String specialistId) async {
    final analytics = SpecialistAnalytics(
      id: specialistId,
      specialistId: specialistId,
      totalBookings: 0,
      completedBookings: 0,
      cancelledBookings: 0,
      averageRating: 0.0,
      totalReviews: 0,
      totalRevenue: 0.0,
      averagePrice: 0.0,
      topServices: [],
      monthlyStats: [],
      lastUpdated: DateTime.now(),
    );

    await _firestore
        .collection('analytics')
        .doc(specialistId)
        .set(analytics.toMap());
  }

  /// Обновляет статистику бронирований
  Future<void> _updateBookingStats(String specialistId, Booking booking) async {
    final increment = booking.status == 'completed' ? {'completedBookings': FieldValue.increment(1)}
        : booking.status == 'cancelled' ? {'cancelledBookings': FieldValue.increment(1)}
        : <String, dynamic>{};

    await _firestore.collection('analytics').doc(specialistId).update({
      'totalBookings': FieldValue.increment(1),
      ...increment,
    });
  }

  /// Обновляет месячную статистику
  Future<void> _updateMonthlyStats(String specialistId, Booking booking) async {
    final analytics = await getSpecialistAnalytics(specialistId);
    if (analytics == null) return;

    final bookingDate = booking.eventDate;
    final existingStatIndex = analytics.monthlyStats.indexWhere(
      (stat) => stat.year == bookingDate.year && stat.month == bookingDate.month,
    );

    List<MonthlyStat> updatedStats = List.from(analytics.monthlyStats);
    
    if (existingStatIndex >= 0) {
      // Обновляем существующую статистику
      final existingStat = updatedStats[existingStatIndex];
      updatedStats[existingStatIndex] = MonthlyStat(
        year: existingStat.year,
        month: existingStat.month,
        bookings: existingStat.bookings + 1,
        revenue: existingStat.revenue + (booking.totalCost ?? 0.0),
        averageRating: existingStat.averageRating, // Обновится в _updateRatingStats
      );
    } else {
      // Создаем новую статистику
      updatedStats.add(MonthlyStat(
        year: bookingDate.year,
        month: bookingDate.month,
        bookings: 1,
        revenue: booking.totalCost ?? 0.0,
        averageRating: 0.0,
      ));
    }

    await _firestore.collection('analytics').doc(specialistId).update({
      'monthlyStats': updatedStats.map((s) => s.toMap()).toList(),
    });
  }

  /// Обновляет статистику услуг
  Future<void> _updateServiceStats(String specialistId, Booking booking) async {
    final analytics = await getSpecialistAnalytics(specialistId);
    if (analytics == null) return;

    final serviceName = booking.eventTitle ?? 'Услуга';
    final existingServiceIndex = analytics.topServices.indexWhere(
      (service) => service.serviceName == serviceName,
    );

    List<ServiceStat> updatedServices = List.from(analytics.topServices);
    
    if (existingServiceIndex >= 0) {
      // Обновляем существующую услугу
      final existingService = updatedServices[existingServiceIndex];
      updatedServices[existingServiceIndex] = ServiceStat(
        serviceName: existingService.serviceName,
        bookingCount: existingService.bookingCount + 1,
        revenue: existingService.revenue + (booking.totalCost ?? 0.0),
        averageRating: existingService.averageRating, // Обновится в _updateRatingStats
      );
    } else {
      // Добавляем новую услугу
      updatedServices.add(ServiceStat(
        serviceName: serviceName,
        bookingCount: 1,
        revenue: booking.totalCost ?? 0.0,
        averageRating: 0.0,
      ));
    }

    await _firestore.collection('analytics').doc(specialistId).update({
      'topServices': updatedServices.map((s) => s.toMap()).toList(),
    });
  }

  /// Обновляет статистику доходов
  Future<void> _updateRevenueStats(String specialistId, Booking booking) async {
    if (booking.status != 'completed') return;

    final revenue = booking.totalCost ?? 0.0;
    
    await _firestore.collection('analytics').doc(specialistId).update({
      'totalRevenue': FieldValue.increment(revenue),
    });

    // Пересчитываем средний чек
    final analytics = await getSpecialistAnalytics(specialistId);
    if (analytics != null && analytics.completedBookings > 0) {
      final averagePrice = analytics.totalRevenue / analytics.completedBookings;
      await _firestore.collection('analytics').doc(specialistId).update({
        'averagePrice': averagePrice,
      });
    }
  }

  /// Обновляет статистику рейтинга
  Future<void> _updateRatingStats(String specialistId) async {
    try {
      // Получаем все отзывы специалиста
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0.0;
      int reviewCount = 0;

      for (final doc in reviewsSnapshot.docs) {
        final review = Review.fromDocument(doc);
        totalRating += review.rating;
        reviewCount++;
      }

      final averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

      await _firestore.collection('analytics').doc(specialistId).update({
        'averageRating': averageRating,
        'totalReviews': reviewCount,
      });
    } catch (e) {
      print('Ошибка обновления статистики рейтинга: $e');
    }
  }

  /// Вычисляет процентное изменение
  double _calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return newValue > 0 ? 100.0 : 0.0;
    return ((newValue - oldValue) / oldValue) * 100;
  }
}