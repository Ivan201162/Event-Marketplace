import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../lib/core/app_router_enhanced.dart';
import '../lib/screens/main_navigation_screen.dart';
import '../lib/screens/home/home_screen_improved.dart';
import '../lib/screens/requests/requests_screen_improved.dart';
import '../lib/screens/chat/chat_list_screen_improved.dart';
import '../lib/screens/ideas/ideas_screen.dart';
import '../lib/screens/profile/profile_screen_enhanced.dart';

void main() {
  group('Navigation Tests', () {
    late GoRouter router;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      router = container.read(appRouterProvider);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Main navigation screen loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что главный экран загружен
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('Bottom navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие всех вкладок
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Лента'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.text('Чаты'), findsOneWidget);
      expect(find.text('Идеи'), findsOneWidget);

      // Проверяем, что нет вкладки "Уведомления"
      expect(find.text('Уведомления'), findsNothing);
    });

    testWidgets('Navigation between tabs works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на вкладку "Заявки"
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверяем, что экран заявок загружен
      expect(find.byType(RequestsScreenImproved), findsOneWidget);

      // Переходим на вкладку "Чаты"
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Проверяем, что экран чатов загружен
      expect(find.byType(ChatListScreenImproved), findsOneWidget);

      // Переходим на вкладку "Идеи"
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Проверяем, что экран идей загружен
      expect(find.byType(IdeasScreen), findsOneWidget);
    });

    testWidgets('Back navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на экран профиля
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Проверяем наличие кнопки "Назад"
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Нажимаем кнопку "Назад"
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Проверяем, что вернулись на главный экран
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('Error handling for invalid routes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Пытаемся перейти на несуществующий маршрут
      router.go('/invalid-route');
      await tester.pumpAndSettle();

      // Проверяем, что показана страница ошибки
      expect(find.text('Страница не найдена'), findsOneWidget);
    });

    testWidgets('Navigation animations work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переходим на экран уведомлений
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      // Проверяем, что анимация завершилась
      expect(find.byType(Material), findsWidgets);
    });
  });

  group('Screen Loading Tests', () {
    testWidgets('Home screen loads with skeleton animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что экран загружен
      expect(find.byType(HomeScreenImproved), findsOneWidget);
    });

    testWidgets('Requests screen loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RequestsScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что экран заявок загружен
      expect(find.byType(RequestsScreenImproved), findsOneWidget);
    });

    testWidgets('Chats screen loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ChatListScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что экран чатов загружен
      expect(find.byType(ChatListScreenImproved), findsOneWidget);
    });

    testWidgets('Ideas screen loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: IdeasScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что экран идей загружен
      expect(find.byType(IdeasScreen), findsOneWidget);
    });
  });

  group('Button Functionality Tests', () {
    testWidgets('Create request button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ищем кнопку создания заявки
      expect(find.text('Создать заявку'), findsOneWidget);

      // Нажимаем на кнопку
      await tester.tap(find.text('Создать заявку'));
      await tester.pumpAndSettle();
    });

    testWidgets('Create idea button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ищем кнопку создания идеи
      expect(find.text('Поделиться идеей'), findsOneWidget);

      // Нажимаем на кнопку
      await tester.tap(find.text('Поделиться идеей'));
      await tester.pumpAndSettle();
    });

    testWidgets('Notifications button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ищем кнопку уведомлений
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      // Нажимаем на кнопку
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
    });
  });

  group('Profile Tests', () {
    testWidgets('Profile screen loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreenEnhanced(userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что экран профиля загружен
      expect(find.byType(ProfileScreenEnhanced), findsOneWidget);
    });

    testWidgets('Profile edit button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreenEnhanced(userId: 'test-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ищем кнопку редактирования профиля
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Нажимаем на кнопку
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
    });
  });

  group('Performance Tests', () {
    testWidgets('Screen loading performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // Проверяем, что экран загрузился быстро (менее 1 секунды)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('Navigation performance', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Переходим между вкладками
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Проверяем, что навигация быстрая (менее 500ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
