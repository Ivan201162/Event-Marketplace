import 'package:flutter_test/flutter_test.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/models/event.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/specialist.dart';

void main() {
  group('Models Tests', () {
    group('AppUser', () {
      test('should create AppUser with required fields', () {
        final user = AppUser(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );

        expect(user.id, equals('user123'));
        expect(user.displayName, equals('Test User'));
        expect(user.email, equals('test@example.com'));
        expect(user.role, equals(UserRole.customer));
      });

      // Note: AppUser.fromMap method doesn't exist in the current model

      test('should convert AppUser to map', () {
        final user = AppUser(
          id: 'user123',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );

        final map = user.toMap();

        expect(map['id'], equals('user123'));
        expect(map['displayName'], equals('Test User'));
        expect(map['email'], equals('test@example.com'));
        expect(map['role'], equals('customer'));
      });
    });

    group('Event', () {
      test('should create Event with required fields', () {
        final event = Event(
          id: 'event123',
          title: 'Test Event',
          description: 'Test Description',
          date: DateTime.now(),
          location: 'Test Location',
          organizerId: 'organizer123',
          organizerName: 'Test Organizer',
          category: EventCategory.wedding,
          status: EventStatus.active,
          price: 100.0,
          maxParticipants: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(event.id, equals('event123'));
        expect(event.title, equals('Test Event'));
        expect(event.description, equals('Test Description'));
        expect(event.organizerId, equals('organizer123'));
        expect(event.category, equals(EventCategory.wedding));
        expect(event.price, equals(100.0));
      });
    });

    group('Booking', () {
      test('should create Booking with required fields', () {
        final booking = Booking(
          id: 'booking123',
          eventId: 'event123',
          eventTitle: 'Test Event',
          userId: 'user123',
          userName: 'Test User',
          status: BookingStatus.pending,
          bookingDate: DateTime.now(),
          eventDate: DateTime.now(),
          participantsCount: 2,
          totalPrice: 200.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(booking.id, equals('booking123'));
        expect(booking.eventId, equals('event123'));
        expect(booking.userId, equals('user123'));
        expect(booking.status, equals(BookingStatus.pending));
        expect(booking.participantsCount, equals(2));
        expect(booking.totalPrice, equals(200.0));
      });
    });

    group('Specialist', () {
      test('should create Specialist with required fields', () {
        final specialist = Specialist(
          id: 'specialist123',
          userId: 'user123',
          name: 'Test Specialist',
          category: SpecialistCategory.host,
          experienceLevel: ExperienceLevel.intermediate,
          yearsOfExperience: 3,
          hourlyRate: 50.0,
          price: 150.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(specialist.id, equals('specialist123'));
        expect(specialist.name, equals('Test Specialist'));
        expect(specialist.category, equals(SpecialistCategory.host));
        expect(specialist.price, equals(150.0));
        expect(specialist.hourlyRate, equals(50.0));
        expect(specialist.yearsOfExperience, equals(3));
      });
    });
  });
}
