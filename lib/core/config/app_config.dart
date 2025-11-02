/// Конфигурация приложения для production режима
class AppConfig {
  // Всегда false в production
  static const bool kUseDemoData = false;
  static const bool kAutoSeedOnStart = false;
  
  // UI флаги
  static const bool kShowFeedFab = false; // FAB в ленте отключен
  static const bool kShowFeedStories = true; // Stories в ленте включены (фильтр 24ч)
  static const bool kEnableFollowingFeed = true; // Лента по подпискам включена
  static const Duration kStoriesTtl = Duration(hours: 24);
  
  // Проверка production режима
  static bool get isProduction => !kUseDemoData && !kAutoSeedOnStart;
}

