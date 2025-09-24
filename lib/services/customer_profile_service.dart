import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_profile.dart';
import '../models/booking.dart';

/// Сервис для работы с профилями заказчиков
class CustomerProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать профиль заказчика
  Future<String> createCustomerProfile(CustomerProfile profile) async {
    try {
      final docRef = await _firestore.collection('customer_profiles').add(profile.toMap());
      
      debugPrint('Customer profile created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating customer profile: $e');
      throw Exception('Ошибка создания профиля заказчика: $e');
    }
  }

  /// Обновить профиль заказчика
  Future<void> updateCustomerProfile(CustomerProfile profile) async {
    try {
      await _firestore.collection('customer_profiles').doc(profile.id).update({
        ...profile.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Customer profile updated: ${profile.id}');
    } catch (e) {
      debugPrint('Error updating customer profile: $e');
      throw Exception('Ошибка обновления профиля заказчика: $e');
    }
  }

  /// Получить профиль заказчика
  Stream<CustomerProfile?> getCustomerProfile(String customerId) {
    return _firestore
        .collection('customer_profiles')
        .where('userId', isEqualTo: customerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CustomerProfile.fromDocument(snapshot.docs.first);
    });
  }

  /// Получить профиль заказчика по ID
  Future<CustomerProfile?> getCustomerProfileById(String profileId) async {
    try {
      final doc = await _firestore.collection('customer_profiles').doc(profileId).get();
      if (!doc.exists) return null;
      
      return CustomerProfile.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting customer profile by ID: $e');
      return null;
    }
  }

  /// Добавить важную дату
  Future<void> addImportantDate(String customerId, ImportantDate importantDate) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      final profile = CustomerProfile.fromDocument(profileDoc);
      
      final updatedImportantDates = [...profile.importantDates, importantDate];
      
      await profileDoc.reference.update({
        'importantDates': updatedImportantDates.map((date) => date.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Important date added: ${importantDate.id}');
    } catch (e) {
      debugPrint('Error adding important date: $e');
      throw Exception('Ошибка добавления важной даты: $e');
    }
  }

  /// Обновить важную дату
  Future<void> updateImportantDate(String customerId, ImportantDate importantDate) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      final profile = CustomerProfile.fromDocument(profileDoc);
      
      final updatedImportantDates = profile.importantDates.map((date) {
        return date.id == importantDate.id ? importantDate : date;
      }).toList();
      
      await profileDoc.reference.update({
        'importantDates': updatedImportantDates.map((date) => date.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Important date updated: ${importantDate.id}');
    } catch (e) {
      debugPrint('Error updating important date: $e');
      throw Exception('Ошибка обновления важной даты: $e');
    }
  }

  /// Удалить важную дату
  Future<void> removeImportantDate(String customerId, String importantDateId) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      final profile = CustomerProfile.fromDocument(profileDoc);
      
      final updatedImportantDates = profile.importantDates
          .where((date) => date.id != importantDateId)
          .toList();
      
      await profileDoc.reference.update({
        'importantDates': updatedImportantDates.map((date) => date.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Important date removed: $importantDateId');
    } catch (e) {
      debugPrint('Error removing important date: $e');
      throw Exception('Ошибка удаления важной даты: $e');
    }
  }

  /// Добавить семейную фотографию
  Future<void> addFamilyPhoto(String customerId, String photoUrl) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'familyPhotos': FieldValue.arrayUnion([photoUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Family photo added: $photoUrl');
    } catch (e) {
      debugPrint('Error adding family photo: $e');
      throw Exception('Ошибка добавления семейной фотографии: $e');
    }
  }

  /// Удалить семейную фотографию
  Future<void> removeFamilyPhoto(String customerId, String photoUrl) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'familyPhotos': FieldValue.arrayRemove([photoUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Family photo removed: $photoUrl');
    } catch (e) {
      debugPrint('Error removing family photo: $e');
      throw Exception('Ошибка удаления семейной фотографии: $e');
    }
  }

  /// Добавить в избранные специалисты
  Future<void> addFavoriteSpecialist(String customerId, String specialistId) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'favoriteSpecialists': FieldValue.arrayUnion([specialistId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Favorite specialist added: $specialistId');
    } catch (e) {
      debugPrint('Error adding favorite specialist: $e');
      throw Exception('Ошибка добавления в избранные специалисты: $e');
    }
  }

  /// Удалить из избранных специалистов
  Future<void> removeFavoriteSpecialist(String customerId, String specialistId) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'favoriteSpecialists': FieldValue.arrayRemove([specialistId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Favorite specialist removed: $specialistId');
    } catch (e) {
      debugPrint('Error removing favorite specialist: $e');
      throw Exception('Ошибка удаления из избранных специалистов: $e');
    }
  }

  /// Добавить сохраненную идею
  Future<void> addSavedIdea(String customerId, String ideaId) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'savedIdeas': FieldValue.arrayUnion([ideaId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Saved idea added: $ideaId');
    } catch (e) {
      debugPrint('Error adding saved idea: $e');
      throw Exception('Ошибка добавления сохраненной идеи: $e');
    }
  }

  /// Удалить сохраненную идею
  Future<void> removeSavedIdea(String customerId, String ideaId) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'savedIdeas': FieldValue.arrayRemove([ideaId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Saved idea removed: $ideaId');
    } catch (e) {
      debugPrint('Error removing saved idea: $e');
      throw Exception('Ошибка удаления сохраненной идеи: $e');
    }
  }

  /// Обновить статистику заказчика
  Future<void> updateCustomerStats(String customerId, {
    int? totalBookings,
    double? totalSpent,
    double? averageRating,
  }) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (totalBookings != null) {
        updateData['totalBookings'] = FieldValue.increment(totalBookings);
      }
      if (totalSpent != null) {
        updateData['totalSpent'] = FieldValue.increment(totalSpent);
      }
      if (averageRating != null) {
        updateData['averageRating'] = averageRating;
      }

      await profileDoc.reference.update(updateData);
      
      debugPrint('Customer stats updated: $customerId');
    } catch (e) {
      debugPrint('Error updating customer stats: $e');
      throw Exception('Ошибка обновления статистики заказчика: $e');
    }
  }

  /// Получить историю заказов заказчика
  Stream<List<Booking>> getCustomerBookingHistory(String customerId) {
    return _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromDocument(doc)).toList();
    });
  }

  /// Получить предстоящие важные даты
  Future<List<ImportantDate>> getUpcomingImportantDates(String customerId) async {
    try {
      final profile = await getCustomerProfile(customerId).first;
      if (profile == null) return [];

      final now = DateTime.now();
      return profile.importantDates.where((date) => date.isUpcoming(now)).toList();
    } catch (e) {
      debugPrint('Error getting upcoming important dates: $e');
      return [];
    }
  }

  /// Получить напоминания о важных датах
  Future<List<ImportantDate>> getImportantDateReminders(String customerId) async {
    try {
      final profile = await getCustomerProfile(customerId).first;
      if (profile == null) return [];

      final now = DateTime.now();
      final reminders = <ImportantDate>[];

      for (final date in profile.importantDates) {
        if (!date.isActive) continue;

        final daysUntil = date.daysUntil(now);
        if (daysUntil >= 0 && date.reminderDays.contains(daysUntil)) {
          reminders.add(date);
        }
      }

      return reminders;
    } catch (e) {
      debugPrint('Error getting important date reminders: $e');
      return [];
    }
  }

  /// Обновить настройки приватности
  Future<void> updatePrivacySettings(String customerId, Map<String, dynamic> settings) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'privacySettings': settings,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Privacy settings updated: $customerId');
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      throw Exception('Ошибка обновления настроек приватности: $e');
    }
  }

  /// Обновить предпочтения
  Future<void> updatePreferences(String customerId, Map<String, dynamic> preferences) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      
      await profileDoc.reference.update({
        'preferences': preferences,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Preferences updated: $customerId');
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      throw Exception('Ошибка обновления предпочтений: $e');
    }
  }

  /// Получить статистику заказчика
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final profile = await getCustomerProfile(customerId).first;
      if (profile == null) return {};

      return {
        'totalBookings': profile.totalBookings,
        'totalSpent': profile.totalSpent,
        'averageRating': profile.averageRating,
        'favoriteSpecialistsCount': profile.favoriteSpecialists.length,
        'savedIdeasCount': profile.savedIdeas.length,
        'importantDatesCount': profile.importantDates.length,
        'familyPhotosCount': profile.familyPhotos.length,
        'profileCompletionPercentage': profile.profileCompletionPercentage,
        'isVerified': profile.isVerified,
        'memberSince': profile.createdAt,
      };
    } catch (e) {
      debugPrint('Error getting customer stats: $e');
      return {};
    }
  }

  /// Поиск заказчиков
  Stream<List<CustomerProfile>> searchCustomers(String query, {int limit = 20}) {
    return _firestore
        .collection('customer_profiles')
        .orderBy('displayName')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CustomerProfile.fromDocument(doc)).toList();
    });
  }

  /// Получить топ заказчиков по потраченным деньгам
  Future<List<CustomerProfile>> getTopCustomersBySpending({int limit = 10}) async {
    try {
      final customersQuery = await _firestore
          .collection('customer_profiles')
          .orderBy('totalSpent', descending: true)
          .limit(limit)
          .get();

      return customersQuery.docs.map((doc) => CustomerProfile.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting top customers by spending: $e');
      return [];
    }
  }

  /// Получить топ заказчиков по количеству заказов
  Future<List<CustomerProfile>> getTopCustomersByBookings({int limit = 10}) async {
    try {
      final customersQuery = await _firestore
          .collection('customer_profiles')
          .orderBy('totalBookings', descending: true)
          .limit(limit)
          .get();

      return customersQuery.docs.map((doc) => CustomerProfile.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting top customers by bookings: $e');
      return [];
    }
  }

  /// Удалить профиль заказчика
  Future<void> deleteCustomerProfile(String customerId) async {
    try {
      final profileQuery = await _firestore
          .collection('customer_profiles')
          .where('userId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (profileQuery.docs.isEmpty) {
        throw Exception('Профиль заказчика не найден');
      }

      final profileDoc = profileQuery.docs.first;
      await profileDoc.reference.delete();
      
      debugPrint('Customer profile deleted: $customerId');
    } catch (e) {
      debugPrint('Error deleting customer profile: $e');
      throw Exception('Ошибка удаления профиля заказчика: $e');
    }
  }
}