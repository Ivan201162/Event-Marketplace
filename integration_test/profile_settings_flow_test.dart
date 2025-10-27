import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:event_marketplace_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile and Settings Flow Tests', () {
    testWidgets('Profile screen loads with user data',
        (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки главного экрана
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Проверка наличия экрана профиля
      expect(find.text('Профиль'), findsOneWidget);

      // Проверка наличия вкладок
      expect(find.text('Посты'), findsOneWidget);
      expect(find.text('Идеи'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);

      // Проверка наличия кнопок действий
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Edit profile flow works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку редактирования
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Проверка открытия экрана редактирования профиля
      expect(find.text('Редактировать профиль'), findsOneWidget);

      // Заполнение полей
      await tester.enterText(
          find.byKey(const Key('display_name_field')), 'Новое имя');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('username_field')), '@newusername');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('bio_field')), 'Новое описание');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Сохранить"
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      // Проверка возврата на экран профиля
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('Profile tabs navigation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Переключение на вкладку "Идеи"
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Переключение на вкладку "Заявки"
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Переключение на вкладку "Посты"
      await tester.tap(find.text('Посты'));
      await tester.pumpAndSettle();
    });

    testWidgets('Profile statistics work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Проверка наличия статистики
      expect(find.text('Подписчики'), findsOneWidget);
      expect(find.text('Подписки'), findsOneWidget);
      expect(find.text('Посты'), findsOneWidget);
      expect(find.text('Идеи'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);

      // Нажатие на статистику подписчиков
      await tester.tap(find.text('Подписчики'));
      await tester.pumpAndSettle();

      // Проверка открытия диалога
      expect(find.text('Список подписчиков'), findsOneWidget);
    });

    testWidgets('Settings screen opens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку настроек
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Проверка открытия экрана настроек
      expect(find.text('Настройки'), findsOneWidget);
    });

    testWidgets('Avatar selection works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку редактирования
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Нажатие на аватар
      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      // Проверка открытия диалога выбора аватара
      expect(find.text('Выбор аватара'), findsOneWidget);
    });

    testWidgets('Cover selection works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку редактирования
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Нажатие на обложку
      await tester.tap(find.byType(Container).first);
      await tester.pumpAndSettle();

      // Проверка открытия диалога выбора обложки
      expect(find.text('Выбор обложки'), findsOneWidget);
    });

    testWidgets('Profile validation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку редактирования
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Очистка поля имени
      await tester.enterText(find.byKey(const Key('display_name_field')), '');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Сохранить"
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      // Проверка появления ошибки валидации
      expect(find.text('Введите имя и фамилию'), findsOneWidget);
    });

    testWidgets('Profile tabs content loads', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Ожидание загрузки контента
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Проверка наличия контента в каждой вкладке
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
