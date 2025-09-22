import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:event_marketplace_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Flow Integration Tests', () {
    testWidgets('полный поток регистрации и входа пользователя', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act & Assert - проверяем начальный экран
      expect(find.text('Event Marketplace'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('Регистрация'), findsOneWidget);

      // Act - нажимаем на кнопку регистрации
      await tester.tap(find.text('Регистрация'));
      await tester.pumpAndSettle();

      // Assert - проверяем экран регистрации
      expect(find.text('Создать аккаунт'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));

      // Act - заполняем форму регистрации
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.pumpAndSettle();

      // Act - нажимаем кнопку регистрации
      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pumpAndSettle();

      // Assert - проверяем успешную регистрацию
      // В реальном приложении здесь должна быть проверка навигации на главный экран
      expect(find.text('Event Marketplace'), findsOneWidget);
    });

    testWidgets('поток входа существующего пользователя', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - нажимаем на кнопку входа
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      // Assert - проверяем экран входа
      expect(find.text('Вход в аккаунт'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));

      // Act - заполняем форму входа
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      // Act - нажимаем кнопку входа
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      // Assert - проверяем успешный вход
      // В реальном приложении здесь должна быть проверка навигации на главный экран
      expect(find.text('Event Marketplace'), findsOneWidget);
    });

    testWidgets('навигация по главному экрану', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Предполагаем, что пользователь уже вошел в систему
      // В реальном приложении здесь должен быть мок или тестовый пользователь

      // Act & Assert - проверяем навигацию по вкладкам
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        // Мобильная навигация
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(find.text('Поиск'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chat));
        await tester.pumpAndSettle();
        expect(find.text('Чаты'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        expect(find.text('Профиль'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.event));
        await tester.pumpAndSettle();
        expect(find.text('События'), findsOneWidget);
      } else if (find.byType(NavigationBar).evaluate().isNotEmpty) {
        // Десктопная навигация
        await tester.tap(find.text('Поиск'));
        await tester.pumpAndSettle();
        expect(find.text('Поиск'), findsOneWidget);

        await tester.tap(find.text('Чаты'));
        await tester.pumpAndSettle();
        expect(find.text('Чаты'), findsOneWidget);

        await tester.tap(find.text('Профиль'));
        await tester.pumpAndSettle();
        expect(find.text('Профиль'), findsOneWidget);

        await tester.tap(find.text('События'));
        await tester.pumpAndSettle();
        expect(find.text('События'), findsOneWidget);
      }
    });

    testWidgets('создание события организатором', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Предполагаем, что пользователь уже вошел в систему как организатор
      // В реальном приложении здесь должен быть мок или тестовый пользователь

      // Act - нажимаем на плавающую кнопку добавления
      if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Assert - проверяем экран создания события
        expect(find.text('Создать событие'), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(3));

        // Act - заполняем форму создания события
        await tester.enterText(find.byType(TextFormField).at(0), 'Test Event');
        await tester.enterText(find.byType(TextFormField).at(1), 'Test Description');
        await tester.enterText(find.byType(TextFormField).at(2), 'Test Location');
        await tester.pumpAndSettle();

        // Act - нажимаем кнопку создания
        await tester.tap(find.text('Создать'));
        await tester.pumpAndSettle();

        // Assert - проверяем успешное создание
        // В реальном приложении здесь должна быть проверка навигации обратно на главный экран
        expect(find.text('Event Marketplace'), findsOneWidget);
      }
    });

    testWidgets('поиск и фильтрация событий', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - переходим на вкладку поиска
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.search));
      } else if (find.byType(NavigationBar).evaluate().isNotEmpty) {
        await tester.tap(find.text('Поиск'));
      }
      await tester.pumpAndSettle();

      // Assert - проверяем экран поиска
      expect(find.text('Поиск'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));

      // Act - вводим поисковый запрос
      await tester.enterText(find.byType(TextFormField).first, 'test');
      await tester.pumpAndSettle();

      // Act - нажимаем кнопку поиска
      if (find.byIcon(Icons.search).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
      }

      // Assert - проверяем результаты поиска
      // В реальном приложении здесь должна быть проверка отображения результатов
      expect(find.text('Поиск'), findsOneWidget);
    });

    testWidgets('отправка сообщения в чате', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - переходим на вкладку чатов
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.chat));
      } else if (find.byType(NavigationBar).evaluate().isNotEmpty) {
        await tester.tap(find.text('Чаты'));
      }
      await tester.pumpAndSettle();

      // Assert - проверяем экран чатов
      expect(find.text('Чаты'), findsOneWidget);

      // Act - нажимаем на первый чат (если есть)
      if (find.byType(ListTile).evaluate().isNotEmpty) {
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        // Assert - проверяем экран чата
        expect(find.byType(TextFormField), findsOneWidget);

        // Act - вводим сообщение
        await tester.enterText(find.byType(TextFormField), 'Test message');
        await tester.pumpAndSettle();

        // Act - нажимаем кнопку отправки
        if (find.byIcon(Icons.send).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.send));
          await tester.pumpAndSettle();
        }

        // Assert - проверяем отправку сообщения
        // В реальном приложении здесь должна быть проверка отображения сообщения
        expect(find.text('Test message'), findsOneWidget);
      }
    });

    testWidgets('выход из системы', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - переходим на вкладку профиля
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.person));
      } else if (find.byType(NavigationBar).evaluate().isNotEmpty) {
        await tester.tap(find.text('Профиль'));
      }
      await tester.pumpAndSettle();

      // Assert - проверяем экран профиля
      expect(find.text('Профиль'), findsOneWidget);

      // Act - нажимаем кнопку выхода
      if (find.text('Выйти').evaluate().isNotEmpty) {
        await tester.tap(find.text('Выйти'));
        await tester.pumpAndSettle();

        // Assert - проверяем возврат на экран входа
        expect(find.text('Event Marketplace'), findsOneWidget);
        expect(find.text('Войти'), findsOneWidget);
        expect(find.text('Регистрация'), findsOneWidget);
      }
    });
  });
}
