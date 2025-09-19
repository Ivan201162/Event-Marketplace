import 'package:event_marketplace_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads correctly', (tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        child: EventMarketplaceApp(prefs: prefs),
      ),
    );

    // Verify that the app loads
    expect(find.byType(EventMarketplaceApp), findsOneWidget);
  });
}
