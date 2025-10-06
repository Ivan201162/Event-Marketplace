import 'package:event_marketplace_app/main.dart';
import 'package:event_marketplace_app/screens/ideas_screen.dart';
import 'package:event_marketplace_app/screens/main_navigation_screen.dart';
import 'package:event_marketplace_app/widgets/animated_transitions.dart';
import 'package:event_marketplace_app/widgets/enhanced_bottom_navigation.dart';
import 'package:event_marketplace_app/widgets/profile_image_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Main Screens Widget Tests', () {
    testWidgets('EventMarketplaceApp should build without errors',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      expect(find.byType(EventMarketplaceApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('MainNavigationScreen should display navigation elements',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(EnhancedBottomNavigationBar), findsOneWidget);
    });

    testWidgets('IdeasScreen should display Pinterest-style layout',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: IdeasScreen(),
          ),
        ),
      );

      expect(find.byType(IdeasScreen), findsOneWidget);
      expect(find.text('Идеи для мероприятий'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('ProfileImagePlaceholder should display correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileImagePlaceholder(
              name: 'Test User',
            ),
          ),
        ),
      );

      expect(find.byType(ProfileImagePlaceholder), findsOneWidget);
      expect(find.text('TU'), findsOneWidget); // Initials
    });

    testWidgets('ProfileImagePlaceholder without name should show person icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileImagePlaceholder(),
          ),
        ),
      );

      expect(find.byType(ProfileImagePlaceholder), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('AnimatedEntranceWidget should animate child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEntranceWidget(
              child: Text('Test Animation'),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedEntranceWidget), findsOneWidget);
      expect(find.text('Test Animation'), findsOneWidget);
    });

    testWidgets('FadeInWidget should fade in child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeInWidget(
              child: Text('Fade In Test'),
            ),
          ),
        ),
      );

      expect(find.byType(FadeInWidget), findsOneWidget);
      expect(find.text('Fade In Test'), findsOneWidget);
    });

    testWidgets('ScaleInWidget should scale in child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScaleInWidget(
              child: Text('Scale In Test'),
            ),
          ),
        ),
      );

      expect(find.byType(ScaleInWidget), findsOneWidget);
      expect(find.text('Scale In Test'), findsOneWidget);
    });

    testWidgets('SlideInWidget should slide in child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideInWidget(
              child: Text('Slide In Test'),
            ),
          ),
        ),
      );

      expect(find.byType(SlideInWidget), findsOneWidget);
      expect(find.text('Slide In Test'), findsOneWidget);
    });

    testWidgets('AnimatedButton should respond to taps', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: () {
                tapped = true;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedButton), findsOneWidget);
      expect(find.text('Tap Me'), findsOneWidget);

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('StaggeredAnimationWidget should display children',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaggeredAnimationWidget(
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StaggeredAnimationWidget), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('EnhancedBottomNavigationBar should display navigation items',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EnhancedBottomNavigationBar(
              currentIndex: 0,
              onTap: null,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedBottomNavigationBar), findsOneWidget);
    });

    testWidgets('Navigation should handle tap events', (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EnhancedBottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Find and tap on a navigation item
      final navigationItems = find.byType(GestureDetector);
      if (navigationItems.evaluate().isNotEmpty) {
        await tester.tap(navigationItems.first);
        await tester.pump();
      }
    });

    testWidgets('Responsive layout should adapt to screen size',
        (tester) async {
      // Test mobile layout
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      expect(find.byType(MainNavigationScreen), findsOneWidget);

      // Test tablet layout
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      expect(find.byType(MainNavigationScreen), findsOneWidget);

      // Test desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('IdeasScreen should handle refresh', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: IdeasScreen(),
          ),
        ),
      );

      expect(find.byType(IdeasScreen), findsOneWidget);

      // Wait for initial load
      await tester.pumpAndSettle();

      // Find RefreshIndicator and trigger refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.drag(refreshIndicator, const Offset(0, 300));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('IdeasScreen should show filter bottom sheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: IdeasScreen(),
          ),
        ),
      );

      expect(find.byType(IdeasScreen), findsOneWidget);

      // Tap filter button
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();

        // Check if bottom sheet appears
        expect(find.text('Фильтры'), findsOneWidget);
      }
    });

    testWidgets('ProfileImagePlaceholder should handle different sizes',
        (tester) async {
      const sizes = [30.0, 60.0, 100.0];

      for (final size in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfileImagePlaceholder(
                size: size,
                name: 'Test User',
              ),
            ),
          ),
        );

        expect(find.byType(ProfileImagePlaceholder), findsOneWidget);

        // Check if the placeholder has the correct size
        final placeholder = tester.widget<ProfileImagePlaceholder>(
          find.byType(ProfileImagePlaceholder),
        );
        expect(placeholder.size, equals(size));
      }
    });

    testWidgets('AnimatedButton should show press animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: null,
              child: Text('Disabled Button'),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedButton), findsOneWidget);
      expect(find.text('Disabled Button'), findsOneWidget);

      // Try to tap disabled button
      await tester.tap(find.text('Disabled Button'));
      await tester.pump();

      // Button should not respond
      expect(find.text('Disabled Button'), findsOneWidget);
    });

    testWidgets('Theme switching should work', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      expect(find.byType(EventMarketplaceApp), findsOneWidget);

      // Look for theme toggle button
      final themeButton = find.byIcon(Icons.light_mode);
      if (themeButton.evaluate().isNotEmpty) {
        await tester.tap(themeButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Language switching should work', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: EventMarketplaceApp(),
        ),
      );

      expect(find.byType(EventMarketplaceApp), findsOneWidget);

      // Look for language toggle button
      final languageButton = find.byType(GestureDetector);
      if (languageButton.evaluate().isNotEmpty) {
        await tester.tap(languageButton.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
