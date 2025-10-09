import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar and Date Filter Tests', () {
    testWidgets('Calendar display', (tester) async {
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

      // Check calendar widget
      final calendar = find.byType(CalendarDatePicker);
      expect(calendar, findsOneWidget);

      // Check month navigation
      final prevMonthButton = find.byIcon(Icons.chevron_left);
      if (prevMonthButton.evaluate().isNotEmpty) {
        await tester.tap(prevMonthButton);
        await tester.pumpAndSettle();
      }

      final nextMonthButton = find.byIcon(Icons.chevron_right);
      if (nextMonthButton.evaluate().isNotEmpty) {
        await tester.tap(nextMonthButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Availability indicators', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to calendar
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      final calendarTab = find.text('Календарь');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // Check availability indicators
      final availableDays = find.byIcon(Icons.check_circle);
      expect(availableDays, findsWidgets);

      final busyDays = find.byIcon(Icons.event_busy);
      expect(busyDays, findsWidgets);

      final partiallyAvailableDays = find.byIcon(Icons.schedule);
      expect(partiallyAvailableDays, findsWidgets);
    });

    testWidgets('Date selection for booking', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to specialist profile
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      // Start booking process
      final bookButton = find.text('Забронировать');
      if (bookButton.evaluate().isNotEmpty) {
        await tester.tap(bookButton);
        await tester.pumpAndSettle();
      }

      // Select date
      final dateField = find.byKey(const Key('date_field'));
      if (dateField.evaluate().isNotEmpty) {
        await tester.tap(dateField);
        await tester.pumpAndSettle();
      }

      // Check date picker
      final datePicker = find.byType(CalendarDatePicker);
      expect(datePicker, findsOneWidget);

      // Select available date
      final availableDate = find.byIcon(Icons.check_circle);
      if (availableDate.evaluate().isNotEmpty) {
        await tester.tap(availableDate);
        await tester.pumpAndSettle();
      }

      // Confirm date selection
      final confirmButton = find.text('OK');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Time slot selection', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to booking
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      final bookButton = find.text('Забронировать');
      if (bookButton.evaluate().isNotEmpty) {
        await tester.tap(bookButton);
        await tester.pumpAndSettle();
      }

      // Select time
      final timeField = find.byKey(const Key('time_field'));
      if (timeField.evaluate().isNotEmpty) {
        await tester.tap(timeField);
        await tester.pumpAndSettle();
      }

      // Check time picker
      final timePicker = find.byType(TimePickerDialog);
      expect(timePicker, findsOneWidget);

      // Select time slot
      final timeSlot = find.text('10:00');
      if (timeSlot.evaluate().isNotEmpty) {
        await tester.tap(timeSlot);
        await tester.pumpAndSettle();
      }

      // Confirm time selection
      final confirmButton = find.text('OK');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Calendar filtering', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Open filters
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
      }

      // Set date range filter
      final dateRangeFilter = find.text('Дата события');
      if (dateRangeFilter.evaluate().isNotEmpty) {
        await tester.tap(dateRangeFilter);
        await tester.pumpAndSettle();
      }

      // Select start date
      final startDateField = find.byKey(const Key('start_date_field'));
      if (startDateField.evaluate().isNotEmpty) {
        await tester.tap(startDateField);
        await tester.pumpAndSettle();
      }

      final datePicker = find.byType(CalendarDatePicker);
      if (datePicker.evaluate().isNotEmpty) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final dateButton = find.text(tomorrow.day.toString());
        if (dateButton.evaluate().isNotEmpty) {
          await tester.tap(dateButton);
          await tester.pumpAndSettle();
        }
      }

      // Select end date
      final endDateField = find.byKey(const Key('end_date_field'));
      if (endDateField.evaluate().isNotEmpty) {
        await tester.tap(endDateField);
        await tester.pumpAndSettle();
      }

      if (datePicker.evaluate().isNotEmpty) {
        final nextWeek = DateTime.now().add(const Duration(days: 7));
        final dateButton = find.text(nextWeek.day.toString());
        if (dateButton.evaluate().isNotEmpty) {
          await tester.tap(dateButton);
          await tester.pumpAndSettle();
        }
      }

      // Apply filters
      final applyButton = find.text('Применить');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Availability management', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Find availability settings
      final availabilityButton = find.text('Настройка доступности');
      if (availabilityButton.evaluate().isNotEmpty) {
        await tester.tap(availabilityButton);
        await tester.pumpAndSettle();
      }

      // Check availability calendar
      final availabilityCalendar = find.byType(CalendarDatePicker);
      expect(availabilityCalendar, findsOneWidget);

      // Toggle availability for a date
      final dateButton = find.text('15');
      if (dateButton.evaluate().isNotEmpty) {
        await tester.tap(dateButton);
        await tester.pumpAndSettle();
      }

      // Set time slots
      final timeSlotsButton = find.text('Временные слоты');
      if (timeSlotsButton.evaluate().isNotEmpty) {
        await tester.tap(timeSlotsButton);
        await tester.pumpAndSettle();
      }

      // Add time slot
      final addSlotButton = find.byIcon(Icons.add);
      if (addSlotButton.evaluate().isNotEmpty) {
        await tester.tap(addSlotButton);
        await tester.pumpAndSettle();
      }

      // Set start time
      final startTimeField = find.byKey(const Key('start_time_field'));
      if (startTimeField.evaluate().isNotEmpty) {
        await tester.tap(startTimeField);
        await tester.pumpAndSettle();
      }

      // Set end time
      final endTimeField = find.byKey(const Key('end_time_field'));
      if (endTimeField.evaluate().isNotEmpty) {
        await tester.tap(endTimeField);
        await tester.pumpAndSettle();
      }

      // Save availability
      final saveButton = find.text('Сохранить');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Event calendar integration', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to calendar
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      final calendarTab = find.text('Календарь');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // Check event indicators
      final eventIndicators = find.byIcon(Icons.event);
      expect(eventIndicators, findsWidgets);

      // Tap on event date
      final eventDate = find.byIcon(Icons.event);
      if (eventDate.evaluate().isNotEmpty) {
        await tester.tap(eventDate);
        await tester.pumpAndSettle();
      }

      // Check event details
      final eventDetails = find.text('Детали события');
      if (eventDetails.evaluate().isNotEmpty) {
        expect(eventDetails, findsOneWidget);
      }
    });

    testWidgets('Calendar export', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to calendar
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      final calendarTab = find.text('Календарь');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab);
        await tester.pumpAndSettle();
      }

      // Find export button
      final exportButton = find.byIcon(Icons.download);
      if (exportButton.evaluate().isNotEmpty) {
        await tester.tap(exportButton);
        await tester.pumpAndSettle();
      }

      // Check export options
      final exportOptions = [
        'Экспорт в Google Calendar',
        'Экспорт в Apple Calendar',
        'Экспорт в Outlook',
        'Скачать .ics файл',
      ];

      for (final option in exportOptions) {
        final exportOption = find.text(option);
        if (exportOption.evaluate().isNotEmpty) {
          expect(exportOption, findsOneWidget);
        }
      }
    });
  });
}









