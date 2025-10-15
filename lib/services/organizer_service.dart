import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organizer_profile.dart';

/// Сервис для управления профилями организаторов
class OrganizerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать профиль организатора
  Future<void> createOrganizerProfile(OrganizerProfile profile) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(profile.id)
          .set(profile.toMap());
    } on Exception catch (e) {
      debugPrint('Ошибка создания профиля организатора: $e');
      throw Exception('Ошибка создания профиля организатора: $e');
    }
  }

  /// Получить профиль организатора по ID
  Future<OrganizerProfile?> getOrganizerProfile(String organizerId) async {
    try {
      final doc = await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .get();

      if (doc.exists) {
        return OrganizerProfile.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения профиля организатора: $e');
      return null;
    }
  }

  /// Получить профиль организатора по ID пользователя
  Future<OrganizerProfile?> getOrganizerProfileByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return OrganizerProfile.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения профиля организатора по userId: $e');
      return null;
    }
  }

  /// Обновить профиль организатора
  Future<void> updateOrganizerProfile(OrganizerProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('organizer_profiles')
          .doc(profile.id)
          .update(updatedProfile.toMap());
    } on Exception catch (e) {
      debugPrint('Ошибка обновления профиля организатора: $e');
      throw Exception('Ошибка обновления профиля организатора: $e');
    }
  }

  /// Удалить профиль организатора
  Future<void> deleteOrganizerProfile(String organizerId) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .delete();
    } on Exception catch (e) {
      debugPrint('Ошибка удаления профиля организатора: $e');
      throw Exception('Ошибка удаления профиля организатора: $e');
    }
  }

  /// Получить список всех активных организаторов
  Future<List<OrganizerProfile>> getAllActiveOrganizers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения списка организаторов: $e');
      return [];
    }
  }

  /// Получить организаторов по категории
  Future<List<OrganizerProfile>> getOrganizersByCategory(
    String category, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .where('categories', arrayContains: category)
          .orderBy('rating', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения организаторов по категории: $e');
      return [];
    }
  }

  /// Поиск организаторов по названию
  Future<List<OrganizerProfile>> searchOrganizers(
    String searchQuery, {
    int limit = 20,
  }) async {
    try {
      // Firestore не поддерживает полнотекстовый поиск, поэтому используем простой фильтр
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(limit)
          .get();

      final allOrganizers =
          querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();

      // Фильтруем результаты на клиенте
      final searchLower = searchQuery.toLowerCase();
      return allOrganizers
          .where(
            (organizer) =>
                organizer.name.toLowerCase().contains(searchLower) ||
                (organizer.description?.toLowerCase().contains(searchLower) ??
                    false) ||
                organizer.categories.any(
                  (category) => category.toLowerCase().contains(searchLower),
                ),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка поиска организаторов: $e');
      return [];
    }
  }

  /// Получить топ организаторов по рейтингу
  Future<List<OrganizerProfile>> getTopOrganizers({
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения топ организаторов: $e');
      return [];
    }
  }

  /// Получить организаторов рядом с локацией
  Future<List<OrganizerProfile>> getOrganizersNearLocation(
    String location, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .where('location', isEqualTo: location)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения организаторов по локации: $e');
      return [];
    }
  }

  /// Обновить рейтинг организатора
  Future<void> updateOrganizerRating(
    String organizerId,
    double newRating,
    int reviewCount,
  ) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .update({
        'rating': newRating,
        'reviewCount': reviewCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления рейтинга организатора: $e');
      throw Exception('Ошибка обновления рейтинга: $e');
    }
  }

  /// Добавить событие в портфолио
  Future<void> addEventToPortfolio(
    String organizerId,
    String eventId,
  ) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .update({
        'pastEvents': FieldValue.arrayUnion([eventId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления события в портфолио: $e');
      throw Exception('Ошибка добавления события: $e');
    }
  }

  /// Добавить изображение в портфолио
  Future<void> addPortfolioImage(
    String organizerId,
    String imageUrl,
  ) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .update({
        'portfolioImages': FieldValue.arrayUnion([imageUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления изображения в портфолио: $e');
      throw Exception('Ошибка добавления изображения: $e');
    }
  }

  /// Добавить видео в портфолио
  Future<void> addPortfolioVideo(
    String organizerId,
    String videoUrl,
  ) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .update({
        'portfolioVideos': FieldValue.arrayUnion([videoUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления видео в портфолио: $e');
      throw Exception('Ошибка добавления видео: $e');
    }
  }

  /// Добавить члена команды
  Future<void> addTeamMember(
    String organizerId,
    String specialistId,
  ) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .update({
        'teamMembers': FieldValue.arrayUnion([specialistId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления члена команды: $e');
      throw Exception('Ошибка добавления члена команды: $e');
    }
  }

  /// Удалить члена команды
  Future<void> removeTeamMember(
    String organizerId,
    String specialistId,
  ) async {
    try {
      await _firestore
          .collection('organizer_profiles')
          .doc(organizerId)
          .update({
        'teamMembers': FieldValue.arrayRemove([specialistId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка удаления члена команды: $e');
      throw Exception('Ошибка удаления члена команды: $e');
    }
  }

  /// Получить статистику организатора
  Future<Map<String, dynamic>> getOrganizerStats(String organizerId) async {
    try {
      final organizer = await getOrganizerProfile(organizerId);
      if (organizer == null) {
        return {};
      }

      // Получаем количество завершенных проектов
      final completedProjectsQuery = await _firestore
          .collection('bookings')
          .where('organizerId', isEqualTo: organizerId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Получаем количество активных проектов
      final activeProjectsQuery = await _firestore
          .collection('bookings')
          .where('organizerId', isEqualTo: organizerId)
          .where(
        'status',
        whereIn: ['pending', 'confirmed', 'in_progress'],
      ).get();

      return {
        'totalProjects': organizer.pastEvents.length,
        'completedProjects': completedProjectsQuery.docs.length,
        'activeProjects': activeProjectsQuery.docs.length,
        'rating': organizer.rating,
        'reviewCount': organizer.reviewCount,
        'teamSize': organizer.teamMembers.length,
        'experienceYears': organizer.experienceYears,
      };
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики организатора: $e');
      return {};
    }
  }

  /// Проверить, существует ли профиль организатора для пользователя
  Future<bool> hasOrganizerProfile(String userId) async {
    try {
      final profile = await getOrganizerProfileByUserId(userId);
      return profile != null;
    } on Exception catch (e) {
      debugPrint('Ошибка проверки профиля организатора: $e');
      return false;
    }
  }
}
