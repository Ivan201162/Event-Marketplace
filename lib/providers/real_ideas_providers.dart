import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea.dart';
import '../core/feature_flags.dart';

/// Провайдеры для реальных данных идей
class RealIdeasProviders {
  /// Провайдер для получения всех идей
  static final ideasProvider = StreamProvider<List<Idea>>((ref) {
    if (!FeatureFlags.useRealIdeasData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('ideas')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          category: data['category'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          images: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          viewsCount: data['viewsCount'] ?? 0,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  });

  /// Провайдер для получения идей по категории
  static final ideasByCategoryProvider = StreamProvider.family<List<Idea>, String>((ref, category) {
    if (!FeatureFlags.useRealIdeasData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('ideas')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          category: data['category'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          images: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          viewsCount: data['viewsCount'] ?? 0,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  });

  /// Провайдер для поиска идей
  static final searchIdeasProvider = FutureProvider.family<List<Idea>, String>((ref, query) async {
    if (!FeatureFlags.useRealIdeasData) {
      return [];
    }

    if (query.isEmpty) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('ideas')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('title')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Idea(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? 'Неизвестный автор',
        category: data['category'] ?? '',
        tags: List<String>.from(data['tags'] ?? []),
        images: List<String>.from(data['images'] ?? []),
        likesCount: data['likesCount'] ?? 0,
        commentsCount: data['commentsCount'] ?? 0,
        viewsCount: data['viewsCount'] ?? 0,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    }).toList();
  });

  /// Провайдер для получения идей пользователя
  static final userIdeasProvider = StreamProvider.family<List<Idea>, String>((ref, userId) {
    if (!FeatureFlags.useRealIdeasData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('ideas')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          category: data['category'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          images: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          viewsCount: data['viewsCount'] ?? 0,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  });

  /// Провайдер для получения популярных идей
  static final popularIdeasProvider = StreamProvider<List<Idea>>((ref) {
    if (!FeatureFlags.useRealIdeasData) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('ideas')
        .orderBy('engagementRate', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          category: data['category'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          images: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          viewsCount: data['viewsCount'] ?? 0,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  });

  /// Провайдер для получения рекомендуемых идей
  static final recommendedIdeasProvider = StreamProvider.family<List<Idea>, String>((ref, userId) {
    if (!FeatureFlags.useRealIdeasData) {
      return Stream.value([]);
    }

    // TODO: Реализовать алгоритм рекомендаций на основе предпочтений пользователя
    return FirebaseFirestore.instance
        .collection('ideas')
        .where('isPublic', isEqualTo: true)
        .orderBy('engagementRate', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          category: data['category'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          images: List<String>.from(data['images'] ?? []),
          likesCount: data['likesCount'] ?? 0,
          commentsCount: data['commentsCount'] ?? 0,
          viewsCount: data['viewsCount'] ?? 0,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  });

  /// Провайдер для состояния загрузки идей
  static final ideasLoadingProvider = Provider<bool>((ref) => false);

  /// Провайдер для ошибок загрузки идей
  static final ideasErrorProvider = Provider<String?>((ref) => null);
}
