import 'package:event_marketplace_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('should display home screen title', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Главная'), findsOneWidget);
    });

    testWidgets('should display welcome message', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(
          find.text('Добро пожаловать в Event Marketplace!'), findsOneWidget);
    });

    testWidgets('should display featured specialists section', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Рекомендуемые специалисты'), findsOneWidget);
    });

    testWidgets('should display recent bookings section', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Последние заявки'), findsOneWidget);
    });

    testWidgets('should display quick actions section', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Быстрые действия'), findsOneWidget);
    });

    testWidgets('should display search button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display my bookings button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Мои заявки'), findsOneWidget);
    });

    testWidgets('should display calendar button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Календарь'), findsOneWidget);
    });

    testWidgets('should display payments button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Платежи'), findsOneWidget);
    });

    testWidgets('should display notifications button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Уведомления'), findsOneWidget);
    });

    testWidgets('should display reviews button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Отзывы'), findsOneWidget);
    });

    testWidgets('should display analytics button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Аналитика'), findsOneWidget);
    });

    testWidgets('should display profile button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('should display settings button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Настройки'), findsOneWidget);
    });

    testWidgets('should display help button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Помощь'), findsOneWidget);
    });

    testWidgets('should display about button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('О приложении'), findsOneWidget);
    });

    testWidgets('should display contact button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Контакты'), findsOneWidget);
    });

    testWidgets('should display privacy button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Конфиденциальность'), findsOneWidget);
    });

    testWidgets('should display terms button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Условия использования'), findsOneWidget);
    });

    testWidgets('should display version info', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomeScreen())));

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Версия 1.0.0'), findsOneWidget);
    });
  });
}
