import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для генерации и обновления аналитики
class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  static final AnalyticsService _instance = AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Генерация аналитики для специалиста
  Future<void> generateSpecialistAnalytics(String specialistId) async {
    try {
      // Получаем все заказы специалиста
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final bookings = bookingsSnapshot.docs.map((doc) => doc.data()).toList();

      // Получаем отзывы
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final reviews = reviewsSnapshot.docs.map((doc) => doc.data()).toList();

      // Вычисляем статистику
      final analytics = _calculateSpecialistAnalytics(bookings, reviews);

      // Сохраняем аналитику
      await _firestore
          .collection('analytics')
          .doc('specialist_$specialistId')
          .set(analytics, SetOptions(merge: true));

      print('Specialist analytics generated for: $specialistId');
    } catch (e) {
      print('Error generating specialist analytics: $e');
    }
  }

  /// Генерация аналитики для заказчика
  Future<void> generateCustomerAnalytics(String customerId) async {
    try {
      // Получаем все заказы заказчика
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .get();

      final bookings = bookingsSnapshot.docs.map((doc) => doc.data()).toList();

      // Вычисляем статистику
      final analytics = _calculateCustomerAnalytics(bookings);

      // Сохраняем аналитику
      await _firestore
          .collection('analytics')
          .doc('customer_$customerId')
          .set(analytics, SetOptions(merge: true));

      print('Customer analytics generated for: $customerId');
    } catch (e) {
      print('Error generating customer analytics: $e');
    }
  }

  /// Вычисление аналитики специалиста
  Map<String, dynamic> _calculateSpecialistAnalytics(
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> reviews,
  ) {
    // Общий доход
    var totalIncome = 0;
    final totalBookings = bookings.length;
    var completedBookings = 0;

    // Доход по месяцам
    final monthlyIncome = <String, double>{};

    // Заказы по статусам
    final bookingsByStatus = <String, int>{};

    // Топ заказчики
    final topCustomers = <String, Map<String, dynamic>>{};

    // Распределение оценок
    final ratingDistribution = <String, int>{};

    for (final booking in bookings) {
      final status = booking['status'] as String? ?? 'unknown';
      final price = (booking['totalPrice'] as num?)?.toDouble() ?? 0.0;
      final eventDate = booking['eventDate'] as Timestamp?;
      final customerId = booking['customerId'] as String? ?? '';
      final customerName = booking['customerName'] as String? ?? 'Неизвестно';

      // Общий доход
      if (status == 'completed') {
        totalIncome += price;
        completedBookings++;
      }

      // Доход по месяцам
      if (eventDate != null && status == 'completed') {
        final date = eventDate.toDate();
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0.0) + price;
      }

      // Заказы по статусам
      bookingsByStatus[status] = (bookingsByStatus[status] ?? 0) + 1;

      // Топ заказчики
      if (customerId.isNotEmpty) {
        if (!topCustomers.containsKey(customerId)) {
          topCustomers[customerId] = {
            'name': customerName,
            'bookings': 0,
            'totalSpent': 0.0,
          };
        }
        topCustomers[customerId]!['bookings'] =
            (topCustomers[customerId]!['bookings'] as int) + 1;
        if (status == 'completed') {
          topCustomers[customerId]!['totalSpent'] =
              (topCustomers[customerId]!['totalSpent'] as double) + price;
        }
      }
    }

    // Средний рейтинг
    var averageRating = 0;
    if (reviews.isNotEmpty) {
      var totalRating = 0;
      for (final review in reviews) {
        final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
        totalRating += rating;

        // Распределение оценок
        final ratingKey = rating.round().toString();
        ratingDistribution[ratingKey] =
            (ratingDistribution[ratingKey] ?? 0) + 1;
      }
      averageRating = totalRating / reviews.length;
    }

    // Сортируем топ заказчиков
    final sortedTopCustomers = topCustomers.values.toList()
      ..sort(
        (a, b) =>
            (b['totalSpent'] as double).compareTo(a['totalSpent'] as double),
      );

    // Форматируем доход по месяцам
    final monthlyIncomeList = monthlyIncome.entries.map((entry) {
      final date = DateTime.parse('${entry.key}-01');
      return {
        'month': '${date.month}/${date.year}',
        'amount': entry.value,
      };
    }).toList()
      ..sort((a, b) => a['month'].toString().compareTo(b['month'].toString()));

    return {
      'totalIncome': totalIncome,
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'averageRating': averageRating,
      'monthlyIncome': monthlyIncomeList,
      'bookingsByStatus': bookingsByStatus,
      'topCustomers': sortedTopCustomers.take(5).toList(),
      'ratingDistribution': ratingDistribution,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Вычисление аналитики заказчика
  Map<String, dynamic> _calculateCustomerAnalytics(
    List<Map<String, dynamic>> bookings,
  ) {
    // Общие расходы
    var totalSpent = 0;
    final totalBookings = bookings.length;

    // Расходы по месяцам
    final monthlySpending = <String, double>{};

    // Частота заказов
    final bookingFrequency = <String, int>{};

    // Топ специалисты
    final topSpecialists = <String, Map<String, dynamic>>{};

    // Любимая категория
    final categoryCount = <String, int>{};

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final thisYear = DateTime(now.year);
    final lastYear = DateTime(now.year - 1);

    for (final booking in bookings) {
      final status = booking['status'] as String? ?? 'unknown';
      final price = (booking['totalPrice'] as num?)?.toDouble() ?? 0.0;
      final eventDate = booking['eventDate'] as Timestamp?;
      final specialistId = booking['specialistId'] as String? ?? '';
      final specialistName =
          booking['specialistName'] as String? ?? 'Неизвестно';
      final category = booking['category'] as String? ?? 'Неизвестно';

      // Общие расходы
      if (status == 'completed') {
        totalSpent += price;
      }

      // Расходы по месяцам
      if (eventDate != null && status == 'completed') {
        final date = eventDate.toDate();
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0.0) + price;
      }

      // Частота заказов
      if (eventDate != null) {
        final date = eventDate.toDate();

        if (date.isAfter(thisMonth)) {
          bookingFrequency['thisMonth'] =
              (bookingFrequency['thisMonth'] ?? 0) + 1;
        }
        if (date.isAfter(lastMonth) && date.isBefore(thisMonth)) {
          bookingFrequency['lastMonth'] =
              (bookingFrequency['lastMonth'] ?? 0) + 1;
        }
        if (date.isAfter(thisYear)) {
          bookingFrequency['thisYear'] =
              (bookingFrequency['thisYear'] ?? 0) + 1;
        }
        if (date.isAfter(lastYear) && date.isBefore(thisYear)) {
          bookingFrequency['lastYear'] =
              (bookingFrequency['lastYear'] ?? 0) + 1;
        }
      }

      // Топ специалисты
      if (specialistId.isNotEmpty) {
        if (!topSpecialists.containsKey(specialistId)) {
          topSpecialists[specialistId] = {
            'name': specialistName,
            'category': category,
            'bookings': 0,
            'rating': 0.0,
          };
        }
        topSpecialists[specialistId]!['bookings'] =
            (topSpecialists[specialistId]!['bookings'] as int) + 1;
      }

      // Категории
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    // Средняя оценка специалистов (нужно получить из отзывов)
    const averageRating = 0;

    // Сортируем топ специалистов
    final sortedTopSpecialists = topSpecialists.values.toList()
      ..sort((a, b) => (b['bookings'] as int).compareTo(a['bookings'] as int));

    // Находим любимую категорию
    var favoriteCategory = 'Не определено';
    if (categoryCount.isNotEmpty) {
      favoriteCategory =
          categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Форматируем расходы по месяцам
    final monthlySpendingList = monthlySpending.entries.map((entry) {
      final date = DateTime.parse('${entry.key}-01');
      return {
        'month': '${date.month}/${date.year}',
        'amount': entry.value,
      };
    }).toList()
      ..sort((a, b) => a['month'].toString().compareTo(b['month'].toString()));

    return {
      'totalSpent': totalSpent,
      'totalBookings': totalBookings,
      'averageRating': averageRating,
      'favoriteCategory': favoriteCategory,
      'monthlySpending': monthlySpendingList,
      'bookingFrequency': bookingFrequency,
      'topSpecialists': sortedTopSpecialists.take(5).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Обновление аналитики при изменении заказа
  Future<void> updateAnalyticsOnBookingChange(String bookingId) async {
    try {
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (!bookingDoc.exists) return;

      final booking = bookingDoc.data()!;
      final specialistId = booking['specialistId'] as String?;
      final customerId = booking['customerId'] as String?;

      if (specialistId != null) {
        await generateSpecialistAnalytics(specialistId);
      }

      if (customerId != null) {
        await generateCustomerAnalytics(customerId);
      }

      print('Analytics updated for booking: $bookingId');
    } catch (e) {
      print('Error updating analytics: $e');
    }
  }

  /// Создание тестовых данных аналитики
  Future<void> createTestAnalytics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Тестовая аналитика для специалиста
      final specialistAnalytics = {
        'totalIncome': 150000.0,
        'totalBookings': 25,
        'completedBookings': 20,
        'averageRating': 4.7,
        'monthlyIncome': [
          {'month': '10/2024', 'amount': 25000.0},
          {'month': '11/2024', 'amount': 30000.0},
          {'month': '12/2024', 'amount': 35000.0},
          {'month': '1/2025', 'amount': 40000.0},
          {'month': '2/2025', 'amount': 20000.0},
        ],
        'bookingsByStatus': {
          'completed': 20,
          'pending': 3,
          'confirmed': 2,
          'cancelled': 0,
        },
        'topCustomers': [
          {
            'name': 'Анна Петрова',
            'bookings': 5,
            'totalSpent': 25000.0,
          },
          {
            'name': 'Михаил Сидоров',
            'bookings': 3,
            'totalSpent': 15000.0,
          },
          {
            'name': 'Елена Козлова',
            'bookings': 2,
            'totalSpent': 10000.0,
          },
        ],
        'ratingDistribution': {
          '5': 15,
          '4': 3,
          '3': 1,
          '2': 0,
          '1': 1,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Тестовая аналитика для заказчика
      final customerAnalytics = {
        'totalSpent': 45000.0,
        'totalBookings': 8,
        'averageRating': 4.5,
        'favoriteCategory': 'Фотограф',
        'monthlySpending': [
          {'month': '10/2024', 'amount': 5000.0},
          {'month': '11/2024', 'amount': 8000.0},
          {'month': '12/2024', 'amount': 12000.0},
          {'month': '1/2025', 'amount': 15000.0},
          {'month': '2/2025', 'amount': 5000.0},
        ],
        'bookingFrequency': {
          'thisMonth': 1,
          'lastMonth': 2,
          'thisYear': 5,
          'lastYear': 3,
        },
        'topSpecialists': [
          {
            'name': 'Иван Иванов',
            'category': 'Фотограф',
            'bookings': 3,
            'rating': 4.8,
          },
          {
            'name': 'Мария Смирнова',
            'category': 'Видеограф',
            'bookings': 2,
            'rating': 4.6,
          },
          {
            'name': 'Алексей Петров',
            'category': 'Ведущий',
            'bookings': 1,
            'rating': 4.9,
          },
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('analytics')
          .doc('specialist_${user.uid}')
          .set(specialistAnalytics);

      await _firestore
          .collection('analytics')
          .doc('customer_${user.uid}')
          .set(customerAnalytics);

      print('Test analytics created');
    } catch (e) {
      print('Error creating test analytics: $e');
    }
  }
}
