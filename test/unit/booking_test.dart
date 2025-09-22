import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/event.dart';
import 'package:event_marketplace_app/models/user.dart' as app_user;

import 'booking_test.mocks.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot, QueryDocumentSnapshot])
void main() {
  group('BookingService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocRef;
    late MockDocumentSnapshot mockDocSnapshot;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockQueryDocumentSnapshot mockQueryDocSnapshot;
    late BookingService bookingService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocRef = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();
      mockQuerySnapshot = MockQuerySnapshot();
      mockQueryDocSnapshot = MockQueryDocumentSnapshot();

      bookingService = BookingService();
    });

    group('Создание бронирования', () {
      test('успешное создание бронирования', () async {
        // Arrange
        final event = Event(
          id: 'event123',
          title: 'Test Event',
          description: 'Test Description',
          date: DateTime.now().add(Duration(days: 1)),
          location: 'Test Location',
          price: 100.0,
          organizerId: 'organizer123',
          category: 'entertainment',
          maxParticipants: 50,
          currentParticipants: 0,
          status: EventStatus.active,
          createdAt: DateTime.now(),
        );

        final customer = app_user.User(
          id: 'customer123',
          email: 'customer@example.com',
          displayName: 'Customer',
          role: app_user.UserRole.customer,
          createdAt: DateTime.now(),
        );

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);
        when(mockDocRef.id).thenReturn('booking123');
        when(mockDocRef.set(any)).thenAnswer((_) async {});

        // Act
        final result = await bookingService.createBooking(
          event: event,
          customer: customer,
          notes: 'Test booking',
        );

        // Assert
        expect(result, isA<Booking>());
        expect(result.eventId, equals(event.id));
        expect(result.customerId, equals(customer.id));
        expect(result.status, equals(BookingStatus.pending));
        verify(mockCollection.add(any)).called(1);
        verify(mockDocRef.set(any)).called(1);
      });

      test('ошибка создания бронирования для неактивного события', () async {
        // Arrange
        final event = Event(
          id: 'event123',
          title: 'Test Event',
          description: 'Test Description',
          date: DateTime.now().add(Duration(days: 1)),
          location: 'Test Location',
          price: 100.0,
          organizerId: 'organizer123',
          category: 'entertainment',
          maxParticipants: 50,
          currentParticipants: 0,
          status: EventStatus.cancelled, // Неактивное событие
          createdAt: DateTime.now(),
        );

        final customer = app_user.User(
          id: 'customer123',
          email: 'customer@example.com',
          displayName: 'Customer',
          role: app_user.UserRole.customer,
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => bookingService.createBooking(
            event: event,
            customer: customer,
            notes: 'Test booking',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('ошибка создания бронирования для заполненного события', () async {
        // Arrange
        final event = Event(
          id: 'event123',
          title: 'Test Event',
          description: 'Test Description',
          date: DateTime.now().add(Duration(days: 1)),
          location: 'Test Location',
          price: 100.0,
          organizerId: 'organizer123',
          category: 'entertainment',
          maxParticipants: 50,
          currentParticipants: 50, // Событие заполнено
          status: EventStatus.active,
          createdAt: DateTime.now(),
        );

        final customer = app_user.User(
          id: 'customer123',
          email: 'customer@example.com',
          displayName: 'Customer',
          role: app_user.UserRole.customer,
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => bookingService.createBooking(
            event: event,
            customer: customer,
            notes: 'Test booking',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Обновление статуса бронирования', () {
      test('успешное обновление статуса на подтверждено', () async {
        // Arrange
        const bookingId = 'booking123';
        const newStatus = BookingStatus.confirmed;

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(bookingId)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act
        await bookingService.updateBookingStatus(
          bookingId: bookingId,
          status: newStatus,
        );

        // Assert
        verify(mockDocRef.update(any)).called(1);
      });

      test('ошибка обновления несуществующего бронирования', () async {
        // Arrange
        const bookingId = 'nonexistent123';
        const newStatus = BookingStatus.confirmed;

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(bookingId)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenThrow(FirebaseException(
          plugin: 'firestore',
          code: 'not-found',
          message: 'Document not found',
        ));

        // Act & Assert
        expect(
          () => bookingService.updateBookingStatus(
            bookingId: bookingId,
            status: newStatus,
          ),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('Получение бронирований', () {
      test('получение бронирований пользователя', () async {
        // Arrange
        const userId = 'user123';

        final bookingData = {
          'id': 'booking123',
          'eventId': 'event123',
          'customerId': userId,
          'status': 'pending',
          'notes': 'Test booking',
          'createdAt': DateTime.now().toIso8601String(),
        };

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.where('customerId', isEqualTo: userId))
            .thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true))
            .thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        when(mockQueryDocSnapshot.data()).thenReturn(bookingData);
        when(mockQueryDocSnapshot.id).thenReturn('booking123');

        // Act
        final result = await bookingService.getUserBookings(userId);

        // Assert
        expect(result, isA<List<Booking>>());
        expect(result.length, equals(1));
        expect(result.first.id, equals('booking123'));
        expect(result.first.customerId, equals(userId));
      });

      test('получение бронирований события', () async {
        // Arrange
        const eventId = 'event123';

        final bookingData = {
          'id': 'booking123',
          'eventId': eventId,
          'customerId': 'customer123',
          'status': 'confirmed',
          'notes': 'Test booking',
          'createdAt': DateTime.now().toIso8601String(),
        };

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.where('eventId', isEqualTo: eventId))
            .thenReturn(mockCollection);
        when(mockCollection.orderBy('createdAt', descending: true))
            .thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        when(mockQueryDocSnapshot.data()).thenReturn(bookingData);
        when(mockQueryDocSnapshot.id).thenReturn('booking123');

        // Act
        final result = await bookingService.getEventBookings(eventId);

        // Assert
        expect(result, isA<List<Booking>>());
        expect(result.length, equals(1));
        expect(result.first.id, equals('booking123'));
        expect(result.first.eventId, equals(eventId));
      });
    });

    group('Отмена бронирования', () {
      test('успешная отмена бронирования', () async {
        // Arrange
        const bookingId = 'booking123';

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(bookingId)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenAnswer((_) async {});

        // Act
        await bookingService.cancelBooking(bookingId);

        // Assert
        verify(mockDocRef.update(any)).called(1);
      });

      test('ошибка отмены несуществующего бронирования', () async {
        // Arrange
        const bookingId = 'nonexistent123';

        when(mockFirestore.collection('bookings')).thenReturn(mockCollection);
        when(mockCollection.doc(bookingId)).thenReturn(mockDocRef);
        when(mockDocRef.update(any)).thenThrow(FirebaseException(
          plugin: 'firestore',
          code: 'not-found',
          message: 'Document not found',
        ));

        // Act & Assert
        expect(
          () => bookingService.cancelBooking(bookingId),
          throwsA(isA<FirebaseException>()),
        );
      });
    });
  });
}
