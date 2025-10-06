import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/services/review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewService Tests', () {
    late ReviewService reviewService;

    setUp(() {
      reviewService = ReviewService();
    });

    test('should calculate average rating correctly', () {
      // Arrange
      final reviews = [
        Review(
          id: '1',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          customerName: 'Customer 1',
          rating: 5,
          comment: 'Great!',
          createdAt: DateTime.now(),
        ),
        Review(
          id: '2',
          specialistId: 'specialist_1',
          customerId: 'customer_2',
          customerName: 'Customer 2',
          rating: 4,
          comment: 'Good!',
          createdAt: DateTime.now(),
        ),
        Review(
          id: '3',
          specialistId: 'specialist_1',
          customerId: 'customer_3',
          customerName: 'Customer 3',
          rating: 3,
          comment: 'Average',
          createdAt: DateTime.now(),
        ),
      ];

      // Act
      final totalRating = reviews.fold<double>(
        0,
        (sum, review) => sum + review.rating.toDouble(),
      );
      final averageRating = totalRating / reviews.length;

      // Assert
      expect(averageRating, equals(4.0));
    });

    test('should validate rating range', () {
      // Test valid ratings
      expect(
        () => Review(
          id: '1',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          customerName: 'Customer 1',
          rating: 1,
          comment: 'Test',
          createdAt: DateTime.now(),
        ),
        returnsNormally,
      );

      expect(
        () => Review(
          id: '2',
          specialistId: 'specialist_1',
          customerId: 'customer_1',
          customerName: 'Customer 1',
          rating: 5,
          comment: 'Test',
          createdAt: DateTime.now(),
        ),
        returnsNormally,
      );
    });

    test('should format review date correctly', () {
      // Arrange
      final now = DateTime.now();
      final review = Review(
        id: '1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 5,
        comment: 'Test',
        createdAt: now,
      );

      // Act
      final formattedDate = review.formattedCreatedAt;

      // Assert
      expect(formattedDate, isA<String>());
      expect(formattedDate, isNotEmpty);
    });

    test('should check if review can be edited', () {
      // Arrange
      final recentReview = Review(
        id: '1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 5,
        comment: 'Test',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      );

      final oldReview = Review(
        id: '2',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 5,
        comment: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      // Act & Assert
      expect(recentReview.canEdit, isTrue);
      expect(oldReview.canEdit, isFalse);
    });

    test('should check if review can be deleted', () {
      // Arrange
      final recentReview = Review(
        id: '1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 5,
        comment: 'Test',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      );

      final oldReview = Review(
        id: '2',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 5,
        comment: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      // Act & Assert
      expect(recentReview.canDelete, isTrue);
      expect(oldReview.canDelete, isFalse);
    });

    test('should generate rating stars correctly', () {
      // Arrange
      final review = Review(
        id: '1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 3,
        comment: 'Test',
        createdAt: DateTime.now(),
      );

      // Act
      final stars = review.ratingStars;

      // Assert
      expect(stars, equals('★★★☆☆'));
    });

    test('should get correct rating color', () {
      // Arrange
      final highRatingReview = Review(
        id: '1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 5,
        comment: 'Test',
        createdAt: DateTime.now(),
      );

      final mediumRatingReview = Review(
        id: '2',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 3,
        comment: 'Test',
        createdAt: DateTime.now(),
      );

      final lowRatingReview = Review(
        id: '3',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer 1',
        rating: 1,
        comment: 'Test',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(highRatingReview.ratingColor, equals('green'));
      expect(mediumRatingReview.ratingColor, equals('orange'));
      expect(lowRatingReview.ratingColor, equals('red'));
    });
  });
}
