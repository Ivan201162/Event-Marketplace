import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/event_idea.dart';

/// Сервис для работы с идеями мероприятий
class EventIdeasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Создать новую идею
  Future<String> createIdea({
    required String title,
    required String description,
    required List<String> imageUrls,
    required List<String> tags,
    required String createdBy,
    required EventIdeaType type,
    String? location,
    int? budget,
    int? guestCount,
    String? colorScheme,
    String? style,
  }) async {
    try {
      final idea = EventIdea(
        id: '', // Будет установлен Firestore
        title: title,
        description: description,
        images: imageUrls,
        tags: tags,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: type,
        location: location,
        budget: budget,
        guestCount: guestCount,
        colorScheme: colorScheme,
        style: style,
      );

      final docRef = await _firestore.collection('eventIdeas').add(idea.toMap());
      
      debugPrint('Event idea created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating event idea: $e');
      throw Exception('Ошибка создания идеи: $e');
    }
  }

  /// Получить все идеи с пагинацией
  Stream<List<EventIdea>> getIdeas({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    EventIdeaType? type,
    List<String>? tags,
    String? searchQuery,
  }) {
    Query query = _firestore
        .collection('eventIdeas')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    });
  }

  /// Получить рекомендуемые идеи
  Stream<List<EventIdea>> getFeaturedIdeas({int limit = 10}) {
    return _firestore
        .collection('eventIdeas')
        .where('isPublic', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('likesCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    });
  }

  /// Получить популярные идеи
  Stream<List<EventIdea>> getPopularIdeas({int limit = 20}) {
    return _firestore
        .collection('eventIdeas')
        .where('isPublic', isEqualTo: true)
        .orderBy('likesCount', descending: true)
        .orderBy('savesCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    });
  }

  /// Получить идеи по типу
  Stream<List<EventIdea>> getIdeasByType(EventIdeaType type, {int limit = 20}) {
    return _firestore
        .collection('eventIdeas')
        .where('isPublic', isEqualTo: true)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    });
  }

  /// Поиск идей
  Stream<List<EventIdea>> searchIdeas(String query, {int limit = 20}) {
    if (query.trim().isEmpty) {
      return getIdeas(limit: limit);
    }

    return _firestore
        .collection('eventIdeas')
        .where('isPublic', isEqualTo: true)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    });
  }

  /// Получить идеи пользователя
  Stream<List<EventIdea>> getUserIdeas(String userId, {int limit = 20}) {
    return _firestore
        .collection('eventIdeas')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    });
  }

  /// Получить сохраненные идеи пользователя
  Stream<List<EventIdea>> getSavedIdeas(String userId, {int limit = 20}) {
    return _firestore
        .collection('eventIdeas')
        .where('savedBy', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    });
  }

  /// Лайкнуть идею
  Future<void> likeIdea(String ideaId, String userId) async {
    try {
      final ideaRef = _firestore.collection('eventIdeas').doc(ideaId);
      
      await _firestore.runTransaction((transaction) async {
        final ideaDoc = await transaction.get(ideaRef);
        if (!ideaDoc.exists) return;

        final idea = EventIdea.fromDocument(ideaDoc);
        final isLiked = idea.isLikedBy(userId);
        
        if (isLiked) {
          // Убираем лайк
          transaction.update(ideaRef, {
            'likedBy': FieldValue.arrayRemove([userId]),
            'likesCount': FieldValue.increment(-1),
          });
        } else {
          // Добавляем лайк
          transaction.update(ideaRef, {
            'likedBy': FieldValue.arrayUnion([userId]),
            'likesCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error liking idea: $e');
      throw Exception('Ошибка лайка идеи: $e');
    }
  }

  /// Сохранить идею
  Future<void> saveIdea(String ideaId, String userId) async {
    try {
      final ideaRef = _firestore.collection('eventIdeas').doc(ideaId);
      
      await _firestore.runTransaction((transaction) async {
        final ideaDoc = await transaction.get(ideaRef);
        if (!ideaDoc.exists) return;

        final idea = EventIdea.fromDocument(ideaDoc);
        final isSaved = idea.isSavedBy(userId);
        
        if (isSaved) {
          // Убираем из сохраненных
          transaction.update(ideaRef, {
            'savedBy': FieldValue.arrayRemove([userId]),
            'savesCount': FieldValue.increment(-1),
          });
        } else {
          // Добавляем в сохраненные
          transaction.update(ideaRef, {
            'savedBy': FieldValue.arrayUnion([userId]),
            'savesCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error saving idea: $e');
      throw Exception('Ошибка сохранения идеи: $e');
    }
  }

  /// Увеличить счетчик просмотров
  Future<void> incrementViews(String ideaId) async {
    try {
      await _firestore.collection('eventIdeas').doc(ideaId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  /// Обновить идею
  Future<void> updateIdea(EventIdea idea) async {
    try {
      await _firestore.collection('eventIdeas').doc(idea.id).update({
        ...idea.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Event idea updated: ${idea.id}');
    } catch (e) {
      debugPrint('Error updating event idea: $e');
      throw Exception('Ошибка обновления идеи: $e');
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection('eventIdeas').doc(ideaId).delete();
      
      debugPrint('Event idea deleted: $ideaId');
    } catch (e) {
      debugPrint('Error deleting event idea: $e');
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Получить идею по ID
  Future<EventIdea?> getIdeaById(String ideaId) async {
    try {
      final doc = await _firestore.collection('eventIdeas').doc(ideaId).get();
      if (!doc.exists) return null;
      
      return EventIdea.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting idea by ID: $e');
      return null;
    }
  }

  /// Загрузить изображение
  Future<String> uploadImage(String filePath, Uint8List fileBytes) async {
    try {
      final ref = _storage.ref().child('event_ideas/$filePath');
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Получить статистику идей
  Future<Map<String, dynamic>> getIdeasStats() async {
    try {
      final ideasQuery = await _firestore
          .collection('eventIdeas')
          .where('isPublic', isEqualTo: true)
          .get();

      if (ideasQuery.docs.isEmpty) {
        return {
          'totalIdeas': 0,
          'totalLikes': 0,
          'totalSaves': 0,
          'totalViews': 0,
          'typeDistribution': {},
          'popularTags': [],
        };
      }

      int totalLikes = 0;
      int totalSaves = 0;
      int totalViews = 0;
      final typeDistribution = <String, int>{};
      final tagCounts = <String, int>{};

      for (final doc in ideasQuery.docs) {
        final data = doc.data();
        totalLikes += data['likesCount'] as int? ?? 0;
        totalSaves += data['savesCount'] as int? ?? 0;
        totalViews += data['viewsCount'] as int? ?? 0;
        
        final type = data['type'] as String? ?? 'other';
        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
        
        final tags = (data['tags'] as List<dynamic>?)?.cast<String>() ?? [];
        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Получаем топ-10 тегов
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final popularTags = sortedTags.take(10).map((e) => e.key).toList();

      return {
        'totalIdeas': ideasQuery.docs.length,
        'totalLikes': totalLikes,
        'totalSaves': totalSaves,
        'totalViews': totalViews,
        'typeDistribution': typeDistribution,
        'popularTags': popularTags,
      };
    } catch (e) {
      debugPrint('Error getting ideas stats: $e');
      return {};
    }
  }

  /// Получить похожие идеи
  Future<List<EventIdea>> getSimilarIdeas(String ideaId, {int limit = 5}) async {
    try {
      final idea = await getIdeaById(ideaId);
      if (idea == null) return [];

      // Ищем идеи с похожими тегами
      final similarQuery = await _firestore
          .collection('eventIdeas')
          .where('isPublic', isEqualTo: true)
          .where('tags', arrayContainsAny: idea.tags)
          .where('id', isNotEqualTo: ideaId)
          .limit(limit)
          .get();

      return similarQuery.docs.map((doc) => EventIdea.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('Error getting similar ideas: $e');
      return [];
    }
  }

  /// Отметить идею как рекомендуемую
  Future<void> markAsFeatured(String ideaId, bool isFeatured) async {
    try {
      await _firestore.collection('eventIdeas').doc(ideaId).update({
        'isFeatured': isFeatured,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Idea featured status updated: $ideaId');
    } catch (e) {
      debugPrint('Error updating featured status: $e');
      throw Exception('Ошибка обновления статуса рекомендации: $e');
    }
  }
}