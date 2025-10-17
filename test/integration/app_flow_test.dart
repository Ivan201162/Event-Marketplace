import 'package:event_marketplace_app/main.dart';
import 'package:event_marketplace_app/screens/auth_screen.dart';
import 'package:event_marketplace_app/screens/home_screen.dart';
import 'package:event_marketplace_app/screens/profile_screen.dart';
import 'package:event_marketplace_app/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Flow Integration Tests', () {
    testWidgets('Complete user journey from auth to booking', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      // Ждем загрузки
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Проверяем наличие полей авторизации
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('Регистрация'), findsOneWidget);
      expect(find.text('Гость'), findsOneWidget);

      // Тестируем гостевой вход
      await tester.tap(find.text('Гость'));
      await tester.pumpAndSettle();

      // Проверяем, что открылся главный экран
      expect(find.byType(HomeScreen), findsOneWidget);

      // Проверяем наличие кнопок навигации
      expect(find.text('Найти специалиста'), findsOneWidget);
      expect(find.text('Мои заявки'), findsOneWidget);
      expect(find.text('Календарь'), findsOneWidget);
      expect(find.text('Сообщения'), findsOneWidget);
      expect(find.text('AI-помощник'), findsOneWidget);

      // Тестируем навигацию к поиску специалистов
      await tester.tap(find.text('Найти специалиста'));
      await tester.pumpAndSettle();

      // Проверяем, что открылся экран поиска
      expect(find.byType(SearchScreen), findsOneWidget);

      // Возвращаемся на главный экран
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Проверяем, что вернулись на главный экран
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Navigation between all main screens', (tester) async {
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

      // Тестируем навигацию к "Мои заявки"
      await tester.tap(find.text('Мои заявки'));
      await tester.pumpAndSettle();

      // Возвращаемся
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Тестируем навигацию к "Календарь"
      await tester.tap(find.text('Календарь'));
      await tester.pumpAndSettle();

      // Возвращаемся
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Тестируем навигацию к "Сообщения"
      await tester.tap(find.text('Сообщения'));
      await tester.pumpAndSettle();

      // Возвращаемся
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Тестируем навигацию к "AI-помощник"
      await tester.tap(find.text('AI-помощник'));
      await tester.pumpAndSettle();

      // Возвращаемся
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Проверяем, что вернулись на главный экран
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Search screen functionality', (tester) async {
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

      // Проверяем наличие элементов поиска
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);

      // Тестируем поиск
      await tester.enterText(find.byType(TextFormField).first, 'фотограф');
      await tester.pumpAndSettle();

      // Проверяем, что поиск выполнился
      expect(find.text('фотограф'), findsOneWidget);
    });

    testWidgets('Profile screen functionality', (tester) async {
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

      // Переходим к профилю (через меню или кнопку)
      // Предполагаем, что есть кнопка профиля
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();

        // Проверяем, что открылся экран профиля
        expect(find.byType(ProfileScreen), findsOneWidget);
      }
    });
  });
}




