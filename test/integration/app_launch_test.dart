import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch Tests', () {
    testWidgets('should launch app without errors', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should display initial screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for common UI elements
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}



