import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/feature_flags.dart';
import '../models/collection.dart';
import '../models/idea.dart';
import '../models/idea_filter.dart';
import '../models/idea_stats.dart';

/// Сервис для работы с идеями
class IdeaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все публичные идеи с пагинацией
  Stream<List<Idea>> getPublicIdeas({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? category,
    List<String>? tags,
  }) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    var query = _firestore
        .collection('ideas')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Idea.fromMap({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }),
              )
              .toList(),
        );
  }

  /// Получить идеи пользователя
  Stream<List<Idea>> getUserIdeas(String userId) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('ideas')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Idea.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Получить сохраненные идеи пользователя
  Stream<List<Idea>> getSavedIdeas(String userId) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('ideas')
        .where('savedBy', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Idea.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Создать новую идею
  Future<String> createIdea(Idea idea) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final docRef = await _firestore.collection('ideas').add(idea.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating idea: $e');
      throw Exception('Ошибка создания идеи: $e');
    }
  }

  /// Обновить идею
  Future<void> updateIdea(String ideaId, Map<String, dynamic> updates) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      await _firestore.collection('ideas').doc(ideaId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating idea: $e');
      throw Exception('Ошибка обновления идеи: $e');
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      await _firestore.collection('ideas').doc(ideaId).delete();
    } catch (e) {
      debugPrint('Error deleting idea: $e');
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Лайкнуть/убрать лайк с идеи
  Future<void> toggleLike(String ideaId, String userId) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final ideaRef = _firestore.collection('ideas').doc(ideaId);

      await _firestore.runTransaction((transaction) async {
        final ideaDoc = await transaction.get(ideaRef);
        if (!ideaDoc.exists) {
          throw Exception('Идея не найдена');
        }

        final idea = Idea.fromMap({
          'id': ideaDoc.id,
          ...ideaDoc.data()!,
        });

        final isLiked = idea.likedBy.contains(userId);
        final newLikedBy = List<String>.from(idea.likedBy);

        if (isLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        transaction.update(ideaRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error toggling like: $e');
      throw Exception('Ошибка изменения лайка: $e');
    }
  }

  /// Сохранить/убрать из сохраненных идею
  Future<void> toggleSave(String ideaId, String userId) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final ideaRef = _firestore.collection('ideas').doc(ideaId);

      await _firestore.runTransaction((transaction) async {
        final ideaDoc = await transaction.get(ideaRef);
        if (!ideaDoc.exists) {
          throw Exception('Идея не найдена');
        }

        final idea = Idea.fromMap({
          'id': ideaDoc.id,
          ...ideaDoc.data()!,
        });

        final isSaved = idea.savedBy.contains(userId);
        final newSavedBy = List<String>.from(idea.savedBy);

        if (isSaved) {
          newSavedBy.remove(userId);
        } else {
          newSavedBy.add(userId);
        }

        transaction.update(ideaRef, {
          'savedBy': newSavedBy,
          'savesCount': newSavedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error toggling save: $e');
      throw Exception('Ошибка изменения сохранения: $e');
    }
  }

  /// Поиск идей
  Stream<List<Idea>> searchIdeas({
    required String query,
    String? category,
    List<String>? tags,
    int limit = 20,
  }) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    var firestoreQuery =
        _firestore.collection('ideas').where('isPublic', isEqualTo: true);

    if (category != null) {
      firestoreQuery = firestoreQuery.where('category', isEqualTo: category);
    }

    if (tags != null && tags.isNotEmpty) {
      firestoreQuery = firestoreQuery.where('tags', arrayContainsAny: tags);
    }

    firestoreQuery =
        firestoreQuery.orderBy('createdAt', descending: true).limit(limit);

    return firestoreQuery.snapshots().map((snapshot) {
      final ideas = snapshot.docs
          .map(
            (doc) => Idea.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      // Фильтруем по тексту поиска
      if (query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        ideas.removeWhere(
          (idea) =>
              !idea.title.toLowerCase().contains(lowercaseQuery) &&
              !idea.description.toLowerCase().contains(lowercaseQuery) &&
              !idea.tags
                  .any((tag) => tag.toLowerCase().contains(lowercaseQuery)),
        );
      }

      return ideas;
    });
  }

  /// Получить популярные идеи
  Stream<List<Idea>> getPopularIdeas({int limit = 20}) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('ideas')
        .where('isPublic', isEqualTo: true)
        .orderBy('likesCount', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Idea.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Получить идеи по категории
  Stream<List<Idea>> getIdeasByCategory(String category, {int limit = 20}) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('ideas')
        .where('isPublic', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Idea.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Получить идею по ID
  Future<Idea?> getIdeaById(String ideaId) async {
    if (!FeatureFlags.ideasEnabled) {
      return null;
    }

    try {
      final doc = await _firestore.collection('ideas').doc(ideaId).get();
      if (!doc.exists) {
        return null;
      }

      return Idea.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('Error getting idea: $e');
      return null;
    }
  }

  /// Получить комментарии к идее
  Stream<List<IdeaComment>> getIdeaComments(String ideaId) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('idea_comments')
        .where('ideaId', isEqualTo: ideaId)
        .where('parentCommentId', isNull: true) // Только основные комментарии
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => IdeaComment.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Добавить комментарий к идее
  Future<String> addComment(IdeaComment comment) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final docRef =
          await _firestore.collection('idea_comments').add(comment.toMap());

      // Увеличиваем счетчик комментариев
      await _firestore.collection('ideas').doc(comment.ideaId).update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('Ошибка добавления комментария: $e');
    }
  }

  /// Лайкнуть/убрать лайк с комментария
  Future<void> toggleCommentLike(String commentId, String userId) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final commentRef = _firestore.collection('idea_comments').doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        if (!commentDoc.exists) {
          throw Exception('Комментарий не найден');
        }

        final comment = IdeaComment.fromMap({
          'id': commentDoc.id,
          ...commentDoc.data()!,
        });

        final isLiked = comment.likedBy.contains(userId);
        final newLikedBy = List<String>.from(comment.likedBy);

        if (isLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        transaction.update(commentRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      throw Exception('Ошибка изменения лайка комментария: $e');
    }
  }

  /// Получить идеи с фильтром
  Stream<List<Idea>> getIdeas(IdeaFilter filter) {
    var query = _firestore.collection('ideas');

    if (filter.category != null) {
      query = query.where('category', isEqualTo: filter.category);
    }

    if (filter.authorId != null) {
      query = query.where('authorId', isEqualTo: filter.authorId);
    }

    if (filter.tags != null && filter.tags!.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: filter.tags);
    }

    if (filter.isPublic != null) {
      query = query.where('isPublic', isEqualTo: filter.isPublic);
    }

    query = query.orderBy('createdAt', descending: true);

    if (filter.limit != null) {
      query = query.limit(filter.limit!);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Idea.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Получить идею по ID
  Future<Idea?> getIdea(String ideaId) async {
    try {
      final doc = await _firestore.collection('ideas').doc(ideaId).get();
      if (doc.exists) {
        return Idea.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting idea: $e');
      return null;
    }
  }

  /// Получить топ идеи недели
  Stream<List<Idea>> getTopIdeasOfWeek({int limit = 10}) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection('ideas')
        .where('isPublic', isEqualTo: true)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .orderBy('createdAt')
        .orderBy('likesCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Idea.fromMap(doc.data())).toList());
  }

  /// Получить коллекции пользователя
  Stream<List<Collection>> getUserCollections(String userId) => _firestore
      .collection('collections')
      .where('authorId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Collection.fromMap(doc.data())).toList(),
      );

  /// Получить статистику идей
  Future<IdeaStats> getIdeaStats(String ideaId) async {
    try {
      final idea = await getIdea(ideaId);
      if (idea == null) {
        throw Exception('Идея не найдена');
      }

      // Получить количество комментариев
      final commentsSnapshot = await _firestore
          .collection('idea_comments')
          .where('ideaId', isEqualTo: ideaId)
          .get();

      // Получить количество сохранений
      final savesSnapshot = await _firestore
          .collection('idea_saves')
          .where('ideaId', isEqualTo: ideaId)
          .get();

      return IdeaStats(
        ideaId: ideaId,
        likesCount: idea.likesCount,
        commentsCount: commentsSnapshot.docs.length,
        savesCount: savesSnapshot.docs.length,
        viewsCount: idea.viewsCount,
      );
    } catch (e) {
      debugPrint('Error getting idea stats: $e');
      throw Exception('Ошибка получения статистики идеи: $e');
    }
  }
}
