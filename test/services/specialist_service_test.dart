import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/specialist_service.dart';
import 'package:event_marketplace_app/models/specialist.dart';

import 'specialist_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot
])
void main() {
  group('SpecialistService', () {
    late SpecialistService specialistService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      specialistService = SpecialistService();
    });

    group('getSpecialist', () {
      test('should return specialist when found', () async {
        // Arrange
        const specialistId = 'specialist_1';
        final mockDocumentSnapshot = MockDocumentSnapshot();

        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(specialistId)).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.id).thenReturn(specialistId);
        when(mockDocumentSnapshot.data()).thenReturn({
          'userId': 'user_1',
          'name': 'Test Specialist',
          'description': 'Test description',
          'category': 'photographer',
          'subcategories': ['свадебная фотография'],
          'experienceLevel': 'advanced',
          'yearsOfExperience': 5,
          'hourlyRate': 3000.0,
          'minBookingHours': 2.0,
          'maxBookingHours': 12.0,
          'serviceAreas': ['Москва'],
          'languages': ['Русский'],
          'equipment': ['Canon EOS R5'],
          'portfolio': ['https://example.com/portfolio'],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.8,
          'reviewCount': 47,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Act
        final result = await specialistService.getSpecialist(specialistId);

        // Assert
        expect(result, isA<Specialist>());
        expect(result?.id, equals(specialistId));
        expect(result?.name, equals('Test Specialist'));
        expect(result?.category, equals(SpecialistCategory.photographer));
      });

      test('should return null when specialist not found', () async {
        // Arrange
        const specialistId = 'nonexistent_specialist';
        final mockDocumentSnapshot = MockDocumentSnapshot();

        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(specialistId)).thenReturn(mockDocument);
        when(mockDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(false);

        // Act
        final result = await specialistService.getSpecialist(specialistId);

        // Assert
        expect(result, isNull);
      });
    });

    group('getAllSpecialists', () {
      test('should return list of specialists', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.where('isAvailable', isEqualTo: true))
            .thenReturn(mockCollection);
        when(mockCollection.orderBy('rating', descending: true))
            .thenReturn(mockCollection);
        when(mockCollection.limit(50)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.id).thenReturn('specialist_1');
        when(mockQueryDocumentSnapshot.data()).thenReturn({
          'userId': 'user_1',
          'name': 'Test Specialist',
          'description': 'Test description',
          'category': 'photographer',
          'subcategories': ['свадебная фотография'],
          'experienceLevel': 'advanced',
          'yearsOfExperience': 5,
          'hourlyRate': 3000.0,
          'minBookingHours': 2.0,
          'maxBookingHours': 12.0,
          'serviceAreas': ['Москва'],
          'languages': ['Русский'],
          'equipment': ['Canon EOS R5'],
          'portfolio': ['https://example.com/portfolio'],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.8,
          'reviewCount': 47,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Act
        final result = await specialistService.getAllSpecialists();

        // Assert
        expect(result, isA<List<Specialist>>());
        expect(result.length, equals(1));
        expect(result.first.name, equals('Test Specialist'));
      });

      test('should return empty list when no specialists found', () async {
        // Arrange
        final mockQuerySnapshot = MockQuerySnapshot();

        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.where('isAvailable', isEqualTo: true))
            .thenReturn(mockCollection);
        when(mockCollection.orderBy('rating', descending: true))
            .thenReturn(mockCollection);
        when(mockCollection.limit(50)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await specialistService.getAllSpecialists();

        // Assert
        expect(result, isA<List<Specialist>>());
        expect(result.length, equals(0));
      });
    });

    group('searchSpecialists', () {
      test('should return filtered specialists based on category', () async {
        // Arrange
        final filters = SpecialistFilters(
          category: SpecialistCategory.photographer,
          isAvailable: true,
        );
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.where('isAvailable', isEqualTo: true))
            .thenReturn(mockCollection);
        when(mockCollection.where('category', isEqualTo: 'photographer'))
            .thenReturn(mockCollection);
        when(mockCollection.orderBy('rating', descending: true))
            .thenReturn(mockCollection);
        when(mockCollection.limit(50)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.id).thenReturn('specialist_1');
        when(mockQueryDocumentSnapshot.data()).thenReturn({
          'userId': 'user_1',
          'name': 'Test Photographer',
          'description': 'Test description',
          'category': 'photographer',
          'subcategories': ['свадебная фотография'],
          'experienceLevel': 'advanced',
          'yearsOfExperience': 5,
          'hourlyRate': 3000.0,
          'minBookingHours': 2.0,
          'maxBookingHours': 12.0,
          'serviceAreas': ['Москва'],
          'languages': ['Русский'],
          'equipment': ['Canon EOS R5'],
          'portfolio': ['https://example.com/portfolio'],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.8,
          'reviewCount': 47,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Act
        final result = await specialistService.searchSpecialists(filters);

        // Assert
        expect(result, isA<List<Specialist>>());
        expect(result.length, equals(1));
        expect(result.first.category, equals(SpecialistCategory.photographer));
      });

      test('should filter by price range', () async {
        // Arrange
        final filters = SpecialistFilters(
          maxHourlyRate: 2000.0,
          isAvailable: true,
        );
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.where('isAvailable', isEqualTo: true))
            .thenReturn(mockCollection);
        when(mockCollection.where('hourlyRate', isLessThanOrEqualTo: 2000.0))
            .thenReturn(mockCollection);
        when(mockCollection.orderBy('rating', descending: true))
            .thenReturn(mockCollection);
        when(mockCollection.limit(50)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.id).thenReturn('specialist_1');
        when(mockQueryDocumentSnapshot.data()).thenReturn({
          'userId': 'user_1',
          'name': 'Test Specialist',
          'description': 'Test description',
          'category': 'photographer',
          'subcategories': ['свадебная фотография'],
          'experienceLevel': 'advanced',
          'yearsOfExperience': 5,
          'hourlyRate': 1500.0,
          'minBookingHours': 2.0,
          'maxBookingHours': 12.0,
          'serviceAreas': ['Москва'],
          'languages': ['Русский'],
          'equipment': ['Canon EOS R5'],
          'portfolio': ['https://example.com/portfolio'],
          'isAvailable': true,
          'isVerified': true,
          'rating': 4.8,
          'reviewCount': 47,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // Act
        final result = await specialistService.searchSpecialists(filters);

        // Assert
        expect(result, isA<List<Specialist>>());
        expect(result.length, equals(1));
        expect(result.first.hourlyRate, lessThanOrEqualTo(2000.0));
      });
    });

    group('createSpecialist', () {
      test('should create specialist successfully', () async {
        // Arrange
        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(any)).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        final result = await specialistService.createSpecialist(
          userId: 'user_1',
          name: 'Test Specialist',
          category: SpecialistCategory.photographer,
          hourlyRate: 3000.0,
        );

        // Assert
        expect(result, isA<Specialist>());
        expect(result.name, equals('Test Specialist'));
        expect(result.category, equals(SpecialistCategory.photographer));
        expect(result.hourlyRate, equals(3000.0));
        verify(mockCollection.doc(any)).called(1);
        verify(mockDocument.set(any)).called(1);
      });

      test('should handle error when creating specialist', () async {
        // Arrange
        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(any)).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => specialistService.createSpecialist(
            userId: 'user_1',
            name: 'Test Specialist',
            category: SpecialistCategory.photographer,
            hourlyRate: 3000.0,
          ),
          throwsException,
        );
      });
    });

    group('updateSpecialistRating', () {
      test('should update specialist rating successfully', () async {
        // Arrange
        const specialistId = 'specialist_1';
        const newRating = 4.9;
        const newReviewCount = 50;

        when(mockFirestore.collection('specialists'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(specialistId)).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await specialistService.updateSpecialistRating(
            specialistId, newRating, newReviewCount);

        // Assert
        verify(mockCollection.doc(specialistId)).called(1);
        verify(mockDocument.update(any)).called(1);
      });
    });
  });
}
