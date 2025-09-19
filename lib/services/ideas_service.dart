import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_idea.dart';

/// Сервис для работы с идеями мероприятий
class IdeasService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить все публичные идеи
  Future<List<EventIdea>> getPublicIdeas({
    String? category,
    String? eventType,
    String? budget,
    String? season,
    String? venue,
    List<String>? tags,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _db
        .collection('event_ideas')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    // Фильтры
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (eventType != null && eventType.isNotEmpty) {
      query = query.where('eventType', isEqualTo: eventType);
    }
    if (budget != null && budget.isNotEmpty) {
      query = query.where('budget', isEqualTo: budget);
    }
    if (season != null && season.isNotEmpty) {
      query = query.where('season', isEqualTo: season);
    }
    if (venue != null && venue.isNotEmpty) {
      query = query.where('venue', isEqualTo: venue);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map(EventIdea.fromDocument).toList();
  }

  /// Получить идеи по автору
  Future<List<EventIdea>> getIdeasByAuthor(String authorId) async {
    final querySnapshot = await _db
        .collection('event_ideas')
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map(EventIdea.fromDocument).toList();
  }

  /// Получить сохраненные идеи пользователя
  Future<List<EventIdea>> getSavedIdeas(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    final savedIdeaIds = List<String>.from(userDoc.data()?['savedIdeas'] ?? []);
    if (savedIdeaIds.isEmpty) return [];

    final querySnapshot = await _db
        .collection('event_ideas')
        .where(FieldPath.documentId, whereIn: savedIdeaIds)
        .get();

    return querySnapshot.docs.map(EventIdea.fromDocument).toList();
  }

  /// Создать новую идею
  Future<String> createIdea(EventIdea idea) async {
    final docRef = await _db.collection('event_ideas').add(idea.toMap());
    return docRef.id;
  }

  /// Обновить идею
  Future<void> updateIdea(String ideaId, EventIdea idea) async {
    await _db.collection('event_ideas').doc(ideaId).update(idea.toMap());
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    await _db.collection('event_ideas').doc(ideaId).delete();
  }

  /// Лайкнуть идею
  Future<void> likeIdea(String ideaId, String userId) async {
    final batch = _db.batch();

    // Добавить лайк в коллекцию лайков
    final likeRef = _db
        .collection('event_ideas')
        .doc(ideaId)
        .collection('likes')
        .doc(userId);
    batch.set(likeRef, {
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Увеличить счетчик лайков
    final ideaRef = _db.collection('event_ideas').doc(ideaId);
    batch.update(ideaRef, {
      'likesCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Убрать лайк с идеи
  Future<void> unlikeIdea(String ideaId, String userId) async {
    final batch = _db.batch();

    // Удалить лайк из коллекции лайков
    final likeRef = _db
        .collection('event_ideas')
        .doc(ideaId)
        .collection('likes')
        .doc(userId);
    batch.delete(likeRef);

    // Уменьшить счетчик лайков
    final ideaRef = _db.collection('event_ideas').doc(ideaId);
    batch.update(ideaRef, {
      'likesCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Сохранить идею
  Future<void> saveIdea(String ideaId, String userId) async {
    final batch = _db.batch();

    // Добавить в сохраненные идеи пользователя
    final userRef = _db.collection('users').doc(userId);
    batch.update(userRef, {
      'savedIdeas': FieldValue.arrayUnion([ideaId]),
    });

    // Увеличить счетчик сохранений
    final ideaRef = _db.collection('event_ideas').doc(ideaId);
    batch.update(ideaRef, {
      'savesCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Убрать из сохраненных
  Future<void> unsaveIdea(String ideaId, String userId) async {
    final batch = _db.batch();

    // Удалить из сохраненных идей пользователя
    final userRef = _db.collection('users').doc(userId);
    batch.update(userRef, {
      'savedIdeas': FieldValue.arrayRemove([ideaId]),
    });

    // Уменьшить счетчик сохранений
    final ideaRef = _db.collection('event_ideas').doc(ideaId);
    batch.update(ideaRef, {
      'savesCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Проверить, лайкнул ли пользователь идею
  Future<bool> isIdeaLiked(String ideaId, String userId) async {
    final likeDoc = await _db
        .collection('event_ideas')
        .doc(ideaId)
        .collection('likes')
        .doc(userId)
        .get();

    return likeDoc.exists;
  }

  /// Проверить, сохранена ли идея пользователем
  Future<bool> isIdeaSaved(String ideaId, String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    final savedIdeas = List<String>.from(userDoc.data()?['savedIdeas'] ?? []);
    return savedIdeas.contains(ideaId);
  }

  /// Поиск идей по тексту
  Future<List<EventIdea>> searchIdeas(String searchText) async {
    // Firestore не поддерживает полнотекстовый поиск,
    // поэтому используем простой поиск по заголовку и описанию
    final querySnapshot = await _db
        .collection('event_ideas')
        .where('isPublic', isEqualTo: true)
        .get();

    final ideas = querySnapshot.docs.map(EventIdea.fromDocument).toList();

    // Фильтруем на клиенте
    final searchLower = searchText.toLowerCase();
    return ideas
        .where(
          (idea) =>
              idea.title.toLowerCase().contains(searchLower) ||
              idea.description.toLowerCase().contains(searchLower) ||
              idea.tags.any((tag) => tag.toLowerCase().contains(searchLower)),
        )
        .toList();
  }

  /// Получить популярные идеи
  Future<List<EventIdea>> getPopularIdeas({int limit = 10}) async {
    final querySnapshot = await _db
        .collection('event_ideas')
        .where('isPublic', isEqualTo: true)
        .orderBy('likesCount', descending: true)
        .orderBy('savesCount', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map(EventIdea.fromDocument).toList();
  }

  /// Получить последние идеи
  Future<List<EventIdea>> getRecentIdeas({int limit = 10}) async {
    final querySnapshot = await _db
        .collection('event_ideas')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map(EventIdea.fromDocument).toList();
  }
}
