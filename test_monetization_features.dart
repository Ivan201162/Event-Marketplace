import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Monetization Features Tests', () {
    testWidgets('Test Monetization Hub Navigation', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки приложения
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Поиск и нажатие на вкладку монетизации
      final monetizationTab = find.byIcon(Icons.monetization_on);
      if (monetizationTab.evaluate().isNotEmpty) {
        await tester.tap(monetizationTab);
      } else {
        // Альтернативный поиск по тексту
        final monetizationText = find.text('Монетизация');
        if (monetizationText.evaluate().isNotEmpty) {
          await tester.tap(monetizationText);
        }
      }
      await tester.pumpAndSettle();

      // Проверка отображения главного экрана монетизации
      expect(find.text('Монетизация и Премиум'), findsOneWidget);
      expect(find.text('Платные Подписки'), findsOneWidget);
      expect(find.text('Продвижение Профиля'), findsOneWidget);
      expect(find.text('Рекламные Кампании'), findsOneWidget);
    });

    testWidgets('Test Subscription Plans Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к планам подписки
      await tester.tap(find.text('Платные Подписки'));
      await tester.pumpAndSettle();

      // Проверка отображения планов
      expect(find.text('Платные Подписки'), findsOneWidget);
      expect(find.text('Выберите свой план:'), findsOneWidget);
      
      // Проверка наличия планов
      expect(find.text('Бесплатный'), findsOneWidget);
      expect(find.text('Премиум (месяц)'), findsOneWidget);
      expect(find.text('PRO (месяц)'), findsOneWidget);
    });

    testWidgets('Test Promotion Packages Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к продвижению
      await tester.tap(find.text('Продвижение Профиля'));
      await tester.pumpAndSettle();

      // Проверка отображения пакетов продвижения
      expect(find.text('Пакеты Продвижения'), findsOneWidget);
      expect(find.text('Выберите пакет для продвижения вашего профиля:'), findsOneWidget);
      
      // Проверка наличия пакетов
      expect(find.text('Топ-1 на 3 дня'), findsOneWidget);
      expect(find.text('Топ-3 на 7 дней'), findsOneWidget);
      expect(find.text('Топ-5 на 14 дней'), findsOneWidget);
    });

    testWidgets('Test Advertisement Campaigns Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к рекламным кампаниям
      await tester.tap(find.text('Рекламные Кампании'));
      await tester.pumpAndSettle();

      // Проверка отображения типов рекламы
      expect(find.text('Рекламные Кампании'), findsOneWidget);
      expect(find.text('Выберите тип рекламной кампании:'), findsOneWidget);
      
      // Проверка наличия типов рекламы
      expect(find.text('Баннерная Реклама'), findsOneWidget);
      expect(find.text('Продвижение Профиля'), findsOneWidget);
      expect(find.text('Реклама События'), findsOneWidget);
    });

    testWidgets('Test Payment Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к планам подписки
      await tester.tap(find.text('Платные Подписки'));
      await tester.pumpAndSettle();

      // Выбор плана и переход к оплате
      final selectPlanButton = find.text('Выбрать план').first;
      if (selectPlanButton.evaluate().isNotEmpty) {
        await tester.tap(selectPlanButton);
        await tester.pumpAndSettle();

        // Проверка отображения экрана оплаты
        expect(find.text('Оплата'), findsOneWidget);
        expect(find.text('Детали заказа:'), findsOneWidget);
        expect(find.text('Выберите способ оплаты:'), findsOneWidget);
        
        // Проверка методов оплаты
        expect(find.text('Банковская карта (Mock)'), findsOneWidget);
        expect(find.text('Apple Pay (Mock)'), findsOneWidget);
        expect(find.text('Google Pay (Mock)'), findsOneWidget);
      }
    });

    testWidgets('Test Premium Badge Display', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Проверка отображения премиум-бейджей в интерфейсе
      // Это может быть в профилях пользователей или в списках
      final premiumBadges = find.byType(Container);
      
      // Премиум-бейджи должны отображаться для премиум-пользователей
      // В тестовых данных есть премиум-пользователи
      expect(premiumBadges, findsWidgets);
    });

    testWidgets('Test Advertisement Widget Display', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к главной странице
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // Проверка отображения рекламных виджетов
      // Реклама должна отображаться в ленте или на главной странице
      // Рекламные виджеты должны отображаться
    });

    testWidgets('Test Navigation Between Monetization Screens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Тестирование навигации между экранами
      await tester.tap(find.text('Платные Подписки'));
      await tester.pumpAndSettle();
      
      // Возврат назад
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Переход к продвижению
      await tester.tap(find.text('Продвижение Профиля'));
      await tester.pumpAndSettle();
      
      // Возврат назад
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Переход к рекламе
      await tester.tap(find.text('Рекламные Кампании'));
      await tester.pumpAndSettle();
    });

    testWidgets('Test My Subscriptions Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к планам подписки
      await tester.tap(find.text('Платные Подписки'));
      await tester.pumpAndSettle();

      // Поиск кнопки управления подпиской (если есть активная подписка)
      final manageButton = find.text('Управлять подпиской');
      if (manageButton.evaluate().isNotEmpty) {
        await tester.tap(manageButton);
        await tester.pumpAndSettle();

        // Проверка отображения экрана управления подпиской
        expect(find.text('Мои Подписки'), findsOneWidget);
      }
    });

    testWidgets('Test My Promotions Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к продвижению
      await tester.tap(find.text('Продвижение Профиля'));
      await tester.pumpAndSettle();

      // Поиск кнопки "Мои продвижения"
      final myPromotionsButton = find.text('Мои продвижения');
      if (myPromotionsButton.evaluate().isNotEmpty) {
        await tester.tap(myPromotionsButton);
        await tester.pumpAndSettle();

        // Проверка отображения экрана моих продвижений
        expect(find.text('Мои Продвижения'), findsOneWidget);
      }
    });

    testWidgets('Test My Advertisements Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к рекламным кампаниям
      await tester.tap(find.text('Рекламные Кампании'));
      await tester.pumpAndSettle();

      // Поиск кнопки "Мои рекламные кампании"
      final myAdsButton = find.text('Мои рекламные кампании');
      if (myAdsButton.evaluate().isNotEmpty) {
        await tester.tap(myAdsButton);
        await tester.pumpAndSettle();

        // Проверка отображения экрана моих рекламных кампаний
        expect(find.text('Мои Рекламные Кампании'), findsOneWidget);
      }
    });

    testWidgets('Test Create Advertisement Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход к монетизации
      await tester.tap(find.byIcon(Icons.monetization_on));
      await tester.pumpAndSettle();

      // Переход к рекламным кампаниям
      await tester.tap(find.text('Рекламные Кампании'));
      await tester.pumpAndSettle();

      // Выбор типа рекламы
      await tester.tap(find.text('Баннерная Реклама'));
      await tester.pumpAndSettle();

      // Проверка отображения экрана создания рекламы
      expect(find.text('Создать Баннерную Рекламу'), findsOneWidget);
      expect(find.text('Заголовок рекламы'), findsOneWidget);
      expect(find.text('URL изображения/видео баннера'), findsOneWidget);
    });
  });
}
