import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:event_marketplace_app/main.dart';
import 'package:event_marketplace_app/screens/home/home_screen_improved.dart';
import 'package:event_marketplace_app/screens/requests/create_request_screen.dart';
import 'package:event_marketplace_app/screens/ideas/create_idea_screen.dart';
import 'package:event_marketplace_app/widgets/ui_kit/ui_kit.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('Home screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем основные элементы главного экрана
      expect(find.text('Быстрые действия'), findsOneWidget);
      expect(find.text('Создать заявку'), findsOneWidget);
      expect(find.text('Поделиться идеей'), findsOneWidget);
      expect(find.text('Ваша статистика'), findsOneWidget);

      // Проверяем наличие кнопки уведомлений
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('Create request screen form validation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateRequestScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие формы
      expect(find.byType(Form), findsOneWidget);

      // Проверяем обязательные поля
      expect(find.text('Название события'), findsOneWidget);
      expect(find.text('Описание'), findsOneWidget);
      expect(find.text('Бюджет (руб.)'), findsOneWidget);
      expect(find.text('Город'), findsOneWidget);

      // Проверяем кнопку создания
      expect(find.text('Создать'), findsOneWidget);
    });

    testWidgets('Create idea screen form validation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateIdeaScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие формы
      expect(find.byType(Form), findsOneWidget);

      // Проверяем обязательные поля
      expect(find.text('Название идеи'), findsOneWidget);
      expect(find.text('Описание'), findsOneWidget);
      expect(find.text('Теги'), findsOneWidget);

      // Проверяем кнопки медиа
      expect(find.text('Фото'), findsOneWidget);
      expect(find.text('Видео'), findsOneWidget);

      // Проверяем кнопку публикации
      expect(find.text('Опубликовать'), findsOneWidget);
    });

    testWidgets('UI Kit buttons work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const UIButtons.primary(
                    text: 'Primary Button',
                  ),
                  const UIButtons.secondary(
                    text: 'Secondary Button',
                  ),
                  const UIButtons.text(
                    text: 'Text Button',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие кнопок
      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.text('Secondary Button'), findsOneWidget);
      expect(find.text('Text Button'), findsOneWidget);
    });

    testWidgets('UI Kit cards display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  UICards.primary(
                    context: null,
                    child: Text('Primary Card'),
                  ),
                  UICards.stats(
                    context: null,
                    title: 'Stats',
                    value: '100',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие карточек
      expect(find.text('Primary Card'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateRequestScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Пытаемся создать заявку без заполнения полей
      await tester.tap(find.text('Создать'));
      await tester.pumpAndSettle();

      // Проверяем, что появились сообщения об ошибках валидации
      expect(find.text('Введите название события'), findsOneWidget);
      expect(find.text('Введите описание события'), findsOneWidget);
      expect(find.text('Укажите бюджет'), findsOneWidget);
      expect(find.text('Выберите город'), findsOneWidget);
    });

    testWidgets('Navigation buttons work', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем кнопки быстрых действий
      expect(find.text('Создать заявку'), findsOneWidget);
      expect(find.text('Поделиться идеей'), findsOneWidget);

      // Проверяем кнопку уведомлений
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('Loading states display correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreenImproved(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие shimmer анимаций при загрузке
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('Error states display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UICards.error(
                context: null,
                message: 'Test error message',
                onRetry: () {},
                retryText: 'Retry',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем отображение ошибки
      expect(find.text('Ошибка: Test error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Empty states display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UICards.empty(
                context: null,
                title: 'No data',
                subtitle: 'No data available',
                icon: Icons.inbox,
                onAction: () {},
                actionText: 'Refresh',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем отображение пустого состояния
      expect(find.text('No data'), findsOneWidget);
      expect(find.text('No data available'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });
  });
}
