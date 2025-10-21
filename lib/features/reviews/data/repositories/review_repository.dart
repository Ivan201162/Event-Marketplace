import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/review.dart';

/// Repository for managing reviews
class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reviewsCollection = 'reviews';

  /// Add a new review
  Future<bool> addReview(Review review) async {
    try {
      await _firestore.collection(_reviewsCollection).add(review.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get reviews by specialist
  Future<List<Review>> getReviewsBySpecialist(String specialistId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
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
      return [];
    }
  }

  /// Update a review
  Future<bool> updateReview(String reviewId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();
      return true;
    } catch (e) {
      return false;
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

      final reviews = snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();

      if (reviews.isEmpty) {
        return null;
      }

      // Calculate statistics
      final totalReviews = reviews.length;
      final averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

      final ratingDistribution = <int, int>{};
      for (final review in reviews) {
        ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
      }

      final verifiedReviews = reviews.where((r) => r.isVerified).length;
      final recentReviews = reviews
          .where((r) => r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .length;

      return ReviewStats(
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        verifiedReviews: verifiedReviews,
        recentReviews: recentReviews,
      );
    } catch (e) {
      return null;
    }
  }
}
