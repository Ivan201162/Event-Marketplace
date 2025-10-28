// Условный импорт для веб-платформы
import 'package:event_marketplace_app/services/demo_auth_service.dart' as demo;

/// Веб-версия сервиса аутентификации
class WebAuthService {
  static demo.DemoAuthService get demoAuth => demo.DemoAuthService();
}
