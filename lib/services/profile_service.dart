import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_profile.dart';
import '../models/specialist_profile.dart';
import '../models/user.dart';

/// Сервис для управления профилями пользователей
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить профиль заказчика
  Future<CustomerProfile?> getCustomerProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('customer_profiles').doc(userId).get();

      if (doc.exists) {
        return CustomerProfile.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения профиля заказчика: $e');
      return null;
    }
  }

  /// Создать или обновить профиль заказчика
  Future<void> createOrUpdateCustomerProfile(CustomerProfile profile) async {
    try {
      await _firestore
          .collection('customer_profiles')
          .doc(profile.userId)
          .set(profile.toMap());
    } catch (e) {
      print('Ошибка сохранения профиля заказчика: $e');
      throw Exception('Ошибка сохранения профиля: $e');
    }
  }

  /// Получить профиль специалиста
  Future<SpecialistProfile?> getSpecialistProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('specialist_profiles').doc(userId).get();

      if (doc.exists) {
        return SpecialistProfile.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения профиля специалиста: $e');
      return null;
    }
  }

  /// Создать или обновить профиль специалиста
  Future<void> createOrUpdateSpecialistProfile(
    SpecialistProfile profile,
  ) async {
    try {
      await _firestore
          .collection('specialist_profiles')
          .doc(profile.userId)
          .set(profile.toMap());
    } catch (e) {
      print('Ошибка сохранения профиля специалиста: $e');
      throw Exception('Ошибка сохранения профиля: $e');
    }
  }

  /// Получить профиль пользователя (автоматически определяет тип)
  Future<dynamic> getUserProfile(String userId, UserRole role) async {
    switch (role) {
      case UserRole.customer:
        return getCustomerProfile(userId);
      case UserRole.specialist:
        return getSpecialistProfile(userId);
      case UserRole.organizer:
        return getCustomerProfile(userId); // Используем customer profile для organizer
      case UserRole.moderator:
        return null;
      case UserRole.guest:
        return null;
      case UserRole.admin:
        return null;
    }
  }

  /// Создать или обновить профиль пользователя
  Future<void> createOrUpdateUserProfile(profile, UserRole role) async {
    switch (role) {
      case UserRole.customer:
        if (profile is CustomerProfile) {
          await createOrUpdateCustomerProfile(profile);
        }
        break;
      case UserRole.specialist:
        if (profile is SpecialistProfile) {
          await createOrUpdateSpecialistProfile(profile);
        }
        break;
      case UserRole.organizer:
        if (profile is CustomerProfile) {
          await createOrUpdateCustomerProfile(profile);
        }
        break;
      case UserRole.moderator:
        // Модераторы не имеют специального профиля
        break;
      case UserRole.guest:
        throw Exception('Гости не могут иметь профили');
      case UserRole.admin:
        throw Exception('Админы не могут иметь профили');
    }
  }

  /// Загрузить фото профиля
  Future<String?> uploadProfilePhoto(String userId, String filePath) async {
    try {
      // В реальном приложении здесь была бы загрузка в Firebase Storage
      // Для демонстрации возвращаем фиктивный URL
      return 'https://example.com/profile_photos/$userId.jpg';
    } catch (e) {
      print('Ошибка загрузки фото: $e');
      return null;
    }
  }

  /// Загрузить элемент портфолио
  Future<String?> uploadPortfolioItem(
    String userId,
    String filePath,
    String type,
  ) async {
    try {
      // В реальном приложении здесь была бы загрузка в Firebase Storage
      // Для демонстрации возвращаем фиктивный URL
      return 'https://example.com/portfolio/$userId/${DateTime.now().millisecondsSinceEpoch}.$type';
    } catch (e) {
      print('Ошибка загрузки портфолио: $e');
      return null;
    }
  }

  /// Получить всех специалистов по категории
  Future<List<SpecialistProfile>> getSpecialistsByCategory(
    SpecialistCategory category,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('specialist_profiles')
          .where('categories', arrayContains: category.name)
          .orderBy('rating', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения специалистов по категории: $e');
      return [];
    }
  }

  /// Поиск специалистов
  Future<List<SpecialistProfile>> searchSpecialists({
    String? query,
    List<SpecialistCategory>? categories,
    double? minRating,
    double? maxHourlyRate,
    String? location,
  }) async {
    try {
      Query<Map<String, dynamic>> queryRef =
          _firestore.collection('specialist_profiles');

      // Фильтр по категориям
      if (categories != null && categories.isNotEmpty) {
        queryRef = queryRef.where(
          'categories',
          arrayContainsAny: categories.map((e) => e.name).toList(),
        );
      }

      // Фильтр по рейтингу
      if (minRating != null) {
        queryRef = queryRef.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Фильтр по цене
      if (maxHourlyRate != null) {
        queryRef =
            queryRef.where('hourlyRate', isLessThanOrEqualTo: maxHourlyRate);
      }

      // Фильтр по локации
      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      final querySnapshot =
          await queryRef.orderBy('rating', descending: true).limit(50).get();

      var specialists =
          querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();

      // Фильтр по текстовому запросу (если указан)
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        specialists = specialists
            .where(
              (specialist) =>
                  specialist.bio?.toLowerCase().contains(lowerQuery) ??
                  false ||
                      specialist.services.any(
                        (service) => service.toLowerCase().contains(lowerQuery),
                      ) ||
                      specialist.categoryDisplayNames.any(
                        (category) =>
                            category.toLowerCase().contains(lowerQuery),
                      ),
            )
            .toList();
      }

      return specialists;
    } catch (e) {
      print('Ошибка поиска специалистов: $e');
      return [];
    }
  }

  /// Получить топ специалистов
  Future<List<SpecialistProfile>> getTopSpecialists({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('specialist_profiles')
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения топ специалистов: $e');
      return [];
    }
  }

  /// Удалить профиль
  Future<void> deleteProfile(String userId, UserRole role) async {
    try {
      switch (role) {
        case UserRole.customer:
          await _firestore.collection('customer_profiles').doc(userId).delete();
          break;
        case UserRole.specialist:
          await _firestore
              .collection('specialist_profiles')
              .doc(userId)
              .delete();
          break;
        case UserRole.organizer:
          await _firestore.collection('customer_profiles').doc(userId).delete();
          break;
        case UserRole.moderator:
          throw Exception('Модераторы не могут иметь профили');
        case UserRole.guest:
          throw Exception('Гости не могут иметь профили');
        case UserRole.admin:
          throw Exception('Админы не могут иметь профили');
      }
    } catch (e) {
      print('Ошибка удаления профиля: $e');
      throw Exception('Ошибка удаления профиля: $e');
    }
  }

  /// Получить статистику профиля
  Future<Map<String, dynamic>> getProfileStats(
    String userId,
    UserRole role,
  ) async {
    try {
      var stats = <String, dynamic>{};

      if (role == UserRole.specialist) {
        // Статистика для специалиста
        final bookingsQuery = await _firestore
            .collection('bookings')
            .where('specialistId', isEqualTo: userId)
            .get();

        final reviewsQuery = await _firestore
            .collection('reviews')
            .where('specialistId', isEqualTo: userId)
            .get();

        stats = {
          'totalBookings': bookingsQuery.docs.length,
          'completedBookings': bookingsQuery.docs
              .where((doc) => doc.data()['status'] == 'completed')
              .length,
          'totalReviews': reviewsQuery.docs.length,
          'averageRating': reviewsQuery.docs.isNotEmpty
              ? reviewsQuery.docs
                      .map((doc) => doc.data()['rating'] as double)
                      .reduce((a, b) => a + b) /
                  reviewsQuery.docs.length
              : 0.0,
        };
      } else if (role == UserRole.customer) {
        // Статистика для заказчика
        final bookingsQuery = await _firestore
            .collection('bookings')
            .where('customerId', isEqualTo: userId)
            .get();

        stats = {
          'totalBookings': bookingsQuery.docs.length,
          'completedBookings': bookingsQuery.docs
              .where((doc) => doc.data()['status'] == 'completed')
              .length,
        };
      }

      return stats;
    } catch (e) {
      print('Ошибка получения статистики профиля: $e');
      return {};
    }
  }
}
