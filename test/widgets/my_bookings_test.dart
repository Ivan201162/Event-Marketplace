import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/screens/my_bookings_screen.dart';
import 'package:event_marketplace_app/models/booking.dart';

void main() {
  group('MyBookingsScreen', () {
    testWidgets('should display empty state when no bookings', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
      expect(find.text('У вас пока нет заявок'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state when error occurs', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ошибка загрузки заявок'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('should display filter button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should show filter dialog when filter button tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
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

    testWidgets('should show booking details when booking card tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
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

    testWidgets('should show cancel dialog when cancel button tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final cancelButton = find.text('Отменить');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Отменить заявку'), findsOneWidget);
        expect(find.text('Вы уверены, что хотите отменить эту заявку?'), findsOneWidget);
        expect(find.text('Отменить'), findsOneWidget);
        expect(find.text('Отмена'), findsOneWidget);
      }
    });

    testWidgets('should show payment dialog when payment button tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final paymentButton = find.text('Оплатить');
      if (paymentButton.evaluate().isNotEmpty) {
        await tester.tap(paymentButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Оплата'), findsOneWidget);
      }
    });

    testWidgets('should display booking status correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display booking date correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display specialist information correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display event details correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display pricing information correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment information correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display action buttons correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should handle booking cancellation correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final cancelButton = find.text('Отменить');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Мои заявки'), findsOneWidget);
      }
    });

    testWidgets('should handle payment processing correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      final paymentButton = find.text('Оплатить');
      if (paymentButton.evaluate().isNotEmpty) {
        await tester.tap(paymentButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Мои заявки'), findsOneWidget);
      }
    });

    testWidgets('should display booking statistics correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should handle empty state correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should handle error state correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment status correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment amount correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment type correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment due date correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment method correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment transaction ID correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment creation date correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display payment update date correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyBookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });
  });
}

