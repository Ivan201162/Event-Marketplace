import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story.dart';

/// Сервис для работы со сторис специалистов
class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'stories';

  /// Получить все активные сторис специалиста
  Future<List<Story>> getSpecialistStories(String specialistId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('specialistId', isEqualTo: specialistId)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Story.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки сторис: $e');
    }
  }

  /// Получить поток сторис специалиста
  Stream<List<Story>> getSpecialistStoriesStream(String specialistId) {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('specialistId', isEqualTo: specialistId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Story.fromDocument).toList(),
        );
  }

  /// Получить все активные сторис (для ленты)
  Future<List<Story>> getAllActiveStories() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Story.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки сторис: $e');
    }
  }

  /// Создать новый сторис
  Future<Story> createStory({
    required String specialistId,
    required String mediaUrl,
    String? text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final storyId = _firestore.collection(_collection).doc().id;
      final story = Story.create(
        id: storyId,
        specialistId: specialistId,
        mediaUrl: mediaUrl,
        text: text,
        metadata: metadata,
      );

      await _firestore.collection(_collection).doc(storyId).set(story.toMap());

      return story;
    } catch (e) {
      throw Exception('Ошибка создания сторис: $e');
    }
  }

  /// Отметить сторис как просмотренный
  Future<void> markStoryAsViewed(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection(_collection).doc(storyId);

      await _firestore.runTransaction((transaction) async {
        final storyDoc = await transaction.get(storyRef);

        if (!storyDoc.exists) {
          throw Exception('Сторис не найден');
        }

        final story = Story.fromDocument(storyDoc);
        final viewedBy = List<String>.from(story.viewedBy);

        if (!viewedBy.contains(userId)) {
          viewedBy.add(userId);

          transaction.update(storyRef, {
            'viewedBy': viewedBy,
            'viewsCount': viewedBy.length,
          });
        }
      });
    } catch (e) {
      throw Exception('Ошибка отметки просмотра: $e');
    }
  }

  /// Удалить сторис
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection(_collection).doc(storyId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления сторис: $e');
    }
  }

  /// Удалить истекшие сторис (для Cloud Functions)
  Future<void> deleteExpiredStories() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка удаления истекших сторис: $e');
    }
  }

  /// Получить статистику сторис специалиста
  Future<Map<String, int>> getStoryStats(String specialistId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('specialistId', isEqualTo: specialistId)
          .get();

      var totalStories = 0;
      var activeStories = 0;
      var totalViews = 0;

      for (final doc in querySnapshot.docs) {
        final story = Story.fromDocument(doc);
        totalStories++;

        if (!story.isExpired) {
          activeStories++;
        }

        totalViews += story.viewsCount;
      }

      return {
        'totalStories': totalStories,
        'activeStories': activeStories,
        'totalViews': totalViews,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики: $e');
    }
  }

  /// Проверить, просмотрел ли пользователь сторис
  Future<bool> hasViewedStory(String storyId, String userId) async {
    try {
      final storyDoc =
          await _firestore.collection(_collection).doc(storyId).get();

      if (!storyDoc.exists) return false;

      final story = Story.fromDocument(storyDoc);
      return story.hasViewedBy(userId);
    } catch (e) {
      return false;
    }
  }

  /// Получить все активные сторис
  Future<List<Story>> getAllStories() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Story.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки всех сторис: $e');
    }
  }

  /// Получить сторис пользователя (альтернативное название)
  Future<List<Story>> getUserStories(String userId) async =>
      getSpecialistStories(userId);

  /// Проверить, просмотрел ли пользователь сторис (альтернативное название)
  Future<bool> hasViewed(String storyId, String userId) async =>
      hasViewedStory(storyId, userId);

  /// Лайкнуть сторис
  Future<void> likeStory(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection(_collection).doc(storyId);

      await _firestore.runTransaction((transaction) async {
        final storyDoc = await transaction.get(storyRef);
        if (!storyDoc.exists) return;

        final story = Story.fromDocument(storyDoc);
        final currentLikes = story.likes;

        transaction.update(storyRef, {
          'metadata.likes': currentLikes + 1,
        });
      });
    } catch (e) {
      throw Exception('Ошибка лайка сторис: $e');
    }
  }
}
