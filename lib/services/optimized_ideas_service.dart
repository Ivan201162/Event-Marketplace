import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/idea.dart';
import 'package:flutter/foundation.dart';

/// Оптимизированный сервис для работы с идеями
class OptimizedIdeasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэш для идей
  List<Idea> _cachedIdeas = [];
  DateTime? _ideasCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 20);

  /// Получить идеи с обработкой состояний
  Future<IdeasState> getIdeas({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? category,
    bool forceRefresh = false,
  }) async {
    try {
      // Проверяем кэш для первой загрузки
      if (lastDocument == null && !forceRefresh && _cachedIdeas.isNotEmpty) {
        if (_ideasCacheTime != null &&
            DateTime.now().difference(_ideasCacheTime!) < _cacheExpiry) {
          return IdeasState(
            ideas: _cachedIdeas,
            isLoading: false,
            hasMore: true,
          );
        }
      }

      debugPrint('💡 Загрузка идей из Firestore...');

      Query query = _firestore
          .collection('ideas')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final ideas = snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'],
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          authorAvatar: data['authorAvatar'],
          category: data['category'],
          tags: List<String>.from(data['tags'] ?? []),
          likeCount: data['likeCount']?.toInt() ?? 0,
          commentCount: data['commentCount']?.toInt() ?? 0,
          isLiked: data['isLiked'] ?? false,
          isSaved: data['isSaved'] ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // Обновляем кэш для первой загрузки
      if (lastDocument == null) {
        _cachedIdeas = ideas;
        _ideasCacheTime = DateTime.now();
      }

      debugPrint('✅ Загружено ${ideas.length} идей');

      return IdeasState(
        ideas: ideas,
        isLoading: false,
        hasMore: ideas.length == limit,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки идей: $e');
      return IdeasState(
        ideas: [],
        isLoading: false,
        error: e.toString(),
        hasMore: false,
      );
    }
  }

  /// Создать новую идею
  Future<String?> createIdea({
    required String authorId,
    required String authorName,
    required String title, required String description, String? authorAvatar,
    String? imageUrl,
    String? category,
    List<String>? tags,
  }) async {
    try {
      final ideaData = {
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'category': category,
        'tags': tags ?? [],
        'likeCount': 0,
        'commentCount': 0,
        'isLiked': false,
        'isSaved': false,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('ideas').add(ideaData);

      debugPrint('✅ Идея создана с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Ошибка создания идеи: $e');
      return null;
    }
  }

  /// Лайкнуть/убрать лайк с идеи
  Future<bool> toggleLike(String ideaId, String userId) async {
    try {
      final ideaRef = _firestore.collection('ideas').doc(ideaId);

      await _firestore.runTransaction((transaction) async {
        final ideaDoc = await transaction.get(ideaRef);

        if (!ideaDoc.exists) {
          throw Exception('Идея не найдена');
        }

        final data = ideaDoc.data()!;
        final likeCount = data['likeCount']?.toInt() ?? 0;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        final var isLiked = likedBy.contains(userId);

        if (isLiked) {
          likedBy.remove(userId);
          transaction.update(ideaRef, {
            'likeCount': likeCount - 1,
            'likedBy': likedBy,
            'isLiked': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          likedBy.add(userId);
          transaction.update(ideaRef, {
            'likeCount': likeCount + 1,
            'likedBy': likedBy,
            'isLiked': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при лайке идеи: $e');
      return false;
    }
  }

  /// Сохранить/убрать из сохранённых
  Future<bool> toggleSave(String ideaId, String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Пользователь не найден');
        }

        final data = userDoc.data()!;
        final savedIdeas = List<String>.from(data['savedIdeas'] ?? []);

        final var isSaved = savedIdeas.contains(ideaId);

        if (isSaved) {
          savedIdeas.remove(ideaId);
        } else {
          savedIdeas.add(ideaId);
        }

        transaction.update(userRef, {
          'savedIdeas': savedIdeas,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении идеи: $e');
      return false;
    }
  }

  /// Получить идеи пользователя
  Future<List<Idea>> getUserIdeas(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('authorId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'],
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          authorAvatar: data['authorAvatar'],
          category: data['category'],
          tags: List<String>.from(data['tags'] ?? []),
          likeCount: data['likeCount']?.toInt() ?? 0,
          commentCount: data['commentCount']?.toInt() ?? 0,
          isLiked: data['isLiked'] ?? false,
          isSaved: data['isSaved'] ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки идей пользователя: $e');
      return [];
    }
  }

  /// Получить сохранённые идеи пользователя
  Future<List<Idea>> getSavedIdeas(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      final data = userDoc.data()!;
      final savedIdeas = List<String>.from(data['savedIdeas'] ?? []);

      if (savedIdeas.isEmpty) return [];

      final snapshot = await _firestore
          .collection('ideas')
          .where(FieldPath.documentId, whereIn: savedIdeas)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'],
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          authorAvatar: data['authorAvatar'],
          category: data['category'],
          tags: List<String>.from(data['tags'] ?? []),
          likeCount: data['likeCount']?.toInt() ?? 0,
          commentCount: data['commentCount']?.toInt() ?? 0,
          isLiked: data['isLiked'] ?? false,
          isSaved: true, // Все сохранённые идеи помечены как сохранённые
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки сохранённых идей: $e');
      return [];
    }
  }

  /// Получить популярные идеи
  Future<List<Idea>> getPopularIdeas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('isActive', isEqualTo: true)
          .orderBy('likeCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'],
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          authorAvatar: data['authorAvatar'],
          category: data['category'],
          tags: List<String>.from(data['tags'] ?? []),
          likeCount: data['likeCount']?.toInt() ?? 0,
          commentCount: data['commentCount']?.toInt() ?? 0,
          isLiked: data['isLiked'] ?? false,
          isSaved: data['isSaved'] ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки популярных идей: $e');
      return [];
    }
  }

  /// Очистить кэш
  void clearCache() {
    _cachedIdeas.clear();
    _ideasCacheTime = null;
    debugPrint('🧹 Кэш идей очищен');
  }
}

/// Состояние идей
class IdeasState {

  const IdeasState({
    required this.ideas,
    required this.isLoading,
    required this.hasMore, this.error,
    this.lastDocument,
  });
  final List<Idea> ideas;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  bool get isEmpty => ideas.isEmpty && !isLoading;
  bool get hasError => error != null;
}
