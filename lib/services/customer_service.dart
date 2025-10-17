import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/user.dart';

/// Сервис для работы с заказчиками
class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'customers';

  /// Получить заказчика по ID
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(customerId).get();

      if (!doc.exists) return null;
      return Customer.fromDocument(doc);
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки заказчика: $e');
    }
  }

  /// Получить заказчика по email
  Future<Customer?> getCustomerByEmail(String email) async {
    try {
      final querySnapshot =
          await _firestore.collection(_collection).where('email', isEqualTo: email).limit(1).get();

      if (querySnapshot.docs.isEmpty) return null;
      return Customer.fromDocument(querySnapshot.docs.first);
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки заказчика: $e');
    }
  }

  /// Создать или обновить заказчика
  Future<Customer> createOrUpdateCustomer(Customer customer) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(customer.id)
          .set(customer.toMap(), SetOptions(merge: true));

      return customer;
    } on Exception catch (e) {
      throw Exception('Ошибка сохранения заказчика: $e');
    }
  }

  /// Создать заказчика из AppUser
  Future<Customer> createCustomerFromUser(AppUser user) async {
    try {
      final customer = Customer.fromAppUser(user);
      return await createOrUpdateCustomer(customer);
    } on Exception catch (e) {
      throw Exception('Ошибка создания заказчика: $e');
    }
  }

  /// Обновить профиль заказчика
  Future<void> updateCustomerProfile(
    String customerId, {
    String? name,
    String? avatarUrl,
    String? phoneNumber,
    MaritalStatus? maritalStatus,
    DateTime? weddingDate,
    String? partnerName,
    bool? anniversaryRemindersEnabled,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (maritalStatus != null) {
        updateData['maritalStatus'] = maritalStatus.name;
      }
      if (weddingDate != null) {
        updateData['weddingDate'] = Timestamp.fromDate(weddingDate);
      }
      if (partnerName != null) updateData['partnerName'] = partnerName;
      if (anniversaryRemindersEnabled != null) {
        updateData['anniversaryRemindersEnabled'] = anniversaryRemindersEnabled;
      }

      await _firestore.collection(_collection).doc(customerId).update(updateData);
    } on Exception catch (e) {
      throw Exception('Ошибка обновления профиля: $e');
    }
  }

  /// Добавить специалиста в избранное
  Future<void> addToFavorites(String customerId, String specialistId) async {
    try {
      await _firestore.collection(_collection).doc(customerId).update({
        'favoriteSpecialists': FieldValue.arrayUnion([specialistId]),
      });
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
      await _firestore.collection(_collection).doc(customerId).update({
        'favoriteSpecialists': FieldValue.arrayRemove([specialistId]),
      });
    } on Exception catch (e) {
      throw Exception('Ошибка удаления из избранного: $e');
    }
  }

  /// Получить избранных специалистов
  Future<List<String>> getFavoriteSpecialists(String customerId) async {
    try {
      final customer = await getCustomerById(customerId);
      return customer?.favoriteSpecialists ?? [];
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки избранного: $e');
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

  /// Получить заказчиков с годовщинами сегодня
  Future<List<Customer>> getCustomersWithAnniversariesToday() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where(
            'weddingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where('weddingDate', isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      return querySnapshot.docs.map(Customer.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки годовщин: $e');
    }
  }

  /// Получить заказчиков с годовщинами в ближайшие дни
  Future<List<Customer>> getCustomersWithUpcomingAnniversaries(
    int daysAhead,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(Duration(days: daysAhead));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where(
            'weddingDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('weddingDate', isLessThan: Timestamp.fromDate(endDate))
          .get();

      return querySnapshot.docs.map(Customer.fromDocument).toList();
    } on Exception catch (e) {
      throw Exception('Ошибка загрузки предстоящих годовщин: $e');
    }
  }

  /// Обновить время последнего входа
  Future<void> updateLastLogin(String customerId) async {
    try {
      await _firestore.collection(_collection).doc(customerId).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      throw Exception('Ошибка обновления времени входа: $e');
    }
  }

  /// Получить статистику заказчика
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final customer = await getCustomerById(customerId);
      if (customer == null) {
        throw Exception('Заказчик не найден');
      }

      // Получить количество бронирований
      final bookingsSnapshot =
          await _firestore.collection('bookings').where('customerId', isEqualTo: customerId).get();

      final totalBookings = bookingsSnapshot.docs.length;
      final completedBookings =
          bookingsSnapshot.docs.where((doc) => doc.data()['status'] == 'completed').length;

      return {
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'favoriteSpecialists': customer.favoriteSpecialists.length,
        'yearsMarried': customer.yearsMarried,
        'isAnniversaryToday': customer.isAnniversaryToday,
        'nextAnniversary': customer.nextAnniversary,
      };
    } on Exception catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Удалить заказчика
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection(_collection).doc(customerId).delete();
    } on Exception catch (e) {
      throw Exception('Ошибка удаления заказчика: $e');
    }
  }
}
