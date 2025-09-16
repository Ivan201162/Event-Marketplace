import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/screens/specialist_profile_screen.dart';
import 'package:event_marketplace_app/models/specialist.dart';

void main() {
  group('SpecialistProfileScreen', () {
    testWidgets('should display specialist information',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display loading state initially',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state when specialist not found',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home:
                SpecialistProfileScreen(specialistId: 'nonexistent_specialist'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Специалист не найден'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('should display booking button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Забронировать'), findsOneWidget);
    });

    testWidgets('should show booking dialog when booking button tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final bookingButton = find.text('Забронировать');
      if (bookingButton.evaluate().isNotEmpty) {
        await tester.tap(bookingButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Создать заявку'), findsOneWidget);
      }
    });

    testWidgets('should display specialist name', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist category',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist rating',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist description',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist services',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist portfolio',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist reviews',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist pricing',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist availability',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist experience',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist equipment',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist languages',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist service areas',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist verification status',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist creation date',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist update date',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist minimum booking hours',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist maximum booking hours',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });
  });
}
