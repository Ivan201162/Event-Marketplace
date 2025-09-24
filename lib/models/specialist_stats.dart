import 'package:cloud_firestore/cloud_firestore.dart';

/// Статистика специалиста
class SpecialistStats {
  final String specialistId;
  final double averageRating;
  final int totalReviews;
  final int totalBookings;
  final int completedBookings;
  final double totalRevenue;
  final double averageBookingValue;
  final Map<int, int> ratingDistribution; // Распределение рейтингов (1-5)
  final List<String> topTags; // Популярные теги в отзывах
  final DateTime lastUpdated;
  final DateTime? lastBookingDate;
  final double responseRate; // Процент откликов на заявки
  final double completionRate; // Процент завершенных заказов
  final int repeatCustomers; // Количество постоянных клиентов

  const SpecialistStats({
    required this.specialistId,
    required this.averageRating,
    required this.totalReviews,
    required this.totalBookings,
    required this.completedBookings,
    required this.totalRevenue,
    required this.averageBookingValue,
    required this.ratingDistribution,
    required this.topTags,
    required this.lastUpdated,
    this.lastBookingDate,
    required this.responseRate,
    required this.completionRate,
    required this.repeatCustomers,
  });

  /// Создать из документа Firestore
  factory SpecialistStats.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistStats(
      specialistId: doc.id,
      averageRating: (data['averageRating'] as num).toDouble(),
      totalReviews: data['totalReviews'] as int,
      totalBookings: data['totalBookings'] as int,
      completedBookings: data['completedBookings'] as int,
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      averageBookingValue: (data['averageBookingValue'] as num).toDouble(),
      ratingDistribution: Map<int, int>.from(
        (data['ratingDistribution'] as Map).map(
          (key, value) => MapEntry(int.parse(key.toString()), value as int),
        ),
      ),
      topTags: List<String>.from(data['topTags'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      lastBookingDate: data['lastBookingDate'] != null 
          ? (data['lastBookingDate'] as Timestamp).toDate() 
          : null,
      responseRate: (data['responseRate'] as num).toDouble(),
      completionRate: (data['completionRate'] as num).toDouble(),
      repeatCustomers: data['repeatCustomers'] as int,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'totalRevenue': totalRevenue,
      'averageBookingValue': averageBookingValue,
      'ratingDistribution': ratingDistribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'topTags': topTags,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastBookingDate': lastBookingDate != null 
          ? Timestamp.fromDate(lastBookingDate!) 
          : null,
      'responseRate': responseRate,
      'completionRate': completionRate,
      'repeatCustomers': repeatCustomers,
    };
  }

  /// Создать копию с изменениями
  SpecialistStats copyWith({
    String? specialistId,
    double? averageRating,
    int? totalReviews,
    int? totalBookings,
    int? completedBookings,
    double? totalRevenue,
    double? averageBookingValue,
    Map<int, int>? ratingDistribution,
    List<String>? topTags,
    DateTime? lastUpdated,
    DateTime? lastBookingDate,
    double? responseRate,
    double? completionRate,
    int? repeatCustomers,
  }) {
    return SpecialistStats(
      specialistId: specialistId ?? this.specialistId,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalBookings: totalBookings ?? this.totalBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageBookingValue: averageBookingValue ?? this.averageBookingValue,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      topTags: topTags ?? this.topTags,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastBookingDate: lastBookingDate ?? this.lastBookingDate,
      responseRate: responseRate ?? this.responseRate,
      completionRate: completionRate ?? this.completionRate,
      repeatCustomers: repeatCustomers ?? this.repeatCustomers,
    );
  }

  /// Получить рейтинг в виде звезд
  String get ratingStars {
    return '★' * averageRating.round() + '☆' * (5 - averageRating.round());
  }

  /// Проверить, является ли специалист топовым
  bool get isTopSpecialist {
    return averageRating >= 4.5 && 
           totalReviews >= 10 && 
           completionRate >= 0.9;
  }

  /// Получить уровень специалиста
  String get level {
    if (averageRating >= 4.8 && totalReviews >= 50) return 'Эксперт';
    if (averageRating >= 4.5 && totalReviews >= 20) return 'Профессионал';
    if (averageRating >= 4.0 && totalReviews >= 10) return 'Опытный';
    if (totalReviews >= 5) return 'Начинающий';
    return 'Новичок';
  }
}
