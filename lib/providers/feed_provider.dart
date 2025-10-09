import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_post.dart';

/// Провайдер для ленты новостей с тестовыми данными
final feedProvider = StreamProvider<List<FeedPost>>((ref) async* {
  // Сначала пытаемся загрузить из Firestore
  try {
    await for (final snapshot in FirebaseFirestore.instance
        .collection('feed')
        .orderBy('createdAt', descending: true)
        .snapshots()) {
      final posts = snapshot.docs.map(FeedPost.fromFirestore).toList();

      // Если нет данных, добавляем тестовые
      if (posts.isEmpty) {
        yield _getTestFeedPosts();
      } else {
        yield posts;
      }
    }
  } catch (e) {
    // В случае ошибки возвращаем тестовые данные
    yield _getTestFeedPosts();
  }
});

/// Тестовые данные для ленты
List<FeedPost> _getTestFeedPosts() => [
      FeedPost(
        id: 'test_1',
        authorId: 'author_1',
        authorName: 'Анна Фотограф',
        authorAvatar: 'https://picsum.photos/200/200?random=1',
        description: 'Красивая свадьба в стиле бохо 🌸✨',
        imageUrl: 'https://picsum.photos/400/600?random=1',
        location: 'Москва',
        likeCount: 24,
        commentCount: 8,
        isLiked: false,
        isSaved: false,
        isFollowing: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      FeedPost(
        id: 'test_2',
        authorId: 'author_2',
        authorName: 'Максим Ведущий',
        authorAvatar: 'https://picsum.photos/200/200?random=2',
        description: 'Отличная вечеринка в честь дня рождения! 🎉',
        imageUrl: 'https://picsum.photos/400/600?random=2',
        location: 'Санкт-Петербург',
        likeCount: 18,
        commentCount: 5,
        isLiked: true,
        isSaved: false,
        isFollowing: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      FeedPost(
        id: 'test_3',
        authorId: 'author_3',
        authorName: 'Елена Декор',
        authorAvatar: 'https://picsum.photos/200/200?random=3',
        description: 'Создаем волшебную атмосферу для вашего праздника ✨',
        imageUrl: 'https://picsum.photos/400/600?random=3',
        location: 'Казань',
        likeCount: 31,
        commentCount: 12,
        isLiked: false,
        isSaved: true,
        isFollowing: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      FeedPost(
        id: 'test_4',
        authorId: 'author_4',
        authorName: 'Дмитрий Диджей',
        authorAvatar: 'https://picsum.photos/200/200?random=4',
        description: 'Музыка - это душа любого праздника! 🎵',
        imageUrl: 'https://picsum.photos/400/600?random=4',
        location: 'Екатеринбург',
        likeCount: 15,
        commentCount: 3,
        isLiked: false,
        isSaved: false,
        isFollowing: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      FeedPost(
        id: 'test_5',
        authorId: 'author_5',
        authorName: 'Ольга Кейтеринг',
        authorAvatar: 'https://picsum.photos/200/200?random=5',
        description: 'Вкусные угощения для вашего торжества 🍰',
        imageUrl: 'https://picsum.photos/400/600?random=5',
        location: 'Новосибирск',
        likeCount: 42,
        commentCount: 18,
        isLiked: true,
        isSaved: true,
        isFollowing: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

/// Провайдер для управления лентой
class FeedNotifier extends StateNotifier<AsyncValue<List<FeedPost>>> {
  FeedNotifier() : super(const AsyncValue.loading()) {
    _loadFeed();
  }

  void _loadFeed() {
    FirebaseFirestore.instance
        .collection('feed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final posts = snapshot.docs.map(FeedPost.fromFirestore).toList();
      state = AsyncValue.data(posts);
    });
  }

  /// Создать новый пост
  Future<void> createPost({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String description,
    String? imageUrl,
    String? location,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('feed').add({
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'description': description,
        'imageUrl': imageUrl,
        'location': location,
        'likeCount': 0,
        'commentCount': 0,
        'isLiked': false,
        'isSaved': false,
        'isFollowing': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      print('Ошибка при создании поста: $e');
    }
  }

  /// Поставить/убрать лайк
  Future<void> toggleLike(String postId, bool isLiked) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('feed').doc(postId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (postDoc.exists) {
          final currentLikes = postDoc.data()?['likeCount'] ?? 0;
          final newLikes = isLiked ? currentLikes - 1 : currentLikes + 1;
          transaction.update(postRef, {
            'likeCount': newLikes,
            'isLiked': !isLiked,
          });
        }
      });
    } on Exception catch (e) {
      print('Ошибка при изменении лайка: $e');
    }
  }

  /// Сохранить/убрать из сохранённых
  Future<void> toggleSave(String postId, bool isSaved) async {
    try {
      await FirebaseFirestore.instance
          .collection('feed')
          .doc(postId)
          .update({'isSaved': !isSaved});
    } on Exception catch (e) {
      print('Ошибка при изменении сохранения: $e');
    }
  }

  /// Подписаться/отписаться
  Future<void> toggleFollow(String postId, bool isFollowing) async {
    try {
      await FirebaseFirestore.instance
          .collection('feed')
          .doc(postId)
          .update({'isFollowing': !isFollowing});
    } on Exception catch (e) {
      print('Ошибка при изменении подписки: $e');
    }
  }

  /// Добавить комментарий
  Future<void> addComment(String postId, String comment) async {
    try {
      final postRef = FirebaseFirestore.instance.collection('feed').doc(postId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (postDoc.exists) {
          final currentComments = postDoc.data()?['commentCount'] ?? 0;
          transaction.update(postRef, {
            'commentCount': currentComments + 1,
          });
        }
      });

      // Добавляем комментарий в подколлекцию
      await FirebaseFirestore.instance
          .collection('feed')
          .doc(postId)
          .collection('comments')
          .add({
        'text': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      print('Ошибка при добавлении комментария: $e');
    }
  }
}

final feedNotifierProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<FeedPost>>>(
        (ref) => FeedNotifier());
