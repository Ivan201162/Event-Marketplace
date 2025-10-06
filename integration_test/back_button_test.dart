import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Назад возвращает на предыдущий экран', (tester) async {
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
  });

  testWidgets('Системная Назад не закрывает приложение на главном экране',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Ждем загрузки главного экрана
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Проверяем, что мы на главном экране
    expect(find.text('Главная'), findsOneWidget);

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
}
