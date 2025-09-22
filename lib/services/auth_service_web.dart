// Условный импорт для веб-платформы
import 'demo_auth_service.dart' as demo;

/// Веб-версия сервиса аутентификации
class WebAuthService {
  static demo.DemoAuthService get demoAuth => demo.DemoAuthService();
}
