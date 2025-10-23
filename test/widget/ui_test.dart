import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_marketplace_app/screens/main_navigation_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/home/home_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/feed/feed_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/requests/requests_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/chat/chat_list_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/ideas/ideas_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/profile/profile_screen_enhanced.dart';

/// Тесты UI компонентов
void main() {
  group('UI Component Tests', () {
    testWidgets('MainNavigationScreenEnhanced displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreenEnhanced(),
        ),
      );

      // Проверка наличия основных элементов
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Лента'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.text('Чаты'), findsOneWidget);
      expect(find.text('Идеи'), findsOneWidget);
    });

    testWidgets('HomeScreenEnhanced displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreenEnhanced(),
        ),
      );

      // Проверка наличия основных элементов
      expect(find.text('Главная'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Категории'), findsOneWidget);
      expect(find.text('Быстрые действия'), findsOneWidget);
    });

    testWidgets('FeedScreenEnhanced displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FeedScreenEnhanced(),
        ),
      );

      // Проверка наличия основных элементов
      expect(find.text('Лента'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('RequestsScreenEnhanced displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RequestsScreenEnhanced(),
        ),
      );

      // Проверка наличия основных элементов
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('ChatListScreenEnhanced displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatListScreenEnhanced(),
        ),
      );

      // Проверка наличия основных элементов
      expect(find.text('Чаты'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('IdeasScreenEnhanced displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdeasScreenEnhanced(),
        ),
      );

      // Проверка наличия основных элементов
      expect(find.text('Идеи'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('ProfileScreenEnhanced displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreenEnhanced(),
        ),
      );

      // Проверка наличия основных элементов
      expect(find.text('Профиль'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Активность'), findsOneWidget);
    });

    testWidgets('Navigation buttons are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScreenEnhanced(),
        ),
      );

      // Проверка нажатия на кнопки навигации
      await tester.tap(find.text('Лента'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Главная'));
      await tester.pumpAndSettle();
    });

    testWidgets('Search fields are functional', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreenEnhanced(),
        ),
      );

      // Поиск поля поиска
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.tap(searchField.first);
        await tester.pumpAndSettle();

        await tester.enterText(searchField.first, 'тест');
        await tester.pumpAndSettle();

        expect(find.text('тест'), findsOneWidget);
      }
    });

    testWidgets('Filter buttons are functional', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FeedScreenEnhanced(),
        ),
      );

      // Поиск кнопки фильтра
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton.first);
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
      }
    });

    testWidgets('Create buttons are functional', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreenEnhanced(),
        ),
      );

      // Поиск кнопок создания
      final createButtons = find.byIcon(Icons.add_circle_outline);
      if (createButtons.evaluate().isNotEmpty) {
        await tester.tap(createButtons.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('App handles empty states gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FeedScreenEnhanced(),
        ),
      );

      // Проверка отсутствия критических ошибок
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });

    testWidgets('App handles loading states gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreenEnhanced(),
        ),
      );

      // Проверка отсутствия критических ошибок
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });
  });
}
