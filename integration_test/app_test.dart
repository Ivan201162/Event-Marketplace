import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Интеграционные тесты Event Marketplace', () {
    testWidgets('Полный тест поиска специалистов', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Проверяем, что приложение запустилось
      expect(
        find.text('Найди специалиста для своего праздника 🎉'),
        findsOneWidget,
      );

      // Тестируем поиск
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Вводим поисковый запрос
      await tester.enterText(searchField, 'фотограф');
      await tester.pumpAndSettle();

      // Проверяем результаты поиска
      final searchResults = find.textContaining('Найдено специалистов:');
      final noResults = find.text('Никого не найдено 😅');

      expect(
        searchResults.evaluate().isNotEmpty || noResults.evaluate().isNotEmpty,
        isTrue,
      );

      // Тестируем быстрые фильтры
      expect(find.text('Фотографы'), findsOneWidget);
      await tester.tap(find.text('Фотографы'));
      await tester.pumpAndSettle();

      // Очищаем поиск
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }

      // Проверяем навигацию
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Лента'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.text('Чаты'), findsOneWidget);
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('Тест навигации и кнопки Назад', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Проверяем, что мы на главной странице
      expect(
        find.text('Найди специалиста для своего праздника 🎉'),
        findsOneWidget,
      );

      // Симулируем нажатие кнопки "Назад"
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Проверяем, что приложение не закрылось
      final backMessage = find.text('Нажмите «Назад» ещё раз, чтобы выйти');
      expect(backMessage, findsOneWidget);

      // Второе нажатие "Назад" должно закрыть приложение
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('Тест перехода к специалисту', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ищем специалиста в результатах
      final specialistTile = find.byType(ListTile);
      if (specialistTile.evaluate().isNotEmpty) {
        await tester.tap(specialistTile.first);
        await tester.pumpAndSettle();

        // Проверяем, что перешли к профилю специалиста
        // (это может быть заголовок профиля или кнопка "Назад")
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
      }
    });
  });
}
