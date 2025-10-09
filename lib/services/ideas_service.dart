import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/idea.dart';
import '../repositories/ideas_repository.dart';

/// Сервис для работы с идеями
class IdeasService {
  factory IdeasService() => _instance;
  IdeasService._internal();
  static final IdeasService _instance = IdeasService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final IdeasRepository _repository = IdeasRepository();

  /// Получение всех идей с фильтрацией
  Stream<List<Idea>> getIdeas({
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) => _repository.streamList(
      category: category,
      searchQuery: searchQuery,
      limit: limit,
      startAfter: startAfter,
    );

  /// Получение идей пользователя
  Stream<List<Idea>> getUserIdeas(String userId) => _repository.getUserIdeas(userId);

  /// Получение сохраненных идей пользователя
  Stream<List<Idea>> getSavedIdeas(String userId) => _repository.getSavedIdeas(userId);

  /// Получение конкретной идеи
  Future<Idea?> getIdea(String ideaId) async => _repository.getById(ideaId);

  /// Создание новой идеи
  Future<String?> createIdea({
    required String title,
    required String description,
    required String category,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required File mediaFile,
    required bool isVideo,
    List<String> tags = const [],
    String? location,
    double? price,
    String? priceCurrency,
    int? duration,
    List<String> requiredSkills = const [],
  }) async {
    try {
      // Загрузка медиа файла
      final mediaUrl = await _uploadMediaFile(mediaFile, isVideo);
      if (mediaUrl == null) {
        throw Exception('Ошибка загрузки медиа файла');
      }

      // Создание документа идеи
      final ideaData = {
        'title': title,
        'description': description,
        'category': category,
        'mediaUrl': mediaUrl,
        'isVideo': isVideo,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'savesCount': 0,
        'sharesCount': 0,
        'tags': tags,
        'likedBy': [],
        'savedBy': [],
        'sharedBy': [],
        'isPublic': true,
        'location': location,
        'price': price,
        'priceCurrency': priceCurrency,
        'duration': duration,
        'requiredSkills': requiredSkills,
      };

      final docRef = await _firestore.collection('ideas').add(ideaData);
      return docRef.id;
    } on Exception catch (e) {
      print('Ошибка создания идеи: $e');
      return null;
    }
  }

  /// Обновление идеи
  Future<bool> updateIdea(String ideaId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('ideas').doc(ideaId).update(updates);
      return true;
    } on Exception catch (e) {
      print('Ошибка обновления идеи: $e');
      return false;
    }
  }

  /// Удаление идеи
  Future<bool> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).delete();
      return true;
    } on Exception catch (e) {
      print('Ошибка удаления идеи: $e');
      return false;
    }
  }

  /// Лайк/анлайк идеи
  Future<bool> toggleLike(String ideaId, String userId) async {
    try {
      final docRef = _firestore.collection('ideas').doc(ideaId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final idea = Idea.fromFirestore(doc);
        final isLiked = idea.isLiked;
        
        final newLikedBy = <String>[];
        if (isLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        transaction.update(docRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      print('Ошибка лайка идеи: $e');
      return false;
    }
  }

  /// Сохранение/удаление из сохраненных
  Future<bool> toggleSave(String ideaId, String userId) async {
    try {
      final docRef = _firestore.collection('ideas').doc(ideaId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final idea = Idea.fromFirestore(doc);
        final isSaved = idea.isSaved;
        
        final newSavedBy = <String>[];
        if (isSaved) {
          newSavedBy.remove(userId);
        } else {
          newSavedBy.add(userId);
        }

        transaction.update(docRef, {
          'savedBy': newSavedBy,
          'savesCount': newSavedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      print('Ошибка сохранения идеи: $e');
      return false;
    }
  }

  /// Поделиться идеей
  Future<bool> shareIdea(String ideaId, String userId) async {
    try {
      final docRef = _firestore.collection('ideas').doc(ideaId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final idea = Idea.fromFirestore(doc);
        final newSharedBy = <String>[];
        
        if (!newSharedBy.contains(userId)) {
          newSharedBy.add(userId);
        }

        transaction.update(docRef, {
          'sharedBy': newSharedBy,
          'sharesCount': newSharedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      print('Ошибка репоста идеи: $e');
      return false;
    }
  }

  /// Получение комментариев к идее
  Stream<List<Map<String, dynamic>>> getIdeaComments(String ideaId) => _firestore
        .collection('idea_comments')
        .where('ideaId', isEqualTo: ideaId)
        .where('parentCommentId', isNull: true) // только основные комментарии
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  /// Добавление комментария
  Future<String?> addComment({
    required String ideaId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final commentData = {
        'ideaId': ideaId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'likedBy': [],
        'parentCommentId': parentCommentId,
        'replies': [],
      };

      final docRef = await _firestore.collection('idea_comments').add(commentData);
      
      // Обновляем счетчик комментариев в идее
      await _firestore.collection('ideas').doc(ideaId).update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } on Exception catch (e) {
      print('Ошибка добавления комментария: $e');
      return null;
    }
  }

  /// Лайк комментария
  Future<bool> toggleCommentLike(String commentId, String userId) async {
    try {
      final docRef = _firestore.collection('idea_comments').doc(commentId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final comment = doc.data();
        const isLiked = false;
        
        final newLikedBy = <String>[];
        if (isLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        transaction.update(docRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      print('Ошибка лайка комментария: $e');
      return false;
    }
  }

  /// Выбор медиа файла
  Future<File?> pickMediaFile({required bool isVideo}) async {
    try {
      final file = await _imagePicker.pickMedia();
      
      if (file != null) {
        return File(file.path);
      }
      return null;
    } on Exception catch (e) {
      print('Ошибка выбора медиа файла: $e');
      return null;
    }
  }

  /// Загрузка медиа файла в Firebase Storage
  Future<String?> _uploadMediaFile(File file, bool isVideo) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = isVideo ? 'ideas/videos/$fileName' : 'ideas/images/$fileName';
      
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } on Exception catch (e) {
      print('Ошибка загрузки медиа файла: $e');
      return null;
    }
  }

  /// Генерация превью для видео
  Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );
      
      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        return await _uploadMediaFile(thumbnailFile, false);
      }
      
      return null;
    } on Exception catch (e) {
      print('Ошибка генерации превью видео: $e');
      return null;
    }
  }

  /// Получение трендовых идей
  Stream<List<Idea>> getTrendingIdeas({int limit = 10}) => _firestore
        .collection('ideas')
        .where('isPublic', isEqualTo: true)
        .orderBy('likesCount', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Idea.fromFirestore).toList());

  /// Поиск идей по тегам
  Stream<List<Idea>> searchIdeasByTags(List<String> tags, {int limit = 20}) => _firestore
        .collection('ideas')
        .where('isPublic', isEqualTo: true)
        .where('tags', arrayContainsAny: tags)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Idea.fromFirestore).toList());
}