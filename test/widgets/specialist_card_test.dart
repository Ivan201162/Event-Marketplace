import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/widgets/specialist_card.dart';
import 'package:event_marketplace_app/models/specialist.dart';

void main() {
  group('SpecialistCard', () {
    late Specialist testSpecialist;

    setUp(() {
      testSpecialist = Specialist(
        id: 'specialist_1',
        userId: 'user_1',
        name: 'Test Specialist',
        description: 'Test description',
        category: SpecialistCategory.photographer,
        subcategories: ['свадебная фотография', 'портретная съемка'],
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 5,
        hourlyRate: 3000.0,
        minBookingHours: 2.0,
        maxBookingHours: 12.0,
        serviceAreas: ['Москва', 'Санкт-Петербург'],
        languages: ['Русский', 'Английский'],
        equipment: ['Canon EOS R5', 'Canon 24-70mm f/2.8'],
        portfolio: ['https://example.com/portfolio1', 'https://example.com/portfolio2'],
        isAvailable: true,
        isVerified: true,
        rating: 4.8,
        reviewCount: 47,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display specialist information correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Specialist'), findsOneWidget);
      expect(find.text('Фотограф'), findsOneWidget);
      expect(find.text('Продвинутый'), findsOneWidget);
      expect(find.text('5 лет опыта'), findsOneWidget);
      expect(find.text('3000 ₽/час'), findsOneWidget);
      expect(find.text('Доступен'), findsOneWidget);
      expect(find.text('свадебная фотография'), findsOneWidget);
      expect(find.text('портретная съемка'), findsOneWidget);
    });

    testWidgets('should display rating and review count', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(47)'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('should display verification badge for verified specialist', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets('should not display verification badge for unverified specialist', (WidgetTester tester) async {
      // Arrange
      final unverifiedSpecialist = testSpecialist.copyWith(isVerified: false);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: unverifiedSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('✓'), findsNothing);
    });

    testWidgets('should display availability status correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Доступен'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display unavailable status for unavailable specialist', (WidgetTester tester) async {
      // Arrange
      final unavailableSpecialist = testSpecialist.copyWith(isAvailable: false);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: unavailableSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Занят'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SpecialistCard));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should display action buttons when showActions is true', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
                showActions: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Забронировать'), findsOneWidget);
      expect(find.text('Подробнее'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should not display action buttons when showActions is false', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
                showActions: false,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Забронировать'), findsNothing);
      expect(find.text('Подробнее'), findsNothing);
    });

    testWidgets('should display favorite button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should display price range correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('6000 - 36000 ₽'), findsOneWidget);
    });

    testWidgets('should display hourly rate when no min/max booking hours', (WidgetTester tester) async {
      // Arrange
      final specialistWithoutHours = testSpecialist.copyWith(
        minBookingHours: null,
        maxBookingHours: null,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: specialistWithoutHours,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('3000 ₽/час'), findsOneWidget);
    });
  });

  group('CompactSpecialistCard', () {
    late Specialist testSpecialist;

    setUp(() {
      testSpecialist = Specialist(
        id: 'specialist_1',
        userId: 'user_1',
        name: 'Test Specialist',
        description: 'Test description',
        category: SpecialistCategory.photographer,
        subcategories: ['свадебная фотография'],
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 5,
        hourlyRate: 3000.0,
        minBookingHours: 2.0,
        maxBookingHours: 12.0,
        serviceAreas: ['Москва'],
        languages: ['Русский'],
        equipment: ['Canon EOS R5'],
        portfolio: ['https://example.com/portfolio'],
        isAvailable: true,
        isVerified: true,
        rating: 4.8,
        reviewCount: 47,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display compact specialist information', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactSpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Specialist'), findsOneWidget);
      expect(find.text('Фотограф'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('6000 - 36000 ₽'), findsOneWidget);
    });

    testWidgets('should display verification icon for verified specialist', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactSpecialistCard(
                specialist: testSpecialist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should call onTap when compact card is tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactSpecialistCard(
                specialist: testSpecialist,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CompactSpecialistCard));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });
  });
}


