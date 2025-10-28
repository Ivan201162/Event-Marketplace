import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/content_creator.dart';

/// Сервис для работы с контент-мейкерами
class ContentCreatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить всех контент-мейкеров
  Future<List<ContentCreator>> getContentCreators({
    String? location,
    List<String>? categories,
    List<String>? formats,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection('contentCreators')
          .where('isActive', isEqualTo: true);

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      if (categories != null && categories.isNotEmpty) {
        query = query.where('categories', arrayContainsAny: categories);
      }

      final snapshot =
          await query.orderBy('rating', descending: true).limit(limit).get();

      var creators = snapshot.docs.map(ContentCreator.fromDocument).toList();

      // Фильтрация по форматам на клиенте (если указаны)
      if (formats != null && formats.isNotEmpty) {
        creators = creators
            .where((creator) =>
                creator.formats.any((format) => formats.contains(format.name)),)
            .toList();
      }

      return creators;
    } catch (e) {
      throw Exception('Ошибка получения контент-мейкеров: $e');
    }
  }

  /// Получить контент-мейкера по ID
  Future<ContentCreator?> getContentCreator(String id) async {
    try {
      final doc = await _firestore.collection('contentCreators').doc(id).get();
      if (doc.exists) {
        return ContentCreator.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения контент-мейкера: $e');
    }
  }

  /// Создать контент-мейкера
  Future<String> createContentCreator(ContentCreator creator) async {
    try {
      final docRef =
          await _firestore.collection('contentCreators').add(creator.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания контент-мейкера: $e');
    }
  }

  /// Обновить контент-мейкера
  Future<void> updateContentCreator(String id, ContentCreator creator) async {
    try {
      await _firestore.collection('contentCreators').doc(id).update({
        ...creator.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления контент-мейкера: $e');
    }
  }

  /// Удалить контент-мейкера
  Future<void> deleteContentCreator(String id) async {
    try {
      await _firestore.collection('contentCreators').doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления контент-мейкера: $e');
    }
  }

  /// Добавить медиа в портфолио
  Future<void> addMediaToPortfolio(
      String creatorId, MediaShowcase media,) async {
    try {
      await _firestore.collection('contentCreators').doc(creatorId).update({
        'mediaShowcase': FieldValue.arrayUnion([media.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка добавления медиа в портфолио: $e');
    }
  }

  /// Удалить медиа из портфолио
  Future<void> removeMediaFromPortfolio(
      String creatorId, String mediaId,) async {
    try {
      // Получаем текущий контент-мейкер
      final doc =
          await _firestore.collection('contentCreators').doc(creatorId).get();
      if (!doc.exists) throw Exception('Контент-мейкер не найден');

      final creator = ContentCreator.fromDocument(doc);
      final updatedMedia = creator.mediaShowcase
          .where((media) => media.id != mediaId)
          .map((media) => media.toMap())
          .toList();

      await _firestore.collection('contentCreators').doc(creatorId).update({
        'mediaShowcase': updatedMedia,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления медиа из портфолио: $e');
    }
  }

  /// Получить портфолио контент-мейкера
  Future<List<MediaShowcase>> getPortfolio(String creatorId) async {
    try {
      final doc =
          await _firestore.collection('contentCreators').doc(creatorId).get();
      if (!doc.exists) return [];

      final creator = ContentCreator.fromDocument(doc);
      return creator.mediaShowcase;
    } catch (e) {
      throw Exception('Ошибка получения портфолио: $e');
    }
  }

  /// Поиск контент-мейкеров
  Future<List<ContentCreator>> searchContentCreators({
    required String query,
    String? location,
    List<String>? categories,
    List<String>? formats,
    int limit = 20,
  }) async {
    try {
      // Получаем всех контент-мейкеров
      final creators = await getContentCreators(
        location: location,
        categories: categories,
        formats: formats,
        limit: 100, // Увеличиваем лимит для поиска
      );

      // Фильтруем по поисковому запросу
      final searchQuery = query.toLowerCase();
      final filteredCreators = creators
          .where(
            (creator) =>
                creator.name.toLowerCase().contains(searchQuery) ||
                creator.description.toLowerCase().contains(searchQuery) ||
                creator.categories.any(
                  (category) => category.toLowerCase().contains(searchQuery),
                ) ||
                creator.formats.any((format) =>
                    format.name.toLowerCase().contains(searchQuery),),
          )
          .toList();

      return filteredCreators.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка поиска контент-мейкеров: $e');
    }
  }

  /// Получить популярные форматы контента
  Future<List<String>> getPopularFormats() async {
    try {
      final snapshot = await _firestore
          .collection('contentCreators')
          .where('isActive', isEqualTo: true)
          .get();

      final formatCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final creator = ContentCreator.fromDocument(doc);
        for (final format in creator.formats) {
          formatCounts[format.name] = (formatCounts[format.name] ?? 0) + 1;
        }
      }

      // Сортируем по популярности
      final sortedFormats = formatCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedFormats.map((entry) => entry.key).toList();
    } catch (e) {
      throw Exception('Ошибка получения популярных форматов: $e');
    }
  }

  /// Получить статистику контент-мейкера
  Future<Map<String, dynamic>> getCreatorStats(String creatorId) async {
    try {
      // Получаем данные контент-мейкера
      final creator = await getContentCreator(creatorId);
      if (creator == null) throw Exception('Контент-мейкер не найден');

      // Получаем количество бронирований
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: creatorId)
          .where('status', isEqualTo: 'completed')
          .get();

      final completedBookings = bookingsSnapshot.docs.length;

      // Получаем общий доход
      double totalRevenue = 0;
      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final price = (data['totalPrice'] as num?)?.toDouble() ?? 0;
        totalRevenue += price;
      }

      // Получаем средний рейтинг
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: creatorId)
          .get();

      double averageRating = 0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        final totalRating = reviewsSnapshot.docs.fold<double>(0, (sum, doc) {
          final data = doc.data();
          return sum + ((data['rating'] as num?)?.toDouble() ?? 0);
        });
        averageRating = totalRating / reviewsSnapshot.docs.length;
      }

      return {
        'creatorId': creatorId,
        'portfolioSize': creator.portfolioSize,
        'supportedFormats': creator.supportedFormats.length,
        'completedBookings': completedBookings,
        'totalRevenue': totalRevenue,
        'averageRating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length,
        'categories': creator.categories,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики контент-мейкера: $e');
    }
  }

  /// Получить рекомендуемых контент-мейкеров
  Future<List<ContentCreator>> getRecommendedCreators({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // Получаем историю бронирований пользователя
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Анализируем предпочтения пользователя
      final preferredCategories = <String, int>{};
      final preferredFormats = <String, int>{};

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final categoryId = data['categoryId'] as String?;
        if (categoryId != null) {
          preferredCategories[categoryId] =
              (preferredCategories[categoryId] ?? 0) + 1;
        }
      }

      // Получаем контент-мейкеров с похожими предпочтениями
      final recommendedCreators = <ContentCreator>[];

      if (preferredCategories.isNotEmpty) {
        final topCategories = preferredCategories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final categoryIds = topCategories.take(3).map((e) => e.key).toList();

        final creators =
            await getContentCreators(categories: categoryIds, limit: limit * 2);

        recommendedCreators.addAll(creators);
      }

      // Если недостаточно рекомендаций, добавляем популярных
      if (recommendedCreators.length < limit) {
        final popularCreators = await getContentCreators(limit: limit);
        for (final creator in popularCreators) {
          if (!recommendedCreators.any((c) => c.id == creator.id)) {
            recommendedCreators.add(creator);
          }
        }
      }

      return recommendedCreators.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендуемых контент-мейкеров: $e');
    }
  }

  /// Обновить рейтинг контент-мейкера
  Future<void> updateCreatorRating(String creatorId) async {
    try {
      // Получаем все отзывы
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: creatorId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      // Вычисляем средний рейтинг
      double totalRating = 0;
      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] as num?)?.toDouble() ?? 0;
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;

      // Обновляем рейтинг
      await _firestore.collection('contentCreators').doc(creatorId).update({
        'rating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления рейтинга контент-мейкера: $e');
    }
  }
}
