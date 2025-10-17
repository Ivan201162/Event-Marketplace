import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story.dart';

/// Сервис для работы со сторис
class StoryService {
  factory StoryService() => _instance;
  StoryService._internal();
  static final StoryService _instance = StoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'stories';

  /// Получить сторис специалиста
  Future<List<Story>> getStoriesBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('specialistId', isEqualTo: specialistId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Story.fromDocument).toList();
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestStories(specialistId);
    }
  }

  /// Получить все активные сторис
  Future<List<Story>> getAllActiveStories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Story.fromDocument).toList();
    } on Exception {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestStories('test_specialist');
    }
  }

  /// Создать сторис
  Future<String> createStory(Story story) async {
    try {
      final docRef = await _firestore.collection(_collection).add(story.toMap());
      return docRef.id;
    } on Exception catch (e) {
      throw Exception('Ошибка создания сторис: $e');
    }
  }

  /// Обновить сторис
  Future<void> updateStory(String storyId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(storyId).update(updates);
    } on Exception catch (e) {
      throw Exception('Ошибка обновления сторис: $e');
    }
  }

  /// Удалить сторис
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection(_collection).doc(storyId).delete();
    } on Exception catch (e) {
      throw Exception('Ошибка удаления сторис: $e');
    }
  }

  /// Отметить сторис как просмотренную
  Future<void> markStoryAsViewed(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection(_collection).doc(storyId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(storyRef);
        if (!snapshot.exists) return;

        final story = Story.fromDocument(snapshot);
        transaction.update(storyRef, {
          'viewsCount': story.viewsCount + 1,
        });
      });
    } on Exception catch (e) {
      throw Exception('Ошибка отметки просмотра: $e');
    }
  }

  /// Очистить истекшие сторис
  Future<void> cleanupExpiredStories() async {
    try {
      final expiredStories = await _firestore
          .collection(_collection)
          .where('expiresAt', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredStories.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on Exception catch (e) {
      throw Exception('Ошибка очистки истекших сторис: $e');
    }
  }

  /// Получить истории пользователя
  Future<List<Story>> getUserStories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('specialistId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: DateTime.now())
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Story.fromDocument).toList();
    } on Exception {
      return _getTestStories(userId);
    }
  }

  /// Лайкнуть историю
  Future<void> likeStory(String storyId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(storyId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } on Exception catch (e) {
      throw Exception('Ошибка лайка истории: $e');
    }
  }

  /// Тестовые данные
  List<Story> _getTestStories(String specialistId) {
    final now = DateTime.now();
    return [
      Story(
        id: '1',
        specialistId: specialistId,
        title: 'За кулисами',
        mediaUrl: 'https://placehold.co/400x600/FF6B6B/white?text=Behind+Scenes',
        thumbnailUrl: 'https://placehold.co/100x100/FF6B6B/white?text=S1',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
        viewsCount: 150,
      ),
      Story(
        id: '2',
        specialistId: specialistId,
        title: 'Новая работа',
        mediaUrl: 'https://placehold.co/400x600/4ECDC4/white?text=New+Work',
        thumbnailUrl: 'https://placehold.co/100x100/4ECDC4/white?text=S2',
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(hours: 19)),
        viewsCount: 80,
      ),
      Story(
        id: '3',
        specialistId: specialistId,
        title: 'Совет дня',
        mediaUrl: 'https://placehold.co/400x600/45B7D1/white?text=Tip+of+Day',
        thumbnailUrl: 'https://placehold.co/100x100/45B7D1/white?text=S3',
        createdAt: now.subtract(const Duration(hours: 8)),
        expiresAt: now.add(const Duration(hours: 16)),
        viewsCount: 200,
      ),
      Story(
        id: '4',
        specialistId: specialistId,
        title: 'Оборудование',
        mediaUrl: 'https://placehold.co/400x600/96CEB4/white?text=Equipment',
        thumbnailUrl: 'https://placehold.co/100x100/96CEB4/white?text=S4',
        createdAt: now.subtract(const Duration(hours: 12)),
        expiresAt: now.add(const Duration(hours: 12)),
        viewsCount: 120,
      ),
    ];
  }
}
