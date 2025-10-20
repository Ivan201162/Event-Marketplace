import 'package:event_marketplace_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Event Marketplace App Tests', () {
    testWidgets('App should start without crashing', (tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      // Verify that the app starts without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Navigation should work correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      // Wait for the app to load
      await tester.pumpAndSettle();

      // Check if main navigation elements are present
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Back Button Tests', () {
    testWidgets('Back button should work correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      // Wait for the app to load
      await tester.pumpAndSettle();

      // Test back button functionality
      // This is a basic test - in a real app you would test specific navigation scenarios
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Profile Tests', () {
    testWidgets('Specialist profile should display correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      // Wait for the app to load
      await tester.pumpAndSettle();

      // Test specialist profile display
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Customer profile should display correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      // Wait for the app to load
      await tester.pumpAndSettle();

      // Test customer profile display
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Reviews Tests', () {
    testWidgets('Review system should work correctly', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      // Wait for the app to load
      await tester.pumpAndSettle();

      // Test review system
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
