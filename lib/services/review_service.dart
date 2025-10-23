import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

/// Service for managing reviews
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reviewsCollection = 'reviews';

  /// Add a new review
  Future<String> addReview(Review review) async {
    try {
      final docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding review: $e');
    }
  }

  /// Create a new review
  Future<String> createReview({
    required String specialistId,
    required String clientId,
    required String clientName,
    required String specialistName,
    required int rating,
    required String comment,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    try {
      final review = Review(
        id: '',
        specialistId: specialistId,
        clientId: clientId,
        clientName: clientName,
        specialistName: specialistName,
        rating: rating,
        comment: comment,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating review: $e');
    }
  }

  /// Get reviews by specialist
  Future<List<Review>> getReviewsBySpecialist(String specialistId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error getting reviews: $e');
    }
  }

  /// Get specialist reviews (alias for getReviewsBySpecialist)
  Future<List<Review>> getSpecialistReviews(String specialistId) async {
    return getReviewsBySpecialist(specialistId);
  }

  /// Get all reviews
  Future<List<Review>> getReviews({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error getting reviews: $e');
    }
  }

  /// Update a review
  Future<void> updateReview(String reviewId, int rating, String comment) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating review: $e');
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }

  /// Get review statistics for a specialist
  Future<ReviewStats?> getReviewStats(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final reviews =
          snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();

      if (reviews.isEmpty) {
        return null;
      }

      // Calculate statistics
      final totalReviews = reviews.length;
      final averageRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

      final ratingDistribution = <int, int>{};
      for (final review in reviews) {
        ratingDistribution[review.rating] =
            (ratingDistribution[review.rating] ?? 0) + 1;
      }

      final verifiedReviews = reviews.where((r) => r.isVerified).length;
      final recentReviews = reviews
          .where((r) => r.createdAt
              .isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .length;

      return ReviewStats(
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        verifiedReviews: verifiedReviews,
        recentReviews: recentReviews,
      );
    } catch (e) {
      throw Exception('Error getting review stats: $e');
    }
  }

  /// Get specialist review statistics
  Future<ReviewStats?> getSpecialistReviewStats(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final reviews =
          snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();

      if (reviews.isEmpty) {
        return null;
      }

      // Calculate statistics
      final totalReviews = reviews.length;
      final averageRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

      final ratingDistribution = <int, int>{};
      for (final review in reviews) {
        ratingDistribution[review.rating] =
            (ratingDistribution[review.rating] ?? 0) + 1;
      }

      // Get top tags from all reviews
      final allTags = <String>[];
      for (final review in reviews) {
        allTags.addAll(review.tags);
      }

      final tagCounts = <String, int>{};
      for (final tag in allTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }

      final topTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topTagsList = topTags.take(5).map((e) => e.key).toList();

      // Get service ratings
      final serviceRatings = <String, double>{};
      for (final review in reviews) {
        for (final serviceTag in review.serviceTags) {
          serviceRatings[serviceTag] =
              (serviceRatings[serviceTag] ?? 0) + review.rating;
        }
      }

      return ReviewStats(
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        verifiedReviews: reviews.where((r) => r.isVerified).length,
        recentReviews: reviews
            .where((r) => r.createdAt
                .isAfter(DateTime.now().subtract(const Duration(days: 30))))
            .length,
        topTags: topTagsList,
      );
    } catch (e) {
      throw Exception('Error getting specialist review stats: $e');
    }
  }
}
