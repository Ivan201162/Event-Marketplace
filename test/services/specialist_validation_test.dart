import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Specialist Service Validation Tests', () {
    group('Specialist Profile Validation', () {
      test('should validate specialist profile completeness', () {
        final profile = {
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '+7 (999) 123-45-67',
          'bio': 'Experienced event specialist',
          'skills': ['photography', 'videography'],
          'experience': 5,
        };

        expect(_isProfileComplete(profile), isTrue);
      });

      test('should validate specialist skills', () {
        final validSkills = ['photography', 'videography', 'music', 'catering'];
        final invalidSkills = ['', 'invalid-skill', null];

        for (final skill in validSkills) {
          expect(_isValidSkill(skill), isTrue);
        }

        for (final skill in invalidSkills) {
          expect(_isValidSkill(skill), isFalse);
        }
      });

      test('should validate specialist experience', () {
        expect(_isValidExperience(0), isTrue);
        expect(_isValidExperience(5), isTrue);
        expect(_isValidExperience(20), isTrue);
        expect(_isValidExperience(-1), isFalse);
        expect(_isValidExperience(100), isFalse);
      });

      test('should validate specialist rating', () {
        expect(_isValidRating(1), isTrue);
        expect(_isValidRating(4.5), isTrue);
        expect(_isValidRating(5), isTrue);
        expect(_isValidRating(0), isFalse);
        expect(_isValidRating(6), isFalse);
        expect(_isValidRating(-1), isFalse);
      });
    });

    group('Service Offering Validation', () {
      test('should validate service categories', () {
        final validCategories = [
          'photography',
          'videography',
          'music',
          'catering',
          'decoration',
        ];
        final invalidCategories = ['', 'invalid-category', null];

        for (final category in validCategories) {
          expect(_isValidServiceCategory(category), isTrue);
        }

        for (final category in invalidCategories) {
          expect(_isValidServiceCategory(category), isFalse);
        }
      });

      test('should validate service pricing', () {
        expect(_isValidPrice(100), isTrue);
        expect(_isValidPrice(0), isFalse);
        expect(_isValidPrice(-50), isFalse);
        expect(_isValidPrice(10000), isTrue);
      });

      test('should validate service duration', () {
        expect(_isValidDuration(1), isTrue); // 1 hour
        expect(_isValidDuration(8), isTrue); // 8 hours
        expect(_isValidDuration(0), isFalse);
        expect(_isValidDuration(24), isFalse); // Too long
      });

      test('should validate service availability', () {
        final availability = {
          'monday': [9, 10, 11, 14, 15, 16],
          'tuesday': [9, 10, 11, 14, 15, 16],
          'wednesday': [9, 10, 11, 14, 15, 16],
        };

        expect(_isValidAvailability(availability), isTrue);

        final invalidAvailability = <String, List<int>>{
          'monday': <int>[],
          'tuesday': <int>[25, 26], // Invalid hours
        };

        expect(_isValidAvailability(invalidAvailability), isFalse);
      });
    });

    group('Portfolio Validation', () {
      test('should validate portfolio images', () {
        final validImages = [
          'https://example.com/image1.jpg',
          'https://example.com/image2.png',
          'https://example.com/image3.jpeg',
        ];

        final invalidImages = [
          'invalid-url',
          'https://example.com/image1.txt',
          '',
          null,
        ];

        for (final image in validImages) {
          expect(_isValidPortfolioImage(image), isTrue);
        }

        for (final image in invalidImages) {
          expect(_isValidPortfolioImage(image), isFalse);
        }
      });

      test('should validate portfolio videos', () {
        final validVideos = [
          'https://example.com/video1.mp4',
          'https://example.com/video2.mov',
          'https://youtube.com/watch?v=123',
        ];

        final invalidVideos = [
          'invalid-url',
          'https://example.com/video1.txt',
          '',
          null,
        ];

        for (final video in validVideos) {
          expect(_isValidPortfolioVideo(video), isTrue);
        }

        for (final video in invalidVideos) {
          expect(_isValidPortfolioVideo(video), isFalse);
        }
      });

      test('should validate portfolio descriptions', () {
        const validDescription =
            'This is a detailed description of the work performed.';
        const invalidDescription = 'Short';

        expect(_isValidPortfolioDescription(validDescription), isTrue);
        expect(_isValidPortfolioDescription(invalidDescription), isFalse);
      });
    });

    group('Booking Management Validation', () {
      test('should validate booking acceptance', () {
        final booking = {
          'id': 'booking-123',
          'customerId': 'customer-123',
          'serviceId': 'service-123',
          'date': DateTime.now().add(const Duration(days: 1)),
          'status': 'pending',
        };

        expect(_canAcceptBooking(booking), isTrue);
      });

      test('should validate booking rejection', () {
        final booking = {
          'id': 'booking-123',
          'status': 'pending',
        };

        expect(_canRejectBooking(booking), isTrue);

        final completedBooking = {
          'id': 'booking-123',
          'status': 'completed',
        };

        expect(_canRejectBooking(completedBooking), isFalse);
      });

      test('should validate schedule conflicts', () {
        final existingBookings = [
          {
            'startTime': DateTime(2024, 1, 1, 14),
            'endTime': DateTime(2024, 1, 1, 16),
          },
        ];

        final newBooking = {
          'startTime': DateTime(2024, 1, 1, 15),
          'endTime': DateTime(2024, 1, 1, 17),
        };

        expect(_hasScheduleConflict(existingBookings, newBooking), isTrue);
      });
    });

    group('Review and Rating Validation', () {
      test('should validate review content', () {
        const validReview = 'Great service! Highly recommended.';
        const invalidReview = 'Bad';

        expect(_isValidReview(validReview), isTrue);
        expect(_isValidReview(invalidReview), isFalse);
      });

      test('should validate rating values', () {
        expect(_isValidRatingValue(1), isTrue);
        expect(_isValidRatingValue(5), isTrue);
        expect(_isValidRatingValue(0), isFalse);
        expect(_isValidRatingValue(6), isFalse);
      });

      test('should validate review submission timing', () {
        final bookingDate = DateTime.now().subtract(const Duration(days: 1));
        final serviceDate = DateTime.now().subtract(const Duration(days: 2));

        expect(_canSubmitReview(bookingDate, serviceDate), isTrue);

        final futureBookingDate = DateTime.now().add(const Duration(days: 1));
        expect(_canSubmitReview(futureBookingDate, serviceDate), isFalse);
      });
    });

    group('Location and Travel Validation', () {
      test('should validate service area', () {
        const specialistLocation = 'Moscow';
        const customerLocation = 'Moscow';
        const maxDistance = 50; // km

        expect(
          _isWithinServiceArea(
            specialistLocation,
            customerLocation,
            maxDistance,
          ),
          isTrue,
        );

        const farLocation = 'St. Petersburg';
        expect(
          _isWithinServiceArea(specialistLocation, farLocation, maxDistance),
          isFalse,
        );
      });

      test('should validate travel fees', () {
        const distance = 25.0; // km
        const baseRate = 2.0; // per km
        const expectedFee = distance * baseRate;

        expect(_calculateTravelFee(distance, baseRate), equals(expectedFee));
      });
    });

    group('Payment and Commission Validation', () {
      test('should validate commission calculation', () {
        const servicePrice = 1000.0;
        const commissionRate = 0.1; // 10%
        const expectedCommission = 100.0;

        expect(
          _calculateCommission(servicePrice, commissionRate),
          equals(expectedCommission),
        );
      });

      test('should validate payout eligibility', () {
        const totalEarnings = 500.0;
        const minimumPayout = 100.0;

        expect(_isEligibleForPayout(totalEarnings, minimumPayout), isTrue);

        const lowEarnings = 50.0;
        expect(_isEligibleForPayout(lowEarnings, minimumPayout), isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle invalid profile data', () {
        expect(_isProfileComplete(null), isFalse);
        expect(_isProfileComplete({}), isFalse);
        expect(_isProfileComplete({'name': ''}), isFalse);
      });

      test('should handle invalid service data', () {
        expect(_isValidServiceCategory(null), isFalse);
        expect(_isValidPrice(null), isFalse);
        expect(_isValidDuration(null), isFalse);
      });

      test('should handle invalid booking data', () {
        expect(_canAcceptBooking(null), isFalse);
        expect(_canRejectBooking(null), isFalse);
        expect(_hasScheduleConflict(null, {}), isFalse);
      });

      test('should handle invalid review data', () {
        expect(_isValidReview(null), isFalse);
        expect(_isValidRatingValue(null), isFalse);
        expect(_canSubmitReview(null, null), isFalse);
      });
    });
  });
}

/// Helper function to validate profile completeness
bool _isProfileComplete(Map<String, dynamic>? profile) {
  if (profile == null) return false;

  final requiredFields = [
    'name',
    'email',
    'phone',
    'bio',
    'skills',
    'experience',
  ];
  for (final field in requiredFields) {
    if (!profile.containsKey(field) || profile[field] == null) {
      return false;
    }
  }

  return profile['name'].toString().isNotEmpty &&
      profile['email'].toString().isNotEmpty &&
      profile['phone'].toString().isNotEmpty &&
      profile['bio'].toString().isNotEmpty &&
      (profile['skills'] as List).isNotEmpty &&
      profile['experience'] is int;
}

/// Helper function to validate skill
bool _isValidSkill(String? skill) {
  if (skill == null || skill.isEmpty) return false;

  const validSkills = [
    'photography',
    'videography',
    'music',
    'catering',
    'decoration',
    'lighting',
    'sound',
    'flowers',
    'entertainment',
    'planning',
  ];

  return validSkills.contains(skill.toLowerCase());
}

/// Helper function to validate experience
bool _isValidExperience(int? experience) {
  if (experience == null) return false;
  return experience >= 0 && experience <= 50;
}

/// Helper function to validate rating
bool _isValidRating(double? rating) {
  if (rating == null) return false;
  return rating > 0.0 && rating <= 5.0;
}

/// Helper function to validate service category
bool _isValidServiceCategory(String? category) {
  if (category == null || category.isEmpty) return false;

  const validCategories = [
    'photography',
    'videography',
    'music',
    'catering',
    'decoration',
    'lighting',
    'sound',
    'flowers',
    'entertainment',
    'planning',
  ];

  return validCategories.contains(category.toLowerCase());
}

/// Helper function to validate price
bool _isValidPrice(double? price) {
  if (price == null) return false;
  return price > 0.0 && price <= 100000.0;
}

/// Helper function to validate duration
bool _isValidDuration(int? duration) {
  if (duration == null) return false;
  return duration > 0 && duration <= 12; // Max 12 hours
}

/// Helper function to validate availability
bool _isValidAvailability(Map<String, List<int>>? availability) {
  if (availability == null || availability.isEmpty) return false;

  for (final daySlots in availability.values) {
    for (final hour in daySlots) {
      if (hour < 0 || hour > 23) return false;
    }
  }

  return true;
}

/// Helper function to validate portfolio image
bool _isValidPortfolioImage(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return false;

  final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  final hasValidExtension =
      validExtensions.any((ext) => imageUrl.toLowerCase().endsWith(ext));

  return imageUrl.startsWith('http') && hasValidExtension;
}

/// Helper function to validate portfolio video
bool _isValidPortfolioVideo(String? videoUrl) {
  if (videoUrl == null || videoUrl.isEmpty) return false;

  final validExtensions = ['.mp4', '.mov', '.avi', '.webm'];
  final hasValidExtension =
      validExtensions.any((ext) => videoUrl.toLowerCase().endsWith(ext));
  final isYouTubeUrl =
      videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be');

  return (videoUrl.startsWith('http') && hasValidExtension) || isYouTubeUrl;
}

/// Helper function to validate portfolio description
bool _isValidPortfolioDescription(String? description) {
  if (description == null) return false;
  return description.length >= 10 && description.length <= 1000;
}

/// Helper function to check booking acceptance
bool _canAcceptBooking(Map<String, dynamic>? booking) {
  if (booking == null) return false;
  return booking['status'] == 'pending';
}

/// Helper function to check booking rejection
bool _canRejectBooking(Map<String, dynamic>? booking) {
  if (booking == null) return false;
  return ['pending', 'confirmed'].contains(booking['status']);
}

/// Helper function to check schedule conflicts
bool _hasScheduleConflict(
  List<Map<String, DateTime>>? existingBookings,
  Map<String, DateTime>? newBooking,
) {
  if (existingBookings == null || newBooking == null) return false;

  final newStart = newBooking['startTime']!;
  final newEnd = newBooking['endTime']!;

  for (final existing in existingBookings) {
    final existingStart = existing['startTime']!;
    final existingEnd = existing['endTime']!;

    if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
      return true;
    }
  }

  return false;
}

/// Helper function to validate review
bool _isValidReview(String? review) {
  if (review == null) return false;
  return review.length >= 10 && review.length <= 500;
}

/// Helper function to validate rating value
bool _isValidRatingValue(int? rating) {
  if (rating == null) return false;
  return rating >= 1 && rating <= 5;
}

/// Helper function to check review submission timing
bool _canSubmitReview(DateTime? bookingDate, DateTime? serviceDate) {
  if (bookingDate == null || serviceDate == null) return false;
  return bookingDate.isAfter(serviceDate) &&
      DateTime.now().difference(serviceDate).inDays <= 30;
}

/// Helper function to check service area
bool _isWithinServiceArea(
  String specialistLocation,
  String customerLocation,
  int maxDistance,
) {
  // Mock implementation - in real app would calculate actual distance
  return specialistLocation == customerLocation;
}

/// Helper function to calculate travel fee
double _calculateTravelFee(double distance, double baseRate) =>
    distance * baseRate;

/// Helper function to calculate commission
double _calculateCommission(double servicePrice, double commissionRate) =>
    servicePrice * commissionRate;

/// Helper function to check payout eligibility
bool _isEligibleForPayout(double totalEarnings, double minimumPayout) =>
    totalEarnings >= minimumPayout;
