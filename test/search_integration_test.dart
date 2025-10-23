import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Поиск специалистов на главной странице', () {
    testWidgets('Проверка поиска специалистов', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
            child: MaterialApp(home: app.EventMarketplaceApp())),
      );

      await tester.pumpAndSettle();

      // Проверяем, что заголовок поиска отображается
      expect(find.text('Найди специалиста для своего праздника 🎉'),
          findsOneWidget);

      // Ищем поле поиска
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Вводим поисковый запрос
      await tester.enterText(searchField, 'ведущий');
      await tester.pumpAndSettle();

      // Проверяем, что поиск работает (результаты отображаются или показывается сообщение "не найдено")
      final searchResults = find.textContaining('Найдено специалистов:');
      final noResults = find.text('Никого не найдено 😅');

      expect(
          searchResults.evaluate().isNotEmpty ||
              noResults.evaluate().isNotEmpty,
          isTrue);
    });

    testWidgets('Проверка быстрых фильтров', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
            child: MaterialApp(home: app.EventMarketplaceApp())),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие фильтров
      expect(find.text('Ведущие'), findsOneWidget);
      expect(find.text('Фотографы'), findsOneWidget);
      expect(find.text('Диджеи'), findsOneWidget);
      expect(find.text('Оформители'), findsOneWidget);
      expect(find.text('Кавер-группы'), findsOneWidget);
      expect(find.text('Видеографы'), findsOneWidget);
    });

    testWidgets('Проверка очистки поиска', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
            child: MaterialApp(home: app.EventMarketplaceApp())),
      );

      await tester.pumpAndSettle();

      // Вводим текст в поиск
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'тест');
      await tester.pumpAndSettle();

      // Проверяем, что кнопка очистки появилась
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      // Нажимаем кнопку очистки
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Проверяем, что поле очистилось
      expect(tester.widget<TextField>(searchField).controller?.text, isEmpty);
    });
  });
}
