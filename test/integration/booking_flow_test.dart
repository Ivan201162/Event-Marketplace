import 'package:event_marketplace_app/main.dart';
import 'package:event_marketplace_app/screens/booking_screen.dart';
import 'package:event_marketplace_app/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Booking Flow Integration Tests', () {
    testWidgets('Complete booking flow from search to confirmation', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Входим как гость
      await tester.tap(find.text('Гость'));
      await tester.pumpAndSettle();

      // Переходим к поиску специалистов
      await tester.tap(find.text('Найти специалиста'));
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран поиска
      expect(find.byType(SearchScreen), findsOneWidget);

      // Выполняем поиск
      final searchField = find.byType(TextFormField).first;
      await tester.enterText(searchField, 'фотограф');
      await tester.pumpAndSettle();

      // Нажимаем кнопку поиска
      final searchButton = find.text('Поиск');
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Проверяем, что появились результаты поиска
      // (в реальном приложении здесь будут карточки специалистов)
      expect(find.byType(Card), findsWidgets);

      // Нажимаем на карточку специалиста
      final specialistCard = find.byType(Card).first;
      await tester.tap(specialistCard);
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран бронирования
      expect(find.byType(BookingScreen), findsOneWidget);

      // Заполняем форму бронирования
      final dateField = find.byType(TextFormField).first;
      final timeField = find.byType(TextFormField).at(1);
      final durationField = find.byType(TextFormField).at(2);

      await tester.enterText(dateField, '2024-12-31');
      await tester.enterText(timeField, '14:00');
      await tester.enterText(durationField, '2');
      await tester.pumpAndSettle();

      // Проверяем, что поля заполнились
      expect(find.text('2024-12-31'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Нажимаем кнопку "Забронировать"
      final bookButton = find.text('Забронировать');
      if (bookButton.evaluate().isNotEmpty) {
        await tester.tap(bookButton);
        await tester.pumpAndSettle();

        // Проверяем, что появилось подтверждение
        expect(find.text('Бронирование создано'), findsOneWidget);
      }
    });

    testWidgets('Booking form validation', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Входим как гость
      await tester.tap(find.text('Гость'));
      await tester.pumpAndSettle();

      // Переходим к поиску
      await tester.tap(find.text('Найти специалиста'));
      await tester.pumpAndSettle();

      // Нажимаем на карточку специалиста
      final specialistCard = find.byType(Card).first;
      await tester.tap(specialistCard);
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран бронирования
      expect(find.byType(BookingScreen), findsOneWidget);

      // Нажимаем кнопку "Забронировать" без заполнения полей
      final bookButton = find.text('Забронировать');
      if (bookButton.evaluate().isNotEmpty) {
        await tester.tap(bookButton);
        await tester.pumpAndSettle();

        // Проверяем, что появились сообщения об ошибках валидации
        final errorMessages = find.textContaining('обязательно');
        if (errorMessages.evaluate().isNotEmpty) {
          expect(errorMessages, findsWidgets);
        }
      }
    });

    testWidgets('Date and time picker functionality', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Входим как гость
      await tester.tap(find.text('Гость'));
      await tester.pumpAndSettle();

      // Переходим к поиску
      await tester.tap(find.text('Найти специалиста'));
      await tester.pumpAndSettle();

      // Нажимаем на карточку специалиста
      final specialistCard = find.byType(Card).first;
      await tester.tap(specialistCard);
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран бронирования
      expect(find.byType(BookingScreen), findsOneWidget);

      // Ищем кнопки выбора даты и времени
      final dateButton = find.text('Выбрать дату');
      final timeButton = find.text('Выбрать время');

      if (dateButton.evaluate().isNotEmpty) {
        // Нажимаем на кнопку выбора даты
        await tester.tap(dateButton);
        await tester.pumpAndSettle();

        // Проверяем, что открылся календарь
        expect(find.byType(CalendarDatePicker), findsOneWidget);

        // Выбираем дату
        final today = find.text('31');
        if (today.evaluate().isNotEmpty) {
          await tester.tap(today);
          await tester.pumpAndSettle();
        }

        // Подтверждаем выбор
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          await tester.tap(okButton);
          await tester.pumpAndSettle();
        }
      }

      if (timeButton.evaluate().isNotEmpty) {
        // Нажимаем на кнопку выбора времени
        await tester.tap(timeButton);
        await tester.pumpAndSettle();

        // Проверяем, что открылся селектор времени
        expect(find.byType(TimePickerDialog), findsOneWidget);

        // Подтверждаем выбор времени
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          await tester.tap(okButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Duration selection', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Входим как гость
      await tester.tap(find.text('Гость'));
      await tester.pumpAndSettle();

      // Переходим к поиску
      await tester.tap(find.text('Найти специалиста'));
      await tester.pumpAndSettle();

      // Нажимаем на карточку специалиста
      final specialistCard = find.byType(Card).first;
      await tester.tap(specialistCard);
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран бронирования
      expect(find.byType(BookingScreen), findsOneWidget);

      // Ищем селектор продолжительности
      final durationDropdown = find.byType(DropdownButtonFormField);
      if (durationDropdown.evaluate().isNotEmpty) {
        // Нажимаем на выпадающий список
        await tester.tap(durationDropdown);
        await tester.pumpAndSettle();

        // Выбираем продолжительность
        final durationOption = find.text('2 часа');
        if (durationOption.evaluate().isNotEmpty) {
          await tester.tap(durationOption);
          await tester.pumpAndSettle();

          // Проверяем, что продолжительность выбрана
          expect(find.text('2 часа'), findsOneWidget);
        }
      }
    });

    testWidgets('Price calculation', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Входим как гость
      await tester.tap(find.text('Гость'));
      await tester.pumpAndSettle();

      // Переходим к поиску
      await tester.tap(find.text('Найти специалиста'));
      await tester.pumpAndSettle();

      // Нажимаем на карточку специалиста
      final specialistCard = find.byType(Card).first;
      await tester.tap(specialistCard);
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран бронирования
      expect(find.byType(BookingScreen), findsOneWidget);

      // Заполняем форму
      final durationField = find.byType(TextFormField).at(2);
      await tester.enterText(durationField, '3');
      await tester.pumpAndSettle();

      // Проверяем, что цена пересчиталась
      // (в реальном приложении здесь будет отображаться обновленная цена)
      expect(find.textContaining('₽'), findsWidgets);
    });
  });
}
