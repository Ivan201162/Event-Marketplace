import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:event_marketplace_app/main.dart';

void main() {
  group('Localization Tests', () {
    testWidgets('should display Russian text when locale is ru',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ru', 'RU'),
          home: const TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что русский текст отображается
      expect(find.text('Маркетплейс Событий'), findsOneWidget);
      expect(find.text('Добро пожаловать'), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('Регистрация'), findsOneWidget);
    });

    testWidgets('should display English text when locale is en',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: const Locale('en', 'US'),
          home: const TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что английский текст отображается
      expect(find.text('Event Marketplace'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('should fallback to English when unsupported locale is used',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: const Locale('fr', 'FR'), // Неподдерживаемый язык
          home: const TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что используется английский как fallback
      expect(find.text('Event Marketplace'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });

    testWidgets('should switch language when locale changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ru', 'RU'),
          home: const TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем русский текст
      expect(find.text('Маркетплейс Событий'), findsOneWidget);

      // Меняем локаль на английский
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: const Locale('en', 'US'),
          home: const TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем английский текст
      expect(find.text('Event Marketplace'), findsOneWidget);
    });
  });

  group('Localization Keys Tests', () {
    testWidgets('should have all required localization keys',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          locale: const Locale('en', 'US'),
          home: const LocalizationKeysTestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие всех ключей локализации
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });
  });
}

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          Text(l10n.appTitle),
          Text(l10n.welcome),
          Text(l10n.login),
          Text(l10n.register),
        ],
      ),
    );
  }
}

class LocalizationKeysTestWidget extends StatelessWidget {
  const LocalizationKeysTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          Text(l10n.home),
          Text(l10n.search),
          Text(l10n.events),
          Text(l10n.profile),
          Text(l10n.settings),
          Text(l10n.notifications),
          Text(l10n.help),
          Text(l10n.about),
        ],
      ),
    );
  }
}
