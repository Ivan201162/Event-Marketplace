import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Basic Navigation Tests', () {
    testWidgets('should launch app successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should display main navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for navigation elements
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
