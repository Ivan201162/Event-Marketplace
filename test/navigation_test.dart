import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Тестирование навигации', () {
    testWidgets('Проверка кнопки Назад на главной странице', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: app.EventMarketplaceApp(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что мы на главной странице
      expect(
        find.text('Найди специалиста для своего праздника 🎉'),
        findsOneWidget,
      );

      // Симулируем нажатие кнопки "Назад"
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Проверяем, что приложение не закрылось (показывается сообщение о двойном нажатии)
      final backMessage = find.text('Нажмите «Назад» ещё раз, чтобы выйти');
      expect(backMessage, findsOneWidget);
    });

    testWidgets('Проверка навигации между вкладками', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: app.EventMarketplaceApp(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие навигационных элементов
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Лента'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.text('Чаты'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('Проверка перехода на экран поиска', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: app.EventMarketplaceApp(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ищем кнопку "Смотреть все" в результатах поиска
      final showAllButton = find.textContaining('Показать все');
      if (showAllButton.evaluate().isNotEmpty) {
        await tester.tap(showAllButton.first);
        await tester.pumpAndSettle();

        // Проверяем, что перешли на экран поиска
        expect(find.text('Найди своего специалиста 🎯'), findsOneWidget);
      }
    });
  });
}
