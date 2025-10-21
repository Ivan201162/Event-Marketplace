import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist_profile.dart';

/// Сервис для генерации отчетов по специалистам
class SpecialistReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить общую статистику по специалистам
  Future<SpecialistReport> generateSpecialistReport() async {
    try {
      final querySnapshot = await _firestore.collection('specialist_profiles').get();

      final specialists = querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();

      return SpecialistReport.fromSpecialists(specialists);
    } on Exception catch (e) {
      debugPrint('Ошибка генерации отчета по специалистам: $e');
      throw Exception('Не удалось сгенерировать отчет');
    }
  }

  /// Получить отчет по категориям специалистов
  Future<CategoryReport> generateCategoryReport() async {
    try {
      final querySnapshot = await _firestore.collection('specialist_profiles').get();

      final specialists = querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();

      return CategoryReport.fromSpecialists(specialists);
    } on Exception catch (e) {
      debugPrint('Ошибка генерации отчета по категориям: $e');
      throw Exception('Не удалось сгенерировать отчет по категориям');
    }
  }

  /// Получить отчет по рейтингам специалистов
  Future<RatingReport> generateRatingReport() async {
    try {
      final querySnapshot = await _firestore
          .collection('specialist_profiles')
          .orderBy('rating', descending: true)
          .get();

      final specialists = querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();

      return RatingReport.fromSpecialists(specialists);
    } on Exception catch (e) {
      debugPrint('Ошибка генерации отчета по рейтингам: $e');
      throw Exception('Не удалось сгенерировать отчет по рейтингам');
    }
  }

  /// Получить отчет по доходам специалистов
  Future<EarningsReport> generateEarningsReport() async {
    try {
      final querySnapshot = await _firestore.collection('specialist_profiles').get();

      final specialists = querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();

      return EarningsReport.fromSpecialists(specialists);
    } on Exception catch (e) {
      debugPrint('Ошибка генерации отчета по доходам: $e');
      throw Exception('Не удалось сгенерировать отчет по доходам');
    }
  }

  /// Получить отчет по активности специалистов
  Future<ActivityReport> generateActivityReport() async {
    try {
      final querySnapshot = await _firestore.collection('specialist_profiles').get();

      final specialists = querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();

      return ActivityReport.fromSpecialists(specialists);
    } on Exception catch (e) {
      debugPrint('Ошибка генерации отчета по активности: $e');
      throw Exception('Не удалось сгенерировать отчет по активности');
    }
  }

  /// Получить детальный отчет по конкретному специалисту
  Future<SpecialistDetailReport> generateSpecialistDetailReport(String specialistId) async {
    try {
      final specialistDoc = await _firestore
          .collection('specialist_profiles')
          .doc(specialistId)
          .get();

      if (!specialistDoc.exists) {
        throw Exception('Специалист не найден');
      }

      final specialist = SpecialistProfile.fromDocument(specialistDoc);

      // Получаем дополнительные данные
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final reviews = reviewsSnapshot.docs.map((doc) => doc.data()).toList();

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final bookings = bookingsSnapshot.docs.map((doc) => doc.data()).toList();

      return SpecialistDetailReport(
        specialist: specialist,
        reviews: reviews,
        bookings: bookings,
        generatedAt: DateTime.now(),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка генерации детального отчета: $e');
      throw Exception('Не удалось сгенерировать детальный отчет');
    }
  }
}

/// Общий отчет по специалистам
class SpecialistReport {
  const SpecialistReport({
    required this.totalSpecialists,
    required this.verifiedSpecialists,
    required this.availableSpecialists,
    required this.averageRating,
    required this.averageHourlyRate,
    required this.totalCategories,
    required this.topCategories,
    required this.generatedAt,
  });

  factory SpecialistReport.fromSpecialists(List<SpecialistProfile> specialists) {
    final totalSpecialists = specialists.length;
    final verifiedSpecialists = specialists.where((s) => s.isVerified).length;
    final availableSpecialists = specialists.where((s) => s.isAvailable).length;

    final averageRating = specialists.isNotEmpty
        ? specialists.map((s) => s.rating).reduce((a, b) => a + b) / specialists.length
        : 0.0;

    final averageHourlyRate = specialists.isNotEmpty
        ? specialists.map((s) => s.hourlyRate).reduce((a, b) => a + b) / specialists.length
        : 0.0;

    // Подсчитываем категории
    final categoryCounts = <String, int>{};
    for (final specialist in specialists) {
      for (final category in specialist.categories) {
        categoryCounts[category.name] = (categoryCounts[category.name] ?? 0) + 1;
      }
    }

    final totalCategories = categoryCounts.length;
    final topCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SpecialistReport(
      totalSpecialists: totalSpecialists,
      verifiedSpecialists: verifiedSpecialists,
      availableSpecialists: availableSpecialists,
      averageRating: averageRating,
      averageHourlyRate: averageHourlyRate,
      totalCategories: totalCategories,
      topCategories: topCategories.take(5).toList(),
      generatedAt: DateTime.now(),
    );
  }

  final int totalSpecialists;
  final int verifiedSpecialists;
  final int availableSpecialists;
  final double averageRating;
  final double averageHourlyRate;
  final int totalCategories;
  final List<MapEntry<String, int>> topCategories;
  final DateTime generatedAt;
}

/// Отчет по категориям
class CategoryReport {
  const CategoryReport({required this.categoryStats, required this.generatedAt});

  factory CategoryReport.fromSpecialists(List<SpecialistProfile> specialists) {
    final categoryStats = <String, CategoryStats>{};

    for (final specialist in specialists) {
      for (final category in specialist.categories) {
        if (!categoryStats.containsKey(category.name)) {
          categoryStats[category.name] = CategoryStats(
            categoryName: category.name,
            specialistCount: 0,
            averageRating: 0,
            averageHourlyRate: 0,
            totalReviews: 0,
          );
        }

        final stats = categoryStats[category.name]!;
        categoryStats[category.name] = CategoryStats(
          categoryName: category.name,
          specialistCount: stats.specialistCount + 1,
          averageRating: stats.averageRating + specialist.rating,
          averageHourlyRate: stats.averageHourlyRate + specialist.hourlyRate,
          totalReviews: stats.totalReviews + specialist.reviewCount,
        );
      }
    }

    // Вычисляем средние значения
    for (final entry in categoryStats.entries) {
      final stats = entry.value;
      categoryStats[entry.key] = CategoryStats(
        categoryName: stats.categoryName,
        specialistCount: stats.specialistCount,
        averageRating: stats.averageRating / stats.specialistCount,
        averageHourlyRate: stats.averageHourlyRate / stats.specialistCount,
        totalReviews: stats.totalReviews,
      );
    }

    return CategoryReport(categoryStats: categoryStats, generatedAt: DateTime.now());
  }

  final Map<String, CategoryStats> categoryStats;
  final DateTime generatedAt;
}

/// Статистика по категории
class CategoryStats {
  const CategoryStats({
    required this.categoryName,
    required this.specialistCount,
    required this.averageRating,
    required this.averageHourlyRate,
    required this.totalReviews,
  });

  final String categoryName;
  final int specialistCount;
  final double averageRating;
  final double averageHourlyRate;
  final int totalReviews;
}

/// Отчет по рейтингам
class RatingReport {
  const RatingReport({
    required this.ratingDistribution,
    required this.topRatedSpecialists,
    required this.averageRating,
    required this.generatedAt,
  });

  factory RatingReport.fromSpecialists(List<SpecialistProfile> specialists) {
    final ratingDistribution = <int, int>{};
    for (var i = 1; i <= 5; i++) {
      ratingDistribution[i] = specialists.where((s) => s.rating.floor() == i).length;
    }

    final topRatedSpecialists = specialists.where((s) => s.rating > 0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    final averageRating = specialists.isNotEmpty
        ? specialists.map((s) => s.rating).reduce((a, b) => a + b) / specialists.length
        : 0.0;

    return RatingReport(
      ratingDistribution: ratingDistribution,
      topRatedSpecialists: topRatedSpecialists.take(10).toList(),
      averageRating: averageRating,
      generatedAt: DateTime.now(),
    );
  }

  final Map<int, int> ratingDistribution;
  final List<SpecialistProfile> topRatedSpecialists;
  final double averageRating;
  final DateTime generatedAt;
}

/// Отчет по доходам
class EarningsReport {
  const EarningsReport({
    required this.totalEarnings,
    required this.averageEarnings,
    required this.topEarners,
    required this.generatedAt,
  });

  factory EarningsReport.fromSpecialists(List<SpecialistProfile> specialists) {
    var totalEarnings = 0;
    final specialistEarnings = <SpecialistProfile, double>{};

    for (final specialist in specialists) {
      final earnings = specialist.earnings['total'] as double? ?? 0.0;
      totalEarnings += earnings;
      specialistEarnings[specialist] = earnings;
    }

    final averageEarnings = specialists.isNotEmpty ? totalEarnings / specialists.length : 0.0;

    final topEarners = specialistEarnings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return EarningsReport(
      totalEarnings: totalEarnings,
      averageEarnings: averageEarnings,
      topEarners: topEarners.take(10).toList(),
      generatedAt: DateTime.now(),
    );
  }

  final double totalEarnings;
  final double averageEarnings;
  final List<MapEntry<SpecialistProfile, double>> topEarners;
  final DateTime generatedAt;
}

/// Отчет по активности
class ActivityReport {
  const ActivityReport({
    required this.activeSpecialists,
    required this.inactiveSpecialists,
    required this.recentlyJoined,
    required this.generatedAt,
  });

  factory ActivityReport.fromSpecialists(List<SpecialistProfile> specialists) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final activeSpecialists = specialists.where((s) => s.isAvailable).length;
    final inactiveSpecialists = specialists.where((s) => !s.isAvailable).length;
    final recentlyJoined = specialists.where((s) => s.createdAt.isAfter(thirtyDaysAgo)).length;

    return ActivityReport(
      activeSpecialists: activeSpecialists,
      inactiveSpecialists: inactiveSpecialists,
      recentlyJoined: recentlyJoined,
      generatedAt: DateTime.now(),
    );
  }

  final int activeSpecialists;
  final int inactiveSpecialists;
  final int recentlyJoined;
  final DateTime generatedAt;
}

/// Детальный отчет по специалисту
class SpecialistDetailReport {
  const SpecialistDetailReport({
    required this.specialist,
    required this.reviews,
    required this.bookings,
    required this.generatedAt,
  });

  final SpecialistProfile specialist;
  final List<Map<String, dynamic>> reviews;
  final List<Map<String, dynamic>> bookings;
  final DateTime generatedAt;
}
