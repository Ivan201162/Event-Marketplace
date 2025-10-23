import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/idea.dart';

/// Репозиторий для работы с идеями в Firestore
class IdeasRepository {
  factory IdeasRepository() => _instance;
  IdeasRepository._internal();
  static final IdeasRepository _instance = IdeasRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получение всех идей с фильтрацией
  Stream<List<Idea>> streamList({
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    try {
      debugPrint(
        'IdeasRepository.streamList: category=$category, searchQuery=$searchQuery, limit=$limit',
      );

      Query query = _firestore
          .collection('ideas')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (category != null && category != 'Все') {
        query = query.where('category', isEqualTo: category);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        debugPrint(
            'IdeasRepository.streamList: получено ${snapshot.docs.length} документов');

        var ideas = snapshot.docs
            .map((doc) {
              try {
                return Idea.fromFirestore(doc);
              } catch (e) {
                debugPrint(
                    'IdeasRepository.streamList: ошибка парсинга документа ${doc.id}: $e');
                return null;
              }
            })
            .where((idea) => idea != null)
            .cast<Idea>()
            .toList();

        // Фильтрация по поисковому запросу на клиенте
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          ideas = ideas
              .where(
                (idea) =>
                    idea.title.toLowerCase().contains(query) ||
                    idea.description.toLowerCase().contains(query) ||
                    false,
              )
              .toList();
        }

        return ideas;
      });
    } catch (e) {
      debugPrint('IdeasRepository.streamList: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение идей пользователя
  Stream<List<Idea>> getUserIdeas(String userId) {
    try {
      debugPrint('IdeasRepository.getUserIdeas: userId=$userId');

      return _firestore
          .collection('ideas')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        debugPrint(
            'IdeasRepository.getUserIdeas: получено ${snapshot.docs.length} документов');

        return snapshot.docs
            .map((doc) {
              try {
                return Idea.fromFirestore(doc);
              } catch (e) {
                debugPrint(
                  'IdeasRepository.getUserIdeas: ошибка парсинга документа ${doc.id}: $e',
                );
                return null;
              }
            })
            .where((idea) => idea != null)
            .cast<Idea>()
            .toList();
      });
    } catch (e) {
      debugPrint('IdeasRepository.getUserIdeas: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение сохраненных идей пользователя
  Stream<List<Idea>> getSavedIdeas(String userId) {
    try {
      debugPrint('IdeasRepository.getSavedIdeas: userId=$userId');

      return _firestore
          .collection('ideas')
          .where('savedBy', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        debugPrint(
          'IdeasRepository.getSavedIdeas: получено ${snapshot.docs.length} документов',
        );

        return snapshot.docs
            .map((doc) {
              try {
                return Idea.fromFirestore(doc);
              } catch (e) {
                debugPrint(
                  'IdeasRepository.getSavedIdeas: ошибка парсинга документа ${doc.id}: $e',
                );
                return null;
              }
            })
            .where((idea) => idea != null)
            .cast<Idea>()
            .toList();
      });
    } catch (e) {
      debugPrint('IdeasRepository.getSavedIdeas: ошибка запроса: $e');
      return Stream.value([]);
    }
  }

  /// Получение конкретной идеи
  Future<Idea?> getById(String ideaId) async {
    try {
      debugPrint('IdeasRepository.getById: ideaId=$ideaId');

      final doc = await _firestore.collection('ideas').doc(ideaId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        debugPrint(
            'IdeasRepository.getById: документ найден, поля: ${data.keys.toList()}');
        return Idea.fromFirestore(doc);
      }
      debugPrint('IdeasRepository.getById: документ не найден');
      return null;
    } catch (e) {
      debugPrint('IdeasRepository.getById: ошибка получения идеи: $e');
      return null;
    }
  }

  /// Создание новой идеи
  Future<String?> create(Map<String, dynamic> ideaData) async {
    try {
      debugPrint(
          'IdeasRepository.create: создание идеи с данными: ${ideaData.keys.toList()}');

      final docRef = await _firestore.collection('ideas').add(ideaData);
      debugPrint('IdeasRepository.create: идея создана с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('IdeasRepository.create: ошибка создания идеи: $e');
      return null;
    }
  }

  /// Обновление идеи
  Future<bool> update(String ideaId, Map<String, dynamic> updates) async {
    try {
      debugPrint(
        'IdeasRepository.update: обновление идеи $ideaId с полями: ${updates.keys.toList()}',
      );

      await _firestore.collection('ideas').doc(ideaId).update(updates);
      debugPrint('IdeasRepository.update: идея обновлена успешно');
      return true;
    } catch (e) {
      debugPrint('IdeasRepository.update: ошибка обновления идеи: $e');
      return false;
    }
  }

  /// Удаление идеи
  Future<bool> delete(String ideaId) async {
    try {
      debugPrint('IdeasRepository.delete: удаление идеи $ideaId');

      await _firestore.collection('ideas').doc(ideaId).delete();
      debugPrint('IdeasRepository.delete: идея удалена успешно');
      return true;
    } catch (e) {
      debugPrint('IdeasRepository.delete: ошибка удаления идеи: $e');
      return false;
    }
  }

  /// Получение комментариев к идее
  Stream<List<Map<String, dynamic>>> getComments(String ideaId) {
    try {
      debugPrint('IdeasRepository.getComments: ideaId=$ideaId');

      return _firestore
          .collection('ideas')
          .doc(ideaId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        debugPrint(
          'IdeasRepository.getComments: получено ${snapshot.docs.length} комментариев',
        );

        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return {'id': doc.id, ...data};
        }).toList();
      });
    } catch (e) {
      debugPrint(
          'IdeasRepository.getComments: ошибка получения комментариев: $e');
      return Stream.value([]);
    }
  }

  /// Добавление комментария к идее
  Future<bool> addComment(
      String ideaId, Map<String, dynamic> commentData) async {
    try {
      debugPrint(
          'IdeasRepository.addComment: добавление комментария к идее $ideaId');

      await _firestore
          .collection('ideas')
          .doc(ideaId)
          .collection('comments')
          .add(commentData);
      debugPrint('IdeasRepository.addComment: комментарий добавлен успешно');
      return true;
    } catch (e) {
      debugPrint(
          'IdeasRepository.addComment: ошибка добавления комментария: $e');
      return false;
    }
  }
}
