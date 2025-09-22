/// Константы маршрутов приложения
class AppRoutes {
  // Главная страница
  static const String home = '/';

  // Аутентификация
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Профили
  static const String profile = '/profile';
  static const String specialistProfile = '/specialist';

  // Бронирование
  static const String booking = '/booking';

  // Чат
  static const String chat = '/chat';

  // Поиск и избранное
  static const String search = '/search';
  static const String favorites = '/favorites';
  
  // Заявки и календарь
  static const String myBookings = '/my-bookings';
  static const String calendar = '/calendar';
  static const String recommendations = '/recommendations';

  // Уведомления и настройки
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  // Административные панели
  static const String adminPanel = '/admin';
  static const String securityManagement = '/admin/security';
  static const String integrationManagement = '/admin/integrations';
  static const String contentManagement = '/admin/content';
  static const String userManagement = '/admin/users';
  static const String settingsManagement = '/admin/settings';

  // Дополнительные маршруты
  static const String about = '/about';
  static const String help = '/help';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String contact = '/contact';

  // API маршруты (для веб-версии)
  static const String apiHealth = '/api/health';
  static const String apiVersion = '/api/version';
  static const String apiStatus = '/api/status';
}
