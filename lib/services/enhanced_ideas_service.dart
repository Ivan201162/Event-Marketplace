import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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

      final snapshot = await query.get();
      final ideas = <EnhancedIdea>[];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data()! as Map<String, dynamic>);
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

      final snapshot = await query.get();
      final ideas = <EnhancedIdea>[];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data()! as Map<String, dynamic>);
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
      final DocumentSnapshot doc =
          await _firestore.collection('ideas').doc(ideaId).get();

      if (doc.exists) {
        return EnhancedIdea.fromMap(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка загрузки идеи: $e');
    }
  }

  /// Создать идею
  Future<EnhancedIdea> createIdea(EnhancedIdea idea) async {
    try {
      final ideaId = _firestore.collection('ideas').doc().id;
      final now = DateTime.now();

      // Создаем новую идею с ID
      final newIdea = idea.copyWith(id: ideaId, createdAt: now, updatedAt: now);

      await _firestore.collection('ideas').doc(ideaId).set(newIdea.toMap());

      return newIdea;
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
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp()
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

      await _firestore.collection('ideas').doc(ideaId).update(updates);
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
      await _firestore.collection('ideas').doc(ideaId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Поставить лайк идее
  Future<void> likeIdea(String ideaId, String userId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).update({
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
      await _firestore.collection('ideas').doc(ideaId).update({
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
      final commentId = _firestore.collection('idea_comments').doc().id;
      final now = DateTime.now();

      final comment = IdeaComment(
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
      await _firestore.collection('ideas').doc(ideaId).update({
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

      final snapshot = await query.get();
      final comments = <IdeaComment>[];

      for (final doc in snapshot.docs) {
        final comment =
            IdeaComment.fromMap(doc.data()! as Map<String, dynamic>);
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
      final shareId = _firestore.collection('idea_shares').doc().id;
      final now = DateTime.now();

      final share = IdeaShare(
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
      await _firestore.collection('ideas').doc(ideaId).update({
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
      await _firestore.collection('ideas').doc(ideaId).update({
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
      await _firestore.collection('ideas').doc(ideaId).update({
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

      final snapshot = await query.get();
      final ideas = <EnhancedIdea>[];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data()! as Map<String, dynamic>);
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

      final snapshot = await queryBuilder.get();
      final ideas = <EnhancedIdea>[];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data()! as Map<String, dynamic>);

        // Фильтр по тексту и бюджету (на клиенте)
        final matchesQuery = query.isEmpty ||
            idea.title.toLowerCase().contains(query.toLowerCase()) ||
            idea.description.toLowerCase().contains(query.toLowerCase()) ||
            idea.tags
                .any((tag) => tag.toLowerCase().contains(query.toLowerCase()));

        var matchesBudget = true;
        if (minBudget != null &&
            idea.budget != null &&
            idea.budget! < minBudget) {
          matchesBudget = false;
        }
        if (maxBudget != null &&
            idea.budget != null &&
            idea.budget! > maxBudget) {
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
  Future<List<EnhancedIdea>> getPopularIdeas(
      {int limit = 10, IdeaType? type}) async {
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

      final snapshot = await query.get();
      final ideas = <EnhancedIdea>[];

      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data()! as Map<String, dynamic>);
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
      final collectionId = _firestore.collection('idea_collections').doc().id;
      final now = DateTime.now();

      final collection = IdeaCollection(
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
  Future<List<IdeaCollection>> getUserCollections(
      {required String userId, int limit = 20}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('idea_collections')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final collections = <IdeaCollection>[];

      for (final doc in snapshot.docs) {
        final collection =
            IdeaCollection.fromMap(doc.data()! as Map<String, dynamic>);
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
      await _firestore.collection('idea_collections').doc(collectionId).update({
        'ideas': FieldValue.arrayUnion([ideaId]),
      });
    } catch (e) {
      throw Exception('Ошибка добавления идеи в коллекцию: $e');
    }
  }

  /// Удалить идею из коллекции
  Future<void> removeIdeaFromCollection(
      String collectionId, String ideaId) async {
    try {
      await _firestore.collection('idea_collections').doc(collectionId).update({
        'ideas': FieldValue.arrayRemove([ideaId]),
      });
    } catch (e) {
      throw Exception('Ошибка удаления идеи из коллекции: $e');
    }
  }

  /// Загрузить медиафайл
  Future<IdeaMedia?> _uploadMediaFile(XFile file, String ideaId) async {
    try {
      final fileToUpload = File(file.path);
      final fileName = '${ideaId}_${DateTime.now().millisecondsSinceEpoch}';
      final extension = file.path.split('.').last;
      final filePath = 'ideas/$ideaId/$fileName.$extension';

      // Загружаем файл в Storage
      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(fileToUpload);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

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
      var width = 0;
      var height = 0;
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
      debugPrint('Ошибка загрузки медиафайла: $e');
      return null;
    }
  }

  /// Удалить медиафайл
  Future<void> _deleteMediaFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Ошибка удаления медиафайла: $e');
    }
  }

  /// Получить идеи по категории
  Future<List<EnhancedIdea>> getCategoryIdeas(String category) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('category', isEqualTo: category)
          .where('isPublic', isEqualTo: true)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final ideas = <EnhancedIdea>[];
      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data());
        ideas.add(idea);
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка загрузки идей категории $category: $e');
    }
  }

  /// Получить видео идеи
  Future<List<EnhancedIdea>> getVideoIdeas() async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('type', isEqualTo: 'video')
          .where('isPublic', isEqualTo: true)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final ideas = <EnhancedIdea>[];
      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data());
        ideas.add(idea);
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка загрузки видео идей: $e');
    }
  }

  /// Получить трендовые идеи
  Future<List<EnhancedIdea>> getTrendingIdeas() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('ideas')
          .where('isPublic', isEqualTo: true)
          .where('isArchived', isEqualTo: false)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('createdAt', descending: true)
          .orderBy('likesCount', descending: true)
          .limit(20)
          .get();

      final ideas = <EnhancedIdea>[];
      for (final doc in snapshot.docs) {
        final idea = EnhancedIdea.fromMap(doc.data());
        ideas.add(idea);
      }

      return ideas;
    } catch (e) {
      throw Exception('Ошибка загрузки трендовых идей: $e');
    }
  }

  /// Поделиться идеей в чат
  Future<void> shareIdeaToChat(
      String ideaId, String chatId, String userId) async {
    try {
      final idea = await getIdeaById(ideaId);
      if (idea == null) {
        throw Exception('Идея не найдена');
      }

      // Добавляем сообщение в чат
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': userId,
        'type': 'idea_share',
        'content': 'Поделился идеей: ${idea.title}',
        'ideaId': ideaId,
        'createdAt': FieldValue.serverTimestamp(),
        'isTest': true,
      });

      // Обновляем последнее сообщение чата
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': {
          'content': 'Поделился идеей: ${idea.title}',
          'senderId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка отправки идеи в чат: $e');
    }
  }

  /// Получить связанных специалистов для идеи
  Future<List<String>> getIdeaSpecialists(String ideaId) async {
    try {
      final doc = await _firestore.collection('ideas').doc(ideaId).get();
      if (!doc.exists) {
        return [];
      }

      final data = doc.data()!;
      final specialists = List<String>.from(data['specialists'] ?? []);
      return specialists;
    } catch (e) {
      return [];
    }
  }

  /// Добавить специалиста к идее
  Future<void> addSpecialistToIdea(String ideaId, String specialistId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).update({
        'specialists': FieldValue.arrayUnion([specialistId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка добавления специалиста к идее: $e');
    }
  }

  /// Удалить специалиста из идеи
  Future<void> removeSpecialistFromIdea(
      String ideaId, String specialistId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).update({
        'specialists': FieldValue.arrayRemove([specialistId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка удаления специалиста из идеи: $e');
    }
  }
}
