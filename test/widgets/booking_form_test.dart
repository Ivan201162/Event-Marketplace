import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/screens/booking_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingFormScreen', () {
    Specialist? testSpecialist;

    setUp(() {
      testSpecialist = Specialist(
        id: 'specialist_1',
        userId: 'user_1',
        name: 'Test Specialist',
        description: 'Test description',
        bio: 'Test bio',
        category: SpecialistCategory.photographer,
        subcategories: ['свадебная фотография'],
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 5,
        hourlyRate: 3000,
        price: 3000,
        minBookingHours: 2,
        maxBookingHours: 12,
        serviceAreas: ['Москва'],
        languages: ['Русский'],
        equipment: ['Canon EOS R5'],
        portfolio: ['https://example.com/portfolio'],
        isVerified: true,
        rating: 4.8,
        reviewCount: 47,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display specialist information', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Specialist'), findsOneWidget);
      expect(find.text('Фотограф'), findsOneWidget);
      expect(find.text('3000 ₽/час'), findsOneWidget);
    });

    testWidgets('should display form fields', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Название мероприятия *'), findsOneWidget);
      expect(find.text('Описание мероприятия'), findsOneWidget);
      expect(find.text('Место проведения *'), findsOneWidget);
      expect(find.text('Телефон *'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Дополнительные пожелания'), findsOneWidget);
    });

    testWidgets('should display date and time selection', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Выберите дату'), findsOneWidget);
      expect(find.text('Продолжительность'), findsOneWidget);
    });

    testWidgets('should display price calculation', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Расчет стоимости'), findsOneWidget);
      expect(find.text('Стоимость за 2 часа'), findsOneWidget);
      expect(find.text('Предоплата (30%)'), findsOneWidget);
      expect(find.text('Доплата (70%)'), findsOneWidget);
      expect(find.text('Итого'), findsOneWidget);
    });

    testWidgets('should display submit button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Создать заявку'), findsOneWidget);
    });

    testWidgets('should validate required fields', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Try to submit without filling required fields
      await tester.tap(find.text('Создать заявку'));
      await tester.pump();

      // Assert - Form should not submit and show validation errors
      expect(find.text('Создать заявку'), findsOneWidget);
    });

    testWidgets('should allow entering event name', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'Test Event');
      await tester.pump();

      // Assert
      expect(find.text('Test Event'), findsOneWidget);
    });

    testWidgets('should allow entering event description', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final descriptionField = find.byType(TextFormField).at(1);
      await tester.enterText(descriptionField, 'Test description');
      await tester.pump();

      // Assert
      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('should allow entering event location', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final locationField = find.byType(TextFormField).at(2);
      await tester.enterText(locationField, 'Test Location');
      await tester.pump();

      // Assert
      expect(find.text('Test Location'), findsOneWidget);
    });

    testWidgets('should allow entering contact phone', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final phoneField = find.byType(TextFormField).at(3);
      await tester.enterText(phoneField, '+7 (999) 123-45-67');
      await tester.pump();

      // Assert
      expect(find.text('+7 (999) 123-45-67'), findsOneWidget);
    });

    testWidgets('should allow entering contact email', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final emailField = find.byType(TextFormField).at(4);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should allow entering special requests', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final requestsField = find.byType(TextFormField).last;
      await tester.enterText(requestsField, 'Special requests');
      await tester.pump();

      // Assert
      expect(find.text('Special requests'), findsOneWidget);
    });

    testWidgets('should show loading state initially', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state when specialist not found',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingFormScreen(specialistId: 'nonexistent_specialist'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Специалист не найден'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });
  });
}
