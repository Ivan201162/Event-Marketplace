import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/idea.dart';

/// Сервис для работы с идеями
class IdeaService {
  static final IdeaService _instance = IdeaService._internal();
  factory IdeaService() => _instance;
  IdeaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Создать идею
  Future<String?> createIdea({
    required String title,
    required String description,
    required String category,
    required String authorId,
    required String authorName,
    List<String>? tags,
    IdeaType type = IdeaType.general,
    String? authorPhotoUrl,
    List<IdeaImage>? images,
    bool isPublic = true,
  }) async {
    try {
      final ideaRef = _firestore.collection('ideas').doc();
      
      final idea = Idea(
        id: ideaRef.id,
        title: title,
        description: description,
        category: category,
        tags: tags ?? [],
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        status: IdeaStatus.published,
        type: type,
        images: images ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ideaRef.set(idea.toMap());
      return ideaRef.id;
    } catch (e) {
      print('Ошибка создания идеи: $e');
      return null;
    }
  }

  /// Получить идеи
  Stream<List<Idea>> getIdeas(IdeaFilter filter) {
    Query query = _firestore.collection('ideas');

    // Применяем фильтры
    if (filter.category != null) {
      query = query.where('category', isEqualTo: filter.category);
    }

    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.name);
    }

    if (filter.type != null) {
      query = query.where('type', isEqualTo: filter.type!.name);
    }

    if (filter.authorId != null) {
      query = query.where('authorId', isEqualTo: filter.authorId);
    }

    if (filter.isPublic != null) {
      query = query.where('isPublic', isEqualTo: filter.isPublic);
    }

    if (filter.isFeatured != null) {
      query = query.where('isFeatured', isEqualTo: filter.isFeatured);
    }

    if (filter.startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!));
    }

    if (filter.endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!));
    }

    // Сортировка
    switch (filter.sortBy) {
      case IdeaSortBy.date:
        query = query.orderBy('createdAt', descending: !filter.sortAscending);
        break;
      case IdeaSortBy.likes:
        query = query.orderBy('likesCount', descending: !filter.sortAscending);
        break;
      case IdeaSortBy.views:
        query = query.orderBy('viewsCount', descending: !filter.sortAscending);
        break;
      case IdeaSortBy.saves:
        query = query.orderBy('savesCount', descending: !filter.sortAscending);
        break;
      case IdeaSortBy.comments:
        query = query.orderBy('commentsCount', descending: !filter.sortAscending);
        break;
      case IdeaSortBy.title:
        query = query.orderBy('title', descending: !filter.sortAscending);
        break;
    }

    return query.snapshots().map((snapshot) {
      var ideas = snapshot.docs
          .map((doc) => Idea.fromDocument(doc))
          .toList();

      // Применяем фильтры, которые нельзя применить в Firestore
      if (filter.tags != null && filter.tags!.isNotEmpty) {
        ideas = ideas.where((idea) => 
            idea.tags.any((tag) => filter.tags!.contains(tag))).toList();
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        ideas = ideas.where((idea) => 
            idea.title.toLowerCase().contains(query) ||
            idea.description.toLowerCase().contains(query) ||
            idea.tags.any((tag) => tag.toLowerCase().contains(query))).toList();
      }

      return ideas;
    });
  }

  /// Получить идею по ID
  Future<Idea?> getIdea(String ideaId) async {
    try {
      final doc = await _firestore.collection('ideas').doc(ideaId).get();
      if (doc.exists) {
        return Idea.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения идеи: $e');
      return null;
    }
  }

  /// Обновить идею
  Future<bool> updateIdea(Idea idea) async {
    try {
      await _firestore.collection('ideas').doc(idea.id).update(idea.toMap());
      return true;
    } catch (e) {
      print('Ошибка обновления идеи: $e');
      return false;
    }
  }

  /// Удалить идею
  Future<bool> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).update({
        'status': IdeaStatus.deleted.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Ошибка удаления идеи: $e');
      return false;
    }
  }

  /// Лайкнуть идею
  Future<bool> likeIdea(String ideaId, String userId) async {
    try {
      final idea = await getIdea(ideaId);
      if (idea == null) return false;

      // Проверяем, не лайкнул ли уже пользователь
      if (idea.isLikedBy(userId)) {
        return await unlikeIdea(ideaId, userId);
      }

      final updatedLikedBy = [...idea.likedBy, userId];
      final updatedIdea = idea.copyWith(
        likedBy: updatedLikedBy,
        likesCount: updatedLikedBy.length,
        updatedAt: DateTime.now(),
      );

      return await updateIdea(updatedIdea);
    } catch (e) {
      print('Ошибка лайка идеи: $e');
      return false;
    }
  }

  /// Убрать лайк с идеи
  Future<bool> unlikeIdea(String ideaId, String userId) async {
    try {
      final idea = await getIdea(ideaId);
      if (idea == null) return false;

      final updatedLikedBy = idea.likedBy.where((id) => id != userId).toList();
      final updatedIdea = idea.copyWith(
        likedBy: updatedLikedBy,
        likesCount: updatedLikedBy.length,
        updatedAt: DateTime.now(),
      );

      return await updateIdea(updatedIdea);
    } catch (e) {
      print('Ошибка удаления лайка: $e');
      return false;
    }
  }

  /// Сохранить идею
  Future<bool> saveIdea(String ideaId, String userId) async {
    try {
      final idea = await getIdea(ideaId);
      if (idea == null) return false;

      // Проверяем, не сохранил ли уже пользователь
      if (idea.isSavedBy(userId)) {
        return await unsaveIdea(ideaId, userId);
      }

      final updatedSavedBy = [...idea.savedBy, userId];
      final updatedIdea = idea.copyWith(
        savedBy: updatedSavedBy,
        savesCount: updatedSavedBy.length,
        updatedAt: DateTime.now(),
      );

      return await updateIdea(updatedIdea);
    } catch (e) {
      print('Ошибка сохранения идеи: $e');
      return false;
    }
  }

  /// Убрать идею из сохраненных
  Future<bool> unsaveIdea(String ideaId, String userId) async {
    try {
      final idea = await getIdea(ideaId);
      if (idea == null) return false;

      final updatedSavedBy = idea.savedBy.where((id) => id != userId).toList();
      final updatedIdea = idea.copyWith(
        savedBy: updatedSavedBy,
        savesCount: updatedSavedBy.length,
        updatedAt: DateTime.now(),
      );

      return await updateIdea(updatedIdea);
    } catch (e) {
      print('Ошибка удаления из сохраненных: $e');
      return false;
    }
  }

  /// Увеличить счетчик просмотров
  Future<void> incrementViewsCount(String ideaId) async {
    try {
      final idea = await getIdea(ideaId);
      if (idea == null) return;

      final updatedIdea = idea.copyWith(
        viewsCount: idea.viewsCount + 1,
        updatedAt: DateTime.now(),
      );

      await updateIdea(updatedIdea);
    } catch (e) {
      print('Ошибка увеличения счетчика просмотров: $e');
    }
  }

  /// Добавить комментарий к идее
  Future<String?> addComment({
    required String ideaId,
    required String authorId,
    required String authorName,
    required String content,
    String? authorPhotoUrl,
  }) async {
    try {
      final commentRef = _firestore.collection('idea_comments').doc();
      
      final comment = IdeaComment(
        id: commentRef.id,
        ideaId: ideaId,
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await commentRef.set(comment.toMap());

      // Обновляем счетчик комментариев в идее
      final idea = await getIdea(ideaId);
      if (idea != null) {
        final updatedComments = [...idea.comments, comment];
        final updatedIdea = idea.copyWith(
          comments: updatedComments,
          commentsCount: updatedComments.length,
          updatedAt: DateTime.now(),
        );
        await updateIdea(updatedIdea);
      }

      return commentRef.id;
    } catch (e) {
      print('Ошибка добавления комментария: $e');
      return null;
    }
  }

  /// Получить комментарии идеи
  Stream<List<IdeaComment>> getIdeaComments(String ideaId) {
    return _firestore
        .collection('idea_comments')
        .where('ideaId', isEqualTo: ideaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IdeaComment.fromMap(doc.data()))
          .toList();
    });
  }

  /// Загрузить изображение идеи
  Future<IdeaImage?> uploadIdeaImage(XFile imageFile, {String? caption}) async {
    try {
      final fileName = 'idea_image_${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('idea_images/$fileName');
      
      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return IdeaImage(
        id: _uuid.v4(),
        url: downloadUrl,
        thumbnailUrl: downloadUrl, // Для простоты используем оригинал как thumbnail
        caption: caption,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Ошибка загрузки изображения идеи: $e');
      return null;
    }
  }

  /// Выбрать изображения из галереи
  Future<List<XFile>> pickImages({int maxImages = 10}) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images.take(maxImages).toList();
    } catch (e) {
      print('Ошибка выбора изображений: $e');
      return [];
    }
  }

  /// Снять фото
  Future<XFile?> takePhoto() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      print('Ошибка съемки фото: $e');
      return null;
    }
  }

  /// Получить топ идеи недели
  Stream<List<Idea>> getTopIdeasOfWeek() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final filter = IdeaFilter(
      startDate: weekAgo,
      isPublic: true,
      sortBy: IdeaSortBy.likes,
    );
    return getIdeas(filter);
  }

  /// Получить идеи пользователя
  Stream<List<Idea>> getUserIdeas(String userId) {
    final filter = IdeaFilter(
      authorId: userId,
      status: IdeaStatus.published,
    );
    return getIdeas(filter);
  }

  /// Получить сохраненные идеи пользователя
  Stream<List<Idea>> getSavedIdeas(String userId) {
    return _firestore
        .collection('ideas')
        .where('savedBy', arrayContains: userId)
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Idea.fromDocument(doc))
          .toList();
    });
  }

  /// Получить статистику идей
  Future<IdeaStats> getIdeaStats() async {
    try {
      final snapshot = await _firestore.collection('ideas').get();
      final ideas = snapshot.docs.map((doc) => Idea.fromDocument(doc)).toList();

      return _calculateIdeaStats(ideas);
    } catch (e) {
      print('Ошибка получения статистики идей: $e');
      return IdeaStats.empty();
    }
  }

  /// Создать коллекцию идей
  Future<String?> createIdeaCollection({
    required String name,
    required String description,
    required String userId,
    List<String>? ideaIds,
    bool isPublic = false,
  }) async {
    try {
      final collectionRef = _firestore.collection('idea_collections').doc();
      
      final collection = IdeaCollection(
        id: collectionRef.id,
        name: name,
        description: description,
        userId: userId,
        ideaIds: ideaIds ?? [],
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await collectionRef.set(collection.toMap());
      return collectionRef.id;
    } catch (e) {
      print('Ошибка создания коллекции идей: $e');
      return null;
    }
  }

  /// Получить коллекции пользователя
  Stream<List<IdeaCollection>> getUserCollections(String userId) {
    return _firestore
        .collection('idea_collections')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IdeaCollection.fromDocument(doc))
          .toList();
    });
  }

  /// Добавить идею в коллекцию
  Future<bool> addIdeaToCollection(String collectionId, String ideaId) async {
    try {
      await _firestore.collection('idea_collections').doc(collectionId).update({
        'ideaIds': FieldValue.arrayUnion([ideaId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Ошибка добавления идеи в коллекцию: $e');
      return false;
    }
  }

  /// Удалить идею из коллекции
  Future<bool> removeIdeaFromCollection(String collectionId, String ideaId) async {
    try {
      await _firestore.collection('idea_collections').doc(collectionId).update({
        'ideaIds': FieldValue.arrayRemove([ideaId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Ошибка удаления идеи из коллекции: $e');
      return false;
    }
  }

  /// Подсчитать статистику идей
  IdeaStats _calculateIdeaStats(List<Idea> ideas) {
    final totalIdeas = ideas.length;
    final publishedIdeas = ideas.where((i) => i.status == IdeaStatus.published).length;
    final draftIdeas = ideas.where((i) => i.status == IdeaStatus.draft).length;
    final archivedIdeas = ideas.where((i) => i.status == IdeaStatus.archived).length;
    
    final totalLikes = ideas.fold<int>(0, (sum, idea) => sum + idea.likesCount);
    final totalViews = ideas.fold<int>(0, (sum, idea) => sum + idea.viewsCount);
    final totalSaves = ideas.fold<int>(0, (sum, idea) => sum + idea.savesCount);
    final totalComments = ideas.fold<int>(0, (sum, idea) => sum + idea.commentsCount);

    // Статистика по категориям
    final ideasByCategory = <String, int>{};
    for (final idea in ideas) {
      ideasByCategory[idea.category] = (ideasByCategory[idea.category] ?? 0) + 1;
    }

    // Статистика по типам
    final ideasByType = <String, int>{};
    for (final idea in ideas) {
      ideasByType[idea.type.name] = (ideasByType[idea.type.name] ?? 0) + 1;
    }

    // Топ теги
    final tagCounts = <String, int>{};
    for (final idea in ideas) {
      for (final tag in idea.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(10).map((e) => e.key).toList();

    // Топ авторы
    final authorCounts = <String, int>{};
    for (final idea in ideas) {
      authorCounts[idea.authorId] = (authorCounts[idea.authorId] ?? 0) + 1;
    }
    final sortedAuthors = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topAuthors = sortedAuthors.take(10).map((e) => e.key).toList();

    return IdeaStats(
      totalIdeas: totalIdeas,
      publishedIdeas: publishedIdeas,
      draftIdeas: draftIdeas,
      archivedIdeas: archivedIdeas,
      totalLikes: totalLikes,
      totalViews: totalViews,
      totalSaves: totalSaves,
      totalComments: totalComments,
      ideasByCategory: ideasByCategory,
      ideasByType: ideasByType,
      topTags: topTags,
      topAuthors: topAuthors,
    );
  }
}
