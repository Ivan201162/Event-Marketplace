import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story.dart';

/// Сервис для работы с историями
class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить истории специалиста
  Stream<List<Story>> getSpecialistStories(String specialistId) => _firestore
      .collection('stories')
      .where('specialistId', isEqualTo: specialistId)
      .where('isActive', isEqualTo: true)
      .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('expiresAt')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Story.fromDocument).toList(),
      );

  /// Получить все активные истории
  Stream<List<Story>> getAllStories() => _firestore
      .collection('stories')
      .where('isActive', isEqualTo: true)
      .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('expiresAt')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Story.fromDocument).toList(),
      );

  /// Создать историю
  Future<String> createStory(Story story) async {
    try {
      final docRef = await _firestore.collection('stories').add(story.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания истории: $e');
    }
  }

  /// Обновить историю
  Future<void> updateStory(Story story) async {
    try {
      await _firestore
          .collection('stories')
          .doc(story.id)
          .update(story.toMap());
    } catch (e) {
      throw Exception('Ошибка обновления истории: $e');
    }
  }

  /// Удалить историю
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления истории: $e');
    }
  }

  /// Отметить историю как просмотренную
  Future<void> markAsViewed(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection('stories').doc(storyId);
      final storyDoc = await storyRef.get();

      if (!storyDoc.exists) {
        throw Exception('История не найдена');
      }

      final storyData = storyDoc.data();
      final viewedBy = List<String>.from(storyData?['viewedBy'] ?? []);

      if (!viewedBy.contains(userId)) {
        viewedBy.add(userId);
        await storyRef.update({
          'viewedBy': viewedBy,
          'viewsCount': viewedBy.length,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Ошибка отметки истории как просмотренной: $e');
    }
  }

  /// Получить истории по подпискам
  Stream<List<Story>> getStoriesBySubscriptions(List<String> specialistIds) {
    if (specialistIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('stories')
        .where('specialistId', whereIn: specialistIds)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Story.fromDocument).toList(),
        );
  }

  /// Очистить истекшие истории
  Future<void> cleanupExpiredStories() async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка очистки истекших историй: $e');
    }
  }

  /// Получить статистику историй специалиста
  Future<Map<String, dynamic>> getSpecialistStoryStats(
    String specialistId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final totalStories = querySnapshot.docs.length;
      var activeStories = 0;
      var totalViews = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == true &&
            (data['expiresAt'] as Timestamp).toDate().isAfter(DateTime.now())) {
          activeStories++;
        }
        totalViews += (data['viewsCount'] ?? 0) as int;
      }

      return {
        'totalStories': totalStories,
        'activeStories': activeStories,
        'totalViews': totalViews,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики историй: $e');
    }
  }

  /// Отметить историю как просмотренную (алиас для markAsViewed)
  Future<void> markStoryAsViewed(String storyId, String userId) async =>
      markAsViewed(storyId, userId);

  /// Лайкнуть историю
  Future<void> likeStory(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection('stories').doc(storyId);
      final storyDoc = await storyRef.get();

      if (!storyDoc.exists) {
        throw Exception('История не найдена');
      }

      final storyData = storyDoc.data();
      final likedBy = List<String>.from(storyData?['likedBy'] ?? []);

      if (!likedBy.contains(userId)) {
        likedBy.add(userId);
        await storyRef.update({
          'likedBy': likedBy,
          'likesCount': likedBy.length,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Ошибка лайка истории: $e');
    }
  }
}
