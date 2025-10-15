/// Конфигурация Supabase для Event Marketplace
/// 
/// ВАЖНО: Замените значения на ваши реальные данные из Supabase проекта
class SupabaseConfig {
  // URL вашего Supabase проекта
  // Найти в Settings → API → Project URL
  // ЗАМЕНИТЕ НА ВАШ РЕАЛЬНЫЙ URL!
  static const String url = 'https://your-project-id.supabase.co';
  
  // Anon public key (безопасен для клиентского кода)
  // Найти в Settings → API → anon public
  // ЗАМЕНИТЕ НА ВАШ РЕАЛЬНЫЙ КЛЮЧ!
  static const String anonKey = 'your-anon-key-here';
  
  // Service role key (только для серверных операций!)
  // Найти в Settings → API → service_role
  // НЕ ИСПОЛЬЗУЙТЕ в клиентском коде!
  static const String serviceRoleKey = 'your-service-role-key-here';
  
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
  static bool get isConfigured {
    return SupabaseConfig.url != 'https://your-project-id.supabase.co' &&
           SupabaseConfig.anonKey != 'your-anon-key-here';
  }
  
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
