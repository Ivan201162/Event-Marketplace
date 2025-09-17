import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/photo_studio.dart';

/// Сервис для работы с фотостудиями
class PhotoStudioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все фотостудии
  Future<List<PhotoStudio>> getPhotoStudios({
    String? location,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('photoStudios')
          .where('isActive', isEqualTo: true);

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      final snapshot =
          await query.orderBy('rating', descending: true).limit(limit).get();

      List<PhotoStudio> studios =
          snapshot.docs.map((doc) => PhotoStudio.fromDocument(doc)).toList();

      // Фильтрация по цене на клиенте
      if (minPrice != null || maxPrice != null) {
        studios = studios.where((studio) {
          final studioMinPrice = studio.minPricePerHour;
          final studioMaxPrice = studio.maxPricePerHour;

          if (studioMinPrice == null || studioMaxPrice == null) return false;

          if (minPrice != null && studioMaxPrice < minPrice) return false;
          if (maxPrice != null && studioMinPrice > maxPrice) return false;

          return true;
        }).toList();
      }

      return studios;
    } catch (e) {
      throw Exception('Ошибка получения фотостудий: $e');
    }
  }

  /// Получить фотостудию по ID
  Future<PhotoStudio?> getPhotoStudio(String id) async {
    try {
      final doc = await _firestore.collection('photoStudios').doc(id).get();
      if (doc.exists) {
        return PhotoStudio.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения фотостудии: $e');
    }
  }

  /// Создать фотостудию
  Future<String> createPhotoStudio(PhotoStudio studio) async {
    try {
      final docRef =
          await _firestore.collection('photoStudios').add(studio.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания фотостудии: $e');
    }
  }

  /// Обновить фотостудию
  Future<void> updatePhotoStudio(String id, PhotoStudio studio) async {
    try {
      await _firestore.collection('photoStudios').doc(id).update({
        ...studio.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления фотостудии: $e');
    }
  }

  /// Удалить фотостудию
  Future<void> deletePhotoStudio(String id) async {
    try {
      await _firestore.collection('photoStudios').doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления фотостудии: $e');
    }
  }

  /// Поиск фотостудий
  Future<List<PhotoStudio>> searchPhotoStudios({
    required String query,
    String? location,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
  }) async {
    try {
      // Получаем все фотостудии
      final studios = await getPhotoStudios(
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: 100, // Увеличиваем лимит для поиска
      );

      // Фильтруем по поисковому запросу
      final searchQuery = query.toLowerCase();
      final filteredStudios = studios.where((studio) {
        return studio.name.toLowerCase().contains(searchQuery) ||
            studio.description.toLowerCase().contains(searchQuery) ||
            studio.address.toLowerCase().contains(searchQuery) ||
            studio.location.toLowerCase().contains(searchQuery);
      }).toList();

      return filteredStudios.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка поиска фотостудий: $e');
    }
  }

  /// Получить доступные даты для фотостудии
  Future<List<DateTime>> getAvailableDates(
      String studioId, DateTime startDate, DateTime endDate) async {
    try {
      final studio = await getPhotoStudio(studioId);
      if (studio == null) return [];

      final availableDates = <DateTime>[];
      final currentDate = startDate;

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final dateString = currentDate.toIso8601String().split('T')[0];
        if (studio.availableDates.contains(dateString)) {
          availableDates.add(
              DateTime(currentDate.year, currentDate.month, currentDate.day));
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return availableDates;
    } catch (e) {
      throw Exception('Ошибка получения доступных дат: $e');
    }
  }

  /// Проверить доступность времени
  Future<bool> isTimeSlotAvailable({
    required String studioId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('studioBookings')
          .where('studioId', isEqualTo: studioId)
          .where('status', whereIn: ['confirmed', 'in_progress']).get();

      for (final doc in snapshot.docs) {
        final booking = StudioBooking.fromDocument(doc);

        // Проверяем пересечение временных интервалов
        if (startTime.isBefore(booking.endTime) &&
            endTime.isAfter(booking.startTime)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      throw Exception('Ошибка проверки доступности времени: $e');
    }
  }

  /// Создать бронирование фотостудии
  Future<String> createStudioBooking({
    required String studioId,
    required String customerId,
    String? photographerId,
    required String optionId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      // Проверяем доступность времени
      final isAvailable = await isTimeSlotAvailable(
        studioId: studioId,
        startTime: startTime,
        endTime: endTime,
      );

      if (!isAvailable) {
        throw Exception('Выбранное время недоступно');
      }

      // Получаем информацию о студии и опции
      final studio = await getPhotoStudio(studioId);
      if (studio == null) throw Exception('Фотостудия не найдена');

      final option = studio.studioOptions.firstWhere(
        (opt) => opt.id == optionId,
        orElse: () => throw Exception('Опция студии не найдена'),
      );

      // Вычисляем стоимость
      final duration = endTime.difference(startTime).inHours.toDouble();
      final totalPrice = option.pricePerHour * duration;

      final now = DateTime.now();

      final booking = StudioBooking(
        id: '', // Будет сгенерирован Firestore
        studioId: studioId,
        customerId: customerId,
        photographerId: photographerId,
        optionId: optionId,
        startTime: startTime,
        endTime: endTime,
        totalPrice: totalPrice,
        status: 'pending',
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final docRef =
          await _firestore.collection('studioBookings').add(booking.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания бронирования фотостудии: $e');
    }
  }

  /// Получить бронирования фотостудии
  Future<List<StudioBooking>> getStudioBookings(String studioId) async {
    try {
      final snapshot = await _firestore
          .collection('studioBookings')
          .where('studioId', isEqualTo: studioId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudioBooking.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения бронирований фотостудии: $e');
    }
  }

  /// Получить бронирования клиента
  Future<List<StudioBooking>> getCustomerBookings(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('studioBookings')
          .where('customerId', isEqualTo: customerId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudioBooking.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения бронирований клиента: $e');
    }
  }

  /// Обновить статус бронирования
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('studioBookings').doc(bookingId).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления статуса бронирования: $e');
    }
  }

  /// Отменить бронирование
  Future<void> cancelBooking(String bookingId) async {
    try {
      await updateBookingStatus(bookingId, 'cancelled');
    } catch (e) {
      throw Exception('Ошибка отмены бронирования: $e');
    }
  }

  /// Получить статистику фотостудии
  Future<Map<String, dynamic>> getStudioStats(String studioId) async {
    try {
      final snapshot = await _firestore
          .collection('studioBookings')
          .where('studioId', isEqualTo: studioId)
          .get();

      int totalBookings = 0;
      int completedBookings = 0;
      double totalRevenue = 0;
      double totalHours = 0;

      for (final doc in snapshot.docs) {
        final booking = StudioBooking.fromDocument(doc);
        totalBookings++;

        if (booking.isCompleted) {
          completedBookings++;
          totalRevenue += booking.totalPrice;
          totalHours += booking.durationInHours;
        }
      }

      return {
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'totalRevenue': totalRevenue,
        'totalHours': totalHours,
        'averageBookingValue':
            completedBookings > 0 ? totalRevenue / completedBookings : 0,
        'averageBookingDuration':
            completedBookings > 0 ? totalHours / completedBookings : 0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики фотостудии: $e');
    }
  }

  /// Получить рекомендуемые фотостудии
  Future<List<PhotoStudio>> getRecommendedStudios({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // Получаем историю бронирований пользователя
      final bookingsSnapshot = await _firestore
          .collection('studioBookings')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Анализируем предпочтения пользователя
      final preferredLocations = <String, int>{};
      final preferredPriceRanges = <String, int>{};

      for (final doc in bookingsSnapshot.docs) {
        final booking = StudioBooking.fromDocument(doc);
        final studio = await getPhotoStudio(booking.studioId);

        if (studio != null) {
          preferredLocations[studio.location] =
              (preferredLocations[studio.location] ?? 0) + 1;

          final priceRange = _getPriceRange(studio.minPricePerHour ?? 0);
          preferredPriceRanges[priceRange] =
              (preferredPriceRanges[priceRange] ?? 0) + 1;
        }
      }

      // Получаем фотостудии с похожими предпочтениями
      final recommendedStudios = <PhotoStudio>[];

      if (preferredLocations.isNotEmpty) {
        final topLocation = preferredLocations.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        final studios = await getPhotoStudios(
          location: topLocation,
          limit: limit * 2,
        );

        recommendedStudios.addAll(studios);
      }

      // Если недостаточно рекомендаций, добавляем популярные
      if (recommendedStudios.length < limit) {
        final popularStudios = await getPhotoStudios(limit: limit);
        for (final studio in popularStudios) {
          if (!recommendedStudios.any((s) => s.id == studio.id)) {
            recommendedStudios.add(studio);
          }
        }
      }

      return recommendedStudios.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендуемых фотостудий: $e');
    }
  }

  /// Обновить рейтинг фотостудии
  Future<void> updateStudioRating(String studioId) async {
    try {
      // Получаем все отзывы
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('studioId', isEqualTo: studioId)
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
      await _firestore.collection('photoStudios').doc(studioId).update({
        'rating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка обновления рейтинга фотостудии: $e');
    }
  }

  /// Получить диапазон цен
  String _getPriceRange(double price) {
    if (price < 1000) return '0-1000';
    if (price < 2000) return '1000-2000';
    if (price < 3000) return '2000-3000';
    if (price < 5000) return '3000-5000';
    return '5000+';
  }
}
