import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';

import '../models/enhanced_idea.dart';

/// Сервис для работы с расширенными идеями
class EnhancedIdeasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Получить все идеи
  Future<List<EnhancedIdea>> getIdeas({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    IdeaType? type,
    String? category,
    bool? isFeatured,
  }) async {
    try {
      Query query = _firestore
          .collection('ideas')
          .where('isPublic', isEqualTo: true)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (isFeatured != null) {
        query = query.where('isFeatured', isEqualTo: isFeatured);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<EnhancedIdea> ideas = [];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data() as Map<String, dynamic>);
        ideas.add(idea);
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка загрузки идей: $e');
    }
  }

  /// Получить идеи пользователя
  Future<List<EnhancedIdea>> getUserIdeas({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('ideas')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<EnhancedIdea> ideas = [];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data() as Map<String, dynamic>);
        ideas.add(idea);
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка загрузки идей пользователя: $e');
    }
  }

  /// Получить идею по ID
  Future<EnhancedIdea?> getIdeaById(String ideaId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('ideas')
          .doc(ideaId)
          .get();

      if (doc.exists) {
        return EnhancedIdea.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка загрузки идеи: $e');
    }
  }

  /// Создать идею
  Future<EnhancedIdea> createIdea({
    required String authorId,
    required String title,
    required String description,
    required IdeaType type,
    List<XFile>? mediaFiles,
    List<String>? tags,
    String? category,
    String? collectionId,
    String? specialistId,
    double? budget,
    String? timeline,
    String? location,
    bool isPublic = true,
  }) async {
    try {
      final String ideaId = _firestore.collection('ideas').doc().id;
      final DateTime now = DateTime.now();

      // Загружаем медиафайлы
      final List<IdeaMedia> media = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          final mediaItem = await _uploadMediaFile(file, ideaId);
          if (mediaItem != null) {
            media.add(mediaItem);
          }
        }
      }

      final EnhancedIdea idea = EnhancedIdea(
        id: ideaId,
        authorId: authorId,
        title: title,
        description: description,
        type: type,
        createdAt: now,
        media: media,
        tags: tags ?? [],
        category: category,
        collectionId: collectionId,
        specialistId: specialistId,
        budget: budget,
        timeline: timeline,
        location: location,
        isPublic: isPublic,
      );

      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .set(idea.toMap());

      return idea;
    } catch (e) {
      throw Exception('Ошибка создания идеи: $e');
    }
  }

  /// Обновить идею
  Future<void> updateIdea({
    required String ideaId,
    String? title,
    String? description,
    List<String>? tags,
    String? category,
    String? specialistId,
    double? budget,
    String? timeline,
    String? location,
    bool? isPublic,
    bool? isFeatured,
    bool? isArchived,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (tags != null) updates['tags'] = tags;
      if (category != null) updates['category'] = category;
      if (specialistId != null) updates['specialistId'] = specialistId;
      if (budget != null) updates['budget'] = budget;
      if (timeline != null) updates['timeline'] = timeline;
      if (location != null) updates['location'] = location;
      if (isPublic != null) updates['isPublic'] = isPublic;
      if (isFeatured != null) updates['isFeatured'] = isFeatured;
      if (isArchived != null) updates['isArchived'] = isArchived;

      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления идеи: $e');
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    try {
      // Удаляем медиафайлы
      final idea = await getIdeaById(ideaId);
      if (idea != null) {
        for (final media in idea.media) {
          await _deleteMediaFile(media.url);
        }
      }

      // Удаляем идею
      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Поставить лайк идее
  Future<void> likeIdea(String ideaId, String userId) async {
    try {
      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Ошибка лайка идеи: $e');
    }
  }

  /// Убрать лайк с идеи
  Future<void> unlikeIdea(String ideaId, String userId) async {
    try {
      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Ошибка снятия лайка: $e');
    }
  }

  /// Добавить комментарий
  Future<IdeaComment> addComment({
    required String ideaId,
    required String authorId,
    required String text,
    String? parentId,
  }) async {
    try {
      final String commentId = _firestore.collection('idea_comments').doc().id;
      final DateTime now = DateTime.now();

      final IdeaComment comment = IdeaComment(
        id: commentId,
        ideaId: ideaId,
        authorId: authorId,
        text: text,
        createdAt: now,
        parentId: parentId,
      );

      // Добавляем комментарий в коллекцию комментариев
      await _firestore
          .collection('idea_comments')
          .doc(commentId)
          .set(comment.toMap());

      // Обновляем счётчик комментариев в идее
      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .update({
        'commentsCount': FieldValue.increment(1),
      });

      return comment;
    } catch (e) {
      throw Exception('Ошибка добавления комментария: $e');
    }
  }

  /// Получить комментарии идеи
  Future<List<IdeaComment>> getIdeaComments({
    required String ideaId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('idea_comments')
          .where('ideaId', isEqualTo: ideaId)
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: false)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<IdeaComment> comments = [];

      for (final doc in snapshot.docs) {
        final comment = IdeaComment.fromMap(doc.data() as Map<String, dynamic>);
        comments.add(comment);
      }

      return comments;
    } catch (e) {
      throw Exception('Ошибка загрузки комментариев: $e');
    }
  }

  /// Репост идеи
  Future<IdeaShare> shareIdea({
    required String ideaId,
    required String userId,
    String? comment,
    String? targetChatId,
    String? targetUserId,
  }) async {
    try {
      final String shareId = _firestore.collection('idea_shares').doc().id;
      final DateTime now = DateTime.now();

      final IdeaShare share = IdeaShare(
        id: shareId,
        ideaId: ideaId,
        userId: userId,
        sharedAt: now,
        comment: comment,
        targetChatId: targetChatId,
        targetUserId: targetUserId,
      );

      // Добавляем репост в коллекцию репостов
      await _firestore
          .collection('idea_shares')
          .doc(shareId)
          .set(share.toMap());

      // Обновляем счётчик репостов в идее
      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .update({
        'sharesCount': FieldValue.increment(1),
      });

      return share;
    } catch (e) {
      throw Exception('Ошибка репоста: $e');
    }
  }

  /// Сохранить идею
  Future<void> saveIdea(String ideaId, String userId) async {
    try {
      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .update({
        'saves': FieldValue.arrayUnion([userId]),
        'savesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Ошибка сохранения идеи: $e');
    }
  }

  /// Убрать идею из сохранённых
  Future<void> unsaveIdea(String ideaId, String userId) async {
    try {
      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .update({
        'saves': FieldValue.arrayRemove([userId]),
        'savesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Ошибка удаления из сохранённых: $e');
    }
  }

  /// Получить сохранённые идеи
  Future<List<EnhancedIdea>> getSavedIdeas({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('ideas')
          .where('saves', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<EnhancedIdea> ideas = [];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data() as Map<String, dynamic>);
        ideas.add(idea);
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка загрузки сохранённых идей: $e');
    }
  }

  /// Поиск идей
  Future<List<EnhancedIdea>> searchIdeas({
    required String query,
    List<String>? tags,
    String? category,
    IdeaType? type,
    double? minBudget,
    double? maxBudget,
    String? location,
    int limit = 20,
  }) async {
    try {
      Query queryBuilder = _firestore.collection('ideas');

      // Фильтр по типу
      if (type != null) {
        queryBuilder = queryBuilder.where('type', isEqualTo: type.value);
      }

      // Фильтр по категории
      if (category != null) {
        queryBuilder = queryBuilder.where('category', isEqualTo: category);
      }

      // Фильтр по тегам
      if (tags != null && tags.isNotEmpty) {
        queryBuilder = queryBuilder.where('tags', arrayContainsAny: tags);
      }

      // Фильтр по местоположению
      if (location != null && location.isNotEmpty) {
        queryBuilder = queryBuilder.where('location', isEqualTo: location);
      }

      queryBuilder = queryBuilder
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final QuerySnapshot snapshot = await queryBuilder.get();
      final List<EnhancedIdea> ideas = [];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data() as Map<String, dynamic>);
        
        // Фильтр по тексту и бюджету (на клиенте)
        bool matchesQuery = query.isEmpty || 
            idea.title.toLowerCase().contains(query.toLowerCase()) ||
            idea.description.toLowerCase().contains(query.toLowerCase()) ||
            idea.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));

        bool matchesBudget = true;
        if (minBudget != null && idea.budget != null && idea.budget! < minBudget) {
          matchesBudget = false;
        }
        if (maxBudget != null && idea.budget != null && idea.budget! > maxBudget) {
          matchesBudget = false;
        }

        if (matchesQuery && matchesBudget) {
          ideas.add(idea);
        }
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка поиска идей: $e');
    }
  }

  /// Получить популярные идеи
  Future<List<EnhancedIdea>> getPopularIdeas({
    int limit = 10,
    IdeaType? type,
  }) async {
    try {
      Query query = _firestore
          .collection('ideas')
          .where('isPublic', isEqualTo: true)
          .where('isArchived', isEqualTo: false)
          .orderBy('likesCount', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<EnhancedIdea> ideas = [];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data() as Map<String, dynamic>);
        ideas.add(idea);
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка загрузки популярных идей: $e');
    }
  }

  /// Создать коллекцию идей
  Future<IdeaCollection> createCollection({
    required String name,
    required String description,
    required String authorId,
    List<String>? tags,
    String? coverImageUrl,
    bool isPublic = true,
  }) async {
    try {
      final String collectionId = _firestore.collection('idea_collections').doc().id;
      final DateTime now = DateTime.now();

      final IdeaCollection collection = IdeaCollection(
        id: collectionId,
        name: name,
        description: description,
        authorId: authorId,
        createdAt: now,
        tags: tags ?? [],
        coverImageUrl: coverImageUrl,
        isPublic: isPublic,
      );

      await _firestore
          .collection('idea_collections')
          .doc(collectionId)
          .set(collection.toMap());

      return collection;
    } catch (e) {
      throw Exception('Ошибка создания коллекции: $e');
    }
  }

  /// Получить коллекции пользователя
  Future<List<IdeaCollection>> getUserCollections({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('idea_collections')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final List<IdeaCollection> collections = [];

      for (final doc in snapshot.docs) {
        final collection = IdeaCollection.fromMap(doc.data() as Map<String, dynamic>);
        collections.add(collection);
      }

      return collections;
    } catch (e) {
      throw Exception('Ошибка загрузки коллекций: $e');
    }
  }

  /// Добавить идею в коллекцию
  Future<void> addIdeaToCollection(String collectionId, String ideaId) async {
    try {
      await _firestore
          .collection('idea_collections')
          .doc(collectionId)
          .update({
        'ideas': FieldValue.arrayUnion([ideaId]),
      });
    } catch (e) {
      throw Exception('Ошибка добавления идеи в коллекцию: $e');
    }
  }

  /// Удалить идею из коллекции
  Future<void> removeIdeaFromCollection(String collectionId, String ideaId) async {
    try {
      await _firestore
          .collection('idea_collections')
          .doc(collectionId)
          .update({
        'ideas': FieldValue.arrayRemove([ideaId]),
      });
    } catch (e) {
      throw Exception('Ошибка удаления идеи из коллекции: $e');
    }
  }

  /// Загрузить медиафайл
  Future<IdeaMedia?> _uploadMediaFile(XFile file, String ideaId) async {
    try {
      final File fileToUpload = File(file.path);
      final String fileName = '${ideaId}_${DateTime.now().millisecondsSinceEpoch}';
      final String extension = file.path.split('.').last;
      final String filePath = 'ideas/$ideaId/$fileName.$extension';

      // Загружаем файл в Storage
      final Reference ref = _storage.ref().child(filePath);
      final UploadTask uploadTask = ref.putFile(fileToUpload);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Определяем тип медиа
      IdeaMediaType mediaType;
      if (file.path.toLowerCase().endsWith('.mp4') || 
          file.path.toLowerCase().endsWith('.mov') ||
          file.path.toLowerCase().endsWith('.avi')) {
        mediaType = IdeaMediaType.video;
      } else if (file.path.toLowerCase().endsWith('.gif')) {
        mediaType = IdeaMediaType.gif;
      } else {
        mediaType = IdeaMediaType.image;
      }

      // Получаем размеры файла
      int width = 0;
      int height = 0;
      String? thumbnailUrl;

      if (mediaType == IdeaMediaType.image) {
        // Для изображений получаем размеры
        // TODO: Добавить обработку изображений
        // final image = await decodeImageFromList(await fileToUpload.readAsBytes());
        width = 400; // Заглушка
        height = 300; // Заглушка
      } else if (mediaType == IdeaMediaType.video) {
        // Для видео создаём превью
        thumbnailUrl = await VideoThumbnail.thumbnailFile(
          video: file.path,
          thumbnailPath: '/tmp', // Заглушка
          imageFormat: ImageFormat.JPEG,
          maxHeight: 200,
          quality: 75,
        );
        
        // Получаем размеры видео (упрощённо)
        width = 1920;
        height = 1080;
      }

      return IdeaMedia(
        id: fileName,
        url: downloadUrl,
        type: mediaType,
        width: width,
        height: height,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      print('Ошибка загрузки медиафайла: $e');
      return null;
    }
  }

  /// Удалить медиафайл
  Future<void> _deleteMediaFile(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Ошибка удаления медиафайла: $e');
    }
  }
}
