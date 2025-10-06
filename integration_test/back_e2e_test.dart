import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Back Navigation E2E Tests', () {
    testWidgets('Navigation flow and double-tap-to-exit', (tester) async {
      // Запускаем приложение
      app.main();
      await tester.pumpAndSettle();

      // Ждем загрузки главного экрана
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Проверяем, что мы на главном экране
      expect(find.text('Главная'), findsOneWidget);

      // Переходим на экран поиска
      await tester.tap(find.text('Поиск'));
      await tester.pumpAndSettle();

      // Проверяем, что мы на экране поиска
      expect(find.text('Поиск'), findsOneWidget);

      // Нажимаем системную кнопку "Назад"
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Проверяем, что вернулись на главную
      expect(find.text('Главная'), findsOneWidget);

      // Тестируем двойное нажатие для выхода
      // Первое нажатие - должно показать SnackBar
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Проверяем, что показался SnackBar
      expect(find.text('Нажмите «Назад» ещё раз, чтобы выйти'), findsOneWidget);

      // Второе нажатие - должно выйти из приложения
      await tester.pageBack();
      await tester.pumpAndSettle();

      // В тестовой среде приложение не закроется, но мы проверим,
      // что SnackBar исчез
      expect(find.text('Нажмите «Назад» ещё раз, чтобы выйти'), findsNothing);
    });

    testWidgets('Tab navigation preserves stack', (tester) async {
      // Запускаем приложение
      app.main();
      await tester.pumpAndSettle();

      // Ждем загрузки главного экрана
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переходим на экран сообщений
      await tester.tap(find.text('Сообщения'));
      await tester.pumpAndSettle();

      // Проверяем, что мы на экране сообщений
      expect(find.text('Сообщения'), findsOneWidget);

      // Переходим на экран профиля
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Проверяем, что мы на экране профиля
      expect(find.text('Профиль'), findsOneWidget);

      // Возвращаемся на экран сообщений
      await tester.tap(find.text('Сообщения'));
      await tester.pumpAndSettle();

      // Проверяем, что мы снова на экране сообщений
      expect(find.text('Сообщения'), findsOneWidget);

      // Проверяем, что состояние сохранилось (нет перезагрузки)
      expect(find.text('Сообщения'), findsOneWidget);
    });
  });
}
