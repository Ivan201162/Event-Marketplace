/// Константы маршрутов приложения
class AppRoutes {
  // Главная страница
  static const String home = '/home';

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
  static const String aiAssistant = '/ai-assistant';

  // Сторисы
  static const String storiesView = '/stories';

  // Поиск и избранное
  static const String search = '/search';
  static const String advancedSearch = '/advanced-search';
  static const String testFilters = '/test-filters';
  static const String testAvailability = '/test-availability';
  static const String specialistComparison = '/specialist-comparison';
  static const String photoStudios = '/photo-studios';
  static const String testPhotoStudios = '/test-photo-studios';
  static const String testMediaChat = '/test-media-chat';
  static const String testReminders = '/test-reminders';
  static const String paymentHistory = '/payment-history';
  static const String testPayments = '/test-payments';
  static const String favorites = '/favorites';

  // Заявки и календарь
  static const String myBookings = '/my-bookings';
  static const String bookingRequests = '/booking-requests';
  static const String calendar = '/calendar';
  static const String availabilityCalendar = '/availability-calendar';
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
