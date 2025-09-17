import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:event_marketplace_app/core/app_router.dart';

void main() {
  group('Navigation Tests', () {
    testWidgets('should navigate to home page', (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что мы на главной странице
      expect(find.text('Главная'), findsOneWidget);
    });

    testWidgets('should navigate to search page', (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице поиска
      router.go('/search');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице поиска
      expect(find.text('Поиск'), findsOneWidget);
    });

    testWidgets('should navigate to profile page', (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице профиля
      router.go('/profile');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице профиля
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('should navigate to settings page',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице настроек
      router.go('/settings');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице настроек
      expect(find.text('Настройки'), findsOneWidget);
    });

    testWidgets('should navigate to event detail page with parameters',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице деталей события
      router.go('/event/test-event-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице деталей события
      expect(find.text('Детали события'), findsOneWidget);
    });

    testWidgets('should navigate to specialist profile page with parameters',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице профиля специалиста
      router.go('/specialist/test-specialist-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице профиля специалиста
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should navigate to booking form page with parameters',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице формы бронирования
      router.go('/booking-form/test-specialist-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице формы бронирования
      expect(find.text('Форма бронирования'), findsOneWidget);
    });

    testWidgets('should navigate to create review page with parameters',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице создания отзыва
      router.go('/create-review/test-target-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице создания отзыва
      expect(find.text('Создать отзыв'), findsOneWidget);
    });

    testWidgets('should navigate to chat page with parameters',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к странице чата
      router.go('/chat/test-chat-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице чата
      expect(find.text('Чат'), findsOneWidget);
    });

    testWidgets('should show error page for invalid route',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к несуществующему маршруту
      router.go('/invalid-route');
      await tester.pumpAndSettle();

      // Проверяем, что отображается страница ошибки
      expect(find.text('Ошибка навигации'), findsOneWidget);
      expect(find.text('Страница не найдена: /invalid-route'), findsOneWidget);
    });

    testWidgets('should navigate back to home from error page',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Навигируем к несуществующему маршруту
      router.go('/invalid-route');
      await tester.pumpAndSettle();

      // Нажимаем кнопку "На главную"
      final homeButton = find.text('На главную');
      expect(homeButton, findsOneWidget);

      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      // Проверяем, что мы вернулись на главную страницу
      expect(find.text('Главная'), findsOneWidget);
    });
  });

  group('AppRouter Utility Tests', () {
    testWidgets('should get current route', (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем текущий маршрут
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          equals('/'));
    });

    testWidgets('should check if route is current',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что главная страница является текущей
      expect(router.routerDelegate.currentConfiguration.uri.toString(),
          equals('/'));
    });

    testWidgets('should navigate to event detail using utility method',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Используем утилитный метод для навигации
      AppRouter.goToEventDetail(
          tester.element(find.byType(MaterialApp.router)), 'test-event-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице деталей события
      expect(find.text('Детали события'), findsOneWidget);
    });

    testWidgets('should navigate to specialist profile using utility method',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Используем утилитный метод для навигации
      AppRouter.goToSpecialistProfile(
          tester.element(find.byType(MaterialApp.router)),
          'test-specialist-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице профиля специалиста
      expect(find.text('Профиль специалиста'), findsOneWidget);
    });

    testWidgets('should navigate to booking form using utility method',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Используем утилитный метод для навигации
      AppRouter.goToBookingForm(tester.element(find.byType(MaterialApp.router)),
          'test-specialist-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице формы бронирования
      expect(find.text('Форма бронирования'), findsOneWidget);
    });

    testWidgets('should navigate to create review using utility method',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Используем утилитный метод для навигации
      AppRouter.goToCreateReview(
          tester.element(find.byType(MaterialApp.router)), 'test-target-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице создания отзыва
      expect(find.text('Создать отзыв'), findsOneWidget);
    });

    testWidgets('should navigate to chat using utility method',
        (WidgetTester tester) async {
      final router = AppRouter.createRouter();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Используем утилитный метод для навигации
      AppRouter.goToChat(
          tester.element(find.byType(MaterialApp.router)), 'test-chat-id');
      await tester.pumpAndSettle();

      // Проверяем, что мы на странице чата
      expect(find.text('Чат'), findsOneWidget);
    });
  });
}
