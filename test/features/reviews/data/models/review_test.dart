import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Review Model Tests', () {
    test('should create review from map', () {
      final map = {
        'id': 'review_1',
        'bookingId': 'booking_1',
        'specialistId': 'specialist_1',
        'customerId': 'customer_1',
        'rating': 4.5,
        'comment': 'Отличная работа!',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 16)),
        'edited': true,
        'reported': false,
        'reportReason': null,
      };

      final review = Review.fromMap(map);

      expect(review.id, 'review_1');
      expect(review.bookingId, 'booking_1');
      expect(review.specialistId, 'specialist_1');
      expect(review.customerId, 'customer_1');
      expect(review.rating, 4);
      expect(review.text, 'Отличная работа!');
      expect(review.isEdited, true);
      expect(review.metadata['reported'], false);
      expect(review.metadata['reportReason'], null);
    });

    test('should convert review to map', () {
      final review = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer Name',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime(2024, 1, 15),
        bookingId: 'booking_1',
        editedAt: DateTime(2024, 1, 16),
        isEdited: true,
      );

      final map = review.toMap();

      expect(map['bookingId'], 'booking_1');
      expect(map['specialistId'], 'specialist_1');
      expect(map['customerId'], 'customer_1');
      expect(map['rating'], 4);
      expect(map['comment'], 'Отличная работа!');
      expect(map['isEdited'], true);
      expect(map['reported'], false);
      expect(map['reportReason'], null);
    });

    test('should validate rating correctly', () {
      final review = Review(
        id: 'test',
        specialistId: 'test',
        customerId: 'test',
        customerName: 'test',
        rating: 1,
        text: 'test',
        date: DateTime.now(),
      );
      expect(review.isValidRating(1), true);
      expect(review.isValidRating(2), true);
      expect(review.isValidRating(5), true);
      expect(review.isValidRating(0), false); // Меньше 1
      expect(review.isValidRating(6), false); // Больше 5
    });

    test('should validate comment correctly', () {
      final review = Review(
        id: 'test',
        specialistId: 'test',
        customerId: 'test',
        customerName: 'test',
        rating: 1,
        text: 'test',
        date: DateTime.now(),
      );
      expect(review.isValidComment('Это хороший комментарий'), true);
      expect(review.isValidComment('   Это тоже хороший комментарий   '), true);
      expect(review.isValidComment('Короткий'), false); // Меньше 10 символов
      expect(review.isValidComment(''), false); // Пустой
      expect(review.isValidComment('   '), false); // Только пробелы
    });

    test('should check if review can be edited', () {
      final editableReview = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime.now(),
        bookingId: 'booking_1',
      );

      final nonEditableReview = Review(
        id: 'review_2',
        specialistId: 'specialist_2',
        customerId: 'customer_2',
        customerName: 'Customer',
        rating: 4,
        text: 'Хорошая работа!',
        date: DateTime.now(),
        bookingId: 'booking_2',
        isEdited: true,
      );

      expect(editableReview.canEdit, true);
      expect(nonEditableReview.canEdit, false);
    });

    test('should check if review can be reported', () {
      final reportableReview = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime.now(),
        bookingId: 'booking_1',
      );

      final reportedReview = Review(
        id: 'review_2',
        specialistId: 'specialist_2',
        customerId: 'customer_2',
        customerName: 'Customer',
        rating: 4,
        text: 'Хорошая работа!',
        date: DateTime.now(),
        bookingId: 'booking_2',
        metadata: const {'reported': true},
      );

      expect(reportableReview.canReport(), true);
      expect(reportedReview.canReport(), false);
    });

    test('should copy review with changes', () {
      final originalReview = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime(2024, 1, 15),
        bookingId: 'booking_1',
      );

      final updatedReview = originalReview.copyWith(
        rating: 5,
        text: 'Превосходная работа!',
        isEdited: true,
        editedAt: DateTime(2024, 1, 16),
      );

      expect(updatedReview.id, originalReview.id);
      expect(updatedReview.rating, 5);
      expect(updatedReview.text, 'Превосходная работа!');
      expect(updatedReview.isEdited, true);
      expect(updatedReview.editedAt, DateTime(2024, 1, 16));
      expect(updatedReview.createdAt, originalReview.createdAt);
    });

    test('should implement equality correctly', () {
      final review1 = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime(2024, 1, 15),
        bookingId: 'booking_1',
      );

      final review2 = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime(2024, 1, 15),
        bookingId: 'booking_1',
      );

      final review3 = Review(
        id: 'review_2',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime(2024, 1, 15),
        bookingId: 'booking_1',
      );

      expect(review1, equals(review2));
      expect(review1, isNot(equals(review3)));
    });

    test('should implement hashCode correctly', () {
      final review1 = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime(2024, 1, 15),
        bookingId: 'booking_1',
      );

      final review2 = Review(
        id: 'review_1',
        specialistId: 'specialist_1',
        customerId: 'customer_1',
        customerName: 'Customer',
        rating: 4,
        text: 'Отличная работа!',
        date: DateTime(2024, 1, 15),
        bookingId: 'booking_1',
      );

      expect(review1.hashCode, equals(review2.hashCode));
    });
  });
}
