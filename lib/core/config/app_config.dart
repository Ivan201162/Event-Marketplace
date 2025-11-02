/// Конфигурация приложения для production режима
class AppConfig {
  static const bool kProduction = true;
  static const bool kUseDemoData = false;
  static const bool kAutoSeedOnStart = false;
  static const bool kShowFeedFab = false;
  static const bool kShowFeedStories = true; // Stories only in feed
  static const bool kEnableFollowingFeed = true; // feed = followed users only
  static const Duration kStoriesTtl = Duration(hours: 24);
  
  static bool get isProduction => kProduction && !kUseDemoData && !kAutoSeedOnStart;
}

