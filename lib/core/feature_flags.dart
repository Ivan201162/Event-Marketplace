/// Feature flags для безопасной миграции от моков к реальным данным
class FeatureFlags {
  // Основные данные
  static const bool useRealSpecialists = true;
  static const bool useRealHosts = true;
  static const bool useRealCategories = true;
  static const bool useRealReviews = true;
  static const bool useRealRequests = true;
  static const bool useRealFeedData = true;
  static const bool useRealIdeasData = true;

  // UI компоненты
  static const bool useRealCarousel = true;
  static const bool useRealCards = true;
  static const bool useRealProviders = true;

  // Сервисы
  static const bool useRealPayments = true;
  static const bool useRealMaps = true;
  static const bool useRealChats = true;
  static const bool shareEnabled = true;
  static const bool analyticsEnabled = true;
  static const bool calendarExportEnabled = true;

  // Debug/Dev (отключить в продакшене)
  static const bool enableDevSeeding = false;
  static const bool enableDebugScreens = false;
  static const bool enableDemoScreens = false;

  // Безопасность
  static const bool enableMockFallbacks =
      true; // Показывать fallback при ошибках реальных данных
  static const bool enableDataValidation =
      true; // Валидация данных перед отображением
}
