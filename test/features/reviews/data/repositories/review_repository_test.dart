import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/features/reviews/data/repositories/review_repository.dart';
import 'package:event_marketplace_app/models/review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'review_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>,
  DocumentSnapshot<Map<String, dynamic>>,
  Query<Map<String, dynamic>>,
  QuerySnapshot<Map<String, dynamic>>,
  QueryDocumentSnapshot<Map<String, dynamic>>,
])
void main() {
  group('ReviewRepository Tests', () {
    late ReviewRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockReviewsCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockReviewsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocumentRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('reviews')).thenReturn(mockReviewsCollection);
      when(mockReviewsCollection.doc(any)).thenReturn(mockDocumentRef);

      repository = ReviewRepository();
    });

    group('addReview', () {
      test('should add review successfully', () async {
        // Arrange
        final review = Review(
          id: 'review_1',
          specialistId: 'specialist_1',
          clientId: 'client_1',
          clientName: 'Client Name',
          specialistName: 'Specialist Name',
          rating: 4,
          comment: 'Отличная работа!',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDocumentRef.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.addReview(review);

        // Assert
        expect(result, true);
        verify(mockDocumentRef.set(any)).called(1);
      });

      test('should handle error when adding review', () async {
        // Arrange
        final review = Review(
          id: 'review_1',
          specialistId: 'specialist_1',
          clientId: 'client_1',
          clientName: 'Client Name',
          specialistName: 'Specialist Name',
          rating: 4,
          comment: 'Отличная работа!',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDocumentRef.set(any)).thenThrow(Exception('Database error'));

        // Act
        final result = await repository.addReview(review);

        // Assert
        expect(result, false);
      });
    });

    group('getReviews', () {
      test('should get reviews successfully', () async {
        // Arrange
        final reviewData = {
          'specialistId': 'specialist_1',
          'clientId': 'client_1',
          'clientName': 'Client Name',
          'specialistName': 'Specialist Name',
          'rating': 4,
          'comment': 'Отличная работа!',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
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

        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.id).thenReturn('review_1');
        when(mockQueryDocSnapshot.data()).thenReturn(reviewData);

        when(mockReviewsCollection.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);

        // Act
        final reviews = await repository.getReviews(limit: 10);

        // Assert
        expect(reviews.length, 1);
        expect(reviews.first.id, 'review_1');
        expect(reviews.first.rating, 4);
      });

      test('should handle error when getting reviews', () async {
        // Arrange
        when(mockReviewsCollection.orderBy(any, descending: any))
            .thenThrow(Exception('Database error'));

        // Act
        final reviews = await repository.getReviews();

        // Assert
        expect(reviews, isEmpty);
      });
    });

    group('getReviewsBySpecialist', () {
      test('should get reviews by specialist successfully', () async {
        // Arrange
        const specialistId = 'specialist_1';
        final reviewData = {
          'specialistId': specialistId,
          'clientId': 'client_1',
          'clientName': 'Client Name',
          'specialistName': 'Specialist Name',
          'rating': 4,
          'comment': 'Отличная работа!',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
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

        final mockQueryDocSnapshot = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot.id).thenReturn('review_1');
        when(mockQueryDocSnapshot.data()).thenReturn(reviewData);

        when(mockReviewsCollection.where('specialistId', isEqualTo: specialistId))
            .thenReturn(mockQuery);
        when(mockQuery.orderBy('createdAt', descending: true)).thenReturn(mockQuery);
        when(mockQuery.limit(any)).thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);

        // Act
        final reviews = await repository.getReviewsBySpecialist(specialistId, limit: 10);

        // Assert
        expect(reviews.length, 1);
        expect(reviews.first.specialistId, specialistId);
      });
    });

    group('updateReview', () {
      test('should update review successfully', () async {
        // Arrange
        const reviewId = 'review_1';
        final updates = {'comment': 'Updated comment', 'rating': 5};

        when(mockDocumentRef.update(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.updateReview(reviewId, updates);

        // Assert
        expect(result, true);
        verify(mockDocumentRef.update(any)).called(1);
      });

      test('should handle error when updating review', () async {
        // Arrange
        const reviewId = 'review_1';
        final updates = {'comment': 'Updated comment'};

        when(mockDocumentRef.update(any)).thenThrow(Exception('Database error'));

        // Act
        final result = await repository.updateReview(reviewId, updates);

        // Assert
        expect(result, false);
      });
    });

    group('deleteReview', () {
      test('should delete review successfully', () async {
        // Arrange
        const reviewId = 'review_1';

        when(mockDocumentRef.delete()).thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteReview(reviewId);

        // Assert
        expect(result, true);
        verify(mockDocumentRef.delete()).called(1);
      });

      test('should handle error when deleting review', () async {
        // Arrange
        const reviewId = 'review_1';

        when(mockDocumentRef.delete()).thenThrow(Exception('Database error'));

        // Act
        final result = await repository.deleteReview(reviewId);

        // Assert
        expect(result, false);
      });
    });

    group('getReviewStats', () {
      test('should get review stats successfully', () async {
        // Arrange
        const specialistId = 'specialist_1';
        final reviewData1 = {
          'specialistId': specialistId,
          'clientId': 'client_1',
          'clientName': 'Client Name',
          'specialistName': 'Specialist Name',
          'rating': 5,
          'comment': 'Excellent!',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'images': [],
          'likedBy': [],
          'likesCount': 0,
          'hasComment': true,
          'tags': [],
          'isVerified': true,
          'isPublic': true,
          'serviceTags': [],
          'photos': [],
          'responses': [],
        };

        final reviewData2 = {
          'specialistId': specialistId,
          'clientId': 'client_2',
          'clientName': 'Client Name 2',
          'specialistName': 'Specialist Name',
          'rating': 4,
          'comment': 'Good work',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
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

        final mockQueryDocSnapshot1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot1.id).thenReturn('review_1');
        when(mockQueryDocSnapshot1.data()).thenReturn(reviewData1);

        final mockQueryDocSnapshot2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQueryDocSnapshot2.id).thenReturn('review_2');
        when(mockQueryDocSnapshot2.data()).thenReturn(reviewData2);

        when(mockReviewsCollection.where('specialistId', isEqualTo: specialistId))
            .thenReturn(mockQuery);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot1, mockQueryDocSnapshot2]);

        // Act
        final stats = await repository.getReviewStats(specialistId);

        // Assert
        expect(stats, isNotNull);
        expect(stats.totalReviews, 2);
        expect(stats.averageRating, 4.5);
      });
    });
  });
}
