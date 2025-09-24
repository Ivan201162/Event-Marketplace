import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель аналитики специалиста
class SpecialistAnalytics {
  const SpecialistAnalytics({
    required this.id,
    required this.specialistId,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.averageRating,
    required this.totalReviews,
    required this.totalRevenue,
    required this.averagePrice,
    required this.topServices,
    required this.monthlyStats,
    required this.lastUpdated,
    this.conversionRate = 0.0,
    this.responseTime = 0,
    this.repeatCustomers = 0,
  });

  final String id;
  final String specialistId;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double averageRating;
  final int totalReviews;
  final double totalRevenue;
  final double averagePrice;
  final List<ServiceStat> topServices;
  final List<MonthlyStat> monthlyStats;
  final DateTime lastUpdated;
  final double conversionRate; // Процент подтверждения заявок
  final int responseTime; // Среднее время ответа в минутах
  final int repeatCustomers; // Количество постоянных клиентов

  /// Создает аналитику из документа Firestore
  factory SpecialistAnalytics.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    
    return SpecialistAnalytics(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      totalBookings: data['totalBookings'] as int? ?? 0,
      completedBookings: data['completedBookings'] as int? ?? 0,
      cancelledBookings: data['cancelledBookings'] as int? ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      topServices: (data['topServices'] as List<dynamic>?)
              ?.map((e) => ServiceStat.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyStats: (data['monthlyStats'] as List<dynamic>?)
              ?.map((e) => MonthlyStat.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      conversionRate: (data['conversionRate'] as num?)?.toDouble() ?? 0.0,
      responseTime: data['responseTime'] as int? ?? 0,
      repeatCustomers: data['repeatCustomers'] as int? ?? 0,
    );
  }

  /// Преобразует аналитику в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'totalRevenue': totalRevenue,
        'averagePrice': averagePrice,
        'topServices': topServices.map((s) => s.toMap()).toList(),
        'monthlyStats': monthlyStats.map((s) => s.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(lastUpdated),
        'conversionRate': conversionRate,
        'responseTime': responseTime,
        'repeatCustomers': repeatCustomers,
      };

  /// Создает копию с измененными полями
  SpecialistAnalytics copyWith({
    String? id,
    String? specialistId,
    int? totalBookings,
    int? completedBookings,
    int? cancelledBookings,
    double? averageRating,
    int? totalReviews,
    double? totalRevenue,
    double? averagePrice,
    List<ServiceStat>? topServices,
    List<MonthlyStat>? monthlyStats,
    DateTime? lastUpdated,
    double? conversionRate,
    int? responseTime,
    int? repeatCustomers,
  }) =>
      SpecialistAnalytics(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        totalBookings: totalBookings ?? this.totalBookings,
        completedBookings: completedBookings ?? this.completedBookings,
        cancelledBookings: cancelledBookings ?? this.cancelledBookings,
        averageRating: averageRating ?? this.averageRating,
        totalReviews: totalReviews ?? this.totalReviews,
        totalRevenue: totalRevenue ?? this.totalRevenue,
        averagePrice: averagePrice ?? this.averagePrice,
        topServices: topServices ?? this.topServices,
        monthlyStats: monthlyStats ?? this.monthlyStats,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        conversionRate: conversionRate ?? this.conversionRate,
        responseTime: responseTime ?? this.responseTime,
        repeatCustomers: repeatCustomers ?? this.repeatCustomers,
      );

  @override
  String toString() =>
      'SpecialistAnalytics(id: $id, totalBookings: $totalBookings, averageRating: $averageRating)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialistAnalytics &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Статистика по услуге
class ServiceStat {
  const ServiceStat({
    required this.serviceName,
    required this.bookingCount,
    required this.revenue,
    required this.averageRating,
  });

  final String serviceName;
  final int bookingCount;
  final double revenue;
  final double averageRating;

  factory ServiceStat.fromMap(Map<String, dynamic> map) => ServiceStat(
        serviceName: map['serviceName'] as String,
        bookingCount: map['bookingCount'] as int,
        revenue: (map['revenue'] as num).toDouble(),
        averageRating: (map['averageRating'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'serviceName': serviceName,
        'bookingCount': bookingCount,
        'revenue': revenue,
        'averageRating': averageRating,
      };
}

/// Месячная статистика
class MonthlyStat {
  const MonthlyStat({
    required this.year,
    required this.month,
    required this.bookings,
    required this.revenue,
    required this.averageRating,
  });

  final int year;
  final int month;
  final int bookings;
  final double revenue;
  final double averageRating;

  factory MonthlyStat.fromMap(Map<String, dynamic> map) => MonthlyStat(
        year: map['year'] as int,
        month: map['month'] as int,
        bookings: map['bookings'] as int,
        revenue: (map['revenue'] as num).toDouble(),
        averageRating: (map['averageRating'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'year': year,
        'month': month,
        'bookings': bookings,
        'revenue': revenue,
        'averageRating': averageRating,
      };

  String get monthName {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }
}