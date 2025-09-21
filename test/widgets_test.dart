import 'package:event_marketplace_app/widgets/language_selector.dart';
import 'package:event_marketplace_app/ui/responsive/responsive_widgets.dart';
import 'package:event_marketplace_app/widgets/theme_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Switch Tests', () {
    testWidgets('should display theme switch widget', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSwitch(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что виджет отображается
      expect(find.byType(ThemeSwitch), findsOneWidget);
      expect(find.text('Тема'), findsOneWidget);
    });

    testWidgets('should show theme options when tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSwitch(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем на виджет
      await tester.tap(find.byType(ThemeSwitch));
      await tester.pumpAndSettle();

      // Проверяем, что диалог открылся
      expect(find.text('Выберите тему'), findsOneWidget);
      expect(find.text('Светлая'), findsOneWidget);
      expect(find.text('Темная'), findsOneWidget);
      expect(find.text('Системная'), findsOneWidget);
    });

    testWidgets('should change theme when option is selected', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThemeSwitch(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем на виджет
      await tester.tap(find.byType(ThemeSwitch));
      await tester.pumpAndSettle();

      // Выбираем темную тему
      await tester.tap(find.text('Темная'));
      await tester.pumpAndSettle();

      // Проверяем, что диалог закрылся
      expect(find.text('Выберите тему'), findsNothing);
    });

    testWidgets('should display compact theme switch', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactThemeSwitch(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что компактный виджет отображается
      expect(find.byType(CompactThemeSwitch), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('should display current theme display', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CurrentThemeDisplay(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что виджет отображается
      expect(find.byType(CurrentThemeDisplay), findsOneWidget);
    });

    testWidgets('should display quick theme toggle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickThemeToggle(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что виджет отображается
      expect(find.byType(QuickThemeToggle), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });
  });

  group('Language Selector Tests', () {
    testWidgets('should display language selector widget', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LanguageSelector(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что виджет отображается
      expect(find.byType(LanguageSelector), findsOneWidget);
      expect(find.text('Язык'), findsOneWidget);
    });

    testWidgets('should show language options when tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LanguageSelector(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем на виджет
      await tester.tap(find.byType(LanguageSelector));
      await tester.pumpAndSettle();

      // Проверяем, что диалог открылся
      expect(find.text('Язык'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('should change language when option is selected',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LanguageSelector(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем на виджет
      await tester.tap(find.byType(LanguageSelector));
      await tester.pumpAndSettle();

      // Выбираем английский язык
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Проверяем, что диалог закрылся
      expect(find.text('Язык'), findsNothing);
    });

    testWidgets('should display compact language selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactLanguageSelector(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что компактный виджет отображается
      expect(find.byType(CompactLanguageSelector), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('should display current language display', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CurrentLanguageDisplay(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что виджет отображается
      expect(find.byType(CurrentLanguageDisplay), findsOneWidget);
    });
  });

  group('Responsive Widgets Tests', () {
    testWidgets('should display mobile widget on small screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для мобильного устройства
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      // Проверяем, что отображается мобильный виджет
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should display tablet widget on medium screen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для планшета
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // Проверяем, что отображается планшетный виджет
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should display desktop widget on large screen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для десктопа
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpAndSettle();

      // Проверяем, что отображается десктопный виджет
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets('should fallback to mobile widget when tablet is not provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobile: Text('Mobile'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для планшета
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // Проверяем, что отображается мобильный виджет как fallback
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('should fallback to tablet widget when desktop is not provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для десктопа
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpAndSettle();

      // Проверяем, что отображается планшетный виджет как fallback
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('should display responsive container with different padding',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              padding: EdgeInsets.all(16),
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для мобильного устройства
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      // Проверяем, что контент отображается
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('should display responsive grid with different columns',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveGrid(
              crossAxisCount: 2,
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для мобильного устройства
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      // Проверяем, что все элементы отображаются
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('should display responsive list with different items per row',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveList(
              children: [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      // Устанавливаем размер экрана для мобильного устройства
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      // Проверяем, что все элементы отображаются
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });
  });
}
