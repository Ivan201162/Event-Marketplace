import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist.dart';
import '../models/recommendation_interaction.dart';

/// Сервис для работы с рекомендациями
class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить похожих специалистов
  Future<List<Specialist>> getSimilarSpecialists(String specialistId) async {
    try {
      // Получить данные специалиста
      final specialistDoc =
          await _firestore.collection('specialists').doc(specialistId).get();

      if (!specialistDoc.exists) {
        return [];
      }

      final specialistData = specialistDoc.data()!;
      final categories = List<String>.from(specialistData['categories'] ?? []);
      final location = specialistData['location'] as String?;

      // Найти специалистов с похожими категориями
      Query query = _firestore
          .collection('specialists')
          .where('categories', arrayContainsAny: categories)
          .where('isAvailable', isEqualTo: true)
          .limit(10);

      final querySnapshot = await query.get();
      final specialists = querySnapshot.docs
          .where((doc) => doc.id != specialistId)
          .map((doc) => Specialist.fromDocument(doc))
          .toList();

      // Сортировать по рейтингу
      specialists.sort((a, b) => b.rating.compareTo(a.rating));

      return specialists;
    } catch (e) {
      throw Exception('Ошибка получения похожих специалистов: $e');
    }
  }

  /// Записать взаимодействие с рекомендацией
  Future<void> recordInteraction(RecommendationInteraction interaction) async {
    try {
      await _firestore
          .collection('recommendation_interactions')
          .add(interaction.toMap());
    } catch (e) {
      throw Exception('Ошибка записи взаимодействия: $e');
    }
  }

  /// Получить рекомендации на основе взаимодействий
  Future<List<Specialist>> getPersonalizedRecommendations(String userId) async {
    try {
      // Получить взаимодействия пользователя
      final interactionsQuery = await _firestore
          .collection('recommendation_interactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      if (interactionsQuery.docs.isEmpty) {
        // Если нет взаимодействий, вернуть популярных специалистов
        return await getPopularSpecialists();
      }

      // Анализировать взаимодействия для определения предпочтений
      final Map<String, int> categoryScores = {};
      final Map<String, int> specialistScores = {};

      for (final doc in interactionsQuery.docs) {
        final data = doc.data();
        final specialistId = data['specialistId'] as String;
        final type = data['type'] as String;

        // Получить данные специалиста
        final specialistDoc =
            await _firestore.collection('specialists').doc(specialistId).get();

        if (specialistDoc.exists) {
          final specialistData = specialistDoc.data()!;
          final categories =
              List<String>.from(specialistData['categories'] ?? []);

          // Подсчитать очки для категорий
          for (final category in categories) {
            categoryScores[category] =
                (categoryScores[category] ?? 0) + _getInteractionScore(type);
          }

          // Подсчитать очки для специалиста
          specialistScores[specialistId] =
              (specialistScores[specialistId] ?? 0) +
                  _getInteractionScore(type);
        }
      }

      // Найти специалистов с высокими очками в предпочитаемых категориях
      final topCategories = _getTopCategories(categoryScores, 3);
      final recommendedSpecialists = <Specialist>[];

      for (final category in topCategories) {
        final querySnapshot = await _firestore
            .collection('specialists')
            .where('categories', arrayContains: category)
            .where('isAvailable', isEqualTo: true)
            .limit(5)
            .get();

        for (final doc in querySnapshot.docs) {
          final specialist = Specialist.fromDocument(doc);
          if (!recommendedSpecialists.any((s) => s.id == specialist.id)) {
            recommendedSpecialists.add(specialist);
          }
        }
      }

      // Сортировать по рейтингу и очкам взаимодействий
      recommendedSpecialists.sort((a, b) {
        final scoreA = specialistScores[a.id] ?? 0;
        final scoreB = specialistScores[b.id] ?? 0;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }
        return b.rating.compareTo(a.rating);
      });

      return recommendedSpecialists.take(10).toList();
    } catch (e) {
      throw Exception('Ошибка получения персонализированных рекомендаций: $e');
    }
  }

  /// Получить популярных специалистов
  Future<List<Specialist>> getPopularSpecialists() async {
    try {
      final querySnapshot = await _firestore
          .collection('specialists')
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => Specialist.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения популярных специалистов: $e');
    }
  }

  /// Получить очки за взаимодействие
  int _getInteractionScore(String type) {
    switch (type) {
      case 'view':
        return 1;
      case 'click':
        return 2;
      case 'like':
        return 3;
      case 'bookmark':
        return 4;
      case 'contact':
        return 5;
      case 'book':
        return 10;
      case 'dislike':
        return -2;
      default:
        return 0;
    }
  }

  /// Получить топ категории
  List<String> _getTopCategories(Map<String, int> categoryScores, int count) {
    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(count).map((e) => e.key).toList();
  }

  /// Получить рекомендации на основе местоположения
  Future<List<Specialist>> getLocationBasedRecommendations(
      double latitude, double longitude, double radiusKm) async {
    try {
      // Простая реализация - получить всех специалистов и фильтровать по расстоянию
      final querySnapshot = await _firestore
          .collection('specialists')
          .where('isAvailable', isEqualTo: true)
          .get();

      final specialists = querySnapshot.docs
          .map((doc) => Specialist.fromDocument(doc))
          .where((specialist) {
        // Здесь должна быть логика расчета расстояния
        // Пока возвращаем всех специалистов
        return true;
      }).toList();

      // Сортировать по рейтингу
      specialists.sort((a, b) => b.rating.compareTo(a.rating));

      return specialists.take(10).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций по местоположению: $e');
    }
  }
}
