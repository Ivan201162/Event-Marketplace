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
    late MockCollectionReference<Map<String, dynamic>> mockBookingsCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockReviewsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockBookingsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocumentRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('reviews'))
          .thenReturn(mockReviewsCollection);
      when(mockFirestore.collection('bookings'))
          .thenReturn(mockBookingsCollection);
      when(mockReviewsCollection.doc(any)).thenReturn(mockDocumentRef);
      when(mockBookingsCollection.doc(any)).thenReturn(mockDocumentRef);

      repository = ReviewRepository();
      // Заменяем приватное поле _db через рефлексию или создаем тестовую версию
    });

    group('addReview', () {
      test('should add review successfully', () async {
        // Arrange
        final review = Review(
          id: 'review_1',
          bookingId: 'booking_1',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          customerName: 'Customer',
          rating: 4,
          comment: 'Отличная работа!',
          createdAt: DateTime.now(),
        );

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'status': 'completed',
          'customerId': 'customer_1',
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockReviewsCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockQuery);

        when(mockDocumentRef.set(any)).thenAnswer((_) async {});

        // Act
        await repository.addReview(review);

        // Assert
        verify(mockDocumentRef.set(any)).called(1);
      });

      test('should throw exception for invalid rating', () async {
        // Arrange
        final review = Review(
          id: 'review_1',
          bookingId: 'booking_1',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          rating: 6, // Неверный рейтинг
          comment: 'Отличная работа!',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => repository.addReview(review),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Некорректный рейтинг'),
            ),
          ),
        );
      });

      test('should throw exception for invalid comment', () async {
        // Arrange
        final review = Review(
          id: 'review_1',
          bookingId: 'booking_1',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          customerName: 'Customer',
          rating: 4,
          comment: 'Короткий', // Неверный комментарий
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => repository.addReview(review),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Комментарий должен содержать минимум 10 символов'),
            ),
          ),
        );
      });

      test('should throw exception for non-completed booking', () async {
        // Arrange
        final review = Review(
          id: 'review_1',
          bookingId: 'booking_1',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          customerName: 'Customer',
          rating: 4,
          comment: 'Отличная работа!',
          createdAt: DateTime.now(),
        );

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'status': 'pending', // Не завершенный заказ
          'customerId': 'customer_1',
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        // Act & Assert
        expect(
          () => repository.addReview(review),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Отзыв можно оставить только для завершенных заказов'),
            ),
          ),
        );
      });

      test('should throw exception for existing review', () async {
        // Arrange
        final review = Review(
          id: 'review_1',
          bookingId: 'booking_1',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          customerName: 'Customer',
          rating: 4,
          comment: 'Отличная работа!',
          createdAt: DateTime.now(),
        );

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'status': 'completed',
          'customerId': 'customer_1',
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        // Существующий отзыв
        final existingReviewDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(existingReviewDoc.id).thenReturn('existing_review');
        when(mockQuerySnapshot.docs).thenReturn([existingReviewDoc]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockReviewsCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockQuery);

        // Act & Assert
        expect(
          () => repository.addReview(review),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Отзыв для этого заказа уже существует'),
            ),
          ),
        );
      });
    });

    group('editReview', () {
      test('should edit review successfully', () async {
        // Arrange
        const reviewId = 'review_1';
        const newRating = 5.0;
        const newComment = 'Превосходная работа!';

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'customerId': 'customer_1',
          'edited': false,
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentRef.update(any)).thenAnswer((_) async {});

        // Act
        await repository.editReview(
          reviewId,
          rating: newRating,
          comment: newComment,
        );

        // Assert
        verify(mockDocumentRef.update(any)).called(1);
      });

      test('should throw exception for non-existent review', () async {
        // Arrange
        const reviewId = 'non_existent_review';

        when(mockDocumentSnapshot.exists).thenReturn(false);
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        // Act & Assert
        expect(
          () => repository.editReview(reviewId, rating: 5),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Отзыв не найден'),
            ),
          ),
        );
      });

      test('should throw exception for already edited review', () async {
        // Arrange
        const reviewId = 'review_1';

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'customerId': 'customer_1',
          'edited': true, // Уже отредактирован
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        // Act & Assert
        expect(
          () => repository.editReview(reviewId, rating: 5),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Отзыв уже был отредактирован'),
            ),
          ),
        );
      });
    });

    group('getReviewsBySpecialist', () {
      test('should return reviews for specialist', () async {
        // Arrange
        const specialistId = 'specialist_1';
        final reviewData = {
          'bookingId': 'booking_1',
          'specialistId': specialistId,
          'customerId': 'customer_1',
          'rating': 4.5,
          'comment': 'Отличная работа!',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'reported': false,
        };

        final reviewDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(reviewDoc.id).thenReturn('review_1');
        when(reviewDoc.data()).thenReturn(reviewData);
        when(mockQuerySnapshot.docs).thenReturn([reviewDoc]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockReviewsCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockQuery);

        // Act
        final reviews = await repository.getReviewsBySpecialist(specialistId);

        // Assert
        expect(reviews, isA<List<Review>>());
        expect(reviews.length, 1);
        expect(reviews.first.specialistId, specialistId);
      });
    });

    group('canLeaveReview', () {
      test('should return true for completed booking without review', () async {
        // Arrange
        const bookingId = 'booking_1';
        const customerId = 'customer_1';

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'status': 'completed',
          'customerId': customerId,
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockReviewsCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockQuery);

        // Act
        final canLeave = await repository.canLeaveReview(
          bookingId: bookingId,
          customerId: customerId,
        );

        // Assert
        expect(canLeave, true);
      });

      test('should return false for non-completed booking', () async {
        // Arrange
        const bookingId = 'booking_1';
        const customerId = 'customer_1';

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'status': 'pending',
          'customerId': customerId,
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        // Act
        final canLeave = await repository.canLeaveReview(
          bookingId: bookingId,
          customerId: customerId,
        );

        // Assert
        expect(canLeave, false);
      });

      test('should return false for existing review', () async {
        // Arrange
        const bookingId = 'booking_1';
        const customerId = 'customer_1';

        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn({
          'status': 'completed',
          'customerId': customerId,
        });
        when(mockDocumentRef.get())
            .thenAnswer((_) async => mockDocumentSnapshot);

        // Существующий отзыв
        final existingReviewDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockQuerySnapshot.docs).thenReturn([existingReviewDoc]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockReviewsCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockQuery);

        // Act
        final canLeave = await repository.canLeaveReview(
          bookingId: bookingId,
          customerId: customerId,
        );

        // Assert
        expect(canLeave, false);
      });
    });

    group('getSpecialistReviewStats', () {
      test('should return correct statistics', () async {
        // Arrange
        const specialistId = 'specialist_1';
        final reviewData1 = {
          'bookingId': 'booking_1',
          'specialistId': specialistId,
          'customerId': 'customer_1',
          'rating': 4.0,
          'comment': 'Хорошая работа!',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'reported': false,
        };

        final reviewData2 = {
          'bookingId': 'booking_2',
          'specialistId': specialistId,
          'customerId': 'customer_2',
          'rating': 5.0,
          'comment': 'Отличная работа!',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'reported': false,
        };

        final reviewDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(reviewDoc1.data()).thenReturn(reviewData1);

        final reviewDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(reviewDoc2.data()).thenReturn(reviewData2);

        when(mockQuerySnapshot.docs).thenReturn([reviewDoc1, reviewDoc2]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockReviewsCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockQuery);

        // Act
        final stats = await repository.getSpecialistReviewStats(specialistId);

        // Assert
        expect(stats['avgRating'], 4.5);
        expect(stats['reviewsCount'], 2);
        expect(stats['ratingDistribution'], isA<Map<int, int>>());
      });

      test('should return zero stats for specialist without reviews', () async {
        // Arrange
        const specialistId = 'specialist_1';

        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockReviewsCollection.where(any, isEqualTo: anyNamed('isEqualTo')))
            .thenReturn(mockQuery);

        // Act
        final stats = await repository.getSpecialistReviewStats(specialistId);

        // Assert
        expect(stats['avgRating'], 0.0);
        expect(stats['reviewsCount'], 0);
        expect(stats['ratingDistribution'], {1: 0, 2: 0, 3: 0, 4: 0, 5: 0});
      });
    });
  });
}
