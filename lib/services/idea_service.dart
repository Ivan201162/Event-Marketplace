import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/idea.dart';

/// Сервис для управления идеями
class IdeaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _ideasCollection = 'ideas';
  static const String _collectionsCollection = 'idea_collections';
  static const String _ideasStoragePath = 'ideas';

  /// Создать новую идею
  Future<String> createIdea({
    required String title,
    required String description,
    required List<File> imageFiles,
    File? videoFile,
    required IdeaCategory category,
    required List<String> tags,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Загружаем изображения
      final imageUrls = <String>[];
      for (final imageFile in imageFiles) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final storageRef = _storage
            .ref()
            .child('$_ideasStoragePath/$authorId/images/$fileName');

        final uploadTask = await storageRef.putFile(imageFile);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Загружаем видео (если есть)
      String? videoUrl;
      if (videoFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${videoFile.path.split('/').last}';
        final storageRef = _storage
            .ref()
            .child('$_ideasStoragePath/$authorId/videos/$fileName');

        final uploadTask = await storageRef.putFile(videoFile);
        videoUrl = await uploadTask.ref.getDownloadURL();
      }

      // Создаем идею
      final ideaId = '${authorId}_${DateTime.now().millisecondsSinceEpoch}';
      final idea = Idea(
        id: ideaId,
        title: title,
        description: description,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        category: category,
        tags: tags,
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: IdeaStatus.active,
        metadata: metadata,
      );

      await _firestore
          .collection(_ideasCollection)
          .doc(ideaId)
          .set(idea.toMap());

      return ideaId;
    } catch (e) {
      print('Ошибка создания идеи: $e');
      rethrow;
    }
  }

  /// Получить все активные идеи
  Future<List<Idea>> getAllIdeas({
    IdeaCategory? category,
    List<String>? tags,
    int limit = 50,
  }) async {
    try {
      var query = _firestore
          .collection(_ideasCollection)
          .where('status', isEqualTo: IdeaStatus.active.name)
          .orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(Idea.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения идей: $e');
      return [];
    }
  }

  /// Поток всех активных идей
  Stream<List<Idea>> getAllIdeasStream({
    IdeaCategory? category,
    List<String>? tags,
    int limit = 50,
  }) {
    var query = _firestore
        .collection(_ideasCollection)
        .where('status', isEqualTo: IdeaStatus.active.name)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(Idea.fromDocument).toList(),
        );
  }

  /// Получить идеи пользователя
  Future<List<Idea>> getUserIdeas(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ideasCollection)
          .where('authorId', isEqualTo: userId)
          .where('status', isEqualTo: IdeaStatus.active.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Idea.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения идей пользователя: $e');
      return [];
    }
  }

  /// Поток идей пользователя
  Stream<List<Idea>> getUserIdeasStream(String userId) => _firestore
      .collection(_ideasCollection)
      .where('authorId', isEqualTo: userId)
      .where('status', isEqualTo: IdeaStatus.active.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Idea.fromDocument).toList(),
      );

  /// Получить сохраненные идеи пользователя
  Future<List<Idea>> getSavedIdeas(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ideasCollection)
          .where('savedBy', arrayContains: userId)
          .where('status', isEqualTo: IdeaStatus.active.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Idea.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения сохраненных идей: $e');
      return [];
    }
  }

  /// Поток сохраненных идей пользователя
  Stream<List<Idea>> getSavedIdeasStream(String userId) => _firestore
      .collection(_ideasCollection)
      .where('savedBy', arrayContains: userId)
      .where('status', isEqualTo: IdeaStatus.active.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Idea.fromDocument).toList(),
      );

  /// Получить идею по ID
  Future<Idea?> getIdeaById(String ideaId) async {
    try {
      final doc =
          await _firestore.collection(_ideasCollection).doc(ideaId).get();
      if (doc.exists) {
        return Idea.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения идеи по ID: $e');
      return null;
    }
  }

  /// Поток идеи по ID
  Stream<Idea?> getIdeaStream(String ideaId) => _firestore
      .collection(_ideasCollection)
      .doc(ideaId)
      .snapshots()
      .map((doc) => doc.exists ? Idea.fromDocument(doc) : null);

  /// Лайкнуть идею
  Future<void> likeIdea(String ideaId, String userId) async {
    try {
      final ideaDoc =
          await _firestore.collection(_ideasCollection).doc(ideaId).get();
      if (!ideaDoc.exists) return;

      final idea = Idea.fromDocument(ideaDoc);
      if (idea.isLikedBy(userId)) return;

      final updatedIdea = idea.addLike(userId);

      await _firestore.collection(_ideasCollection).doc(ideaId).update({
        'likesCount': updatedIdea.likesCount,
        'likedBy': updatedIdea.likedBy,
      });
    } catch (e) {
      print('Ошибка лайка идеи: $e');
      rethrow;
    }
  }

  /// Убрать лайк с идеи
  Future<void> unlikeIdea(String ideaId, String userId) async {
    try {
      final ideaDoc =
          await _firestore.collection(_ideasCollection).doc(ideaId).get();
      if (!ideaDoc.exists) return;

      final idea = Idea.fromDocument(ideaDoc);
      if (!idea.isLikedBy(userId)) return;

      final updatedIdea = idea.removeLike(userId);

      await _firestore.collection(_ideasCollection).doc(ideaId).update({
        'likesCount': updatedIdea.likesCount,
        'likedBy': updatedIdea.likedBy,
      });
    } catch (e) {
      print('Ошибка убирания лайка с идеи: $e');
      rethrow;
    }
  }

  /// Сохранить идею
  Future<void> saveIdea(String ideaId, String userId) async {
    try {
      final ideaDoc =
          await _firestore.collection(_ideasCollection).doc(ideaId).get();
      if (!ideaDoc.exists) return;

      final idea = Idea.fromDocument(ideaDoc);
      if (idea.isSavedBy(userId)) return;

      final updatedIdea = idea.addSave(userId);

      await _firestore.collection(_ideasCollection).doc(ideaId).update({
        'savesCount': updatedIdea.savesCount,
        'savedBy': updatedIdea.savedBy,
      });
    } catch (e) {
      print('Ошибка сохранения идеи: $e');
      rethrow;
    }
  }

  /// Убрать идею из сохраненных
  Future<void> unsaveIdea(String ideaId, String userId) async {
    try {
      final ideaDoc =
          await _firestore.collection(_ideasCollection).doc(ideaId).get();
      if (!ideaDoc.exists) return;

      final idea = Idea.fromDocument(ideaDoc);
      if (!idea.isSavedBy(userId)) return;

      final updatedIdea = idea.removeSave(userId);

      await _firestore.collection(_ideasCollection).doc(ideaId).update({
        'savesCount': updatedIdea.savesCount,
        'savedBy': updatedIdea.savedBy,
      });
    } catch (e) {
      print('Ошибка убирания идеи из сохраненных: $e');
      rethrow;
    }
  }

  /// Добавить просмотр идеи
  Future<void> addView(String ideaId) async {
    try {
      await _firestore.collection(_ideasCollection).doc(ideaId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Ошибка добавления просмотра: $e');
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    try {
      final ideaDoc =
          await _firestore.collection(_ideasCollection).doc(ideaId).get();
      if (!ideaDoc.exists) return;

      final idea = Idea.fromDocument(ideaDoc);

      // Удаляем файлы из Storage
      try {
        for (final imageUrl in idea.imageUrls) {
          final storageRef = _storage.refFromURL(imageUrl);
          await storageRef.delete();
        }

        if (idea.videoUrl != null) {
          final videoRef = _storage.refFromURL(idea.videoUrl!);
          await videoRef.delete();
        }
      } catch (e) {
        print('Ошибка удаления файлов из Storage: $e');
      }

      // Удаляем документ из Firestore
      await _firestore.collection(_ideasCollection).doc(ideaId).delete();
    } catch (e) {
      print('Ошибка удаления идеи: $e');
      rethrow;
    }
  }

  /// Создать коллекцию идей
  Future<String> createCollection({
    required String userId,
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final collectionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final collection = IdeaCollection(
        id: collectionId,
        userId: userId,
        name: name,
        description: description,
        ideaIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: isPublic,
      );

      await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .set(collection.toMap());

      return collectionId;
    } catch (e) {
      print('Ошибка создания коллекции: $e');
      rethrow;
    }
  }

  /// Получить коллекции пользователя
  Future<List<IdeaCollection>> getUserCollections(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map(IdeaCollection.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения коллекций пользователя: $e');
      return [];
    }
  }

  /// Добавить идею в коллекцию
  Future<void> addIdeaToCollection(String collectionId, String ideaId) async {
    try {
      final collectionDoc = await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .get();
      if (!collectionDoc.exists) return;

      final collection = IdeaCollection.fromDocument(collectionDoc);
      if (collection.containsIdea(ideaId)) return;

      final updatedCollection = collection.addIdea(ideaId);

      await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .update({
        'ideaIds': updatedCollection.ideaIds,
        'updatedAt': Timestamp.fromDate(updatedCollection.updatedAt),
      });
    } catch (e) {
      print('Ошибка добавления идеи в коллекцию: $e');
      rethrow;
    }
  }

  /// Удалить идею из коллекции
  Future<void> removeIdeaFromCollection(
    String collectionId,
    String ideaId,
  ) async {
    try {
      final collectionDoc = await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .get();
      if (!collectionDoc.exists) return;

      final collection = IdeaCollection.fromDocument(collectionDoc);
      if (!collection.containsIdea(ideaId)) return;

      final updatedCollection = collection.removeIdea(ideaId);

      await _firestore
          .collection(_collectionsCollection)
          .doc(collectionId)
          .update({
        'ideaIds': updatedCollection.ideaIds,
        'updatedAt': Timestamp.fromDate(updatedCollection.updatedAt),
      });
    } catch (e) {
      print('Ошибка удаления идеи из коллекции: $e');
      rethrow;
    }
  }

  /// Поиск идей
  Future<List<Idea>> searchIdeas(String query) async {
    try {
      // Простой поиск по заголовку и описанию
      final titleQuery = await _firestore
          .collection(_ideasCollection)
          .where('status', isEqualTo: IdeaStatus.active.name)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      final descriptionQuery = await _firestore
          .collection(_ideasCollection)
          .where('status', isEqualTo: IdeaStatus.active.name)
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      final ideas = <Idea>[];
      final ideaIds = <String>{};

      for (final doc in titleQuery.docs) {
        if (!ideaIds.contains(doc.id)) {
          ideas.add(Idea.fromDocument(doc));
          ideaIds.add(doc.id);
        }
      }

      for (final doc in descriptionQuery.docs) {
        if (!ideaIds.contains(doc.id)) {
          ideas.add(Idea.fromDocument(doc));
          ideaIds.add(doc.id);
        }
      }

      return ideas;
    } catch (e) {
      print('Ошибка поиска идей: $e');
      return [];
    }
  }

  /// Получить популярные идеи
  Future<List<Idea>> getPopularIdeas({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ideasCollection)
          .where('status', isEqualTo: IdeaStatus.active.name)
          .orderBy('likesCount', descending: true)
          .orderBy('viewsCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Idea.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения популярных идей: $e');
      return [];
    }
  }

  /// Получить статистику идей
  Future<IdeaStats> getIdeaStats(String userId) async {
    try {
      final ideas = await getUserIdeas(userId);
      return IdeaStats.fromIdeas(ideas);
    } catch (e) {
      print('Ошибка получения статистики идей: $e');
      return const IdeaStats(
        totalIdeas: 0,
        totalLikes: 0,
        totalSaves: 0,
        totalViews: 0,
        categoryStats: {},
        topTags: [],
      );
    }
  }
}
