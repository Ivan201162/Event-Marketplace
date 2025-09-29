import 'package:event_marketplace_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  testWidgets('App loads correctly', (tester) async {
    // Initialize FlutterSecureStorage for testing
    const storage = FlutterSecureStorage();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        child: EventMarketplaceApp(storage: storage),
      ),
    );

    // Verify that the app loads
    expect(find.byType(EventMarketplaceApp), findsOneWidget);
  });
}
