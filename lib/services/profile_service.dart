import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_profile.dart';
import '../models/organizer_profile.dart';
import '../models/specialist_profile.dart';
import '../models/user.dart';
import 'organizer_service.dart';

/// Сервис для управления профилями пользователей
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrganizerService _organizerService = OrganizerService();

  /// Получить профиль заказчика
  Future<CustomerProfile?> getCustomerProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('customer_profiles').doc(userId).get();

      if (doc.exists) {
        return CustomerProfile.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      print('Ошибка получения профиля специалиста: $e');
      return null;
    }
  }

  /// Создать или обновить профиль специалиста
  Future<void> createOrUpdateSpecialistProfile(
    SpecialistProfile profile,
  ) async {
    try {
      // Обновляем время последнего изменения
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('specialist_profiles')
          .doc(profile.userId)
          .set(updatedProfile.toMap(), SetOptions(merge: true));
    } on Exception catch (e) {
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
        return _organizerService.getOrganizerProfileByUserId(userId);
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
        if (profile is OrganizerProfile) {
          await _organizerService.createOrganizerProfile(profile);
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      print('Ошибка загрузки портфолио: $e');
      return null;
    }
  }

  /// Получить всех специалистов по категории
  Future<List<SpecialistProfile>> getSpecialistsByCategory(
    SpecialistCategory category, {
    int limit = 20,
    bool onlyAvailable = true,
    bool onlyVerified = false,
  }) async {
    try {
      var query = _firestore
          .collection('specialist_profiles')
          .where('categories', arrayContains: category.name);

      if (onlyAvailable) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      if (onlyVerified) {
        query = query.where('isVerified', isEqualTo: true);
      }

      final querySnapshot =
          await query.orderBy('rating', descending: true).limit(limit).get();

      return querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();
    } on Exception catch (e) {
      print('Ошибка получения специалистов по категории: $e');
      return [];
    }
  }

  /// Получить специалистов по нескольким категориям
  Future<List<SpecialistProfile>> getSpecialistsByCategories(
    List<SpecialistCategory> categories, {
    int limit = 20,
    bool onlyAvailable = true,
    bool onlyVerified = false,
  }) async {
    try {
      var query = _firestore.collection('specialist_profiles').where(
            'categories',
            arrayContainsAny: categories.map((e) => e.name).toList(),
          );

      if (onlyAvailable) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      if (onlyVerified) {
        query = query.where('isVerified', isEqualTo: true);
      }

      final querySnapshot =
          await query.orderBy('rating', descending: true).limit(limit).get();

      return querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();
    } on Exception catch (e) {
      print('Ошибка получения специалистов по категориям: $e');
      return [];
    }
  }

  /// Получить популярные категории специалистов
  Future<List<Map<String, dynamic>>> getPopularCategories({
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('specialist_profiles')
          .where('isAvailable', isEqualTo: true)
          .get();

      final categoryCounts = <String, int>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final categories = List<String>.from(data['categories'] ?? []);

        for (final category in categories) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories
          .take(limit)
          .map(
            (entry) => {
              'category': entry.key,
              'count': entry.value,
            },
          )
          .toList();
    } on Exception catch (e) {
      print('Ошибка получения популярных категорий: $e');
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
    bool? isAvailable,
    bool? isVerified,
    int? minExperienceYears,
    int? maxExperienceYears,
    List<String>? languages,
    List<String>? equipment,
    DateTime? availableDate,
  }) async {
    try {
      Query<Map<String, dynamic>> queryRef =
          _firestore.collection('specialist_profiles');

      // Фильтр по доступности
      if (isAvailable != null) {
        queryRef = queryRef.where('isAvailable', isEqualTo: isAvailable);
      }

      // Фильтр по верификации
      if (isVerified != null) {
        queryRef = queryRef.where('isVerified', isEqualTo: isVerified);
      }

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

      // Фильтр по опыту
      if (minExperienceYears != null) {
        queryRef = queryRef.where(
          'experienceYears',
          isGreaterThanOrEqualTo: minExperienceYears,
        );
      }
      if (maxExperienceYears != null) {
        queryRef = queryRef.where(
          'experienceYears',
          isLessThanOrEqualTo: maxExperienceYears,
        );
      }

      // Фильтр по локации
      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      // Фильтр по языкам
      if (languages != null && languages.isNotEmpty) {
        queryRef = queryRef.where('languages', arrayContainsAny: languages);
      }

      // Фильтр по оборудованию
      if (equipment != null && equipment.isNotEmpty) {
        queryRef = queryRef.where('equipment', arrayContainsAny: equipment);
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
                  specialist.name?.toLowerCase().contains(lowerQuery) ??
                  false || specialist.bio?.toLowerCase().contains(lowerQuery) ??
                  false ||
                      specialist.services.any(
                        (service) => service.toLowerCase().contains(lowerQuery),
                      ) ||
                      specialist.categoryDisplayNames.any(
                        (category) =>
                            category.toLowerCase().contains(lowerQuery),
                      ) ||
                      specialist.languages.any(
                        (lang) => lang.toLowerCase().contains(lowerQuery),
                      ) ||
                      specialist.equipment.any(
                        (eq) => eq.toLowerCase().contains(lowerQuery),
                      ),
            )
            .toList();
      }

      // Фильтр по доступности на дату
      if (availableDate != null) {
        specialists = specialists
            .where(
              (specialist) =>
                  specialist.isAvailable &&
                  !specialist.busyDates.any(
                    (busyDate) =>
                        busyDate.year == availableDate.year &&
                        busyDate.month == availableDate.month &&
                        busyDate.day == availableDate.day,
                  ),
            )
            .toList();
      }

      return specialists;
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      print('Ошибка получения статистики профиля: $e');
      return {};
    }
  }

  /// Обновить доступность специалиста
  Future<void> updateSpecialistAvailability(
    String userId,
    Map<String, dynamic> availability,
  ) async {
    try {
      await _firestore.collection('specialist_profiles').doc(userId).update({
        'availability': availability,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      print('Ошибка обновления доступности: $e');
      throw Exception('Не удалось обновить доступность');
    }
  }

  /// Добавить занятую дату
  Future<void> addBusyDate(String userId, DateTime date) async {
    try {
      final profile = await getSpecialistProfile(userId);
      if (profile != null) {
        final updatedProfile = profile.addBusyDate(date);
        await createOrUpdateSpecialistProfile(updatedProfile);
      }
    } on Exception catch (e) {
      print('Ошибка добавления занятой даты: $e');
      throw Exception('Не удалось добавить занятую дату');
    }
  }

  /// Удалить занятую дату
  Future<void> removeBusyDate(String userId, DateTime date) async {
    try {
      final profile = await getSpecialistProfile(userId);
      if (profile != null) {
        final updatedProfile = profile.removeBusyDate(date);
        await createOrUpdateSpecialistProfile(updatedProfile);
      }
    } on Exception catch (e) {
      print('Ошибка удаления занятой даты: $e');
      throw Exception('Не удалось удалить занятую дату');
    }
  }

  /// Получить занятые даты специалиста
  Future<List<DateTime>> getSpecialistBusyDates(String userId) async {
    try {
      final profile = await getSpecialistProfile(userId);
      return profile?.busyDates ?? [];
    } on Exception catch (e) {
      print('Ошибка получения занятых дат: $e');
      return [];
    }
  }

  /// Проверить доступность специалиста на дату
  Future<bool> isSpecialistAvailable(String userId, DateTime date) async {
    try {
      final profile = await getSpecialistProfile(userId);
      if (profile == null) return false;

      return profile.isAvailable &&
          !profile.busyDates.any(
            (busyDate) =>
                busyDate.year == date.year &&
                busyDate.month == date.month &&
                busyDate.day == date.day,
          );
    } on Exception catch (e) {
      print('Ошибка проверки доступности: $e');
      return false;
    }
  }
}
