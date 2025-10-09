import 'package:event_marketplace_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Тесты поиска на главной странице', () {
    testWidgets('Проверка отображения поисковой строки', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что заголовок поиска отображается
      expect(find.text('Найди специалиста для своего праздника 🎉'),
          findsOneWidget,);

      // Проверяем наличие поисковой строки
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Проверка быстрых фильтров', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
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

    testWidgets('Проверка ввода в поисковую строку', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Находим поле поиска
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Вводим текст
      await tester.enterText(searchField, 'тест');
      await tester.pumpAndSettle();

      // Проверяем, что текст введён
      expect(tester.widget<TextField>(searchField).controller?.text,
          equals('тест'),);
    });

    testWidgets('Проверка кнопки очистки поиска', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
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
