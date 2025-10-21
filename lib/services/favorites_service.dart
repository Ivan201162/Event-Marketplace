import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/specialist.dart';

/// Сервис для работы с избранными специалистами
class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'favorites';

  /// Добавить специалиста в избранное
  Future<void> addToFavorites({
    required String userId,
    required String specialistId,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc('${userId}_$specialistId').set({
        'userId': userId,
        'specialistId': specialistId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Ошибка добавления в избранное: $e');
      throw Exception('Не удалось добавить в избранное');
    }
  }

  /// Удалить специалиста из избранного
  Future<void> removeFromFavorites({
    required String userId,
    required String specialistId,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc('${userId}_$specialistId').delete();
    } catch (e) {
      debugPrint('Ошибка удаления из избранного: $e');
      throw Exception('Не удалось удалить из избранного');
    }
  }

  /// Проверить, находится ли специалист в избранном
  Future<bool> isFavorite({
    required String userId,
    required String specialistId,
  }) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc('${userId}_$specialistId').get();
      return doc.exists;
    } catch (e) {
      debugPrint('Ошибка проверки избранного: $e');
      return false;
    }
  }

  /// Получить список избранных специалистов
  Future<List<Specialist>> getFavoriteSpecialists(String userId) async {
    try {
      final favoritesSnapshot =
          await _firestore.collection(_collectionName).where('userId', isEqualTo: userId).get();

      if (favoritesSnapshot.docs.isEmpty) {
        return [];
      }

      final specialistIds =
          favoritesSnapshot.docs.map((doc) => doc.data()['specialistId'] as String).toList();

      final specialistsSnapshot = await _firestore
          .collection('specialists')
          .where(FieldPath.documentId, whereIn: specialistIds)
          .get();

      return specialistsSnapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      debugPrint('Ошибка получения избранных специалистов: $e');
      return [];
    }
  }

  /// Получить поток избранных специалистов
  Stream<List<Specialist>> getFavoriteSpecialistsStream(String userId) => _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((favoritesSnapshot) async {
        if (favoritesSnapshot.docs.isEmpty) {
          return <Specialist>[];
        }

        final specialistIds =
            favoritesSnapshot.docs.map((doc) => doc.data()['specialistId'] as String).toList();

        final specialistsSnapshot = await _firestore
            .collection('specialists')
            .where(FieldPath.documentId, whereIn: specialistIds)
            .get();

        return specialistsSnapshot.docs.map(Specialist.fromDocument).toList();
      });

  /// Получить количество избранных специалистов
  Future<int> getFavoritesCount(String userId) async {
    try {
      final snapshot =
          await _firestore.collection(_collectionName).where('userId', isEqualTo: userId).get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Ошибка получения количества избранных: $e');
      return 0;
    }
  }

  /// Переключить статус избранного
  Future<bool> toggleFavorite({
    required String userId,
    required String specialistId,
  }) async {
    try {
      final isCurrentlyFavorite = await isFavorite(
        userId: userId,
        specialistId: specialistId,
      );

      if (isCurrentlyFavorite) {
        await removeFromFavorites(
          userId: userId,
          specialistId: specialistId,
        );
        return false;
      } else {
        await addToFavorites(
          userId: userId,
          specialistId: specialistId,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Ошибка переключения избранного: $e');
      throw Exception('Не удалось изменить статус избранного');
    }
  }
}
