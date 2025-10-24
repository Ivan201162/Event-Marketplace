import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/idea.dart';

/// Сервис для работы с идеями
class IdeasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить идеи
  Future<List<Idea>> getIdeas() async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки идей: $e');
    }
  }

  /// Загрузить больше идей
  Future<List<Idea>> getMoreIdeas(int offset) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .orderBy('createdAt', descending: true)
          .startAfter([offset])
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки дополнительных идей: $e');
    }
  }

  /// Поиск идей
  Future<List<Idea>> searchIdeas(String query) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThan: query + '\uf8ff')
          .orderBy('text')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка поиска идей: $e');
    }
  }

  /// Фильтрация идей
  Future<List<Idea>> filterIdeas(String filter) async {
    try {
      Query query = _firestore.collection('ideas');

      switch (filter) {
        case 'popular':
          query = query.orderBy('likesCount', descending: true);
          break;
        case 'new':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'trending':
          // Тренды - комбинация лайков и времени
          query = query.orderBy('trendingScore', descending: true);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.limit(20).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Idea.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка фильтрации идей: $e');
    }
  }

  /// Создать идею
  Future<String> createIdea(Idea idea) async {
    try {
      final docRef = await _firestore.collection('ideas').add(idea.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания идеи: $e');
    }
  }

  /// Лайк идеи
  Future<void> likeIdea(String ideaId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).update({
        'likesCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка лайка идеи: $e');
    }
  }

  /// Сохранить идею
  Future<void> saveIdea(String ideaId) async {
    try {
      // Добавить в коллекцию сохранённых идей пользователя
      await _firestore
          .collection('users')
          .doc('current_user_id') // TODO: Получить ID текущего пользователя
          .collection('saved_ideas')
          .doc(ideaId)
          .set({
        'ideaId': ideaId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка сохранения идеи: $e');
    }
  }

  /// Поделиться идеей
  Future<void> shareIdea(String ideaId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).update({
        'sharesCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка шаринга идеи: $e');
    }
  }

  /// Удалить идею
  Future<void> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления идеи: $e');
    }
  }

  /// Получить идею по ID
  Future<Idea?> getIdeaById(String ideaId) async {
    try {
      final doc = await _firestore.collection('ideas').doc(ideaId).get();
      if (doc.exists) {
        return Idea.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения идеи: $e');
    }
  }

  /// Получить рекомендации
  Future<List<Idea>> getRecommendations() async {
    try {
      // Упрощённая модель рекомендаций
      final snapshot = await _firestore
          .collection('ideas')
          .orderBy('likesCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций: $e');
    }
  }
}