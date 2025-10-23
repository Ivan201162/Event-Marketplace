import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_idea.dart';

/// Сервис для работы с идеями мероприятий
class EventIdeaService {
  factory EventIdeaService() => _instance;
  EventIdeaService._internal();
  static final EventIdeaService _instance = EventIdeaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Создать идею
  Future<String> createIdea(CreateEventIdea createIdea) async {
    try {
      if (!createIdea.isValid) {
        final errors = createIdea.validationErrors;
        throw Exception('Ошибка валидации: ${errors.join(', ')}');
      }

      final idea = EventIdea(
        id: '', // Будет сгенерирован Firestore
        authorId: createIdea.authorId,
        title: createIdea.title,
        description: createIdea.description,
        images: createIdea.images,
        createdAt: DateTime.now(),
        authorName: createIdea.authorName,
        authorAvatar: createIdea.authorAvatar,
        tags: createIdea.tags,
        category: createIdea.category,
        budget: createIdea.budget,
        duration: createIdea.duration,
        guests: createIdea.guests,
        location: createIdea.location,
        metadata: createIdea.metadata,
      );

      final docRef =
          await _firestore.collection('event_ideas').add(idea.toMap());

      debugPrint('Event idea created: ${docRef.id}');
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Error creating event idea: $e');
      throw Exception('Ошибка создания идеи: $e');
    }
  }

  /// Загрузить изображения для идеи
  Future<List<String>> uploadIdeaImages({
    required String authorId,
    required List<XFile> imageFiles,
  }) async {
    try {
      final urls = <String>[];

      for (var i = 0; i < imageFiles.length; i++) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${i}_${imageFiles[i].name}';
        final storagePath = 'event_ideas/$authorId/images/$fileName';

        final ref = _storage.ref().child(storagePath);
        final uploadTask = ref.putFile(File(imageFiles[i].path));
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        urls.add(downloadUrl);
      }

      debugPrint('Event idea images uploaded: ${urls.length} images');
      return urls;
    } on Exception catch (e) {
      debugPrint('Error uploading event idea images: $e');
      throw Exception('Ошибка загрузки изображений: $e');
    }
  }

  /// Получить все идеи (Pinterest-лента)
  Future<List<EventIdea>> getAllIdeas({
    int limit = 20,
    String? category,
    List<String>? tags,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore
          .collection('event_ideas')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Простой поиск по заголовку и описанию
        // В реальном приложении лучше использовать Algolia или Elasticsearch
        final snapshot = await query.get();
        final ideas = snapshot.docs.map(EventIdea.fromDocument).where((idea) {
          final query = searchQuery.toLowerCase();
          return idea.title.toLowerCase().contains(query) ||
              idea.description.toLowerCase().contains(query) ||
              idea.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();

        return ideas.take(limit).toList();
      }

      final querySnapshot = await query.limit(limit).get();
      return querySnapshot.docs.map(EventIdea.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Error getting all ideas: $e');
      throw Exception('Ошибка получения идей: $e');
    }
  }

  /// Получить идеи пользователя
  Future<List<EventIdea>> getUserIdeas(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('authorId', isEqualTo: userId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(EventIdea.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Error getting user ideas: $e');
      throw Exception('Ошибка получения идей пользователя: $e');
    }
  }

  /// Получить идею по ID
  Future<EventIdea?> getIdeaById(String ideaId) async {
    try {
      final doc = await _firestore.collection('event_ideas').doc(ideaId).get();
      if (doc.exists) {
        return EventIdea.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Error getting idea by ID: $e');
      throw Exception('Ошибка получения идеи: $e');
    }
  }

  /// Обновить идею
  Future<void> updateIdea(String ideaId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).update(updates);
      debugPrint('Event idea updated: $ideaId');
    } on Exception catch (e) {
      debugPrint('Error updating event idea: $e');
      throw Exception('Ошибка обновления идеи: $e');
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    try {
      // Получаем информацию об идее
      final doc = await _firestore.collection('event_ideas').doc(ideaId).get();
      if (!doc.exists) {
        throw Exception('Идея не найдена');
      }

      final idea = EventIdea.fromDocument(doc);

      // Удаляем изображения из Storage
      for (final imageUrl in idea.images) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } on Exception catch (e) {
          debugPrint('Error deleting idea image: $e');
        }
      }

      // Удаляем запись из Firestore
      await _firestore.collection('event_ideas').doc(ideaId).delete();

      debugPrint('Event idea deleted: $ideaId');
    } on Exception catch (e) {
      debugPrint('Error deleting event idea: $e');
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Лайкнуть идею
  Future<void> likeIdea(String ideaId) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'likes': FieldValue.increment(1),
      });
      debugPrint('Event idea liked: $ideaId');
    } on Exception catch (e) {
      debugPrint('Error liking event idea: $e');
      throw Exception('Ошибка лайка идеи: $e');
    }
  }

  /// Убрать лайк с идеи
  Future<void> unlikeIdea(String ideaId) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'likes': FieldValue.increment(-1),
      });
      debugPrint('Event idea unliked: $ideaId');
    } on Exception catch (e) {
      debugPrint('Error unliking event idea: $e');
      throw Exception('Ошибка удаления лайка: $e');
    }
  }

  /// Увеличить счетчик просмотров
  Future<void> incrementViews(String ideaId) async {
    try {
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'views': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      debugPrint('Error incrementing views: $e');
      // Не выбрасываем исключение, так как это не критично
    }
  }

  /// Добавить комментарий к идее
  Future<String> addComment({
    required String ideaId,
    required String authorId,
    required String text,
    String? authorName,
    String? authorAvatar,
    String? parentId,
  }) async {
    try {
      final comment = IdeaComment(
        id: '', // Будет сгенерирован Firestore
        ideaId: ideaId,
        authorId: authorId,
        text: text,
        createdAt: DateTime.now(),
        authorName: authorName,
        authorAvatar: authorAvatar,
        parentId: parentId,
      );

      final docRef =
          await _firestore.collection('idea_comments').add(comment.toMap());

      // Увеличиваем счетчик комментариев
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'comments': FieldValue.increment(1),
      });

      // Если это ответ на комментарий, увеличиваем счетчик ответов
      if (parentId != null) {
        await _firestore.collection('idea_comments').doc(parentId).update({
          'replies': FieldValue.increment(1),
        });
      }

      debugPrint('Comment added to idea: $ideaId');
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('Ошибка добавления комментария: $e');
    }
  }

  /// Получить комментарии к идее
  Future<List<IdeaComment>> getIdeaComments(String ideaId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('idea_comments')
          .where('ideaId', isEqualTo: ideaId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(IdeaComment.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Error getting idea comments: $e');
      throw Exception('Ошибка получения комментариев: $e');
    }
  }

  /// Лайкнуть комментарий
  Future<void> likeComment(String commentId) async {
    try {
      await _firestore.collection('idea_comments').doc(commentId).update({
        'likes': FieldValue.increment(1),
      });
      debugPrint('Comment liked: $commentId');
    } on Exception catch (e) {
      debugPrint('Error liking comment: $e');
      throw Exception('Ошибка лайка комментария: $e');
    }
  }

  /// Убрать лайк с комментария
  Future<void> unlikeComment(String commentId) async {
    try {
      await _firestore.collection('idea_comments').doc(commentId).update({
        'likes': FieldValue.increment(-1),
      });
      debugPrint('Comment unliked: $commentId');
    } on Exception catch (e) {
      debugPrint('Error unliking comment: $e');
      throw Exception('Ошибка удаления лайка: $e');
    }
  }

  /// Получить популярные теги
  Future<List<String>> getPopularTags({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('isPublic', isEqualTo: true)
          .get();

      final tagCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final idea = EventIdea.fromDocument(doc);
        for (final tag in idea.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(limit).map((entry) => entry.key).toList();
    } on Exception catch (e) {
      debugPrint('Error getting popular tags: $e');
      return [];
    }
  }

  /// Выбрать изображения из галереи
  Future<List<XFile>> pickImages({int maxImages = 5}) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return images.take(maxImages).toList();
    } on Exception catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// Сделать фото с камеры
  Future<XFile?> takePhoto() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } on Exception catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }
}
