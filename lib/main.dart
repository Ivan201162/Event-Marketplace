import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_routes.dart';
import 'core/error_handler.dart';
import 'core/extensions/build_context_extensions.dart';
import 'core/feature_flags.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/content_management_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/integration_management_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/security_management_screen.dart';
import 'screens/settings_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/specialist_profile_screen.dart';
import 'screens/user_management_screen.dart';
import 'services/ab_testing_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';
import 'services/caching_service.dart';
import 'services/content_management_service.dart';
import 'services/integration_service.dart';
import 'services/notification_service.dart';
import 'services/performance_service.dart';
import 'services/reporting_service.dart';
import 'services/security_service.dart';
import 'services/settings_service.dart';
import 'services/user_management_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Инициализация Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Инициализация Performance Monitoring
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  // Инициализация SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Инициализация сервисов
  await _initializeServices();

  runApp(
    ProviderScope(
      child: EventMarketplaceApp(prefs: prefs),
    ),
  );
}

/// Инициализация всех сервисов приложения
Future<void> _initializeServices() async {
  try {
    // Основные сервисы
    await AuthService().initialize();
    await NotificationService().initialize();
    await AnalyticsService().initialize();
    PerformanceService().initialize();

    // Сервисы управления
    await SecurityService().initialize();
    await IntegrationService().initialize();
    await ContentManagementService().initialize();
    await UserManagementService().initialize();
    await SettingsService().initialize();

    // Сервисы оптимизации
    await CachingService().initialize();
    await BackupService().initialize();
    await ReportingService().initialize();
    await ABTestingService().initialize();

    print('All services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
    FirebaseCrashlytics.instance.recordError(e, null);
  }
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({
    super.key,
    required this.prefs,
  });
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Тема
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Локализация
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
        Locale('kk', 'KZ'),
      ],
      locale: const Locale('ru', 'RU'),

      // Роутинг
      routerConfig: router,

      // Обработка ошибок
      builder: (context, child) => ErrorHandler(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Провайдер роутера
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Главная страница
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Аутентификация
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Профили
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.specialistProfile}/:id',
        name: 'specialist-profile',
        builder: (context, state) {
          final specialistId = state.pathParameters['id'];
          return SpecialistProfileScreen(specialistId: specialistId);
        },
      ),

      // Бронирование
      GoRoute(
        path: '${AppRoutes.booking}/:specialistId',
        name: 'booking',
        builder: (context, state) {
          final specialistId = state.pathParameters['specialistId'];
          return BookingScreen(specialistId: specialistId);
        },
      ),

      // Чат
      GoRoute(
        path: '${AppRoutes.chat}/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'];
          return ChatScreen(chatId: chatId);
        },
      ),

      // Поиск и избранное
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),

      // Уведомления и настройки
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Административные панели
      GoRoute(
        path: AppRoutes.adminPanel,
        name: 'admin-panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityManagement,
        name: 'security-management',
        builder: (context, state) => const SecurityManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.integrationManagement,
        name: 'integration-management',
        builder: (context, state) => const IntegrationManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.contentManagement,
        name: 'content-management',
        builder: (context, state) => const ContentManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsManagement,
        name: 'settings-management',
        builder: (context, state) => const SettingsManagementScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Ошибка'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Страница не найдена',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Путь: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Провайдер сервиса аутентификации
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Провайдер режима темы
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier());

/// Провайдер флагов функций
final featureFlagsProvider = Provider<FeatureFlags>((ref) => FeatureFlags());

/// Провайдер сервиса уведомлений
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// Провайдер сервиса аналитики
final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => AnalyticsService());

/// Провайдер сервиса производительности
final performanceServiceProvider =
    Provider<PerformanceService>((ref) => PerformanceService());

/// Провайдер сервиса безопасности
final securityServiceProvider =
    Provider<SecurityService>((ref) => SecurityService());

/// Провайдер сервиса интеграций
final integrationServiceProvider =
    Provider<IntegrationService>((ref) => IntegrationService());

/// Провайдер сервиса управления контентом
final contentManagementServiceProvider =
    Provider<ContentManagementService>((ref) => ContentManagementService());

/// Провайдер сервиса управления пользователями
final userManagementServiceProvider =
    Provider<UserManagementService>((ref) => UserManagementService());

/// Провайдер сервиса настроек
final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService());

/// Провайдер сервиса кэширования
final cachingServiceProvider =
    Provider<CachingService>((ref) => CachingService());

/// Провайдер сервиса бэкапов
final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

/// Провайдер сервиса отчетов
final reportingServiceProvider =
    Provider<ReportingService>((ref) => ReportingService());

/// Провайдер сервиса A/B тестирования
final abTestingServiceProvider =
    Provider<ABTestingService>((ref) => ABTestingService());
