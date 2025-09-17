import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/providers/theme_provider.dart';
import 'package:event_marketplace_app/core/app_styles.dart';

void main() {
  group('Theme Tests', () {
    testWidgets('should display light theme by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestThemeWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что светлая тема активна
      final theme = Theme.of(tester.element(find.byType(TestThemeWidget)));
      expect(theme.brightness, equals(Brightness.light));
    });

    testWidgets('should switch to dark theme when toggled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestThemeWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Находим кнопку переключения темы
      final toggleButton = find.byType(ElevatedButton);
      expect(toggleButton, findsOneWidget);

      // Нажимаем на кнопку
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Проверяем, что тема изменилась на темную
      final theme = Theme.of(tester.element(find.byType(TestThemeWidget)));
      expect(theme.brightness, equals(Brightness.dark));
    });

    testWidgets('should maintain theme state across rebuilds',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestThemeWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переключаем на темную тему
      final toggleButton = find.byType(ElevatedButton);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Перестраиваем виджет
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestThemeWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что тема сохранилась
      final theme = Theme.of(tester.element(find.byType(TestThemeWidget)));
      expect(theme.brightness, equals(Brightness.dark));
    });

    testWidgets('should have correct color scheme in light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestThemeWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(TestThemeWidget)));
      final colorScheme = theme.colorScheme;

      // Проверяем основные цвета светлой темы
      expect(colorScheme.brightness, equals(Brightness.light));
      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.surface, isNotNull);
      expect(colorScheme.background, isNotNull);
    });

    testWidgets('should have correct color scheme in dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TestThemeWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переключаем на темную тему
      final toggleButton = find.byType(ElevatedButton);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(TestThemeWidget)));
      final colorScheme = theme.colorScheme;

      // Проверяем основные цвета темной темы
      expect(colorScheme.brightness, equals(Brightness.dark));
      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.surface, isNotNull);
      expect(colorScheme.background, isNotNull);
    });
  });

  group('App Styles Tests', () {
    test('should have correct primary color', () {
      expect(AppStyles.primaryColor, equals(const Color(0xFF1976D2)));
    });

    test('should have correct secondary color', () {
      expect(AppStyles.secondaryColor, equals(const Color(0xFF03DAC6)));
    });

    test('should have correct error color', () {
      expect(AppStyles.errorColor, equals(const Color(0xFFB00020)));
    });

    test('should have correct warning color', () {
      expect(AppStyles.warningColor, equals(const Color(0xFFFF9800)));
    });

    test('should have correct success color', () {
      expect(AppStyles.successColor, equals(const Color(0xFF4CAF50)));
    });

    test('should have correct info color', () {
      expect(AppStyles.infoColor, equals(const Color(0xFF2196F3)));
    });

    test('should have correct border radius values', () {
      expect(AppStyles.radiusSmall, equals(8.0));
      expect(AppStyles.radiusMedium, equals(12.0));
      expect(AppStyles.radiusLarge, equals(16.0));
      expect(AppStyles.radiusXLarge, equals(24.0));
    });

    test('should have correct padding values', () {
      expect(AppStyles.paddingSmall, equals(8.0));
      expect(AppStyles.paddingMedium, equals(16.0));
      expect(AppStyles.paddingLarge, equals(24.0));
      expect(AppStyles.paddingXLarge, equals(32.0));
    });

    test('should have correct icon sizes', () {
      expect(AppStyles.iconSmall, equals(16.0));
      expect(AppStyles.iconMedium, equals(24.0));
      expect(AppStyles.iconLarge, equals(32.0));
      expect(AppStyles.iconXLarge, equals(48.0));
    });

    test('should have correct button heights', () {
      expect(AppStyles.buttonHeightSmall, equals(32.0));
      expect(AppStyles.buttonHeightMedium, equals(48.0));
      expect(AppStyles.buttonHeightLarge, equals(56.0));
    });

    test('should have correct breakpoints', () {
      expect(AppStyles.mobileBreakpoint, equals(600.0));
      expect(AppStyles.tabletBreakpoint, equals(900.0));
      expect(AppStyles.desktopBreakpoint, equals(1200.0));
    });

    test('should have correct animation durations', () {
      expect(
          AppStyles.shortAnimation, equals(const Duration(milliseconds: 200)));
      expect(
          AppStyles.mediumAnimation, equals(const Duration(milliseconds: 300)));
      expect(
          AppStyles.longAnimation, equals(const Duration(milliseconds: 500)));
    });

    test('should have correct curves', () {
      expect(AppStyles.defaultCurve, equals(Curves.easeInOut));
      expect(AppStyles.bounceCurve, equals(Curves.elasticOut));
      expect(AppStyles.fastCurve, equals(Curves.fastOutSlowIn));
    });
  });

  group('Responsive Tests', () {
    testWidgets('should detect mobile screen size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveTestWidget(),
        ),
      );

      // Устанавливаем размер экрана для мобильного устройства
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should detect tablet screen size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveTestWidget(),
        ),
      );

      // Устанавливаем размер экрана для планшета
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should detect desktop screen size',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveTestWidget(),
        ),
      );

      // Устанавливаем размер экрана для десктопа
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpAndSettle();

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);
    });
  });
}

class TestThemeWidget extends ConsumerWidget {
  const TestThemeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: Column(
        children: [
          Text('Current theme: ${themeMode.name}'),
          ElevatedButton(
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
            child: const Text('Toggle Theme'),
          ),
        ],
      ),
    );
  }
}

class ResponsiveTestWidget extends StatelessWidget {
  const ResponsiveTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (AppStyles.isMobile(context))
            const Text('Mobile')
          else if (AppStyles.isTablet(context))
            const Text('Tablet')
          else if (AppStyles.isDesktop(context))
            const Text('Desktop'),
        ],
      ),
    );
  }
}
