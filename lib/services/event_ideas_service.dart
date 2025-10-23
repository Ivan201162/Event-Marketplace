import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/logger.dart';
import '../models/event_idea.dart';
import '../models/event_idea_category.dart';
import '../models/favorite_idea.dart';
// import '../models/idea_comment.dart'; // Конфликт с EventIdea

/// Сервис для работы с идеями мероприятий
class EventIdeasService {
  factory EventIdeasService() => _instance;
  EventIdeasService._internal();

  static final EventIdeasService _instance = EventIdeasService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Получить все опубликованные идеи с пагинацией
  Future<List<EventIdea>> getPublishedIdeas({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    EventIdeaCategory? category,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore
          .collection('event_ideas')
          .where('status', isEqualTo: 'published')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final ideas = snapshot.docs
          .map((doc) => EventIdea.fromMap(doc.data()! as Map<String, dynamic>))
          .toList();

      // Фильтрация по поисковому запросу
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final filteredIdeas = ideas.where((idea) {
          final query = searchQuery.toLowerCase();
          return idea.title.toLowerCase().contains(query) ||
              idea.description.toLowerCase().contains(query) ||
              idea.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();

        AppLogger.logI(
            'Получено идей: ${filteredIdeas.length}', 'event_ideas_service');
        return filteredIdeas;
      }

      AppLogger.logI('Получено идей: ${ideas.length}', 'event_ideas_service');
      return ideas;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения идей', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Получить идеи пользователя
  Future<List<EventIdea>> getUserIdeas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final ideas =
          snapshot.docs.map((doc) => EventIdea.fromMap(doc.data())).toList();

      AppLogger.logI('Получено идей пользователя $userId: ${ideas.length}',
          'event_ideas_service');
      return ideas;
    } on Exception catch (e) {
      AppLogger.logE(
          'Ошибка получения идей пользователя', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Получить идею по ID
  Future<EventIdea?> getIdeaById(String ideaId) async {
    try {
      final doc = await _firestore.collection('event_ideas').doc(ideaId).get();

      if (!doc.exists) {
        return null;
      }

      final idea = EventIdea.fromMap(doc.data()!);

      // Увеличиваем счетчик просмотров
      await _incrementViews(ideaId);

      AppLogger.logI('Получена идея: $ideaId', 'event_ideas_service');
      return idea;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения идеи', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Создать новую идею
  Future<String> createIdea({
    required String title,
    required String description,
    required String imageUrl,
    required EventIdeaCategory category,
    required String createdBy,
    List<String>? tags,
    String? location,
    double? budget,
    int? duration,
    int? guestCount,
    String? season,
    String? style,
    List<String>? colorScheme,
    String? inspiration,
  }) async {
    try {
      final ideaId = _uuid.v4();
      final now = DateTime.now();

      final idea = EventIdea(
        id: ideaId,
        authorId: createdBy,
        title: title,
        description: description,
        images: [imageUrl],
        createdAt: now,
        category: category.name,
        imageUrl: imageUrl,
        createdBy: createdBy,
        tags: tags ?? [],
        location: location,
        budget: budget,
        duration: duration,
        guestCount: guestCount,
        season: season,
        style: style,
        colorScheme: colorScheme,
        inspiration: inspiration,
      );

      await _firestore.collection('event_ideas').doc(ideaId).set(idea.toMap());

      AppLogger.logI('Создана идея: $ideaId', 'event_ideas_service');
      return ideaId;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка создания идеи', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Обновить идею
  Future<void> updateIdea(String ideaId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection('event_ideas').doc(ideaId).update(updates);

      AppLogger.logI('Обновлена идея: $ideaId', 'event_ideas_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка обновления идеи', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).delete();

      AppLogger.logI('Удалена идея: $ideaId', 'event_ideas_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка удаления идеи', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Поставить лайк идее
  Future<void> likeIdea(String ideaId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Добавляем лайк в коллекцию лайков
      final likeRef =
          _firestore.collection('idea_likes').doc('${ideaId}_$userId');

      batch.set(likeRef, {
        'ideaId': ideaId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Увеличиваем счетчик лайков
      final ideaRef = _firestore.collection('event_ideas').doc(ideaId);
      batch.update(ideaRef, {'likes': FieldValue.increment(1)});

      await batch.commit();

      AppLogger.logI('Поставлен лайк идее: $ideaId', 'event_ideas_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка постановки лайка', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Убрать лайк с идеи
  Future<void> unlikeIdea(String ideaId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Удаляем лайк из коллекции лайков
      final likeRef =
          _firestore.collection('idea_likes').doc('${ideaId}_$userId');

      batch.delete(likeRef);

      // Уменьшаем счетчик лайков
      final ideaRef = _firestore.collection('event_ideas').doc(ideaId);
      batch.update(ideaRef, {'likes': FieldValue.increment(-1)});

      await batch.commit();

      AppLogger.logI('Убран лайк с идеи: $ideaId', 'event_ideas_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка убирания лайка', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Проверить, лайкнул ли пользователь идею
  Future<bool> isIdeaLiked(String ideaId, String userId) async {
    try {
      final doc = await _firestore
          .collection('idea_likes')
          .doc('${ideaId}_$userId')
          .get();

      return doc.exists;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка проверки лайка', 'event_ideas_service', e);
      return false;
    }
  }

  /// Добавить идею в избранное
  Future<void> addToFavorites(
    String ideaId,
    String userId, {
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final favoriteId = _uuid.v4();

      final favorite = FavoriteIdea(
        id: favoriteId,
        userId: userId,
        ideaId: ideaId,
        addedAt: DateTime.now(),
        notes: notes,
        tags: tags ?? [],
      );

      await _firestore
          .collection('favorite_ideas')
          .doc(favoriteId)
          .set(favorite.toMap());

      AppLogger.logI(
          'Добавлена в избранное идея: $ideaId', 'event_ideas_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка добавления в избранное', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Убрать идею из избранного
  Future<void> removeFromFavorites(String ideaId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorite_ideas')
          .where('ideaId', isEqualTo: ideaId)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      AppLogger.logI(
          'Убрана из избранного идея: $ideaId', 'event_ideas_service');
    } on Exception catch (e) {
      AppLogger.logE('Ошибка убирания из избранного', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Получить избранные идеи пользователя
  Future<List<EventIdea>> getFavoriteIdeas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorite_ideas')
          .where('userId', isEqualTo: userId)
          .orderBy('addedAt', descending: true)
          .get();

      final favoriteIds =
          snapshot.docs.map((doc) => doc.data()['ideaId'] as String).toList();

      if (favoriteIds.isEmpty) {
        return [];
      }

      final ideasSnapshot = await _firestore
          .collection('event_ideas')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .get();

      final ideas = ideasSnapshot.docs
          .map((doc) => EventIdea.fromMap(doc.data()))
          .toList();

      // Сортируем по дате добавления в избранное
      ideas.sort((a, b) {
        final aIndex = favoriteIds.indexOf(a.id);
        final bIndex = favoriteIds.indexOf(b.id);
        return aIndex.compareTo(bIndex);
      });

      AppLogger.logI(
          'Получено избранных идей: ${ideas.length}', 'event_ideas_service');
      return ideas;
    } on Exception catch (e) {
      AppLogger.logE(
          'Ошибка получения избранных идей', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Проверить, в избранном ли идея
  Future<bool> isIdeaInFavorites(String ideaId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorite_ideas')
          .where('ideaId', isEqualTo: ideaId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка проверки избранного', 'event_ideas_service', e);
      return false;
    }
  }

  /// Получить комментарии к идее
  Future<List<IdeaComment>> getIdeaComments(String ideaId) async {
    try {
      final snapshot = await _firestore
          .collection('idea_comments')
          .where('ideaId', isEqualTo: ideaId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .get();

      final comments =
          snapshot.docs.map((doc) => IdeaComment.fromMap(doc.data())).toList();

      AppLogger.logI(
        'Получено комментариев к идее $ideaId: ${comments.length}',
        'event_ideas_service',
      );
      return comments;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения комментариев', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Добавить комментарий к идее
  Future<String> addComment({
    required String ideaId,
    required String userId,
    required String userName,
    required String content,
    String? userAvatar,
    String? parentCommentId,
  }) async {
    try {
      final commentId = _uuid.v4();
      final now = DateTime.now();

      final comment = IdeaComment(
        id: commentId,
        ideaId: ideaId,
        authorId: userId,
        text: content,
        createdAt: now,
        authorName: userName,
        authorAvatar: userAvatar,
        parentId: parentCommentId,
      );

      final batch = _firestore.batch();

      // Добавляем комментарий
      batch.set(_firestore.collection('idea_comments').doc(commentId),
          comment.toMap());

      // Увеличиваем счетчик комментариев
      batch.update(_firestore.collection('event_ideas').doc(ideaId), {
        'commentsCount': FieldValue.increment(1),
      });

      await batch.commit();

      AppLogger.logI(
          'Добавлен комментарий к идее: $ideaId', 'event_ideas_service');
      return commentId;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка добавления комментария', 'event_ideas_service', e);
      rethrow;
    }
  }

  /// Увеличить счетчик просмотров
  Future<void> _incrementViews(String ideaId) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'views': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      AppLogger.logE('Ошибка увеличения просмотров', 'event_ideas_service', e);
    }
  }

  /// Получить похожие идеи
  Future<List<EventIdea>> getSimilarIdeas(String ideaId,
      {int limit = 5}) async {
    try {
      final idea = await getIdeaById(ideaId);
      if (idea == null) return [];

      final snapshot = await _firestore
          .collection('event_ideas')
          .where('category', isEqualTo: idea.category)
          .where('status', isEqualTo: 'published')
          .where('isPublic', isEqualTo: true)
          .where(FieldPath.documentId, isNotEqualTo: ideaId)
          .orderBy(FieldPath.documentId)
          .limit(limit)
          .get();

      final similarIdeas =
          snapshot.docs.map((doc) => EventIdea.fromMap(doc.data())).toList();

      AppLogger.logI('Получено похожих идей: ${similarIdeas.length}',
          'event_ideas_service');
      return similarIdeas;
    } on Exception catch (e) {
      AppLogger.logE('Ошибка получения похожих идей', 'event_ideas_service', e);
      return [];
    }
  }

  /// Получить рекомендуемые идеи для пользователя
  Future<List<EventIdea>> getRecommendedIdeas(String userId,
      {int limit = 10}) async {
    try {
      // Получаем избранные идеи пользователя для анализа предпочтений
      final favoriteIdeas = await getFavoriteIdeas(userId);

      if (favoriteIdeas.isEmpty) {
        // Если нет избранных, возвращаем популярные идеи
        return await getPublishedIdeas(limit: limit);
      }

      // Анализируем категории избранных идей
      final categoryCounts = <String, int>{};
      for (final idea in favoriteIdeas) {
        categoryCounts[idea.category ?? 'other'] =
            (categoryCounts[idea.category ?? 'other'] ?? 0) + 1;
      }

      // Получаем самую популярную категорию
      final topCategory = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Получаем идеи из этой категории
      final recommendedIdeas = await getPublishedIdeas(limit: limit);

      AppLogger.logI(
        'Получено рекомендуемых идей: ${recommendedIdeas.length}',
        'event_ideas_service',
      );
      return recommendedIdeas;
    } on Exception catch (e) {
      AppLogger.logE(
          'Ошибка получения рекомендуемых идей', 'event_ideas_service', e);
      return [];
    }
  }
}
