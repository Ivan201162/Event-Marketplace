import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';

import '../models/enhanced_feed_post.dart';
import '../models/app_user.dart';

/// Сервис для работы с расширенной лентой
class EnhancedFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Получить ленту пользователя
  Future<List<EnhancedFeedPost>> getFeed({
    String? userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('feed')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<EnhancedFeedPost> posts = [];

      for (final doc in snapshot.docs) {
        final post = EnhancedFeedPost.fromMap(doc.data() as Map<String, dynamic>);
        posts.add(post);
      }

      return posts;
    } catch (e) {
      throw Exception('Ошибка загрузки ленты: $e');
    }
  }

  /// Получить посты пользователя
  Future<List<EnhancedFeedPost>> getUserPosts({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('feed')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<EnhancedFeedPost> posts = [];

      for (final doc in snapshot.docs) {
        final post = EnhancedFeedPost.fromMap(doc.data() as Map<String, dynamic>);
        posts.add(post);
      }

      return posts;
    } catch (e) {
      throw Exception('Ошибка загрузки постов пользователя: $e');
    }
  }

  /// Получить пост по ID
  Future<EnhancedFeedPost?> getPostById(String postId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('feed')
          .doc(postId)
          .get();

      if (doc.exists) {
        return EnhancedFeedPost.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка загрузки поста: $e');
    }
  }

  /// Создать пост
  Future<EnhancedFeedPost> createPost({
    required String authorId,
    required String content,
    required FeedPostType type,
    List<XFile>? mediaFiles,
    List<String>? tags,
    String? location,
    bool isSponsored = false,
  }) async {
    try {
      final String postId = _firestore.collection('feed').doc().id;
      final DateTime now = DateTime.now();

      // Загружаем медиафайлы
      final List<FeedPostMedia> media = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          final mediaItem = await _uploadMediaFile(file, postId);
          if (mediaItem != null) {
            media.add(mediaItem);
          }
        }
      }

      final EnhancedFeedPost post = EnhancedFeedPost(
        id: postId,
        authorId: authorId,
        content: content,
        type: type,
        createdAt: now,
        media: media,
        tags: tags ?? [],
        location: location,
        isSponsored: isSponsored,
      );

      await _firestore
          .collection('feed')
          .doc(postId)
          .set(post.toMap());

      return post;
    } catch (e) {
      throw Exception('Ошибка создания поста: $e');
    }
  }

  /// Обновить пост
  Future<void> updatePost({
    required String postId,
    String? content,
    List<String>? tags,
    String? location,
    bool? isPinned,
    bool? isArchived,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (content != null) updates['content'] = content;
      if (tags != null) updates['tags'] = tags;
      if (location != null) updates['location'] = location;
      if (isPinned != null) updates['isPinned'] = isPinned;
      if (isArchived != null) updates['isArchived'] = isArchived;

      await _firestore
          .collection('feed')
          .doc(postId)
          .update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления поста: $e');
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId) async {
    try {
      // Удаляем медиафайлы
      final post = await getPostById(postId);
      if (post != null) {
        for (final media in post.media) {
          await _deleteMediaFile(media.url);
        }
      }

      // Удаляем пост
      await _firestore
          .collection('feed')
          .doc(postId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления поста: $e');
    }
  }

  /// Поставить лайк посту
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('feed')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Ошибка лайка поста: $e');
    }
  }

  /// Убрать лайк с поста
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('feed')
          .doc(postId)
          .update({
        'likes': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Ошибка снятия лайка: $e');
    }
  }

  /// Добавить комментарий
  Future<FeedPostComment> addComment({
    required String postId,
    required String authorId,
    required String text,
    String? parentId,
  }) async {
    try {
      final String commentId = _firestore.collection('comments').doc().id;
      final DateTime now = DateTime.now();

      final FeedPostComment comment = FeedPostComment(
        id: commentId,
        postId: postId,
        authorId: authorId,
        text: text,
        createdAt: now,
        parentId: parentId,
      );

      // Добавляем комментарий в коллекцию комментариев
      await _firestore
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      // Обновляем счётчик комментариев в посте
      await _firestore
          .collection('feed')
          .doc(postId)
          .update({
        'commentsCount': FieldValue.increment(1),
      });

      return comment;
    } catch (e) {
      throw Exception('Ошибка добавления комментария: $e');
    }
  }

  /// Получить комментарии поста
  Future<List<FeedPostComment>> getPostComments({
    required String postId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: false)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<FeedPostComment> comments = [];

      for (final doc in snapshot.docs) {
        final comment = FeedPostComment.fromMap(doc.data() as Map<String, dynamic>);
        comments.add(comment);
      }

      return comments;
    } catch (e) {
      throw Exception('Ошибка загрузки комментариев: $e');
    }
  }

  /// Репост поста
  Future<FeedPostShare> sharePost({
    required String postId,
    required String userId,
    String? comment,
    String? targetChatId,
    String? targetUserId,
  }) async {
    try {
      final String shareId = _firestore.collection('shares').doc().id;
      final DateTime now = DateTime.now();

      final FeedPostShare share = FeedPostShare(
        id: shareId,
        postId: postId,
        userId: userId,
        sharedAt: now,
        comment: comment,
        targetChatId: targetChatId,
        targetUserId: targetUserId,
      );

      // Добавляем репост в коллекцию репостов
      await _firestore
          .collection('shares')
          .doc(shareId)
          .set(share.toMap());

      // Обновляем счётчик репостов в посте
      await _firestore
          .collection('feed')
          .doc(postId)
          .update({
        'sharesCount': FieldValue.increment(1),
      });

      return share;
    } catch (e) {
      throw Exception('Ошибка репоста: $e');
    }
  }

  /// Сохранить пост
  Future<void> savePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('feed')
          .doc(postId)
          .update({
        'saves': FieldValue.arrayUnion([userId]),
        'savesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Ошибка сохранения поста: $e');
    }
  }

  /// Убрать пост из сохранённых
  Future<void> unsavePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('feed')
          .doc(postId)
          .update({
        'saves': FieldValue.arrayRemove([userId]),
        'savesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Ошибка удаления из сохранённых: $e');
    }
  }

  /// Получить сохранённые посты
  Future<List<EnhancedFeedPost>> getSavedPosts({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('feed')
          .where('saves', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<EnhancedFeedPost> posts = [];

      for (final doc in snapshot.docs) {
        final post = EnhancedFeedPost.fromMap(doc.data() as Map<String, dynamic>);
        posts.add(post);
      }

      return posts;
    } catch (e) {
      throw Exception('Ошибка загрузки сохранённых постов: $e');
    }
  }

  /// Поиск постов
  Future<List<EnhancedFeedPost>> searchPosts({
    required String query,
    List<String>? tags,
    String? location,
    FeedPostType? type,
    int limit = 20,
  }) async {
    try {
      Query queryBuilder = _firestore.collection('feed');

      // Фильтр по типу
      if (type != null) {
        queryBuilder = queryBuilder.where('type', isEqualTo: type.value);
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
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final QuerySnapshot snapshot = await queryBuilder.get();
      final List<EnhancedFeedPost> posts = [];

      for (final doc in snapshot.docs) {
        final post = EnhancedFeedPost.fromMap(doc.data() as Map<String, dynamic>);
        
        // Фильтр по тексту (на клиенте, так как Firestore не поддерживает полнотекстовый поиск)
        if (query.isEmpty || 
            post.content.toLowerCase().contains(query.toLowerCase()) ||
            post.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))) {
          posts.add(post);
        }
      }

      return posts;
    } catch (e) {
      throw Exception('Ошибка поиска постов: $e');
    }
  }

  /// Загрузить медиафайл
  Future<FeedPostMedia?> _uploadMediaFile(XFile file, String postId) async {
    try {
      final File fileToUpload = File(file.path);
      final String fileName = '${postId}_${DateTime.now().millisecondsSinceEpoch}';
      final String extension = file.path.split('.').last;
      final String filePath = 'feed/$postId/$fileName.$extension';

      // Загружаем файл в Storage
      final Reference ref = _storage.ref().child(filePath);
      final UploadTask uploadTask = ref.putFile(fileToUpload);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Определяем тип медиа
      FeedPostMediaType mediaType;
      if (file.path.toLowerCase().endsWith('.mp4') || 
          file.path.toLowerCase().endsWith('.mov') ||
          file.path.toLowerCase().endsWith('.avi')) {
        mediaType = FeedPostMediaType.video;
      } else if (file.path.toLowerCase().endsWith('.gif')) {
        mediaType = FeedPostMediaType.gif;
      } else {
        mediaType = FeedPostMediaType.image;
      }

      // Получаем размеры файла
      int width = 0;
      int height = 0;
      String? thumbnailUrl;

      if (mediaType == FeedPostMediaType.image) {
        // Для изображений получаем размеры
        // TODO: Добавить обработку изображений
        // final image = await decodeImageFromList(await fileToUpload.readAsBytes());
        width = 400; // Заглушка
        height = 300; // Заглушка
      } else if (mediaType == FeedPostMediaType.video) {
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

      return FeedPostMedia(
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
