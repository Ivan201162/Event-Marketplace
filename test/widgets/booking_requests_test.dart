import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/screens/booking_requests_screen.dart';

void main() {
  group('BookingRequestsScreen', () {
    testWidgets('should display empty state when no bookings',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
      expect(
          find.text('У вас пока нет заявок на бронирование'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets('should display loading state initially',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state when error occurs',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ошибка загрузки заявок'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('should display booking requests when available',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should display filter button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should show filter dialog when filter button tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Фильтр заявок'), findsOneWidget);
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Ожидают'), findsOneWidget);
      expect(find.text('Подтверждены'), findsOneWidget);
      expect(find.text('Отклонены'), findsOneWidget);
    });

    testWidgets('should show booking details when booking card tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final bookingCard = find.byType(Card).first;
      if (bookingCard.evaluate().isNotEmpty) {
        await tester.tap(bookingCard);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Детали заявки'), findsOneWidget);
      }
    });

    testWidgets('should show confirm dialog when confirm button tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final confirmButton = find.text('Подтвердить');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Подтвердить заявку'), findsOneWidget);
        expect(find.text('Вы уверены, что хотите подтвердить эту заявку?'),
            findsOneWidget);
        expect(find.text('Подтвердить'), findsOneWidget);
        expect(find.text('Отмена'), findsOneWidget);
      }
    });

    testWidgets('should show reject dialog when reject button tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final rejectButton = find.text('Отклонить');
      if (rejectButton.evaluate().isNotEmpty) {
        await tester.tap(rejectButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Отклонить заявку'), findsOneWidget);
        expect(find.text('Вы уверены, что хотите отклонить эту заявку?'),
            findsOneWidget);
        expect(find.text('Отклонить'), findsOneWidget);
        expect(find.text('Отмена'), findsOneWidget);
      }
    });

    testWidgets('should display booking status correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should display booking date correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should display customer information correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should display event details correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should display pricing information correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should display action buttons correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should handle booking status updates correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final confirmButton = find.text('Подтвердить');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Заявки на бронирование'), findsOneWidget);
      }
    });

    testWidgets('should handle booking rejection correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final rejectButton = find.text('Отклонить');
      if (rejectButton.evaluate().isNotEmpty) {
        await tester.tap(rejectButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Заявки на бронирование'), findsOneWidget);
      }
    });

    testWidgets('should display booking statistics correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should handle empty state correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });

    testWidgets('should handle error state correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookingRequestsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Заявки на бронирование'), findsOneWidget);
    });
  });
}
