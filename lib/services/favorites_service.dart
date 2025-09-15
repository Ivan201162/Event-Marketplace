import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

/// Сервис для работы с избранными событиями
class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить событие в избранное
  Future<void> addToFavorites(String userId, String eventId) async {
    try {
      await _firestore
          .collection('favorites')
          .doc('${userId}_$eventId')
          .set({
        'userId': userId,
        'eventId': eventId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка добавления в избранное: $e');
    }
  }

  /// Удалить событие из избранного
  Future<void> removeFromFavorites(String userId, String eventId) async {
    try {
      await _firestore
          .collection('favorites')
          .doc('${userId}_$eventId')
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления из избранного: $e');
    }
  }

  /// Получить избранные события пользователя
  Stream<List<Event>> getUserFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final eventIds = snapshot.docs.map((doc) => doc.data()['eventId'] as String).toList();
      
      if (eventIds.isEmpty) return <Event>[];

      final eventsSnapshot = await _firestore
          .collection('events')
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      return eventsSnapshot.docs
          .map((doc) => Event.fromDocument(doc))
          .toList();
    });
  }

  /// Проверить, добавлено ли событие в избранное
  Future<bool> isFavorite(String userId, String eventId) async {
    try {
      final doc = await _firestore
          .collection('favorites')
          .doc('${userId}_$eventId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Получить количество избранных событий пользователя
  Stream<int> getFavoritesCount(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Очистить все избранные события пользователя
  Future<void> clearAllFavorites(String userId) async {
    try {
      final batch = _firestore.batch();
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in favoritesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка очистки избранного: $e');
    }
  }
}
