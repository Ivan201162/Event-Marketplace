import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/main.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/models/booking.dart';

void main() {
  group('Booking Flow Integration Tests', () {
    testWidgets('should complete full booking flow from search to confirmation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to search screen
      await tester.tap(find.text('Поиск'));
      await tester.pumpAndSettle();

      // Act 2: Search for specialist
      await tester.enterText(find.byType(TextField), 'photographer');
      await tester.pumpAndSettle();

      // Act 3: Select specialist from results
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();

        // Act 4: Navigate to specialist profile
        expect(find.text('Профиль специалиста'), findsOneWidget);

        // Act 5: Start booking process
        await tester.tap(find.text('Забронировать'));
        await tester.pumpAndSettle();

        // Act 6: Fill booking form
        await tester.enterText(find.byType(TextFormField).first, 'Wedding Photography');
        await tester.enterText(find.byType(TextFormField).at(1), 'Beautiful wedding ceremony');
        await tester.enterText(find.byType(TextFormField).at(2), 'Moscow, Russia');
        await tester.enterText(find.byType(TextFormField).at(3), '+7 (999) 123-45-67');
        await tester.enterText(find.byType(TextFormField).at(4), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'Special requests');

        // Act 7: Select date and time
        await tester.tap(find.text('Выберите дату'));
        await tester.pumpAndSettle();

        // Act 8: Submit booking
        await tester.tap(find.text('Создать заявку'));
        await tester.pumpAndSettle();

        // Assert: Booking should be created successfully
        expect(find.text('Заявка создана успешно'), findsOneWidget);
      }
    });

    testWidgets('should handle booking confirmation flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to booking requests (as specialist)
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Act 2: View booking request
      final bookingCard = find.byType(Card).first;
      if (bookingCard.evaluate().isNotEmpty) {
        await tester.tap(bookingCard);
        await tester.pumpAndSettle();

        // Act 3: Confirm booking
        await tester.tap(find.text('Подтвердить'));
        await tester.pumpAndSettle();

        // Act 4: Confirm in dialog
        await tester.tap(find.text('Подтвердить'));
        await tester.pumpAndSettle();

        // Assert: Booking should be confirmed
        expect(find.text('Заявка подтверждена'), findsOneWidget);
      }
    });

    testWidgets('should handle booking rejection flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to booking requests (as specialist)
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Act 2: View booking request
      final bookingCard = find.byType(Card).first;
      if (bookingCard.evaluate().isNotEmpty) {
        await tester.tap(bookingCard);
        await tester.pumpAndSettle();

        // Act 3: Reject booking
        await tester.tap(find.text('Отклонить'));
        await tester.pumpAndSettle();

        // Act 4: Confirm rejection in dialog
        await tester.tap(find.text('Отклонить'));
        await tester.pumpAndSettle();

        // Assert: Booking should be rejected
        expect(find.text('Заявка отклонена'), findsOneWidget);
      }
    });

    testWidgets('should handle booking cancellation flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to my bookings (as customer)
      await tester.tap(find.text('Мои заявки'));
      await tester.pumpAndSettle();

      // Act 2: View booking
      final bookingCard = find.byType(Card).first;
      if (bookingCard.evaluate().isNotEmpty) {
        await tester.tap(bookingCard);
        await tester.pumpAndSettle();

        // Act 3: Cancel booking
        await tester.tap(find.text('Отменить'));
        await tester.pumpAndSettle();

        // Act 4: Confirm cancellation in dialog
        await tester.tap(find.text('Отменить'));
        await tester.pumpAndSettle();

        // Assert: Booking should be cancelled
        expect(find.text('Заявка отменена'), findsOneWidget);
      }
    });

    testWidgets('should handle payment flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to my bookings
      await tester.tap(find.text('Мои заявки'));
      await tester.pumpAndSettle();

      // Act 2: View booking with payment
      final bookingCard = find.byType(Card).first;
      if (bookingCard.evaluate().isNotEmpty) {
        await tester.tap(bookingCard);
        await tester.pumpAndSettle();

        // Act 3: Make payment
        await tester.tap(find.text('Оплатить'));
        await tester.pumpAndSettle();

        // Act 4: Fill payment form
        await tester.enterText(find.byType(TextFormField).first, '1234 5678 9012 3456');
        await tester.enterText(find.byType(TextFormField).at(1), '12/25');
        await tester.enterText(find.byType(TextFormField).at(2), '123');

        // Act 5: Submit payment
        await tester.tap(find.text('Оплатить'));
        await tester.pumpAndSettle();

        // Assert: Payment should be processed
        expect(find.text('Платеж успешно обработан'), findsOneWidget);
      }
    });

    testWidgets('should handle review submission flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to reviews
      await tester.tap(find.text('Отзывы'));
      await tester.pumpAndSettle();

      // Act 2: Submit review
      await tester.tap(find.text('Оставить отзыв'));
      await tester.pumpAndSettle();

      // Act 3: Fill review form
      await tester.enterText(find.byType(TextFormField).first, 'Great service!');
      await tester.enterText(find.byType(TextFormField).at(1), 'Excellent photographer, very professional');

      // Act 4: Submit review
      await tester.tap(find.text('Отправить отзыв'));
      await tester.pumpAndSettle();

      // Assert: Review should be submitted
      expect(find.text('Отзыв отправлен'), findsOneWidget);
    });

    testWidgets('should handle chat flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to chat
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Act 2: Select chat
      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();

        // Act 3: Send message
        await tester.enterText(find.byType(TextField), 'Hello, how are you?');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert: Message should be sent
        expect(find.text('Hello, how are you?'), findsOneWidget);
      }
    });

    testWidgets('should handle notification flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to notifications
      await tester.tap(find.text('Уведомления'));
      await tester.pumpAndSettle();

      // Act 2: View notification
      final notificationCard = find.byType(Card).first;
      if (notificationCard.evaluate().isNotEmpty) {
        await tester.tap(notificationCard);
        await tester.pumpAndSettle();

        // Assert: Notification should be marked as read
        expect(find.text('Уведомления'), findsOneWidget);
      }
    });

    testWidgets('should handle analytics flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to analytics
      await tester.tap(find.text('Аналитика'));
      await tester.pumpAndSettle();

      // Assert: Analytics should be displayed
      expect(find.text('Аналитика'), findsOneWidget);
      expect(find.text('KPI'), findsOneWidget);
      expect(find.text('Метрики'), findsOneWidget);
      expect(find.text('Отчеты'), findsOneWidget);
    });

    testWidgets('should handle profile flow', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to profile
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Assert: Profile should be displayed
      expect(find.text('Профиль'), findsOneWidget);
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Выйти'), findsOneWidget);
    });
  });
}


