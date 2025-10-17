import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/customer_portfolio.dart';
import '../models/order_history.dart';

/// Сервис для работы с портфолио заказчика
class CustomerPortfolioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _customersCollection = 'customers';
  final String _ordersCollection = 'orders';
  final String _favoritesCollection = 'favorites';

  /// Получить портфолио заказчика
  Future<CustomerPortfolio?> getCustomerPortfolio(String customerId) async {
    try {
      final doc = await _firestore.collection(_customersCollection).doc(customerId).get();

      if (!doc.exists) return null;
      return CustomerPortfolio.fromDocument(doc);
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки портфолио: $e');
    }
  }

  /// Создать или обновить портфолио заказчика
  Future<CustomerPortfolio> createOrUpdatePortfolio(
    CustomerPortfolio portfolio,
  ) async {
    try {
      await _firestore
          .collection(_customersCollection)
          .doc(portfolio.id)
          .set(portfolio.toMap(), SetOptions(merge: true));

      return portfolio;
    } on Exception catch (e) {
      throw Exception('Ошибка сохранения портфолио: $e');
    }
  }

  /// Получить историю заказов заказчика
  Future<List<OrderHistory>> getOrderHistory(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection(_customersCollection)
          .doc(customerId)
          .collection(_ordersCollection)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map(OrderHistory.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки истории заказов: $e');
    }
  }

  /// Добавить заказ в историю
  Future<void> addOrderToHistory(String customerId, OrderHistory order) async {
    try {
      await _firestore
          .collection(_customersCollection)
          .doc(customerId)
          .collection(_ordersCollection)
          .doc(order.id)
          .set(order.toMap());
    } on Exception catch (e) {
      throw Exception('Ошибка добавления заказа в историю: $e');
    }
  }

  /// Добавить заказ из бронирования в историю
  Future<void> addBookingToHistory(String customerId, Booking booking) async {
    try {
      final orderHistory = OrderHistory.fromMap(
        {
          'specialistId': booking.specialistId,
          'specialistName': booking.specialistName,
          'serviceName': booking.serviceName ?? booking.eventTitle,
          'date': booking.eventDate,
          'price': booking.effectivePrice,
          'status': booking.status.toString().split('.').last,
          'eventType': booking.eventType,
          'location': booking.eventLocation,
          'notes': booking.specialRequests,
          'createdAt': booking.createdAt,
          'updatedAt': booking.updatedAt,
        },
        booking.id,
      );
      await addOrderToHistory(customerId, orderHistory);
    } on Exception catch (e) {
      throw Exception('Ошибка добавления бронирования в историю: $e');
    }
  }

  /// Обновить заказ в истории
  Future<void> updateOrderInHistory(
    String customerId,
    OrderHistory order,
  ) async {
    try {
      await _firestore
          .collection(_customersCollection)
          .doc(customerId)
          .collection(_ordersCollection)
          .doc(order.id)
          .update(order.toMap());
    } on Exception catch (e) {
      throw Exception('Ошибка обновления заказа в истории: $e');
    }
  }

  /// Удалить заказ из истории
  Future<void> removeOrderFromHistory(String customerId, String orderId) async {
    try {
      await _firestore
          .collection(_customersCollection)
          .doc(customerId)
          .collection(_ordersCollection)
          .doc(orderId)
          .delete();
    } on Exception catch (e) {
      throw Exception('Ошибка удаления заказа из истории: $e');
    }
  }

  /// Получить избранных специалистов
  Future<List<String>> getFavoriteSpecialists(String customerId) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      return portfolio?.favoriteSpecialists ?? [];
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки избранных специалистов: $e');
    }
  }

  /// Добавить специалиста в избранное
  Future<void> addToFavorites(String customerId, String specialistId) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio == null) {
        throw Exception('Портфолио заказчика не найдено');
      }

      final updatedPortfolio = portfolio.addFavoriteSpecialist(specialistId);
      await createOrUpdatePortfolio(updatedPortfolio);
    } on Exception catch (e) {
      throw Exception('Ошибка добавления в избранное: $e');
    }
  }

  /// Удалить специалиста из избранного
  Future<void> removeFromFavorites(
    String customerId,
    String specialistId,
  ) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio == null) {
        throw Exception('Портфолио заказчика не найдено');
      }

      final updatedPortfolio = portfolio.removeFavoriteSpecialist(specialistId);
      await createOrUpdatePortfolio(updatedPortfolio);
    } on Exception catch (e) {
      throw Exception('Ошибка удаления из избранного: $e');
    }
  }

  /// Проверить, является ли специалист избранным
  Future<bool> isFavoriteSpecialist(
    String customerId,
    String specialistId,
  ) async {
    try {
      final favorites = await getFavoriteSpecialists(customerId);
      return favorites.contains(specialistId);
    } on Exception {
      return false;
    }
  }

  /// Получить годовщины заказчика
  Future<List<DateTime>> getAnniversaries(String customerId) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      return portfolio?.anniversaries ?? [];
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки годовщин: $e');
    }
  }

  /// Добавить годовщину
  Future<void> addAnniversary(String customerId, DateTime anniversary) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio == null) {
        throw Exception('Портфолио заказчика не найдено');
      }

      final updatedPortfolio = portfolio.addAnniversary(anniversary);
      await createOrUpdatePortfolio(updatedPortfolio);
    } on Exception catch (e) {
      throw Exception('Ошибка добавления годовщины: $e');
    }
  }

  /// Удалить годовщину
  Future<void> removeAnniversary(
    String customerId,
    DateTime anniversary,
  ) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio == null) {
        throw Exception('Портфолио заказчика не найдено');
      }

      final updatedPortfolio = portfolio.removeAnniversary(anniversary);
      await createOrUpdatePortfolio(updatedPortfolio);
    } on Exception catch (e) {
      throw Exception('Ошибка удаления годовщины: $e');
    }
  }

  /// Обновить заметки заказчика
  Future<void> updateNotes(String customerId, String notes) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio == null) {
        throw Exception('Портфолио заказчика не найдено');
      }

      final updatedPortfolio = portfolio.copyWith(notes: notes);
      await createOrUpdatePortfolio(updatedPortfolio);
    } on Exception catch (e) {
      throw Exception('Ошибка обновления заметок: $e');
    }
  }

  /// Получить заметки заказчика
  Future<String?> getNotes(String customerId) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      return portfolio?.notes;
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки заметок: $e');
    }
  }

  /// Включить/выключить напоминания о годовщинах
  Future<void> setAnniversaryReminders(String customerId, bool enabled) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio == null) {
        throw Exception('Портфолио заказчика не найдено');
      }

      final updatedPortfolio = portfolio.copyWith(anniversaryRemindersEnabled: enabled);
      await createOrUpdatePortfolio(updatedPortfolio);
    } on Exception catch (e) {
      throw Exception('Ошибка настройки напоминаний: $e');
    }
  }

  /// Получить заказчиков с годовщинами сегодня
  Future<List<CustomerPortfolio>> getCustomersWithAnniversariesToday() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_customersCollection)
          .where(
            'weddingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where('weddingDate', isLessThan: Timestamp.fromDate(tomorrow))
          .where('anniversaryRemindersEnabled', isEqualTo: true)
          .get();

      return querySnapshot.docs.map(CustomerPortfolio.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки годовщин: $e');
    }
  }

  /// Получить заказчиков с годовщинами в ближайшие дни
  Future<List<CustomerPortfolio>> getCustomersWithUpcomingAnniversaries(
    int daysAhead,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(Duration(days: daysAhead));

      final querySnapshot = await _firestore
          .collection(_customersCollection)
          .where(
            'weddingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('weddingDate', isLessThan: Timestamp.fromDate(endDate))
          .where('anniversaryRemindersEnabled', isEqualTo: true)
          .get();

      return querySnapshot.docs.map(CustomerPortfolio.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки предстоящих годовщин: $e');
    }
  }

  /// Получить статистику портфолио
  Future<Map<String, dynamic>> getPortfolioStats(String customerId) async {
    try {
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio == null) {
        throw Exception('Портфолио заказчика не найдено');
      }

      final orderHistory = await getOrderHistory(customerId);
      final totalSpent = orderHistory.fold(0, (sum, order) => sum + order.price);
      final completedOrders = orderHistory.where((order) => order.status == 'completed').length;

      return {
        ...portfolio.portfolioStats,
        'totalOrders': orderHistory.length,
        'completedOrders': completedOrders,
        'totalSpent': totalSpent,
        'averageOrderValue': orderHistory.isNotEmpty ? totalSpent / orderHistory.length : 0.0,
        'lastOrderDate': orderHistory.isNotEmpty ? orderHistory.first.date : null,
      };
    } on Exception catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Синхронизировать историю заказов из бронирований
  Future<void> syncOrderHistoryFromBookings(String customerId) async {
    try {
      // Получить все завершенные бронирования заказчика
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Получить существующую историю заказов
      final existingOrders = await getOrderHistory(customerId);
      final existingOrderIds = existingOrders.map((order) => order.id).toSet();

      // Добавить новые заказы в историю
      for (final doc in bookingsSnapshot.docs) {
        final booking = Booking.fromDocument(doc);
        if (!existingOrderIds.contains(booking.id)) {
          await addBookingToHistory(customerId, booking);
        }
      }
    } on Exception catch (e) {
      throw Exception('Ошибка синхронизации истории заказов: $e');
    }
  }

  /// Получить рекомендации на основе истории заказов
  Future<List<String>> getRecommendations(String customerId) async {
    try {
      final orderHistory = await getOrderHistory(customerId);
      final favoriteSpecialists = await getFavoriteSpecialists(customerId);

      final recommendations = <String>[];

      // Рекомендации на основе истории
      if (orderHistory.isNotEmpty) {
        final lastOrder = orderHistory.first;
        recommendations.add('Повторить заказ у ${lastOrder.specialistName}');

        if (lastOrder.hadDiscount) {
          recommendations.add(
            'У вас была скидка ${lastOrder.discountAmount.toStringAsFixed(0)} ₽ на последний заказ',
          );
        }
      }

      // Рекомендации на основе избранного
      if (favoriteSpecialists.isNotEmpty) {
        recommendations.add('У вас ${favoriteSpecialists.length} избранных специалистов');
      }

      // Рекомендации на основе годовщин
      final portfolio = await getCustomerPortfolio(customerId);
      if (portfolio != null && portfolio.upcomingAnniversaries.isNotEmpty) {
        final nextAnniversary = portfolio.upcomingAnniversaries.first;
        final daysUntil = nextAnniversary.difference(DateTime.now()).inDays;
        recommendations.add('До следующей годовщины осталось $daysUntil дней');
      }

      return recommendations;
    } on Exception catch (e) {
      throw Exception('Ошибка получения рекомендаций: $e');
    }
  }
}
