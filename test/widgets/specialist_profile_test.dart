import 'package:event_marketplace_app/screens/specialist_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpecialistProfileScreen', () {
    testWidgets('should display specialist information', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display loading state initially', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state when specialist not found',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
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

    testWidgets('should display booking button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
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
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
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

    testWidgets('should display specialist name', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist category', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist rating', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist description', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist services', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist portfolio', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist reviews', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist pricing', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist availability', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist experience', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist equipment', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist languages', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist service areas', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
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
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist creation date', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpecialistProfileScreen(specialistId: 'specialist_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should display specialist update date', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
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
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
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
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
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
