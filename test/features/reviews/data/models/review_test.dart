import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot(this._id, this._data) {
    when(id).thenReturn(_id);
    when(data()).thenReturn(_data);
    when(exists).thenReturn(true);
    when(metadata).thenReturn(const SnapshotMetadata(false, false, false));
  }

  @override
  dynamic get(Object field) => _data[field];
}

void main() {
  group('Review Model Tests', () {
    test('should create review from firestore document', () {
      final data = {
        'specialistId': 'specialist_1',
        'clientId': 'client_1',
        'clientName': 'Client Name',
        'specialistName': 'Specialist Name',
        'rating': 4,
        'comment': 'Отличная работа!',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 16)),
        'images': [],
        'likedBy': [],
        'likesCount': 0,
        'hasComment': true,
        'tags': [],
        'isVerified': false,
        'isPublic': true,
        'serviceTags': [],
        'photos': [],
        'responses': [],
      };

      final doc = MockDocumentSnapshot('review_1', data);
      final review = Review.fromFirestore(doc);

      expect(review.id, 'review_1');
      expect(review.specialistId, 'specialist_1');
      expect(review.clientId, 'client_1');
      expect(review.clientName, 'Client Name');
      expect(review.specialistName, 'Specialist Name');
      expect(review.rating, 4);
      expect(review.comment, 'Отличная работа!');
      expect(review.hasComment, true);
    });

    test('should convert review to firestore document', () {
      final review = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 4,
        comment: 'Отличная работа!',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
      );

      final firestoreData = review.toFirestore();

      expect(firestoreData['specialistId'], 'specialist_1');
      expect(firestoreData['clientId'], 'client_1');
      expect(firestoreData['clientName'], 'Client Name');
      expect(firestoreData['specialistName'], 'Specialist Name');
      expect(firestoreData['rating'], 4);
      expect(firestoreData['comment'], 'Отличная работа!');
    });

    test('should create review with all parameters', () {
      final review = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 5,
        comment: 'Отличная работа!',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
        images: const ['image1.jpg', 'image2.jpg'],
        likedBy: const ['user1', 'user2'],
        likesCount: 2,
        title: 'Great service',
        hasComment: true,
        tags: const ['professional', 'friendly'],
        isVerified: true,
        serviceTags: const ['photography'],
        photos: const ['photo1.jpg'],
        responses: const [
          {'text': 'Thank you!'},
        ],
      );

      expect(review.id, 'review_1');
      expect(review.specialistId, 'specialist_1');
      expect(review.clientId, 'client_1');
      expect(review.clientName, 'Client Name');
      expect(review.specialistName, 'Specialist Name');
      expect(review.rating, 5);
      expect(review.comment, 'Отличная работа!');
      expect(review.images, ['image1.jpg', 'image2.jpg']);
      expect(review.likedBy, ['user1', 'user2']);
      expect(review.likesCount, 2);
      expect(review.title, 'Great service');
      expect(review.hasComment, true);
      expect(review.tags, ['professional', 'friendly']);
      expect(review.isVerified, true);
      expect(review.isPublic, true);
      expect(review.serviceTags, ['photography']);
      expect(review.photos, ['photo1.jpg']);
      expect(review.responses, [
        {'text': 'Thank you!'},
      ]);
    });

    test('should create copy with updated fields', () {
      final originalReview = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 4,
        comment: 'Good work',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
      );

      final updatedReview = originalReview.copyWith(
        rating: 5,
        comment: 'Excellent work!',
        isVerified: true,
      );

      expect(updatedReview.id, 'review_1');
      expect(updatedReview.rating, 5);
      expect(updatedReview.comment, 'Excellent work!');
      expect(updatedReview.isVerified, true);
      expect(updatedReview.specialistId, 'specialist_1'); // unchanged
    });

    test('should get rating stars string', () {
      final review = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(review.ratingStars, '⭐⭐⭐');
    });

    test('should get time ago string', () {
      final now = DateTime.now();
      final review = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 4,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      );

      expect(review.timeAgo, '2ч назад');
    });

    test('should check if review has images', () {
      final reviewWithImages = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        images: const ['image1.jpg'],
      );

      final reviewWithoutImages = Review(
        id: 'review_2',
        specialistId: 'specialist_2',
        clientId: 'client_2',
        clientName: 'Client Name 2',
        specialistName: 'Specialist Name 2',
        rating: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(reviewWithImages.hasImages, true);
      expect(reviewWithoutImages.hasImages, false);
    });

    test('should get first image', () {
      final review = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        images: const ['image1.jpg', 'image2.jpg'],
      );

      expect(review.firstImage, 'image1.jpg');
    });

    test('should return null for first image when no images', () {
      final review = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        clientId: 'client_1',
        clientName: 'Client Name',
        specialistName: 'Specialist Name',
        rating: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(review.firstImage, null);
    });
  });

  group('ReviewStats Model Tests', () {
    test('should create review stats', () {
      const stats = ReviewStats(
        averageRating: 4.5,
        totalReviews: 100,
        ratingDistribution: {1: 5, 2: 10, 3: 20, 4: 35, 5: 30},
        verifiedReviews: 80,
        recentReviews: 25,
      );

      expect(stats.averageRating, 4.5);
      expect(stats.totalReviews, 100);
      expect(stats.verifiedReviews, 80);
      expect(stats.recentReviews, 25);
    });

    test('should calculate rating percentage', () {
      const stats = ReviewStats(
        averageRating: 4.5,
        totalReviews: 100,
        ratingDistribution: {1: 5, 2: 10, 3: 20, 4: 35, 5: 30},
        verifiedReviews: 80,
        recentReviews: 25,
      );

      expect(stats.getRatingPercentage(5), 30.0);
      expect(stats.getRatingPercentage(4), 35.0);
      expect(stats.getRatingPercentage(1), 5.0);
    });

    test('should format average rating', () {
      const stats = ReviewStats(
        averageRating: 4.567,
        totalReviews: 100,
        ratingDistribution: {},
        verifiedReviews: 80,
        recentReviews: 25,
      );

      expect(stats.formattedAverageRating, '4.6');
    });
  });

  group('SpecialistReviewStats Model Tests', () {
    test('should create specialist review stats', () {
      const stats = SpecialistReviewStats(
        specialistId: 'specialist_1',
        averageRating: 4.8,
        totalReviews: 50,
        ratingDistribution: {1: 0, 2: 1, 3: 2, 4: 10, 5: 37},
        topTags: ['professional', 'friendly', 'reliable'],
        serviceRatings: {'photography': 4.9, 'videography': 4.7},
      );

      expect(stats.specialistId, 'specialist_1');
      expect(stats.averageRating, 4.8);
      expect(stats.totalReviews, 50);
      expect(stats.topTags, ['professional', 'friendly', 'reliable']);
      expect(stats.serviceRatings, {'photography': 4.9, 'videography': 4.7});
    });
  });
}
