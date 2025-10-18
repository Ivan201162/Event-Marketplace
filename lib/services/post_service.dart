import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';

/// Сервис для работы с постами
class PostService {
  factory PostService() => _instance;
  PostService._internal();
  static final PostService _instance = PostService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

  /// Получить посты специалиста
  Future<List<Post>> getPostsBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Post.fromDocument).toList();
    } catch (e) {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestPosts(specialistId);
    }
  }

  /// Получить все посты
  Future<List<Post>> getAllPosts() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map(Post.fromDocument).toList();
    } catch (e) {
      // Возвращаем тестовые данные в случае ошибки
      return _getTestPosts('test_specialist');
    }
  }

  /// Создать пост
  Future<String> createPost(Post post) async {
    try {
      final docRef = await _firestore.collection(_collection).add(post.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания поста: $e');
    }
  }

  /// Обновить пост
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(postId).update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления поста: $e');
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления поста: $e');
    }
  }

  /// Лайкнуть пост
  Future<void> likePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(_collection).doc(postId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return;

        final post = Post.fromDocument(snapshot);
        final likedBy = List<String>.from(post.likedBy);

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }

        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': likedBy.length,
        });
      });
    } catch (e) {
      throw Exception('Ошибка лайка поста: $e');
    }
  }

  /// Переключить лайк поста (алиас для likePost)
  Future<void> toggleLike(String postId, String userId) async {
    return likePost(postId, userId);
  }

  /// Тестовые данные
  List<Post> _getTestPosts(String specialistId) => [
        Post(
          id: '1',
          specialistId: specialistId,
          text: 'Отличная свадебная фотосессия в парке! 🌸',
          mediaUrls: [
            'https://placehold.co/400x400/FF6B6B/white?text=Wedding+1',
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          likesCount: 42,
          commentsCount: 8,
          likedBy: ['user1', 'user2', 'user3'],
        ),
        Post(
          id: '2',
          specialistId: specialistId,
          text: 'Портретная съёмка в студии с профессиональным освещением',
          mediaUrls: [
            'https://placehold.co/400x400/4ECDC4/white?text=Portrait+1',
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          likesCount: 28,
          commentsCount: 5,
          likedBy: ['user1', 'user4'],
        ),
        Post(
          id: '3',
          specialistId: specialistId,
          text: 'Семейная фотосессия на природе. Счастье в каждом кадре! ❤️',
          mediaUrls: [
            'https://placehold.co/400x400/45B7D1/white?text=Family+1',
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          likesCount: 67,
          commentsCount: 12,
          likedBy: ['user2', 'user3', 'user5'],
        ),
        Post(
          id: '4',
          specialistId: specialistId,
          text: 'Корпоративная съёмка для IT-компании',
          mediaUrls: [
            'https://placehold.co/400x400/96CEB4/white?text=Corporate+1',
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          likesCount: 15,
          commentsCount: 3,
          likedBy: ['user1'],
        ),
        Post(
          id: '5',
          specialistId: specialistId,
          text: 'Детская фотосессия в студии. Такие милые малыши! 👶',
          mediaUrls: ['https://placehold.co/400x400/FFEAA7/white?text=Kids+1'],
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          likesCount: 89,
          commentsCount: 18,
          likedBy: ['user1', 'user2', 'user3', 'user4', 'user5'],
        ),
      ];
}
