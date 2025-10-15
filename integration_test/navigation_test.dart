import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Tests', () {
    testWidgets('Bottom navigation bar navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test home navigation
      final homeButton = find.byIcon(Icons.home);
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pumpAndSettle();
        expect(find.text('Главная'), findsOneWidget);
      }

      // Test search navigation
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
        expect(find.text('Поиск'), findsOneWidget);
      }

      // Test bookings navigation
      final bookingsButton = find.byIcon(Icons.book_online);
      if (bookingsButton.evaluate().isNotEmpty) {
        await tester.tap(bookingsButton);
        await tester.pumpAndSettle();
        expect(find.text('Мои заявки'), findsOneWidget);
      }

      // Test chats navigation
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
        expect(find.text('Чаты'), findsOneWidget);
      }

      // Test profile navigation
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
        expect(find.text('Профиль'), findsOneWidget);
      }
    });

    testWidgets('Back button functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search screen
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Test back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.text('Главная'), findsOneWidget);
      }

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Test back button from profile
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.text('Главная'), findsOneWidget);
      }
    });

    testWidgets('App bar navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test app bar title
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // Test app bar actions
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();
      }

      // Test settings navigation
      final settingsButton = find.text('Настройки');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        expect(find.text('Настройки'), findsOneWidget);
      }
    });

    testWidgets('Drawer navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open drawer
      final drawerButton = find.byIcon(Icons.menu);
      if (drawerButton.evaluate().isNotEmpty) {
        await tester.tap(drawerButton);
        await tester.pumpAndSettle();
      }

      // Test drawer items
      final drawerItems = [
        'Главная',
        'Поиск',
        'Мои заявки',
        'Чаты',
        'Профиль',
        'Настройки',
        'Помощь',
      ];

      for (final item in drawerItems) {
        final drawerItem = find.text(item);
        if (drawerItem.evaluate().isNotEmpty) {
          await tester.tap(drawerItem);
          await tester.pumpAndSettle();
          // Verify navigation worked
          expect(find.text(item), findsOneWidget);
          break; // Test one navigation to avoid infinite loop
        }
      }
    });

    testWidgets('Deep link navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test navigation to specific specialist profile
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();

        // Should navigate to specialist profile
        expect(find.text('Профиль специалиста'), findsOneWidget);

        // Test back navigation
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
          expect(find.text('Главная'), findsOneWidget);
        }
      }
    });

    testWidgets('Tab navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search screen
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Test tab bar if present
      final tabBar = find.byType(TabBar);
      if (tabBar.evaluate().isNotEmpty) {
        final tabs = find.byType(Tab);
        if (tabs.evaluate().isNotEmpty) {
          await tester.tap(tabs.first);
          await tester.pumpAndSettle();

          await tester.tap(tabs.last);
          await tester.pumpAndSettle();
        }
      }
    });
  });
}

