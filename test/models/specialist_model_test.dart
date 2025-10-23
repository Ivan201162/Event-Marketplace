import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/common_types.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Specialist Model Tests', () {
    test('Specialist toMap should convert all fields correctly', () {
      final now = DateTime.now();
      final specialist = Specialist(
        id: 'test_id',
        userId: 'test_user_id',
        name: 'Test Specialist',
        specialization: 'Photography',
        city: 'Moscow',
        rating: 4.5,
        pricePerHour: 3000,
        createdAt: now,
        updatedAt: now,
        description: 'Test description',
        bio: 'Test bio',
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.intermediate,
        yearsOfExperience: 5,
        hourlyRate: 3000,
        price: 3000,
        location: 'Test Location',
        imageUrl: 'https://example.com/image.jpg',
        isVerified: true,
        reviewCount: 100,
        contacts: const {
          'phone': '+7 (999) 123-45-67',
          'email': 'test@example.com'
        },
        servicesWithPrices: const {'Service 1': 5000.0, 'Service 2': 10000.0},
      );

      final map = specialist.toMap();

      expect(map['userId'], equals('test_user_id'));
      expect(map['name'], equals('Test Specialist'));
      expect(map['description'], equals('Test description'));
      expect(map['bio'], equals('Test bio'));
      expect(map['category'], equals('photographer'));
      expect(map['experienceLevel'], equals('intermediate'));
      expect(map['yearsOfExperience'], equals(5));
      expect(map['hourlyRate'], equals(3000.0));
      expect(map['price'], equals(3000.0));
      expect(map['location'], equals('Test Location'));
      expect(map['imageUrl'], equals('https://example.com/image.jpg'));
      expect(map['isAvailable'], equals(true));
      expect(map['isVerified'], equals(true));
      expect(map['rating'], equals(4.5));
      expect(map['reviewCount'], equals(100));
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect(map['contacts'], isA<Map<String, String>>());
      expect(map['servicesWithPrices'], isA<Map<String, double>>());
    });

    test('Specialist fromMap should create object from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test_id',
        'userId': 'test_user_id',
        'name': 'Test Specialist',
        'description': 'Test description',
        'bio': 'Test bio',
        'category': 'photographer',
        'experienceLevel': 'intermediate',
        'yearsOfExperience': 5,
        'hourlyRate': 3000.0,
        'price': 3000.0,
        'location': 'Test Location',
        'imageUrl': 'https://example.com/image.jpg',
        'isAvailable': true,
        'isVerified': true,
        'rating': 4.5,
        'reviewCount': 100,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'contacts': {
          'phone': '+7 (999) 123-45-67',
          'email': 'test@example.com'
        },
        'servicesWithPrices': {'Service 1': 5000.0, 'Service 2': 10000.0},
      };

      final specialist = Specialist.fromMap(map);

      expect(specialist.id, equals('test_id'));
      expect(specialist.userId, equals('test_user_id'));
      expect(specialist.name, equals('Test Specialist'));
      expect(specialist.description, equals('Test description'));
      expect(specialist.bio, equals('Test bio'));
      expect(specialist.category, equals(SpecialistCategory.photographer));
      expect(specialist.experienceLevel, equals(ExperienceLevel.intermediate));
      expect(specialist.yearsOfExperience, equals(5));
      expect(specialist.hourlyRate, equals(3000.0));
      expect(specialist.price, equals(3000.0));
      expect(specialist.location, equals('Test Location'));
      expect(specialist.imageUrl, equals('https://example.com/image.jpg'));
      expect(specialist.isAvailable, equals(true));
      expect(specialist.isVerified, equals(true));
      expect(specialist.rating, equals(4.5));
      expect(specialist.reviewCount, equals(100));
      expect(specialist.contacts, isA<Map<String, String>>());
      expect(specialist.servicesWithPrices, isA<Map<String, double>>());
    });

    test('Specialist toMap and fromMap should be consistent', () {
      final now = DateTime.now();
      final originalSpecialist = Specialist(
        id: 'test_id',
        userId: 'test_user_id',
        name: 'Test Specialist',
        specialization: 'Photography',
        city: 'Moscow',
        rating: 4.5,
        pricePerHour: 3000,
        createdAt: now,
        updatedAt: now,
        description: 'Test description',
        bio: 'Test bio',
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.intermediate,
        yearsOfExperience: 5,
        hourlyRate: 3000,
        price: 3000,
        location: 'Test Location',
        imageUrl: 'https://example.com/image.jpg',
        isVerified: true,
        reviewCount: 100,
        contacts: const {
          'phone': '+7 (999) 123-45-67',
          'email': 'test@example.com'
        },
        servicesWithPrices: const {'Service 1': 5000.0, 'Service 2': 10000.0},
      );

      final map = originalSpecialist.toMap();
      final restoredSpecialist = Specialist.fromMap(map);

      expect(restoredSpecialist.id, equals(originalSpecialist.id));
      expect(restoredSpecialist.userId, equals(originalSpecialist.userId));
      expect(restoredSpecialist.name, equals(originalSpecialist.name));
      expect(restoredSpecialist.description,
          equals(originalSpecialist.description));
      expect(restoredSpecialist.bio, equals(originalSpecialist.bio));
      expect(restoredSpecialist.category, equals(originalSpecialist.category));
      expect(restoredSpecialist.experienceLevel,
          equals(originalSpecialist.experienceLevel));
      expect(restoredSpecialist.yearsOfExperience,
          equals(originalSpecialist.yearsOfExperience));
      expect(
          restoredSpecialist.hourlyRate, equals(originalSpecialist.hourlyRate));
      expect(restoredSpecialist.price, equals(originalSpecialist.price));
      expect(restoredSpecialist.location, equals(originalSpecialist.location));
      expect(restoredSpecialist.imageUrl, equals(originalSpecialist.imageUrl));
      expect(restoredSpecialist.isAvailable,
          equals(originalSpecialist.isAvailable));
      expect(
          restoredSpecialist.isVerified, equals(originalSpecialist.isVerified));
      expect(restoredSpecialist.rating, equals(originalSpecialist.rating));
      expect(restoredSpecialist.reviewCount,
          equals(originalSpecialist.reviewCount));
      expect(restoredSpecialist.contacts, equals(originalSpecialist.contacts));
      expect(restoredSpecialist.servicesWithPrices,
          equals(originalSpecialist.servicesWithPrices));
    });

    test('SpecialistCategory enum should have correct display names', () {
      expect(SpecialistCategory.photographer.displayName, equals('Фотограф'));
      expect(SpecialistCategory.videographer.displayName, equals('Видеограф'));
      expect(SpecialistCategory.dj.displayName, equals('DJ'));
      expect(SpecialistCategory.host.displayName, equals('Ведущий'));
      expect(SpecialistCategory.decorator.displayName, equals('Декоратор'));
      expect(SpecialistCategory.musician.displayName, equals('Музыкант'));
      expect(SpecialistCategory.caterer.displayName, equals('Кейтеринг'));
      expect(SpecialistCategory.security.displayName, equals('Охрана'));
      expect(SpecialistCategory.technician.displayName, equals('Техник'));
      expect(SpecialistCategory.other.displayName, equals('Другое'));
    });

    test('ExperienceLevel enum should have correct values', () {
      expect(ExperienceLevel.beginner.name, equals('beginner'));
      expect(ExperienceLevel.intermediate.name, equals('intermediate'));
      expect(ExperienceLevel.advanced.name, equals('advanced'));
      expect(ExperienceLevel.expert.name, equals('expert'));
    });

    test('Specialist should handle null values correctly', () {
      final now = DateTime.now();
      final specialist = Specialist(
        id: 'test_id',
        userId: 'test_user_id',
        name: 'Test Specialist',
        specialization: 'Photography',
        city: 'Moscow',
        rating: 0.0,
        pricePerHour: 0,
        createdAt: now,
        updatedAt: now,
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.beginner,
        yearsOfExperience: 0,
        hourlyRate: 0,
        price: 0,
      );

      final map = specialist.toMap();

      expect(map['description'], isNull);
      expect(map['bio'], isNull);
      expect(map['location'], isNull);
      expect(map['imageUrl'], isNull);
      expect(map['contacts'], isNull);
      expect(map['servicesWithPrices'], isNull);
    });

    test('Specialist should handle empty collections correctly', () {
      final now = DateTime.now();
      final specialist = Specialist(
        id: 'test_id',
        userId: 'test_user_id',
        name: 'Test Specialist',
        specialization: 'Photography',
        city: 'Moscow',
        rating: 0.0,
        pricePerHour: 0,
        createdAt: now,
        updatedAt: now,
        category: SpecialistCategory.photographer,
        experienceLevel: ExperienceLevel.beginner,
        yearsOfExperience: 0,
        hourlyRate: 0,
        price: 0,
        contacts: const {},
        servicesWithPrices: const {},
      );

      final map = specialist.toMap();

      expect(map['contacts'], isA<Map<String, dynamic>>());
      expect(map['servicesWithPrices'], isA<Map<String, dynamic>>());
      expect((map['contacts'] as Map).isEmpty, isTrue);
      expect((map['servicesWithPrices'] as Map).isEmpty, isTrue);
    });
  });
}
