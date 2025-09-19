import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/safe_log.dart';
import '../models/review.dart';

/// Сервис для работы с отзывами
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Коллекции
  static const String _reviewsCollection = 'reviews';
  static const String _reviewStatsCollection = 'review_stats';

  /// Создать отзыв
  Future<Review> createReview({
    required String reviewerId,
    required String reviewerName,
    String? reviewerAvatar,
    required String targetId,
    required ReviewType type,
    required int rating,
    required String title,
    required String content,
    List<String>? images,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      SafeLog.info(
        'ReviewService: Creating review for $targetId by $reviewerId',
      );

      // Проверяем, не оставлял ли пользователь уже отзыв
      final existingReview =
          await _getUserReviewForTarget(reviewerId, targetId);
      if (existingReview != null) {
        throw Exception('Вы уже оставили отзыв для этого ${type.name}');
      }

      // Создаем отзыв
      final review = Review(
        id: '', // Будет установлен Firestore
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        reviewerAvatar: reviewerAvatar,
        targetId: targetId,
        type: type,
        rating: rating,
        title: title,
        content: content,
        images: images ?? [],
        tags: tags ?? [],
        status: ReviewStatus.pending,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Сохраняем в Firestore
      final docRef =
          await _firestore.collection(_reviewsCollection).add(review.toMap());

      // Обновляем ID
      final createdReview = review.copyWith(id: docRef.id);

      // Обновляем статистику
      await _updateReviewStats(targetId, type);

      SafeLog.info('ReviewService: Review created successfully: ${docRef.id}');

      return createdReview;
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error creating review', e, stackTrace);
      rethrow;
    }
  }

  /// Получить отзывы для цели
  Stream<List<Review>> getReviewsForTarget(
    String targetId,
    ReviewType type, {
    ReviewFilter? filter,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    var query = _firestore
        .collection(_reviewsCollection)
        .where('targetId', isEqualTo: targetId)
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: ReviewStatus.approved.name)
        .orderBy('createdAt', descending: true);

    // Применяем фильтры
    if (filter != null) {
      if (filter.minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: filter.minRating);
      }
      if (filter.maxRating != null) {
        query = query.where('rating', isLessThanOrEqualTo: filter.maxRating);
      }
      if (filter.verifiedOnly ?? false) {
        query = query.where('isVerified', isEqualTo: true);
      }
      if (filter.withImages ?? false) {
        query = query.where('images', isNotEqualTo: []);
      }
      if (filter.withResponse ?? false) {
        query = query.where('response', isNotEqualTo: null);
      }
      if (filter.fromDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(filter.fromDate!),
        );
      }
      if (filter.toDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(filter.toDate!),
        );
      }
    }

    // Пагинация
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      List<Review> reviews = snapshot.docs.map(Review.fromDocument).toList();

      // Применяем клиентские фильтры
      if (filter != null) {
        reviews = _applyClientFilters(reviews, filter);
      }

      return reviews;
    });
  }

  /// Получить отзыв пользователя для цели
  Future<Review?> getUserReviewForTarget(String userId, String targetId) async {
    try {
      return await _getUserReviewForTarget(userId, targetId);
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error getting user review', e, stackTrace);
      return null;
    }
  }

  /// Внутренний метод для получения отзыва пользователя
  Future<Review?> _getUserReviewForTarget(
    String userId,
    String targetId,
  ) async {
    final query = await _firestore
        .collection(_reviewsCollection)
        .where('reviewerId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Review.fromDocument(query.docs.first);
    }
    return null;
  }

  /// Обновить отзыв
  Future<Review> updateReview(
    String reviewId, {
    int? rating,
    String? title,
    String? content,
    List<String>? images,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      SafeLog.info('ReviewService: Updating review $reviewId');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rating != null) updateData['rating'] = rating;
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (images != null) updateData['images'] = images;
      if (tags != null) updateData['tags'] = tags;
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update(updateData);

      // Получаем обновленный отзыв
      final doc =
          await _firestore.collection(_reviewsCollection).doc(reviewId).get();
      final updatedReview = Review.fromDocument(doc);

      // Обновляем статистику
      await _updateReviewStats(updatedReview.targetId, updatedReview.type);

      SafeLog.info('ReviewService: Review updated successfully');

      return updatedReview;
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error updating review', e, stackTrace);
      rethrow;
    }
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    try {
      SafeLog.info('ReviewService: Deleting review $reviewId');

      // Получаем отзыв для обновления статистики
      final doc =
          await _firestore.collection(_reviewsCollection).doc(reviewId).get();
      if (doc.exists) {
        final review = Review.fromDocument(doc);

        // Удаляем отзыв
        await _firestore.collection(_reviewsCollection).doc(reviewId).delete();

        // Обновляем статистику
        await _updateReviewStats(review.targetId, review.type);
      }

      SafeLog.info('ReviewService: Review deleted successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error deleting review', e, stackTrace);
      rethrow;
    }
  }

  /// Одобрить отзыв
  Future<void> approveReview(String reviewId) async {
    try {
      SafeLog.info('ReviewService: Approving review $reviewId');

      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'status': ReviewStatus.approved.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Получаем отзыв для обновления статистики
      final doc =
          await _firestore.collection(_reviewsCollection).doc(reviewId).get();
      if (doc.exists) {
        final review = Review.fromDocument(doc);
        await _updateReviewStats(review.targetId, review.type);
      }

      SafeLog.info('ReviewService: Review approved successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error approving review', e, stackTrace);
      rethrow;
    }
  }

  /// Отклонить отзыв
  Future<void> rejectReview(String reviewId) async {
    try {
      SafeLog.info('ReviewService: Rejecting review $reviewId');

      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'status': ReviewStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('ReviewService: Review rejected successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error rejecting review', e, stackTrace);
      rethrow;
    }
  }

  /// Добавить ответ на отзыв
  Future<void> addResponseToReview(
    String reviewId,
    String response,
    String responseAuthorId,
  ) async {
    try {
      SafeLog.info('ReviewService: Adding response to review $reviewId');

      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'response': response,
        'responseAuthorId': responseAuthorId,
        'responseDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('ReviewService: Response added successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error adding response', e, stackTrace);
      rethrow;
    }
  }

  /// Голосовать за полезность отзыва
  Future<void> voteHelpful(
    String reviewId,
    String userId,
    bool isHelpful,
  ) async {
    try {
      SafeLog.info('ReviewService: Voting helpful for review $reviewId');

      final reviewDoc = _firestore.collection(_reviewsCollection).doc(reviewId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reviewDoc);
        if (!snapshot.exists) {
          throw Exception('Отзыв не найден');
        }

        final review = Review.fromDocument(snapshot);
        final currentVote = review.helpfulVotes[userId];

        // Если пользователь уже голосовал, отменяем предыдущий голос
        if (currentVote != null) {
          if (currentVote == isHelpful) {
            // Отменяем голос
            final newVotes = Map<String, bool>.from(review.helpfulVotes);
            newVotes.remove(userId);

            transaction.update(reviewDoc, {
              'helpfulVotes': newVotes,
              'helpfulCount':
                  isHelpful ? review.helpfulCount - 1 : review.helpfulCount,
              'notHelpfulCount': !isHelpful
                  ? review.notHelpfulCount - 1
                  : review.notHelpfulCount,
            });
          } else {
            // Меняем голос
            final newVotes = Map<String, bool>.from(review.helpfulVotes);
            newVotes[userId] = isHelpful;

            transaction.update(reviewDoc, {
              'helpfulVotes': newVotes,
              'helpfulCount':
                  isHelpful ? review.helpfulCount + 1 : review.helpfulCount - 1,
              'notHelpfulCount': !isHelpful
                  ? review.notHelpfulCount + 1
                  : review.notHelpfulCount - 1,
            });
          }
        } else {
          // Новый голос
          final newVotes = Map<String, bool>.from(review.helpfulVotes);
          newVotes[userId] = isHelpful;

          transaction.update(reviewDoc, {
            'helpfulVotes': newVotes,
            'helpfulCount':
                isHelpful ? review.helpfulCount + 1 : review.helpfulCount,
            'notHelpfulCount': !isHelpful
                ? review.notHelpfulCount + 1
                : review.notHelpfulCount,
          });
        }
      });

      SafeLog.info('ReviewService: Vote recorded successfully');
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error voting helpful', e, stackTrace);
      rethrow;
    }
  }

  /// Получить статистику отзывов
  Future<ReviewStats> getReviewStats(String targetId, ReviewType type) async {
    try {
      SafeLog.info('ReviewService: Getting review stats for $targetId');

      final doc = await _firestore
          .collection(_reviewStatsCollection)
          .doc('${targetId}_${type.name}')
          .get();

      if (doc.exists) {
        return ReviewStats.fromDocument(doc);
      } else {
        // Создаем пустую статистику
        return ReviewStats(
          averageRating: 0,
          totalReviews: 0,
          ratingDistribution: {},
          verifiedReviews: 0,
          helpfulReviews: 0,
          helpfulPercentage: 0,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e, stackTrace) {
      SafeLog.error('ReviewService: Error getting review stats', e, stackTrace);
      rethrow;
    }
  }

  /// Получить статистику отзывов (Stream)
  Stream<ReviewStats> getReviewStatsStream(String targetId, ReviewType type) =>
      _firestore
          .collection(_reviewStatsCollection)
          .doc('${targetId}_${type.name}')
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return ReviewStats.fromDocument(doc);
        } else {
          return ReviewStats(
            averageRating: 0,
            totalReviews: 0,
            ratingDistribution: {},
            verifiedReviews: 0,
            helpfulReviews: 0,
            helpfulPercentage: 0,
            lastUpdated: DateTime.now(),
          );
        }
      });

  /// Поиск отзывов
  Stream<List<Review>> searchReviews({
    String? query,
    ReviewType? type,
    ReviewFilter? filter,
    int limit = 20,
  }) {
    var queryBuilder = _firestore
        .collection(_reviewsCollection)
        .where('status', isEqualTo: ReviewStatus.approved.name)
        .orderBy('createdAt', descending: true);

    if (type != null) {
      queryBuilder = queryBuilder.where('type', isEqualTo: type.name);
    }

    if (query != null && query.isNotEmpty) {
      // Для поиска по тексту используем клиентскую фильтрацию
      // В реальном приложении лучше использовать Algolia или Elasticsearch
    }

    queryBuilder = queryBuilder.limit(limit);

    return queryBuilder.snapshots().map((snapshot) {
      List<Review> reviews = snapshot.docs.map(Review.fromDocument).toList();

      // Применяем клиентские фильтры
      if (filter != null) {
        reviews = _applyClientFilters(reviews, filter);
      }

      // Применяем поисковый запрос
      if (query != null && query.isNotEmpty) {
        reviews = reviews
            .where(
              (review) =>
                  review.title.toLowerCase().contains(query.toLowerCase()) ||
                  review.content.toLowerCase().contains(query.toLowerCase()) ||
                  review.tags.any(
                    (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                  ),
            )
            .toList();
      }

      return reviews;
    });
  }

  /// Обновить статистику отзывов
  Future<void> _updateReviewStats(String targetId, ReviewType type) async {
    try {
      SafeLog.info('ReviewService: Updating review stats for $targetId');

      // Получаем все одобренные отзывы
      final reviewsQuery = await _firestore
          .collection(_reviewsCollection)
          .where('targetId', isEqualTo: targetId)
          .where('type', isEqualTo: type.name)
          .where('status', isEqualTo: ReviewStatus.approved.name)
          .get();

      final reviews = reviewsQuery.docs.map(Review.fromDocument).toList();

      // Вычисляем статистику
      final totalReviews = reviews.length;
      if (totalReviews == 0) {
        // Удаляем документ статистики, если нет отзывов
        await _firestore
            .collection(_reviewStatsCollection)
            .doc('${targetId}_${type.name}')
            .delete();
        return;
      }

      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / totalReviews;

      final ratingDistribution = <int, int>{};
      for (var i = 1; i <= 5; i++) {
        ratingDistribution[i] = reviews.where((r) => r.rating == i).length;
      }

      final verifiedReviews = reviews.where((r) => r.isVerified).length;
      final helpfulReviews = reviews.where((r) => r.isHelpful).length;
      final helpfulPercentage =
          totalReviews > 0 ? (helpfulReviews / totalReviews) * 100 : 0.0;

      final stats = ReviewStats(
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        verifiedReviews: verifiedReviews,
        helpfulReviews: helpfulReviews,
        helpfulPercentage: helpfulPercentage,
        lastUpdated: DateTime.now(),
      );

      // Сохраняем статистику
      await _firestore
          .collection(_reviewStatsCollection)
          .doc('${targetId}_${type.name}')
          .set(stats.toMap());

      SafeLog.info('ReviewService: Review stats updated successfully');
    } catch (e, stackTrace) {
      SafeLog.error(
        'ReviewService: Error updating review stats',
        e,
        stackTrace,
      );
    }
  }

  /// Применить клиентские фильтры
  List<Review> _applyClientFilters(List<Review> reviews, ReviewFilter filter) =>
      reviews.where((review) {
        // Фильтр по тегам
        if (filter.tags != null && filter.tags!.isNotEmpty) {
          if (!filter.tags!.any((tag) => review.tags.contains(tag))) {
            return false;
          }
        }

        return true;
      }).toList();

  /// Получить отзывы пользователя
  Stream<List<Review>> getUserReviews(String userId, {int limit = 20}) =>
      _firestore
          .collection(_reviewsCollection)
          .where('reviewerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(Review.fromDocument).toList());

  /// Получить отзывы на рассмотрении (для админов)
  Stream<List<Review>> getPendingReviews({int limit = 20}) => _firestore
      .collection(_reviewsCollection)
      .where('status', isEqualTo: ReviewStatus.pending.name)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Review.fromDocument).toList());

  /// Отметить отзыв как проверенный
  Future<void> markAsVerified(String reviewId) async {
    try {
      SafeLog.info('ReviewService: Marking review as verified: $reviewId');

      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Получаем отзыв для обновления статистики
      final doc =
          await _firestore.collection(_reviewsCollection).doc(reviewId).get();
      if (doc.exists) {
        final review = Review.fromDocument(doc);
        await _updateReviewStats(review.targetId, review.type);
      }

      SafeLog.info('ReviewService: Review marked as verified successfully');
    } catch (e, stackTrace) {
      SafeLog.error(
        'ReviewService: Error marking review as verified',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Получить статистику отзывов события (для совместимости)
  Future<ReviewStats> getEventReviewStats(String eventId) async =>
      getReviewStats(eventId, ReviewType.event);

  /// Получить отзывы события (для совместимости)
  Stream<List<Review>> getEventReviews(String eventId) =>
      getReviewsForTarget(eventId, ReviewType.event);
}
