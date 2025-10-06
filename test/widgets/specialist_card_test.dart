import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/widgets/specialist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpecialistCard', () {
    Specialist? testSpecialist;

    setUp(() {
      testSpecialist = Specialist(
        id: 'specialist_1',
        userId: 'user_1',
        name: 'Test Specialist',
        description: 'Test description',
        bio: 'Test bio',
        category: SpecialistCategory.photographer,
        subcategories: ['свадебная фотография', 'портретная съемка'],
        experienceLevel: ExperienceLevel.advanced,
        yearsOfExperience: 5,
        hourlyRate: 3000,
        price: 3000,
        minBookingHours: 2,
        maxBookingHours: 12,
        serviceAreas: ['Москва', 'Санкт-Петербург'],
        languages: ['Русский', 'Английский'],
        equipment: ['Canon EOS R5', 'Canon 24-70mm f/2.8'],
        portfolio: [
          'https://example.com/portfolio1',
          'https://example.com/portfolio2',
        ],
        isVerified: true,
        rating: 4.8,
        reviewCount: 47,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display specialist information correctly',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist!,
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

    testWidgets('should display rating and review count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist!,
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

    testWidgets('should display verification badge for verified specialist',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist!,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets(
        'should not display verification badge for unverified specialist',
        (tester) async {
      // Arrange
      final unverifiedSpecialist = testSpecialist!.copyWith(isVerified: false);

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

    testWidgets('should display availability status correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist!,
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

    testWidgets('should display unavailable status for unavailable specialist',
        (tester) async {
      // Arrange
      final unavailableSpecialist =
          testSpecialist!.copyWith(isAvailable: false);

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

    testWidgets('should call onTap when card is tapped', (tester) async {
      // Arrange
      var tapped = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist!,
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

    testWidgets('should display favorite button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist!,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should display price range correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpecialistCard(
                specialist: testSpecialist!,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('6000 - 36000 ₽'), findsOneWidget);
    });

    testWidgets('should display hourly rate when no min/max booking hours',
        (tester) async {
      // Arrange
      final specialistWithoutHours = testSpecialist!.copyWith();

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
}
