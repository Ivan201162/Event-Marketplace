import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'feed_model.dart';
import 'feed_notification_service.dart';

/// Сервис для работы с лентой активности
class FeedService {
  factory FeedService() => _instance;
  FeedService._internal();
  static final FeedService _instance = FeedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final FeedNotificationService _notificationService =
      FeedNotificationService();

  /// Получение постов по городу
  Stream<List<FeedPost>> getPostsByCity(String city) => _firestore
      .collection('posts')
      .where('authorCity', isEqualTo: city)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => FeedPost.fromMap(doc.data())).toList());

  /// Получение постов от подписанных пользователей
  Stream<List<FeedPost>> getPostsBySubscriptions(List<String> followedIds) {
    if (followedIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('posts')
        .where('authorId', whereIn: followedIds)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FeedPost.fromMap(doc.data())).toList());
  }

  /// Комбинированный поток постов (город + подписки)
  Stream<List<FeedPost>> getCombinedFeed({
    required String city,
    required List<String> followedIds,
  }) {
    final cityPosts = getPostsByCity(city);
    final followedPosts = getPostsBySubscriptions(followedIds);

    return Rx.combineLatest2(cityPosts, followedPosts, (city, followed) {
      // Объединяем посты и убираем дубликаты
      final allPosts = <String, FeedPost>{};

      for (final post in city) {
        allPosts[post.id] = post;
      }

      for (final post in followed) {
        allPosts[post.id] = post;
      }

      // Сортируем по дате создания
      final sortedPosts = allPosts.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sortedPosts;
    });
  }

  /// Получение постов с фильтрацией
  Stream<List<FeedPost>> getFilteredPosts({
    required String city,
    required List<String> followedIds,
    required FeedFilter filter,
    String? category,
  }) {
    Stream<List<FeedPost>> baseStream;

    switch (filter) {
      case FeedFilter.subscriptions:
        baseStream = getPostsBySubscriptions(followedIds);
        break;
      case FeedFilter.photos:
        baseStream = getPostsByCity(
          city,
        ).map((posts) =>
            posts.where((post) => post.type == PostType.photo).toList());
        break;
      case FeedFilter.videos:
        baseStream = getPostsByCity(
          city,
        ).map((posts) =>
            posts.where((post) => post.type == PostType.video).toList());
        break;
      case FeedFilter.categories:
        if (category != null) {
          baseStream = getPostsByCity(city).map(
            (posts) => posts
                .where((post) => post.taggedCategories.contains(category))
                .toList(),
          );
        } else {
          baseStream = getPostsByCity(city);
        }
        break;
      case FeedFilter.all:
      default:
        baseStream = getCombinedFeed(city: city, followedIds: followedIds);
        break;
    }

    return baseStream;
  }

  /// Лайк поста
  Future<void> likePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      FeedPost? originalPost;
      List<String>? finalLikedBy;

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Пост не найден');
        }

        final post = FeedPost.fromMap(postDoc.data()!);
        originalPost = post;
        final likedBy = List<String>.from(post.likedBy);

        if (likedBy.contains(userId)) {
          // Убираем лайк
          likedBy.remove(userId);
        } else {
          // Добавляем лайк
          likedBy.add(userId);
        }

        finalLikedBy = likedBy;
        final updatedPost =
            post.copyWith(likes: likedBy.length, likedBy: likedBy);

        transaction.update(postRef, updatedPost.toMap());
      });

      // Отправляем уведомление о лайке (только если лайк был добавлен)
      if (originalPost != null && finalLikedBy != null) {
        final wasLiked = originalPost!.likedBy.contains(userId);
        final isLiked = finalLikedBy!.contains(userId);

        if (!wasLiked && isLiked) {
          await _notificationService.sendLikeNotification(
            postId: postId,
            postAuthorId: originalPost!.authorId,
            likerId: userId,
            likerName:
                'Пользователь', // TODO(developer): Получить имя пользователя
          );
        }
      }
    } catch (e) {
      throw Exception('Ошибка при лайке поста: $e');
    }
  }

  /// Добавление комментария к посту
  Future<void> addComment(String postId, FeedComment comment) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      FeedPost? originalPost;

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Пост не найден');
        }

        final post = FeedPost.fromMap(postDoc.data()!);
        originalPost = post;
        final comments = List<FeedComment>.from(post.comments);
        comments.add(comment);

        final updatedPost =
            post.copyWith(comments: comments, commentsCount: comments.length);

        transaction.update(postRef, updatedPost.toMap());
      });

      // Отправляем уведомление о комментарии
      if (originalPost != null) {
        await _notificationService.sendCommentNotification(
          postId: postId,
          postAuthorId: originalPost!.authorId,
          commenterId: comment.authorId,
          commenterName: comment.authorName,
          commentText: comment.text,
        );
      }
    } catch (e) {
      throw Exception('Ошибка при добавлении комментария: $e');
    }
  }

  /// Создание нового поста
  Future<void> addPost(FeedPost post) async {
    try {
      await _firestore.collection('posts').doc(post.id).set(post.toMap());

      // Отправляем уведомления подписчикам о новом посте
      await _notificationService.sendNewPostNotification(
        postId: post.id,
        authorId: post.authorId,
        authorName: post.authorName,
        postDescription: post.description,
      );
    } catch (e) {
      throw Exception('Ошибка при создании поста: $e');
    }
  }

  /// Загрузка медиа файла
  Future<String> uploadMedia(File file, String userId, PostType type) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      final extension = file.path.split('.').last;
      final fullFileName = '$fileName.$extension';

      final ref = _storage.ref().child('posts/$fullFileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка при загрузке медиа: $e');
    }
  }

  /// Выбор изображения
  Future<File?> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Ошибка при выборе изображения: $e');
    }
  }

  /// Выбор видео
  Future<File?> pickVideo() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1), // Максимум 1 минута
      );

      return video != null ? File(video.path) : null;
    } catch (e) {
      throw Exception('Ошибка при выборе видео: $e');
    }
  }

  /// Создание поста с медиа
  Future<void> createPostWithMedia({
    required String userId,
    required String userName,
    required String userCity,
    required String userAvatar,
    required String description,
    required List<String> taggedCategories,
    required PostType type,
    File? mediaFile,
  }) async {
    try {
      String? mediaUrl;

      if (mediaFile != null) {
        mediaUrl = await uploadMedia(mediaFile, userId, type);
      }

      final post = FeedPost(
        id: _firestore.collection('posts').doc().id,
        authorId: userId,
        authorName: userName,
        authorCity: userCity,
        authorAvatar: userAvatar,
        mediaUrl: mediaUrl ?? '',
        description: description,
        createdAt: DateTime.now(),
        likes: 0,
        commentsCount: 0,
        type: type,
        taggedCategories: taggedCategories,
      );

      await addPost(post);
    } catch (e) {
      throw Exception('Ошибка при создании поста: $e');
    }
  }

  /// Удаление поста
  Future<void> deletePost(String postId, String userId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        throw Exception('Пост не найден');
      }

      final post = FeedPost.fromMap(postDoc.data()!);

      if (post.authorId != userId) {
        throw Exception('Недостаточно прав для удаления поста');
      }

      // Удаляем медиа файл из Storage
      if (post.mediaUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(post.mediaUrl);
          await ref.delete();
        } catch (e) {
          // Игнорируем ошибки удаления файла
        }
      }

      // Удаляем пост из Firestore
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Ошибка при удалении поста: $e');
    }
  }

  /// Получение постов пользователя
  Stream<List<FeedPost>> getUserPosts(String userId) => _firestore
      .collection('posts')
      .where('authorId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => FeedPost.fromMap(doc.data())).toList());
}
