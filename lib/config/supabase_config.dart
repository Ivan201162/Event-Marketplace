/// Конфигурация Supabase для Event Marketplace
/// 
/// ВАЖНО: Замените значения на ваши реальные данные из Supabase проекта
class SupabaseConfig {
  // URL вашего Supabase проекта
  // Найти в Settings → API → Project URL
  // ЗАМЕНИТЕ НА ВАШ РЕАЛЬНЫЙ URL!
  static const String url = 'https://eventmarketplace.supabase.co';
  
  // Anon public key (безопасен для клиентского кода)
  // Найти в Settings → API → anon public
  // ЗАМЕНИТЕ НА ВАШ РЕАЛЬНЫЙ КЛЮЧ!
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2ZW50bWFya2V0cGxhY2UiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTczNDU2NzIwMCwiZXhwIjoyMDUwMTQzMjAwfQ.example-key';
  
  // Service role key (только для серверных операций!)
  // Найти в Settings → API → service_role
  // НЕ ИСПОЛЬЗУЙТЕ в клиентском коде!
  static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2ZW50bWFya2V0cGxhY2UiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzM0NTY3MjAwLCJleHAiOjIwNTAxNDMyMDB9.example-service-key';
  
  // Настройки для разработки
  static const bool isDevelopment = true;
  
  // URL для редиректов (для веб-версии)
  static const String redirectUrl = 'io.supabase.eventmarketplace://login-callback/';
  
  // Настройки Storage
  static const String avatarsBucket = 'avatars';
  static const String postsBucket = 'posts';
  
  // Лимиты для пагинации
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Настройки Realtime
  static const Duration reconnectInterval = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;
}

/// Валидация конфигурации
class SupabaseConfigValidator {
  static bool get isConfigured =>
      SupabaseConfig.url != 'https://your-project-id.supabase.co' &&
      SupabaseConfig.anonKey != 'your-anon-key-here';
  
  static List<String> get missingConfigs {
    final List<String> missing = [];
    
    if (SupabaseConfig.url == 'https://your-project-id.supabase.co') {
      missing.add('Supabase URL');
    }
    
    if (SupabaseConfig.anonKey == 'your-anon-key-here') {
      missing.add('Supabase Anon Key');
    }
    
    return missing;
  }
  
  static void validate() {
    if (!isConfigured) {
      throw Exception(
        'Supabase не настроен! Отсутствуют: ${missingConfigs.join(', ')}. '
        'См. SUPABASE_SETUP_GUIDE.md для инструкций по настройке.'
      );
    }
  }
}
