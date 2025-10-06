import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// import 'package:patrol/patrol.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Flow Integration Tests', () {
    testWidgets('Complete booking flow: search → select → book → pay → confirm',
        (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Login as customer
      await _loginAsCustomer(tester);

      // Step 2: Search for photographer
      await _searchForPhotographer(tester);

      // Step 3: Select specialist
      await _selectSpecialist(tester);

      // Step 4: Create booking
      await _createBooking(tester);

      // Step 5: Process payment
      await _processPayment(tester);

      // Step 6: Confirm booking
      await _confirmBooking(tester);

      // Step 7: Verify booking in list
      await _verifyBookingInList(tester);
    });

    testWidgets('Booking modification flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login and create initial booking
      await _loginAsCustomer(tester);
      await _searchForPhotographer(tester);
      await _selectSpecialist(tester);
      await _createBooking(tester);
      await _processPayment(tester);

      // Modify booking
      await _modifyBooking(tester);

      // Verify modification
      await _verifyBookingModification(tester);
    });

    testWidgets('Booking cancellation flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login and create initial booking
      await _loginAsCustomer(tester);
      await _searchForPhotographer(tester);
      await _selectSpecialist(tester);
      await _createBooking(tester);
      await _processPayment(tester);

      // Cancel booking
      await _cancelBooking(tester);

      // Verify cancellation
      await _verifyBookingCancellation(tester);
    });

    testWidgets('Specialist booking management flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login as specialist
      await _loginAsSpecialist(tester);

      // View incoming bookings
      await _viewIncomingBookings(tester);

      // Accept booking
      await _acceptBooking(tester);

      // Update booking status
      await _updateBookingStatus(tester);

      // Complete booking
      await _completeBooking(tester);
    });

    testWidgets('Payment failure and retry flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login and create booking
      await _loginAsCustomer(tester);
      await _searchForPhotographer(tester);
      await _selectSpecialist(tester);
      await _createBooking(tester);

      // Simulate payment failure
      await _simulatePaymentFailure(tester);

      // Retry payment
      await _retryPayment(tester);

      // Verify successful payment
      await _verifySuccessfulPayment(tester);
    });

    testWidgets('Booking conflict resolution flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login as customer
      await _loginAsCustomer(tester);

      // Try to book conflicting time slot
      await _attemptConflictingBooking(tester);

      // Handle conflict
      await _handleBookingConflict(tester);

      // Select alternative time
      await _selectAlternativeTime(tester);

      // Complete booking with new time
      await _completeBookingWithNewTime(tester);
    });
  });
}

// Helper functions for booking flow tests

Future<void> _loginAsCustomer(WidgetTester tester) async {
  // Navigate to login
  await tester.tap(find.text('Войти'));
  await tester.pumpAndSettle();

  // Enter credentials
  await tester.enterText(
    find.byKey(const Key('email_field')),
    'customer@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('password_field')),
    'password123',
  );

  // Submit login
  await tester.tap(find.text('Войти'));
  await tester.pumpAndSettle();

  // Verify login success
  expect(find.text('Добро пожаловать!'), findsOneWidget);
}

Future<void> _loginAsSpecialist(WidgetTester tester) async {
  // Navigate to login
  await tester.tap(find.text('Войти'));
  await tester.pumpAndSettle();

  // Enter specialist credentials
  await tester.enterText(
    find.byKey(const Key('email_field')),
    'specialist@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('password_field')),
    'password123',
  );

  // Submit login
  await tester.tap(find.text('Войти'));
  await tester.pumpAndSettle();

  // Verify specialist login
  expect(find.text('Панель специалиста'), findsOneWidget);
}

Future<void> _searchForPhotographer(WidgetTester tester) async {
  // Navigate to search
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // Enter search query
  await tester.enterText(find.byType(TextField), 'photographer');
  await tester.pumpAndSettle();

  // Apply filters
  await tester.tap(find.byIcon(Icons.filter_list));
  await tester.pumpAndSettle();

  // Set price range
  await tester.drag(find.byType(Slider), const Offset(50, 0));
  await tester.pumpAndSettle();

  // Set minimum rating
  await tester.tap(find.text('4+ звезд'));
  await tester.pumpAndSettle();

  // Apply filters
  await tester.tap(find.text('Применить'));
  await tester.pumpAndSettle();

  // Verify search results
  expect(find.byType(Card), findsWidgets);
  expect(find.text('photographer'), findsWidgets);
}

Future<void> _selectSpecialist(WidgetTester tester) async {
  // Tap on first specialist card
  final specialistCard = find.byType(Card).first;
  await tester.tap(specialistCard);
  await tester.pumpAndSettle();

  // Verify specialist profile
  expect(find.text('Профиль специалиста'), findsOneWidget);
  expect(find.text('Забронировать'), findsOneWidget);

  // Check availability
  expect(find.text('Доступен'), findsOneWidget);
}

Future<void> _createBooking(WidgetTester tester) async {
  // Tap book button
  await tester.tap(find.text('Забронировать'));
  await tester.pumpAndSettle();

  // Select date
  await tester.tap(find.text('Выберите дату'));
  await tester.pumpAndSettle();

  // Select tomorrow's date
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final dateButton = find.text('${tomorrow.day}');
  await tester.tap(dateButton);
  await tester.pumpAndSettle();

  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  // Select time
  await tester.tap(find.text('Выберите время'));
  await tester.pumpAndSettle();

  // Select 10:00 AM
  await tester.tap(find.text('10:00'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  // Set duration
  await tester.drag(find.byType(Slider), const Offset(100, 0)); // 4 hours
  await tester.pumpAndSettle();

  // Select service
  await tester.tap(find.text('Выберите услугу'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Wedding Photography'));
  await tester.pumpAndSettle();

  // Add notes
  await tester.enterText(
    find.byKey(const Key('notes_field')),
    'Please bring extra lighting equipment for indoor ceremony',
  );
  await tester.pumpAndSettle();

  // Verify total price
  expect(find.text('Итого: 20 000 ₽'), findsOneWidget); // 4 hours * 5000

  // Submit booking
  await tester.tap(find.text('Забронировать'));
  await tester.pumpAndSettle();

  // Verify booking creation
  expect(find.text('Бронирование создано!'), findsOneWidget);
}

Future<void> _processPayment(WidgetTester tester) async {
  // Navigate to payment
  await tester.tap(find.text('Оплатить'));
  await tester.pumpAndSettle();

  // Select payment method
  await tester.tap(find.text('Банковская карта'));
  await tester.pumpAndSettle();

  // Fill card details
  await tester.enterText(
    find.byKey(const Key('card_number_field')),
    '4111111111111111',
  );
  await tester.enterText(find.byKey(const Key('expiry_field')), '12/25');
  await tester.enterText(find.byKey(const Key('cvv_field')), '123');
  await tester.enterText(
    find.byKey(const Key('cardholder_field')),
    'Test User',
  );
  await tester.pumpAndSettle();

  // Process payment
  await tester.tap(find.text('Оплатить'));
  await tester.pumpAndSettle();

  // Verify payment success
  expect(find.text('Оплата успешно проведена!'), findsOneWidget);
}

Future<void> _confirmBooking(WidgetTester tester) async {
  // Confirm booking details
  await tester.tap(find.text('Подтвердить бронирование'));
  await tester.pumpAndSettle();

  // Verify confirmation
  expect(find.text('Бронирование подтверждено!'), findsOneWidget);
  expect(find.text('Ожидает подтверждения специалиста'), findsOneWidget);
}

Future<void> _verifyBookingInList(WidgetTester tester) async {
  // Navigate to bookings
  await tester.tap(find.byIcon(Icons.calendar_today));
  await tester.pumpAndSettle();

  // Verify booking in list
  expect(find.text('Мои заказы'), findsOneWidget);
  expect(find.text('Wedding Photography'), findsOneWidget);
  expect(find.text('Ожидает подтверждения'), findsOneWidget);
}

Future<void> _modifyBooking(WidgetTester tester) async {
  // Navigate to bookings
  await tester.tap(find.byIcon(Icons.calendar_today));
  await tester.pumpAndSettle();

  // Tap on booking
  final bookingCard = find.byType(Card).first;
  await tester.tap(bookingCard);
  await tester.pumpAndSettle();

  // Tap modify button
  await tester.tap(find.text('Изменить'));
  await tester.pumpAndSettle();

  // Change duration
  await tester.drag(find.byType(Slider), const Offset(-50, 0)); // 3 hours
  await tester.pumpAndSettle();

  // Update notes
  await tester.enterText(
    find.byKey(const Key('notes_field')),
    'Updated: Please bring extra lighting and backup camera',
  );
  await tester.pumpAndSettle();

  // Save changes
  await tester.tap(find.text('Сохранить изменения'));
  await tester.pumpAndSettle();

  // Verify modification
  expect(find.text('Бронирование изменено!'), findsOneWidget);
}

Future<void> _verifyBookingModification(WidgetTester tester) async {
  // Navigate back to booking details
  await tester.tap(find.byType(Card).first);
  await tester.pumpAndSettle();

  // Verify updated details
  expect(find.text('3 часа'), findsOneWidget);
  expect(
    find.text('Updated: Please bring extra lighting and backup camera'),
    findsOneWidget,
  );
}

Future<void> _cancelBooking(WidgetTester tester) async {
  // Navigate to bookings
  await tester.tap(find.byIcon(Icons.calendar_today));
  await tester.pumpAndSettle();

  // Tap on booking
  final bookingCard = find.byType(Card).first;
  await tester.tap(bookingCard);
  await tester.pumpAndSettle();

  // Tap cancel button
  await tester.tap(find.text('Отменить'));
  await tester.pumpAndSettle();

  // Select cancellation reason
  await tester.tap(find.text('Изменение планов'));
  await tester.pumpAndSettle();

  // Confirm cancellation
  await tester.tap(find.text('Да, отменить'));
  await tester.pumpAndSettle();

  // Verify cancellation
  expect(find.text('Бронирование отменено'), findsOneWidget);
}

Future<void> _verifyBookingCancellation(WidgetTester tester) async {
  // Navigate to bookings
  await tester.tap(find.byIcon(Icons.calendar_today));
  await tester.pumpAndSettle();

  // Verify cancelled booking
  expect(find.text('Отменено'), findsOneWidget);
  expect(find.text('Изменение планов'), findsOneWidget);
}

Future<void> _viewIncomingBookings(WidgetTester tester) async {
  // Navigate to specialist bookings
  await tester.tap(find.byIcon(Icons.calendar_today));
  await tester.pumpAndSettle();

  // Verify incoming bookings
  expect(find.text('Входящие заказы'), findsOneWidget);
  expect(find.byType(Card), findsWidgets);
}

Future<void> _acceptBooking(WidgetTester tester) async {
  // Tap on incoming booking
  final bookingCard = find.byType(Card).first;
  await tester.tap(bookingCard);
  await tester.pumpAndSettle();

  // Accept booking
  await tester.tap(find.text('Принять'));
  await tester.pumpAndSettle();

  // Verify acceptance
  expect(find.text('Заказ принят!'), findsOneWidget);
}

Future<void> _updateBookingStatus(WidgetTester tester) async {
  // Navigate to active bookings
  await tester.tap(find.text('Активные заказы'));
  await tester.pumpAndSettle();

  // Tap on active booking
  final bookingCard = find.byType(Card).first;
  await tester.tap(bookingCard);
  await tester.pumpAndSettle();

  // Update status to "In Progress"
  await tester.tap(find.text('В работе'));
  await tester.pumpAndSettle();

  // Verify status update
  expect(find.text('Статус обновлен'), findsOneWidget);
}

Future<void> _completeBooking(WidgetTester tester) async {
  // Navigate to active bookings
  await tester.tap(find.text('Активные заказы'));
  await tester.pumpAndSettle();

  // Tap on active booking
  final bookingCard = find.byType(Card).first;
  await tester.tap(bookingCard);
  await tester.pumpAndSettle();

  // Mark as completed
  await tester.tap(find.text('Завершить'));
  await tester.pumpAndSettle();

  // Add completion notes
  await tester.enterText(
    find.byKey(const Key('completion_notes_field')),
    'All photos delivered successfully. Client was very satisfied.',
  );
  await tester.pumpAndSettle();

  // Confirm completion
  await tester.tap(find.text('Подтвердить завершение'));
  await tester.pumpAndSettle();

  // Verify completion
  expect(find.text('Заказ завершен!'), findsOneWidget);
}

Future<void> _simulatePaymentFailure(WidgetTester tester) async {
  // Navigate to payment
  await tester.tap(find.text('Оплатить'));
  await tester.pumpAndSettle();

  // Select payment method
  await tester.tap(find.text('Банковская карта'));
  await tester.pumpAndSettle();

  // Fill invalid card details
  await tester.enterText(
    find.byKey(const Key('card_number_field')),
    '4000000000000002',
  ); // Declined card
  await tester.enterText(find.byKey(const Key('expiry_field')), '12/25');
  await tester.enterText(find.byKey(const Key('cvv_field')), '123');
  await tester.pumpAndSettle();

  // Attempt payment
  await tester.tap(find.text('Оплатить'));
  await tester.pumpAndSettle();

  // Verify payment failure
  expect(find.text('Ошибка оплаты'), findsOneWidget);
  expect(find.text('Недостаточно средств'), findsOneWidget);
}

Future<void> _retryPayment(WidgetTester tester) async {
  // Tap retry button
  await tester.tap(find.text('Повторить оплату'));
  await tester.pumpAndSettle();

  // Select different payment method
  await tester.tap(find.text('СБП'));
  await tester.pumpAndSettle();

  // Enter phone number
  await tester.enterText(
    find.byKey(const Key('phone_field')),
    '+7 900 123 45 67',
  );
  await tester.pumpAndSettle();

  // Process payment
  await tester.tap(find.text('Оплатить'));
  await tester.pumpAndSettle();
}

Future<void> _verifySuccessfulPayment(WidgetTester tester) async {
  // Verify payment success
  expect(find.text('Оплата успешно проведена!'), findsOneWidget);
  expect(find.text('Бронирование подтверждено'), findsOneWidget);
}

Future<void> _attemptConflictingBooking(WidgetTester tester) async {
  // Navigate to search
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // Select same specialist
  final specialistCard = find.byType(Card).first;
  await tester.tap(specialistCard);
  await tester.pumpAndSettle();

  // Try to book same time slot
  await tester.tap(find.text('Забронировать'));
  await tester.pumpAndSettle();

  // Select same date and time
  await tester.tap(find.text('Выберите дату'));
  await tester.pumpAndSettle();

  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final dateButton = find.text('${tomorrow.day}');
  await tester.tap(dateButton);
  await tester.pumpAndSettle();

  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Выберите время'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('10:00'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  // Submit booking
  await tester.tap(find.text('Забронировать'));
  await tester.pumpAndSettle();
}

Future<void> _handleBookingConflict(WidgetTester tester) async {
  // Verify conflict detection
  expect(find.text('Время занято'), findsOneWidget);
  expect(find.text('Выберите другое время'), findsOneWidget);
}

Future<void> _selectAlternativeTime(WidgetTester tester) async {
  // Tap on alternative time suggestion
  await tester.tap(find.text('14:00'));
  await tester.pumpAndSettle();

  // Confirm alternative time
  await tester.tap(find.text('Подтвердить'));
  await tester.pumpAndSettle();
}

Future<void> _completeBookingWithNewTime(WidgetTester tester) async {
  // Submit booking with new time
  await tester.tap(find.text('Забронировать'));
  await tester.pumpAndSettle();

  // Verify successful booking
  expect(find.text('Бронирование создано!'), findsOneWidget);
  expect(find.text('14:00'), findsOneWidget);
}
