import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/review.dart';

/// Service for managing reviews
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = kIsWeb ? null : FirebaseStorage.instance;

  /// Get reviews for a specialist
  Future<List<Review>> getSpecialistReviews(String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting specialist reviews: $e');
      return [];
    }
  }

  /// Get reviews by a client
  Future<List<Review>> getClientReviews(String clientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting client reviews: $e');
      return [];
    }
  }

  /// Get reviews by rating
  Future<List<Review>> getReviewsByRating(int rating) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('rating', isEqualTo: rating)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting reviews by rating: $e');
      return [];
    }
  }

  /// Get review by ID
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final doc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (doc.exists) {
        return Review.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting review by ID: $e');
      return null;
    }
  }

  /// Create a new review
  Future<String?> createReview(Review review) async {
    try {
      final docRef = await _firestore
          .collection('reviews')
          .add(review.toFirestore());

      // Update specialist rating
      await _updateSpecialistRating(review.specialistId);

      debugPrint('Review created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating review: $e');
      return null;
    }
  }

  /// Update review
  Future<bool> updateReview(Review review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.id)
          .update(review.toFirestore());

      // Update specialist rating
      await _updateSpecialistRating(review.specialistId);

      debugPrint('Review updated: ${review.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating review: $e');
      return false;
    }
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId) async {
    try {
      final review = await getReviewById(reviewId);
      if (review == null) return false;

      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Update specialist rating
      await _updateSpecialistRating(review.specialistId);

      debugPrint('Review deleted: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Like/unlike review
  Future<bool> toggleReviewLike(String reviewId, String userId) async {
    try {
      final review = await getReviewById(reviewId);
      if (review == null) return false;

      final isLiked = review.isLikedBy(userId);
      final newLikedBy = List<String>.from(review.likedBy);
      
      if (isLiked) {
        newLikedBy.remove(userId);
      } else {
        newLikedBy.add(userId);
      }

      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update({
        'likedBy': newLikedBy,
        'likesCount': newLikedBy.length,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('Review like toggled: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error toggling review like: $e');
      return false;
    }
  }

  /// Upload review image
  Future<String?> uploadReviewImage(String filePath, String fileName) async {
    if (_storage == null) {
      debugPrint('Firebase Storage not available on web');
      return null;
    }
    try {
      final ref = _storage.ref().child('reviews/$fileName');
      final uploadTask = await ref.putFile(filePath as dynamic); // In real app, use File
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading review image: $e');
      return null;
    }
  }

  /// Get reviews stream for specialist
  Stream<List<Review>> getSpecialistReviewsStream(String specialistId) {
    return _firestore
        .collection('reviews')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  /// Get reviews stream for client
  Stream<List<Review>> getClientReviewsStream(String clientId) {
    return _firestore
        .collection('reviews')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  /// Get reviews stream by rating
  Stream<List<Review>> getReviewsByRatingStream(int rating) {
    return _firestore
        .collection('reviews')
        .where('rating', isEqualTo: rating)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  /// Get review statistics for specialist
  Future<Map<String, dynamic>> getSpecialistReviewStats(String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final reviews = querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();

      final totalReviews = reviews.length;
      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / totalReviews;

      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final review in reviews) {
        ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
      }

      return {
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      debugPrint('Error getting specialist review stats: $e');
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  /// Update specialist rating based on reviews
  Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      final stats = await getSpecialistReviewStats(specialistId);
      
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .update({
        'rating': stats['averageRating'],
        'reviewsCount': stats['totalReviews'],
        'updatedAt': Timestamp.now(),
      });

      debugPrint('Specialist rating updated: $specialistId');
    } catch (e) {
      debugPrint('Error updating specialist rating: $e');
    }
  }

  /// Check if client can review specialist
  Future<bool> canClientReviewSpecialist(String clientId, String specialistId) async {
    try {
      // Check if client has completed bookings with specialist
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'completed')
          .get();

      if (bookingsQuery.docs.isEmpty) {
        return false;
      }

      // Check if client already reviewed this specialist
      final reviewQuery = await _firestore
          .collection('reviews')
          .where('clientId', isEqualTo: clientId)
          .where('specialistId', isEqualTo: specialistId)
          .get();

      return reviewQuery.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking if client can review: $e');
      return false;
    }
  }

  /// Get recent reviews
  Future<List<Review>> getRecentReviews({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting recent reviews: $e');
      return [];
    }
  }

  /// Get top rated specialists
  Future<List<Map<String, dynamic>>> getTopRatedSpecialists({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('specialists')
          .orderBy('rating', descending: true)
          .orderBy('reviewsCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
            'id': doc.id,
            'name': doc.data()['name'] ?? '',
            'rating': doc.data()['rating'] ?? 0.0,
            'reviewsCount': doc.data()['reviewsCount'] ?? 0,
          })
          .toList();
    } catch (e) {
      debugPrint('Error getting top rated specialists: $e');
      return [];
    }
  }
}