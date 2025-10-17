import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/feature_flags.dart';
import '../models/idea.dart';

/// Сервис для работы с коллекциями идей
class CollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все публичные коллекции
  Stream<List<IdeaCollection>> getPublicCollections({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    var query = _firestore
        .collection('idea_collections')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => IdeaCollection.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Получить коллекции пользователя
  Stream<List<IdeaCollection>> getUserCollections(String userId) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('idea_collections')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => IdeaCollection.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Получить коллекции, на которые подписан пользователь
  Stream<List<IdeaCollection>> getFollowedCollections(String userId) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('idea_collections')
        .where('followers', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => IdeaCollection.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  /// Создать новую коллекцию
  Future<String> createCollection(IdeaCollection collection) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final docRef = await _firestore.collection('idea_collections').add(collection.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating collection: $e');
      throw Exception('Ошибка создания коллекции: $e');
    }
  }

  /// Обновить коллекцию
  Future<void> updateCollection(
    String collectionId,
    Map<String, dynamic> updates,
  ) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      await _firestore.collection('idea_collections').doc(collectionId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating collection: $e');
      throw Exception('Ошибка обновления коллекции: $e');
    }
  }

  /// Удалить коллекцию
  Future<void> deleteCollection(String collectionId) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      await _firestore.collection('idea_collections').doc(collectionId).delete();
    } catch (e) {
      debugPrint('Error deleting collection: $e');
      throw Exception('Ошибка удаления коллекции: $e');
    }
  }

  /// Подписаться/отписаться от коллекции
  Future<void> toggleFollow(String collectionId, String userId) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final collectionRef = _firestore.collection('idea_collections').doc(collectionId);

      await _firestore.runTransaction((transaction) async {
        final collectionDoc = await transaction.get(collectionRef);
        if (!collectionDoc.exists) {
          throw Exception('Коллекция не найдена');
        }

        final collection = IdeaCollection.fromMap({
          'id': collectionDoc.id,
          ...collectionDoc.data()!,
        });

        final isFollowing = collection.followers.contains(userId);
        final newFollowers = List<String>.from(collection.followers);

        if (isFollowing) {
          newFollowers.remove(userId);
        } else {
          newFollowers.add(userId);
        }

        transaction.update(collectionRef, {
          'followers': newFollowers,
          'followersCount': newFollowers.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      throw Exception('Ошибка изменения подписки: $e');
    }
  }

  /// Добавить идею в коллекцию
  Future<void> addIdeaToCollection(String collectionId, String ideaId) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final collectionRef = _firestore.collection('idea_collections').doc(collectionId);

      await _firestore.runTransaction((transaction) async {
        final collectionDoc = await transaction.get(collectionRef);
        if (!collectionDoc.exists) {
          throw Exception('Коллекция не найдена');
        }

        final collection = IdeaCollection.fromMap({
          'id': collectionDoc.id,
          ...collectionDoc.data()!,
        });

        if (collection.ideaIds.contains(ideaId)) {
          throw Exception('Идея уже добавлена в коллекцию');
        }

        final newIdeaIds = List<String>.from(collection.ideaIds)..add(ideaId);

        // Получаем изображения идеи для превью
        final ideaDoc = await transaction.get(_firestore.collection('ideas').doc(ideaId));
        if (ideaDoc.exists) {
          final idea = Idea.fromMap({
            'id': ideaDoc.id,
            ...ideaDoc.data()!,
          });

          final newImages = List<String>.from(collection.images);
          if (idea.images.isNotEmpty && !newImages.contains(idea.images.first)) {
            newImages.add(idea.images.first);
            // Ограничиваем количество превью
            if (newImages.length > 4) {
              newImages.removeAt(0);
            }
          }

          transaction.update(collectionRef, {
            'ideaIds': newIdeaIds,
            'images': newImages,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(collectionRef, {
            'ideaIds': newIdeaIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error adding idea to collection: $e');
      throw Exception('Ошибка добавления идеи в коллекцию: $e');
    }
  }

  /// Удалить идею из коллекции
  Future<void> removeIdeaFromCollection(
    String collectionId,
    String ideaId,
  ) async {
    if (!FeatureFlags.ideasEnabled) {
      throw Exception('Функция идей отключена');
    }

    try {
      final collectionRef = _firestore.collection('idea_collections').doc(collectionId);

      await _firestore.runTransaction((transaction) async {
        final collectionDoc = await transaction.get(collectionRef);
        if (!collectionDoc.exists) {
          throw Exception('Коллекция не найдена');
        }

        final collection = IdeaCollection.fromMap({
          'id': collectionDoc.id,
          ...collectionDoc.data()!,
        });

        final newIdeaIds = List<String>.from(collection.ideaIds)..remove(ideaId);

        // Удаляем изображение идеи из превью, если оно есть
        final ideaDoc = await transaction.get(_firestore.collection('ideas').doc(ideaId));
        if (ideaDoc.exists) {
          final idea = Idea.fromMap({
            'id': ideaDoc.id,
            ...ideaDoc.data()!,
          });

          final newImages = List<String>.from(collection.images);
          if (idea.images.isNotEmpty) {
            newImages.remove(idea.images.first);
          }

          transaction.update(collectionRef, {
            'ideaIds': newIdeaIds,
            'images': newImages,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(collectionRef, {
            'ideaIds': newIdeaIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error removing idea from collection: $e');
      throw Exception('Ошибка удаления идеи из коллекции: $e');
    }
  }

  /// Получить коллекцию по ID
  Future<IdeaCollection?> getCollectionById(String collectionId) async {
    if (!FeatureFlags.ideasEnabled) {
      return null;
    }

    try {
      final doc = await _firestore.collection('idea_collections').doc(collectionId).get();
      if (!doc.exists) {
        return null;
      }

      return IdeaCollection.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('Error getting collection: $e');
      return null;
    }
  }

  /// Получить идеи из коллекции
  Stream<List<Idea>> getCollectionIdeas(String collectionId) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('idea_collections')
        .doc(collectionId)
        .snapshots()
        .asyncMap((collectionDoc) async {
      if (!collectionDoc.exists) {
        return <Idea>[];
      }

      final collection = IdeaCollection.fromMap({
        'id': collectionDoc.id,
        ...collectionDoc.data()!,
      });

      if (collection.ideaIds.isEmpty) {
        return <Idea>[];
      }

      // Получаем идеи по ID
      final ideas = <Idea>[];
      for (final ideaId in collection.ideaIds) {
        final ideaDoc = await _firestore.collection('ideas').doc(ideaId).get();
        if (ideaDoc.exists) {
          ideas.add(
            Idea.fromMap({
              'id': ideaDoc.id,
              ...ideaDoc.data()!,
            }),
          );
        }
      }

      return ideas;
    });
  }

  /// Поиск коллекций
  Stream<List<IdeaCollection>> searchCollections({
    required String query,
    int limit = 20,
  }) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('idea_collections')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final collections = snapshot.docs
          .map(
            (doc) => IdeaCollection.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();

      // Фильтруем по тексту поиска
      if (query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        collections.removeWhere(
          (collection) =>
              !collection.name.toLowerCase().contains(lowercaseQuery) &&
              !collection.description.toLowerCase().contains(lowercaseQuery),
        );
      }

      return collections;
    });
  }

  /// Получить популярные коллекции
  Stream<List<IdeaCollection>> getPopularCollections({int limit = 20}) {
    if (!FeatureFlags.ideasEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('idea_collections')
        .where('isPublic', isEqualTo: true)
        .orderBy('followersCount', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => IdeaCollection.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }
}
