import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:event_marketplace_app/core/app_router_minimal_working.dart';
import 'package:event_marketplace_app/screens/main_navigation_screen.dart';
import 'package:event_marketplace_app/screens/home/home_screen_improved.dart';
import 'package:event_marketplace_app/screens/requests/create_request_screen.dart';
import 'package:event_marketplace_app/screens/ideas/create_idea_screen.dart';
import 'package:event_marketplace_app/screens/notifications/notifications_screen.dart';

void main() {
  group('Navigation Tests', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/main',
        routes: [
          GoRoute(
            path: '/main',
            builder: (context, state) => const MainNavigationScreen(),
          ),
          GoRoute(
            path: '/create-request',
            builder: (context, state) => const CreateRequestScreen(),
          ),
          GoRoute(
            path: '/create-idea',
            builder: (context, state) => const CreateIdeaScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      );
    });

    testWidgets('Main navigation screen loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что главный экран загрузился
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      
      // Проверяем наличие основных вкладок
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Лента'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.text('Чаты'), findsOneWidget);
      expect(find.text('Идеи'), findsOneWidget);
      
      // Проверяем, что уведомления НЕ в нижнем меню
      expect(find.text('Уведомления'), findsNothing);
    });

    testWidgets('Navigation between tabs works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на вкладку "Заявки"
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверяем, что экран заявок загрузился
      expect(find.byType(MainNavigationScreen), findsOneWidget);

      // Переходим на вкладку "Идеи"
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Проверяем, что экран идей загрузился
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('Create request screen navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на экран создания заявки
      router.go('/create-request');
      await tester.pumpAndSettle();

      // Проверяем, что экран создания заявки загрузился
      expect(find.byType(CreateRequestScreen), findsOneWidget);
      
      // Проверяем наличие основных полей
      expect(find.text('Создать заявку'), findsOneWidget);
      expect(find.text('Название события'), findsOneWidget);
      expect(find.text('Описание'), findsOneWidget);
      expect(find.text('Бюджет (руб.)'), findsOneWidget);
      expect(find.text('Город'), findsOneWidget);
    });

    testWidgets('Create idea screen navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на экран создания идеи
      router.go('/create-idea');
      await tester.pumpAndSettle();

      // Проверяем, что экран создания идеи загрузился
      expect(find.byType(CreateIdeaScreen), findsOneWidget);
      
      // Проверяем наличие основных полей
      expect(find.text('Поделиться идеей'), findsOneWidget);
      expect(find.text('Название идеи'), findsOneWidget);
      expect(find.text('Описание'), findsOneWidget);
      expect(find.text('Теги'), findsOneWidget);
    });

    testWidgets('Notifications screen navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на экран уведомлений
      router.go('/notifications');
      await tester.pumpAndSettle();

      // Проверяем, что экран уведомлений загрузился
      expect(find.byType(NotificationsScreen), findsOneWidget);
      
      // Проверяем наличие основных элементов
      expect(find.text('Уведомления'), findsOneWidget);
    });

    testWidgets('Back navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на экран создания заявки
      router.go('/create-request');
      await tester.pumpAndSettle();

      // Проверяем наличие кнопки "Назад"
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Нажимаем кнопку "Назад"
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Проверяем, что вернулись на главный экран
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('All navigation routes are valid', (WidgetTester tester) async {
      final validRoutes = [
        '/main',
        '/create-request',
        '/create-idea',
        '/notifications',
      ];

      for (final route in validRoutes) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        router.go(route);
        await tester.pumpAndSettle();

        // Проверяем, что экран загрузился без ошибок
        expect(tester.takeException(), isNull, reason: 'Route $route should not throw exception');
      }
    });
  });
}