import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user.dart';
import '../models/user_profile.dart';

/// Сервис для работы с профилями пользователей
class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Коллекции
  static const String _profilesCollection = 'user_profiles';
  static const String _postsCollection = 'user_posts';
  static const String _storiesCollection = 'user_stories';
  static const String _reviewsCollection = 'user_reviews';

  /// Получить профиль пользователя по ID
  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection(_profilesCollection).doc(userId).get();

      if (doc.exists) {
        return UserProfile.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения профиля: $e');
      return null;
    }
  }

  /// Создать или обновить профиль пользователя
  static Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_profilesCollection)
          .doc(profile.id)
          .set(profile.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Ошибка сохранения профиля: $e');
      return false;
    }
  }

  /// Создать профиль из AppUser
  static Future<bool> createProfileFromUser(AppUser user) async {
    try {
      final profile = UserProfile.fromAppUser(user);
      return await saveUserProfile(profile);
    } catch (e) {
      print('Ошибка создания профиля из пользователя: $e');
      return false;
    }
  }

  /// Обновить аватар пользователя
  static Future<String?> updateAvatar(String userId, String imagePath) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      await ref.putFile(File(imagePath));
      final downloadUrl = await ref.getDownloadURL();

      await _firestore
          .collection(_profilesCollection)
          .doc(userId)
          .update({'avatarUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Ошибка обновления аватара: $e');
      return null;
    }
  }

  /// Обновить обложку профиля
  static Future<String?> updateCover(String userId, String imagePath) async {
    try {
      final ref = _storage.ref().child('covers/$userId.jpg');
      await ref.putFile(File(imagePath));
      final downloadUrl = await ref.getDownloadURL();

      await _firestore
          .collection(_profilesCollection)
          .doc(userId)
          .update({'coverUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Ошибка обновления обложки: $e');
      return null;
    }
  }

  /// Получить посты пользователя
  static Stream<List<UserPost>> getUserPosts(String userId) => _firestore
      .collection(_postsCollection)
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => UserPost.fromMap(doc.data())).toList(),
      );

  /// Создать пост
  static Future<bool> createPost(UserPost post) async {
    try {
      await _firestore
          .collection(_postsCollection)
          .doc(post.id)
          .set(post.toMap());
      return true;
    } catch (e) {
      print('Ошибка создания поста: $e');
      return false;
    }
  }

  /// Обновить пост
  static Future<bool> updatePost(UserPost post) async {
    try {
      await _firestore
          .collection(_postsCollection)
          .doc(post.id)
          .update(post.toMap());
      return true;
    } catch (e) {
      print('Ошибка обновления поста: $e');
      return false;
    }
  }

  /// Удалить пост
  static Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления поста: $e');
      return false;
    }
  }

  /// Лайкнуть/убрать лайк с поста
  static Future<bool> togglePostLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(_postsCollection).doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) return false;

      final post = UserPost.fromMap(postDoc.data()!);
      final isLiked = post.likedBy.contains(userId);

      if (isLiked) {
        // Убираем лайк
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Добавляем лайк
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }

      return true;
    } catch (e) {
      print('Ошибка лайка поста: $e');
      return false;
    }
  }

  /// Получить активные сторис пользователя
  static Stream<List<UserStory>> getUserStories(String userId) => _firestore
      .collection(_storiesCollection)
      .where('userId', isEqualTo: userId)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => UserStory.fromMap(doc.data())).toList(),
      );

  /// Создать сторис
  static Future<bool> createStory(UserStory story) async {
    try {
      await _firestore
          .collection(_storiesCollection)
          .doc(story.id)
          .set(story.toMap());
      return true;
    } catch (e) {
      print('Ошибка создания сторис: $e');
      return false;
    }
  }

  /// Удалить сторис
  static Future<bool> deleteStory(String storyId) async {
    try {
      await _firestore.collection(_storiesCollection).doc(storyId).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления сторис: $e');
      return false;
    }
  }

  /// Отметить сторис как просмотренную
  static Future<bool> markStoryAsViewed(String storyId, String userId) async {
    try {
      await _firestore.collection(_storiesCollection).doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      print('Ошибка отметки сторис как просмотренной: $e');
      return false;
    }
  }

  /// Получить отзывы специалиста
  static Stream<List<UserReview>> getSpecialistReviews(String specialistId) =>
      _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserReview.fromMap(doc.data()))
                .toList(),
          );

  /// Создать отзыв
  static Future<bool> createReview(UserReview review) async {
    try {
      await _firestore
          .collection(_reviewsCollection)
          .doc(review.id)
          .set(review.toMap());

      // Обновляем рейтинг специалиста
      await _updateSpecialistRating(review.specialistId);

      return true;
    } catch (e) {
      print('Ошибка создания отзыва: $e');
      return false;
    }
  }

  /// Обновить рейтинг специалиста
  static Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (final doc in reviewsSnapshot.docs) {
        final review = UserReview.fromMap(doc.data());
        totalRating += review.rating;
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore
          .collection(_profilesCollection)
          .doc(specialistId)
          .update({'rating': averageRating});
    } catch (e) {
      print('Ошибка обновления рейтинга: $e');
    }
  }

  /// Обновить прайс-лист специалиста
  static Future<bool> updateServices(
    String userId,
    List<ServicePrice> services,
  ) async {
    try {
      await _firestore.collection(_profilesCollection).doc(userId).update({
        'services': services.map((service) => service.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Ошибка обновления прайс-листа: $e');
      return false;
    }
  }

  /// Подписаться/отписаться от пользователя
  static Future<bool> toggleFollow(
    String followerId,
    String followingId,
  ) async {
    try {
      final batch = _firestore.batch();

      // Обновляем подписки подписчика
      final followerRef =
          _firestore.collection(_profilesCollection).doc(followerId);
      final followerDoc = await followerRef.get();

      if (followerDoc.exists) {
        final followerProfile = UserProfile.fromDocument(followerDoc);
        final isFollowing = followerProfile.additionalData['following']
                ?.contains(followingId) ??
            false;

        if (isFollowing) {
          batch.update(followerRef, {
            'following': FieldValue.increment(-1),
            'additionalData.following': FieldValue.arrayRemove([followingId]),
          });
        } else {
          batch.update(followerRef, {
            'following': FieldValue.increment(1),
            'additionalData.following': FieldValue.arrayUnion([followingId]),
          });
        }
      }

      // Обновляем подписчиков пользователя
      final followingRef =
          _firestore.collection(_profilesCollection).doc(followingId);
      final followingDoc = await followingRef.get();

      if (followingDoc.exists) {
        final followingProfile = UserProfile.fromDocument(followingDoc);
        final hasFollower = followingProfile.additionalData['followers']
                ?.contains(followerId) ??
            false;

        if (hasFollower) {
          batch.update(followingRef, {
            'followers': FieldValue.increment(-1),
            'additionalData.followers': FieldValue.arrayRemove([followerId]),
          });
        } else {
          batch.update(followingRef, {
            'followers': FieldValue.increment(1),
            'additionalData.followers': FieldValue.arrayUnion([followerId]),
          });
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Ошибка подписки/отписки: $e');
      return false;
    }
  }

  /// Получить рекомендуемых специалистов
  static Future<List<UserProfile>> getRecommendedSpecialists(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_profilesCollection)
          .where('role', isEqualTo: 'specialist')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(UserProfile.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения рекомендуемых специалистов: $e');
      return [];
    }
  }

  /// Поиск специалистов
  static Future<List<UserProfile>> searchSpecialists(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_profilesCollection)
          .where('role', isEqualTo: 'specialist')
          .get();

      final profiles = snapshot.docs.map(UserProfile.fromDocument).toList();

      // Фильтруем по имени, биографии и городу
      return profiles.where((profile) {
        final searchText = query.toLowerCase();
        return profile.name.toLowerCase().contains(searchText) ||
            profile.bio.toLowerCase().contains(searchText) ||
            profile.city.toLowerCase().contains(searchText);
      }).toList();
    } catch (e) {
      print('Ошибка поиска специалистов: $e');
      return [];
    }
  }

  /// Загрузить медиа файл
  static Future<String?> uploadMedia(
    String userId,
    String filePath,
    String type,
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$type/$userId/$fileName');
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Ошибка загрузки медиа: $e');
      return null;
    }
  }

  /// Удалить медиа файл
  static Future<bool> deleteMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      print('Ошибка удаления медиа: $e');
      return false;
    }
  }
}
