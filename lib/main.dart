import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'core/enhanced_router.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/monetization_provider.dart';
// import 'services/firestore_test_data_service.dart';
// import 'services/notification_service.dart';
// import 'services/analytics_service.dart';
// import 'services/growth_pack_integration_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Exception catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  // Инициализация Supabase
  try {
    // Проверяем конфигурацию
    SupabaseConfigValidator.validate();
    
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: SupabaseConfig.isDevelopment,
    );
    
    debugPrint('✅ Supabase initialized successfully');
  } on Exception catch (e) {
    debugPrint('❌ Supabase initialization error: $e');
    // Приложение может работать без Supabase (только Firebase функции)
  }
  
  // Инициализация тестовых данных (только в режиме разработки)
  // try {
  //   await FirestoreTestDataService.initializeTestData();
  //   debugPrint('✅ Test data initialized successfully');
  // } on Exception catch (e) {
  //   debugPrint('❌ Test data initialization error: $e');
  // }
  
  // Инициализация сервисов
  // try {
  //   await NotificationService.initialize();
  //   await AnalyticsService.initialize();
  //   debugPrint('✅ Services initialized successfully');
  // } on Exception catch (e) {
  //   debugPrint('❌ Services initialization error: $e');
  // }
  
  // Инициализация Growth Pack
  // try {
  //   final growthPackService = GrowthPackIntegrationService();
  //   await growthPackService.initializeGrowthPack();
  //   debugPrint('✅ Growth Pack initialized successfully');
  // } on Exception catch (e) {
  //   debugPrint('❌ Growth Pack initialization error: $e');
  // }
  
  runApp(const ProviderScope(child: EventMarketplaceApp()));
}

class EventMarketplaceApp extends ConsumerWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'Event Marketplace',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
