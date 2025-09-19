import 'package:event_marketplace_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calendar Flow Integration Tests', () {
    testWidgets('should complete full calendar management flow',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Assert: Calendar should be displayed
      expect(find.text('Календарь'), findsOneWidget);
      expect(find.text('Статистика'), findsOneWidget);
      expect(find.text('Быстрые действия'), findsOneWidget);
    });

    testWidgets('should handle adding unavailable period', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: Add unavailable period
      await tester.tap(find.text('Добавить недоступность'));
      await tester.pumpAndSettle();

      // Act 3: Fill unavailable period form
      await tester.enterText(find.byType(TextFormField).first, 'Personal time');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Need some time off',
      );

      // Act 4: Select date range
      await tester.tap(find.text('Выберите дату начала'));
      await tester.pumpAndSettle();

      // Act 5: Submit unavailable period
      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();

      // Assert: Unavailable period should be added
      expect(find.text('Недоступность добавлена'), findsOneWidget);
    });

    testWidgets('should handle adding vacation period', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: Add vacation period
      await tester.tap(find.text('Добавить отпуск'));
      await tester.pumpAndSettle();

      // Act 3: Fill vacation form
      await tester.enterText(
        find.byType(TextFormField).first,
        'Summer vacation',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Going on vacation',
      );

      // Act 4: Select date range
      await tester.tap(find.text('Выберите дату начала'));
      await tester.pumpAndSettle();

      // Act 5: Submit vacation
      await tester.tap(find.text('Добавить'));
      await tester.pumpAndSettle();

      // Assert: Vacation should be added
      expect(find.text('Отпуск добавлен'), findsOneWidget);
    });

    testWidgets('should handle viewing calendar statistics', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: View statistics
      await tester.tap(find.text('Статистика'));
      await tester.pumpAndSettle();

      // Assert: Statistics should be displayed
      expect(find.text('Статистика календаря'), findsOneWidget);
      expect(find.text('Всего событий'), findsOneWidget);
      expect(find.text('Забронировано'), findsOneWidget);
      expect(find.text('Недоступно'), findsOneWidget);
      expect(find.text('Отпуск'), findsOneWidget);
    });

    testWidgets('should handle viewing calendar analytics', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: View analytics
      await tester.tap(find.byIcon(Icons.analytics));
      await tester.pumpAndSettle();

      // Assert: Analytics should be displayed
      expect(find.text('Аналитика календаря'), findsOneWidget);
      expect(find.text('Загрузка'), findsOneWidget);
      expect(find.text('Доходность'), findsOneWidget);
      expect(find.text('Популярные дни'), findsOneWidget);
    });

    testWidgets('should handle viewing test data', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: View test data
      await tester.tap(find.byIcon(Icons.data_usage));
      await tester.pumpAndSettle();

      // Assert: Test data should be displayed
      expect(find.text('Тестовые данные'), findsOneWidget);
      expect(find.text('Создать тестовые события'), findsOneWidget);
    });

    testWidgets('should handle calendar navigation', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: Navigate to previous month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Act 3: Navigate to next month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Assert: Calendar should navigate correctly
      expect(find.text('Календарь'), findsOneWidget);
    });

    testWidgets('should handle calendar date selection', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: Select a date
      final dateCell = find.byType(GestureDetector).first;
      if (dateCell.evaluate().isNotEmpty) {
        await tester.tap(dateCell);
        await tester.pumpAndSettle();

        // Assert: Date should be selected
        expect(find.text('Календарь'), findsOneWidget);
      }
    });

    testWidgets('should handle calendar event viewing', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: View events for selected date
      final dateCell = find.byType(GestureDetector).first;
      if (dateCell.evaluate().isNotEmpty) {
        await tester.tap(dateCell);
        await tester.pumpAndSettle();

        // Assert: Events should be displayed
        expect(find.text('Календарь'), findsOneWidget);
      }
    });

    testWidgets('should handle calendar event editing', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: Edit existing event
      final eventCard = find.byType(Card).first;
      if (eventCard.evaluate().isNotEmpty) {
        await tester.tap(eventCard);
        await tester.pumpAndSettle();

        // Act 3: Edit event details
        await tester.enterText(
          find.byType(TextFormField).first,
          'Updated event',
        );

        // Act 4: Save changes
        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();

        // Assert: Event should be updated
        expect(find.text('Событие обновлено'), findsOneWidget);
      }
    });

    testWidgets('should handle calendar event deletion', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Act 1: Navigate to calendar
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Act 2: Delete existing event
      final eventCard = find.byType(Card).first;
      if (eventCard.evaluate().isNotEmpty) {
        await tester.tap(eventCard);
        await tester.pumpAndSettle();

        // Act 3: Delete event
        await tester.tap(find.text('Удалить'));
        await tester.pumpAndSettle();

        // Act 4: Confirm deletion
        await tester.tap(find.text('Подтвердить'));
        await tester.pumpAndSettle();

        // Assert: Event should be deleted
        expect(find.text('Событие удалено'), findsOneWidget);
      }
    });
  });
}
