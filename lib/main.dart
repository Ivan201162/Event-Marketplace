import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'core/performance_optimizer.dart';
import 'firebase_options.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'services/test_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация оптимизатора производительности
  await PerformanceOptimizer.initialize();

  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Инициализация сервиса уведомлений
  await NotificationService().initialize();

  // Инициализация сервиса напоминаний
  await ReminderService().initialize();

  // Инициализация тестовых данных
  await _initializeTestData();

  runApp(const ProviderScope(child: EventMarketplaceApp()));
}

/// Инициализация тестовых данных
Future<void> _initializeTestData() async {
  try {
    final testDataService = TestDataService();
    final hasData = await testDataService.hasTestData();

    if (!hasData) {
      print('Загружаем тестовые данные...');
      await testDataService.populateAll();
    } else {
      print('Тестовые данные уже загружены');
    }
  } catch (e) {
    print('Ошибка при инициализации тестовых данных: $e');
  }
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
        Locale('kk'),
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
