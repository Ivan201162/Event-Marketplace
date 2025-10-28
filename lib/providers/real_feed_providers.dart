import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/enhanced_feed_post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдеры для реальных данных ленты
class RealFeedProviders {
  /// Провайдер для получения всех постов ленты
  static final feedPostsProvider =
      StreamProvider<List<EnhancedFeedPost>>((ref) {
    if (!FeatureFlags.useRealFeedData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedFeedPost(
          id: doc.id,
          authorId: data['authorId'] ?? '',
          authorId: data['authorId'] ?? '',
          content: data['content'] ?? '',
          media: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          sharesCount: data['sharesCount'] ?? 0,
          isLiked: data['isLiked'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          tags: List<String>.from(data['tags'] ?? []),
          location: data['location'],
          category: data['category'],
          isPinned: data['isPinned'] ?? false,
          viewsCount: data['viewsCount'] ?? 0,
        );
      }).toList();
    });
  });

  /// Провайдер для получения постов по категории
  static final feedPostsByCategoryProvider =
      StreamProvider.family<List<EnhancedFeedPost>, String>((ref, category) {
    if (!FeatureFlags.useRealFeedData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedFeedPost(
          id: doc.id,
          authorId: data['authorId'] ?? '',
          authorId: data['authorId'] ?? '',
          content: data['content'] ?? '',
          media: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          sharesCount: data['sharesCount'] ?? 0,
          isLiked: data['isLiked'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          tags: List<String>.from(data['tags'] ?? []),
          location: data['location'],
          category: data['category'],
          isPinned: data['isPinned'] ?? false,
          viewsCount: data['viewsCount'] ?? 0,
        );
      }).toList();
    });
  });

  /// Провайдер для поиска постов
  static final searchPostsProvider =
      FutureProvider.family<List<EnhancedFeedPost>, String>((ref, query) async {
    if (!FeatureFlags.useRealFeedData) {
      return [];
    }

    if (query.isEmpty) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('content')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return EnhancedFeedPost(
        id: doc.id,
        authorId: data['authorId'] ?? '',
        content: data['content'] ?? '',
        likesCount: data['likesCount'] ?? 0,
        commentsCount: data['commentsCount'] ?? 0,
        sharesCount: data['sharesCount'] ?? 0,
        isLiked: data['isLiked'] ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        tags: List<String>.from(data['tags'] ?? []),
        location: data['location'],
        category: data['category'],
        isPinned: data['isPinned'] ?? false,
        viewsCount: data['viewsCount'] ?? 0,
      );
    }).toList();
  });

  /// Провайдер для получения постов пользователя
  static final userPostsProvider =
      StreamProvider.family<List<EnhancedFeedPost>, String>((ref, userId) {
    if (!FeatureFlags.useRealFeedData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedFeedPost(
          id: doc.id,
          authorId: data['authorId'] ?? '',
          authorId: data['authorId'] ?? '',
          content: data['content'] ?? '',
          media: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          sharesCount: data['sharesCount'] ?? 0,
          isLiked: data['isLiked'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          tags: List<String>.from(data['tags'] ?? []),
          location: data['location'],
          category: data['category'],
          isPinned: data['isPinned'] ?? false,
          viewsCount: data['viewsCount'] ?? 0,
        );
      }).toList();
    });
  });

  /// Провайдер для получения популярных постов
  static final popularPostsProvider =
      StreamProvider<List<EnhancedFeedPost>>((ref) {
    if (!FeatureFlags.useRealFeedData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('engagementRate', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedFeedPost(
          id: doc.id,
          authorId: data['authorId'] ?? '',
          authorId: data['authorId'] ?? '',
          content: data['content'] ?? '',
          media: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          sharesCount: data['sharesCount'] ?? 0,
          isLiked: data['isLiked'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          tags: List<String>.from(data['tags'] ?? []),
          location: data['location'],
          category: data['category'],
          isPinned: data['isPinned'] ?? false,
          viewsCount: data['viewsCount'] ?? 0,
        );
      }).toList();
    });
  });

  /// Провайдер для получения закрепленных постов
  static final pinnedPostsProvider =
      StreamProvider<List<EnhancedFeedPost>>((ref) {
    if (!FeatureFlags.useRealFeedData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('posts')
        .where('isPinned', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedFeedPost(
          id: doc.id,
          authorId: data['authorId'] ?? '',
          authorId: data['authorId'] ?? '',
          content: data['content'] ?? '',
          media: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          sharesCount: data['sharesCount'] ?? 0,
          isLiked: data['isLiked'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          tags: List<String>.from(data['tags'] ?? []),
          location: data['location'],
          category: data['category'],
          isPinned: data['isPinned'] ?? false,
          viewsCount: data['viewsCount'] ?? 0,
        );
      }).toList();
    });
  });

  /// Провайдер для состояния загрузки ленты
  static final feedLoadingProvider = Provider<bool>((ref) => false);

  /// Провайдер для ошибок загрузки ленты
  static final feedErrorProvider = Provider<String?>((ref) => null);
}
