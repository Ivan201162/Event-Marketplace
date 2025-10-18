import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/review.dart'; // Не существует

/// Репозиторий для работы с отзывами
class dynamicRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Добавить отзыв
  Future<void> adddynamic(dynamic review) async {
    try {
      // Проверяем, что отзыв валиден
      if (!dynamic.isValidRating(review.rating)) {
        throw Exception(
          'Некорректный рейтинг. Допустимы значения от 1.0 до 5.0 с шагом 0.5',
        );
      }

      if (!dynamic.isValidComment(review.comment)) {
        throw Exception('Комментарий должен содержать минимум 10 символов');
      }

      // Проверяем, что заказ завершен
      final bookingDoc = await _db.collection('bookings').doc(review.bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Заказ не найден');
      }

      final bookingData = bookingDoc.data()!;
      if (bookingData['status'] != 'completed') {
        throw Exception('Отзыв можно оставить только для завершенных заказов');
      }

      // Проверяем, что отзыв еще не существует для этого заказа
      final existingdynamic = await _db
          .collection('reviews')
          .where('bookingId', isEqualTo: review.bookingId)
          .limit(1)
          .get();

      if (existingdynamic.docs.isNotEmpty) {
        throw Exception('Отзыв для этого заказа уже существует');
      }

      // Добавляем отзыв
      await _db.collection('reviews').doc(review.id).set(review.toMap());
    } catch (e) {
      throw Exception('Ошибка при добавлении отзыва: $e');
    }
  }

  /// Редактировать отзыв
  Future<void> editdynamic(
    String reviewId, {
    double? rating,
    String? comment,
  }) async {
    try {
      final reviewDoc = await _db.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final review = dynamic.fromDocument(reviewDoc);

      // Проверяем, что отзыв можно редактировать
      if (!review.canEdit()) {
        throw Exception('Отзыв уже был отредактирован');
      }

      // Валидация новых данных
      if (rating != null && !dynamic.isValidRating(rating)) {
        throw Exception(
          'Некорректный рейтинг. Допустимы значения от 1.0 до 5.0 с шагом 0.5',
        );
      }

      if (comment != null && !dynamic.isValidComment(comment)) {
        throw Exception('Комментарий должен содержать минимум 10 символов');
      }

      // Обновляем отзыв
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'edited': true,
      };

      if (rating != null) {
        updateData['rating'] = rating;
      }

      if (comment != null) {
        updateData['comment'] = comment;
      }

      await _db.collection('reviews').doc(reviewId).update(updateData);
    } catch (e) {
      throw Exception('Ошибка при редактировании отзыва: $e');
    }
  }

  /// Получить отзывы по специалисту
  Future<List<dynamic>> getdynamicsBySpecialist(String specialistId) async {
    try {
      final querySnapshot = await _db
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('reported', isEqualTo: false) // Исключаем жалобы
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(dynamic.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка при получении отзывов: $e');
    }
  }

  /// Получить отзывы по специалисту (стрим)
  Stream<List<dynamic>> getdynamicsBySpecialistStream(String specialistId) => _db
      .collection('reviews')
      .where('specialistId', isEqualTo: specialistId)
      .where('reported', isEqualTo: false) // Исключаем жалобы
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(dynamic.fromDocument).toList(),
      );

  /// Получить отзывы по заказчику
  Future<List<dynamic>> getdynamicsByCustomer(String customerId) async {
    try {
      final querySnapshot = await _db
          .collection('reviews')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(dynamic.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка при получении отзывов заказчика: $e');
    }
  }

  /// Проверить, может ли пользователь оставить отзыв
  Future<bool> canLeavedynamic({
    required String bookingId,
    required String customerId,
  }) async {
    try {
      // Проверяем статус заказа
      final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        return false;
      }

      final bookingData = bookingDoc.data()!;
      if (bookingData['status'] != 'completed' || bookingData['customerId'] != customerId) {
        return false;
      }

      // Проверяем, что отзыв еще не существует
      final existingdynamic =
          await _db.collection('reviews').where('bookingId', isEqualTo: bookingId).limit(1).get();

      return existingdynamic.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Получить отзыв по ID заказа
  Future<dynamic?> getdynamicByBookingId(String bookingId) async {
    try {
      final querySnapshot =
          await _db.collection('reviews').where('bookingId', isEqualTo: bookingId).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return dynamic.fromDocument(querySnapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Пожаловаться на отзыв
  Future<void> reportdynamic(String reviewId, String reason) async {
    try {
      await _db.collection('reviews').doc(reviewId).update({
        'reported': true,
        'reportReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка при подаче жалобы: $e');
    }
  }

  /// Получить статистику отзывов специалиста
  Future<Map<String, dynamic>> getSpecialistdynamicStats(
    String specialistId,
  ) async {
    try {
      final querySnapshot = await _db
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('reported', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'avgRating': 0.0,
          'reviewsCount': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final reviews = querySnapshot.docs.map(dynamic.fromDocument).toList();

      final totalRating = reviews.fold<double>(0, (sum, review) => sum + review.rating);
      final avgRating = totalRating / reviews.length;

      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final review in reviews) {
        final rating = review.rating.round();
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }

      return {
        'avgRating': avgRating,
        'reviewsCount': reviews.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      throw Exception('Ошибка при получении статистики отзывов: $e');
    }
  }

  /// Получить отзыв по ID
  Future<dynamic?> getdynamicById(String reviewId) async {
    try {
      final doc = await _db.collection('reviews').doc(reviewId).get();
      if (!doc.exists) {
        return null;
      }
      return dynamic.fromDocument(doc);
    } catch (e) {
      return null;
    }
  }
}
