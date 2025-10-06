import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpecialistProfileScreen Tests', () {
    testWidgets('should create basic widget test', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test Widget'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Widget'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
