import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/firestore_service.dart';
import 'package:event_marketplace_app/models/booking.dart';

import 'firestore_service_test.mocks.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot, QueryDocumentSnapshot])
void main() {
  group('FirestoreService', () {
    late FirestoreService firestoreService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      firestoreService = FirestoreService();
    });

    group('addOrUpdateBooking', () {
      test('should add booking successfully', () async {
        // Arrange
        final booking = Booking(
          id: 'test_booking_1',
          customerId: 'customer_1',
          specialistId: 'specialist_1',
          eventDate: DateTime.now(),
          status: 'pending',
          prepayment: 1000.0,
          totalPrice: 5000.0,
          prepaymentPaid: false,
          paymentStatus: 'pending',
        );

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(booking.id)).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        await firestoreService.addOrUpdateBooking(booking);

        // Assert
        verify(mockCollection.doc(booking.id)).called(1);
        verify(mockDocument.set(any)).called(1);
      });

      test('should handle error when adding booking', () async {
        // Arrange
        final booking = Booking(
          id: 'test_booking_1',
          customerId: 'customer_1',
          specialistId: 'specialist_1',
          eventDate: DateTime.now(),
          status: 'pending',
          prepayment: 1000.0,
          totalPrice: 5000.0,
          prepaymentPaid: false,
          paymentStatus: 'pending',
        );

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(booking.id)).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => firestoreService.addOrUpdateBooking(booking),
          throwsException,
        );
      });
    });

    group('updateBookingStatus', () {
      test('should update booking status successfully', () async {
        // Arrange
        const bookingId = 'test_booking_1';
        const newStatus = 'confirmed';

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(bookingId)).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act
        await firestoreService.updateBookingStatus(bookingId, newStatus);

        // Assert
        verify(mockCollection.doc(bookingId)).called(1);
        verify(mockDocument.update(any)).called(1);
      });

      test('should handle error when updating booking status', () async {
        // Arrange
        const bookingId = 'test_booking_1';
        const newStatus = 'confirmed';

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(bookingId)).thenReturn(mockDocument);
        when(mockDocument.update(any)).thenThrow(Exception('Update error'));

        // Act & Assert
        expect(
          () => firestoreService.updateBookingStatus(bookingId, newStatus),
          throwsException,
        );
      });
    });

    group('getBookingsByCustomer', () {
      test('should return list of bookings for customer', () async {
        // Arrange
        const customerId = 'customer_1';
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.where('customerId', isEqualTo: customerId)).thenReturn(mockCollection);
        when(mockCollection.orderBy('eventDate', descending: true)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.id).thenReturn('booking_1');
        when(mockQueryDocumentSnapshot.data()).thenReturn({
          'customerId': customerId,
          'specialistId': 'specialist_1',
          'eventDate': Timestamp.fromDate(DateTime.now()),
          'status': 'pending',
          'prepayment': 1000.0,
          'totalPrice': 5000.0,
          'prepaymentPaid': false,
          'paymentStatus': 'pending',
        });

        // Act
        final result = await firestoreService.getBookingsByCustomer(customerId);

        // Assert
        expect(result, isA<List<Booking>>());
        expect(result.length, equals(1));
        expect(result.first.customerId, equals(customerId));
      });

      test('should return empty list when no bookings found', () async {
        // Arrange
        const customerId = 'customer_1';
        final mockQuerySnapshot = MockQuerySnapshot();

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.where('customerId', isEqualTo: customerId)).thenReturn(mockCollection);
        when(mockCollection.orderBy('eventDate', descending: true)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([]);

        // Act
        final result = await firestoreService.getBookingsByCustomer(customerId);

        // Assert
        expect(result, isA<List<Booking>>());
        expect(result.length, equals(0));
      });
    });

    group('getBookingsBySpecialist', () {
      test('should return list of bookings for specialist', () async {
        // Arrange
        const specialistId = 'specialist_1';
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.where('specialistId', isEqualTo: specialistId)).thenReturn(mockCollection);
        when(mockCollection.orderBy('eventDate', descending: true)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
        when(mockQueryDocumentSnapshot.id).thenReturn('booking_1');
        when(mockQueryDocumentSnapshot.data()).thenReturn({
          'customerId': 'customer_1',
          'specialistId': specialistId,
          'eventDate': Timestamp.fromDate(DateTime.now()),
          'status': 'pending',
          'prepayment': 1000.0,
          'totalPrice': 5000.0,
          'prepaymentPaid': false,
          'paymentStatus': 'pending',
        });

        // Act
        final result = await firestoreService.getBookingsBySpecialist(specialistId);

        // Assert
        expect(result, isA<List<Booking>>());
        expect(result.length, equals(1));
        expect(result.first.specialistId, equals(specialistId));
      });
    });

    group('addTestBookings', () {
      test('should add test bookings successfully', () async {
        // Arrange
        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(any)).thenReturn(mockDocument);
        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act
        await firestoreService.addTestBookings();

        // Assert
        verify(mockCollection.doc(any)).called(greaterThan(0));
        verify(mockDocument.set(any)).called(greaterThan(0));
      });
    });
  });
}

