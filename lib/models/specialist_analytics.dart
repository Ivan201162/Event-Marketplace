/// Аналитика специалиста
class SpecialistAnalytics {
  const SpecialistAnalytics({
    required this.specialistId,
    required this.period,
    required this.profileViews,
    required this.bookings,
    required this.revenue,
    required this.reviews,
    required this.performance,
  });

  final String specialistId;
  final AnalyticsPeriod period;
  final ProfileViewsAnalytics profileViews;
  final BookingsAnalytics bookings;
  final RevenueAnalytics revenue;
  final ReviewsAnalytics reviews;
  final PerformanceMetrics performance;
}

/// Период аналитики
class AnalyticsPeriod {
  const AnalyticsPeriod({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;
}

/// Аналитика просмотров профиля
class ProfileViewsAnalytics {
  const ProfileViewsAnalytics({
    required this.total,
    required this.unique,
    required this.trend,
    required this.dailyViews,
  });

  final int total;
  final int unique;
  final double trend;
  final List<ProfileView> dailyViews;
}

/// Просмотр профиля
class ProfileView {
  const ProfileView({
    required this.date,
    required this.count,
    required this.source,
  });

  final DateTime date;
  final int count;
  final String source;
}

/// Аналитика заявок
class BookingsAnalytics {
  const BookingsAnalytics({
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.conversionRate,
    required this.trend,
  });

  final int total;
  final int completed;
  final int cancelled;
  final double conversionRate;
  final double trend;
}

/// Аналитика доходов
class RevenueAnalytics {
  const RevenueAnalytics({
    required this.totalRevenue,
    required this.averageCheck,
    required this.trend,
    required this.monthlyRevenue,
  });

  final double totalRevenue;
  final double averageCheck;
  final double trend;
  final Map<String, double> monthlyRevenue;
}

/// Аналитика отзывов
class ReviewsAnalytics {
  const ReviewsAnalytics({
    required this.total,
    required this.averageRating,
    required this.recentReviews,
  });

  final int total;
  final double averageRating;
  final List<ReviewAnalytics> recentReviews;
}

/// Отзыв для аналитики
class ReviewAnalytics {
  const ReviewAnalytics({
    required this.id,
    required this.rating,
    required this.comment,
    required this.customerName,
    required this.createdAt,
  });

  final String id;
  final double rating;
  final String comment;
  final String customerName;
  final DateTime createdAt;
}

/// Метрики производительности
class PerformanceMetrics {
  const PerformanceMetrics({
    required this.responseTime,
    required this.customerSatisfaction,
    required this.repeatCustomers,
  });

  final double responseTime; // В часах
  final double customerSatisfaction; // Средний рейтинг
  final int repeatCustomers;
}
