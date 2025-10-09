import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking System Tests', () {
    testWidgets('Create booking request', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to specialist profile
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      // Find and tap book button
      final bookButton = find.text('Забронировать');
      if (bookButton.evaluate().isNotEmpty) {
        await tester.tap(bookButton);
        await tester.pumpAndSettle();
      }

      // Fill booking form
      final eventTypeField = find.byKey(const Key('event_type_field'));
      if (eventTypeField.evaluate().isNotEmpty) {
        await tester.enterText(eventTypeField, 'Свадьба');
        await tester.pumpAndSettle();
      }

      final dateField = find.byKey(const Key('date_field'));
      if (dateField.evaluate().isNotEmpty) {
        await tester.tap(dateField);
        await tester.pumpAndSettle();

        // Select date from calendar
        final datePicker = find.byType(CalendarDatePicker);
        if (datePicker.evaluate().isNotEmpty) {
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final dateButton = find.text(tomorrow.day.toString());
          if (dateButton.evaluate().isNotEmpty) {
            await tester.tap(dateButton);
            await tester.pumpAndSettle();
          }
        }

        // Confirm date selection
        final confirmButton = find.text('OK');
        if (confirmButton.evaluate().isNotEmpty) {
          await tester.tap(confirmButton);
          await tester.pumpAndSettle();
        }
      }

      final timeField = find.byKey(const Key('time_field'));
      if (timeField.evaluate().isNotEmpty) {
        await tester.tap(timeField);
        await tester.pumpAndSettle();

        // Select time
        final timePicker = find.byType(TimePickerDialog);
        if (timePicker.evaluate().isNotEmpty) {
          final confirmButton = find.text('OK');
          if (confirmButton.evaluate().isNotEmpty) {
            await tester.tap(confirmButton);
            await tester.pumpAndSettle();
          }
        }
      }

      final locationField = find.byKey(const Key('location_field'));
      if (locationField.evaluate().isNotEmpty) {
        await tester.enterText(locationField, 'Москва, Красная площадь');
        await tester.pumpAndSettle();
      }

      final descriptionField = find.byKey(const Key('description_field'));
      if (descriptionField.evaluate().isNotEmpty) {
        await tester.enterText(
          descriptionField,
          'Свадебная церемония на 50 человек',
        );
        await tester.pumpAndSettle();
      }

      final budgetField = find.byKey(const Key('budget_field'));
      if (budgetField.evaluate().isNotEmpty) {
        await tester.enterText(budgetField, '50000');
        await tester.pumpAndSettle();
      }

      // Submit booking
      final submitButton = find.text('Отправить заявку');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
      }

      // Verify booking created
      expect(find.text('Заявка отправлена'), findsOneWidget);
    });

    testWidgets('View booking requests', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to bookings
      final bookingsButton = find.byIcon(Icons.book_online);
      if (bookingsButton.evaluate().isNotEmpty) {
        await tester.tap(bookingsButton);
        await tester.pumpAndSettle();
      }

      // Check booking list
      final bookingCards = find.byType(Card);
      expect(bookingCards, findsWidgets);

      // Tap on a booking
      if (bookingCards.evaluate().isNotEmpty) {
        await tester.tap(bookingCards.first);
        await tester.pumpAndSettle();
      }

      // Verify booking details
      expect(find.text('Детали заявки'), findsOneWidget);
    });

    testWidgets('Accept booking request', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to bookings
      final bookingsButton = find.byIcon(Icons.book_online);
      if (bookingsButton.evaluate().isNotEmpty) {
        await tester.tap(bookingsButton);
        await tester.pumpAndSettle();
      }

      // Find a pending booking
      final pendingBooking = find.text('Ожидает подтверждения');
      if (pendingBooking.evaluate().isNotEmpty) {
        await tester.tap(pendingBooking);
        await tester.pumpAndSettle();
      }

      // Accept booking
      final acceptButton = find.text('Принять');
      if (acceptButton.evaluate().isNotEmpty) {
        await tester.tap(acceptButton);
        await tester.pumpAndSettle();
      }

      // Verify booking accepted
      expect(find.text('Заявка принята'), findsOneWidget);
    });

    testWidgets('Reject booking request', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to bookings
      final bookingsButton = find.byIcon(Icons.book_online);
      if (bookingsButton.evaluate().isNotEmpty) {
        await tester.tap(bookingsButton);
        await tester.pumpAndSettle();
      }

      // Find a pending booking
      final pendingBooking = find.text('Ожидает подтверждения');
      if (pendingBooking.evaluate().isNotEmpty) {
        await tester.tap(pendingBooking);
        await tester.pumpAndSettle();
      }

      // Reject booking
      final rejectButton = find.text('Отклонить');
      if (rejectButton.evaluate().isNotEmpty) {
        await tester.tap(rejectButton);
        await tester.pumpAndSettle();
      }

      // Enter rejection reason
      final reasonField = find.byKey(const Key('rejection_reason_field'));
      if (reasonField.evaluate().isNotEmpty) {
        await tester.enterText(reasonField, 'Не подходит дата');
        await tester.pumpAndSettle();
      }

      // Confirm rejection
      final confirmButton = find.text('Подтвердить');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();
      }

      // Verify booking rejected
      expect(find.text('Заявка отклонена'), findsOneWidget);
    });

    testWidgets('Booking status updates', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to bookings
      final bookingsButton = find.byIcon(Icons.book_online);
      if (bookingsButton.evaluate().isNotEmpty) {
        await tester.tap(bookingsButton);
        await tester.pumpAndSettle();
      }

      // Check different booking statuses
      final statuses = [
        'Ожидает подтверждения',
        'Принята',
        'Отклонена',
        'Завершена',
        'Отменена',
      ];

      for (final status in statuses) {
        final statusWidget = find.text(status);
        if (statusWidget.evaluate().isNotEmpty) {
          expect(statusWidget, findsOneWidget);
        }
      }
    });

    testWidgets('Booking calendar integration', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to specialist profile
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      // Find calendar tab
      final calendarTab = find.text('Календарь');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // Check calendar display
      final calendar = find.byType(CalendarDatePicker);
      expect(calendar, findsOneWidget);

      // Check availability indicators
      final availableDays = find.byIcon(Icons.check_circle);
      expect(availableDays, findsWidgets);

      final busyDays = find.byIcon(Icons.event_busy);
      expect(busyDays, findsWidgets);
    });

    testWidgets('Booking payment flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to accepted booking
      final bookingsButton = find.byIcon(Icons.book_online);
      if (bookingsButton.evaluate().isNotEmpty) {
        await tester.tap(bookingsButton);
        await tester.pumpAndSettle();
      }

      // Find accepted booking
      final acceptedBooking = find.text('Принята');
      if (acceptedBooking.evaluate().isNotEmpty) {
        await tester.tap(acceptedBooking);
        await tester.pumpAndSettle();
      }

      // Find payment button
      final paymentButton = find.text('Оплатить');
      if (paymentButton.evaluate().isNotEmpty) {
        await tester.tap(paymentButton);
        await tester.pumpAndSettle();
      }

      // Check payment options
      final paymentMethods = [
        'Банковская карта',
        'СБП',
        'ЮMoney',
        'Тинькофф',
      ];

      for (final method in paymentMethods) {
        final methodButton = find.text(method);
        if (methodButton.evaluate().isNotEmpty) {
          expect(methodButton, findsOneWidget);
        }
      }
    });
  });
}
