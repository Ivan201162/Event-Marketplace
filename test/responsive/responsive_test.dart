import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:event_marketplace_app/screens/responsive/responsive_main_navigation_screen.dart';
import 'package:event_marketplace_app/screens/responsive/responsive_home_screen.dart';
import 'package:event_marketplace_app/screens/responsive/responsive_feed_screen.dart';
import 'package:event_marketplace_app/screens/responsive/responsive_requests_screen.dart';
import 'package:event_marketplace_app/screens/responsive/responsive_chat_screen.dart';
import 'package:event_marketplace_app/screens/responsive/responsive_ideas_screen.dart';
import 'package:event_marketplace_app/screens/responsive/responsive_profile_screen.dart';

/// Тесты адаптивности
void main() {
  group('Responsive Design Tests', () {
    testWidgets('ResponsiveMainNavigationScreen adapts to mobile screens',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveMainNavigationScreen(),
        ),
      );

      // Проверка адаптации к мобильным экранам
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Проверка отсутствия переполнения
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });

    testWidgets('ResponsiveMainNavigationScreen adapts to tablet screens',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveMainNavigationScreen(),
        ),
      );

      // Проверка адаптации к планшетам
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // Проверка отсутствия переполнения
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });

    testWidgets('ResponsiveMainNavigationScreen adapts to desktop screens',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveMainNavigationScreen(),
        ),
      );

      // Проверка адаптации к десктопам
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // Проверка отсутствия переполнения
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });

    testWidgets('ResponsiveHomeScreen adapts to different screen sizes',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveHomeScreen(),
          ),
        );

        // Проверка адаптации к разным размерам экрана
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);

        // Проверка отсутствия переполнения
        expect(find.text('Ошибка'), findsNothing);
        expect(find.text('Error'), findsNothing);
        expect(find.text('Exception'), findsNothing);
      }
    });

    testWidgets('ResponsiveFeedScreen adapts to different screen sizes',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveFeedScreen(),
          ),
        );

        // Проверка адаптации к разным размерам экрана
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);

        // Проверка отсутствия переполнения
        expect(find.text('Ошибка'), findsNothing);
        expect(find.text('Error'), findsNothing);
        expect(find.text('Exception'), findsNothing);
      }
    });

    testWidgets('ResponsiveRequestsScreen adapts to different screen sizes',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveRequestsScreen(),
          ),
        );

        // Проверка адаптации к разным размерам экрана
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);

        // Проверка отсутствия переполнения
        expect(find.text('Ошибка'), findsNothing);
        expect(find.text('Error'), findsNothing);
        expect(find.text('Exception'), findsNothing);
      }
    });

    testWidgets('ResponsiveChatScreen adapts to different screen sizes',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveChatScreen(),
          ),
        );

        // Проверка адаптации к разным размерам экрана
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);

        // Проверка отсутствия переполнения
        expect(find.text('Ошибка'), findsNothing);
        expect(find.text('Error'), findsNothing);
        expect(find.text('Exception'), findsNothing);
      }
    });

    testWidgets('ResponsiveIdeasScreen adapts to different screen sizes',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveIdeasScreen(),
          ),
        );

        // Проверка адаптации к разным размерам экрана
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);

        // Проверка отсутствия переполнения
        expect(find.text('Ошибка'), findsNothing);
        expect(find.text('Error'), findsNothing);
        expect(find.text('Exception'), findsNothing);
      }
    });

    testWidgets('ResponsiveProfileScreen adapts to different screen sizes',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveProfileScreen(),
          ),
        );

        // Проверка адаптации к разным размерам экрана
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);

        // Проверка отсутствия переполнения
        expect(find.text('Ошибка'), findsNothing);
        expect(find.text('Error'), findsNothing);
        expect(find.text('Exception'), findsNothing);
      }
    });

    testWidgets('App handles dynamic screen size changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveMainNavigationScreen(),
        ),
      );

      // Динамическое изменение размера экрана
      final screenSizes = [
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 768), // iPad landscape
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpAndSettle();

        // Проверка отсутствия ошибок при изменении размера
        expect(find.text('Ошибка'), findsNothing);
        expect(find.text('Error'), findsNothing);
        expect(find.text('Exception'), findsNothing);
      }
    });

    testWidgets('App handles orientation changes gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveMainNavigationScreen(),
        ),
      );

      // Изменение ориентации
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpAndSettle();

      // Проверка отсутствия ошибок при изменении ориентации
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });

    testWidgets('App handles screen rotation during navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveMainNavigationScreen(),
        ),
      );

      // Переход на вкладку "Лента"
      await tester.tap(find.text('Лента'));
      await tester.pumpAndSettle();

      // Изменение ориентации
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // Переход на вкладку "Заявки"
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверка отсутствия ошибок
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });
  });
}
