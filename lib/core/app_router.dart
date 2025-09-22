import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/event_providers.dart';
import '../screens/about_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/register_screen.dart';
import '../screens/booking_form_screen.dart';
import '../screens/booking_requests_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/chats_demo_screen.dart';
import '../screens/create_event_screen.dart';
import '../screens/create_review_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/help_screen.dart';
import '../screens/home_screen.dart';
import '../screens/monitoring_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/my_events_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/profile_page.dart';
import '../screens/recommendations_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_page.dart';
import '../screens/specialist_profile_screen.dart';

/// Wrapper для загрузки события по ID
class EventDetailScreenWrapper extends ConsumerWidget {
  const EventDetailScreenWrapper({
    super.key,
    required this.eventId,
  });
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(eventProvider(eventId)).when(
            data: (event) {
              if (event == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Событие не найдено')),
                  body: const Center(child: Text('Событие не найдено')),
                );
              }
              return EventDetailScreen(event: event);
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Scaffold(
              appBar: AppBar(title: const Text('Ошибка')),
              body: Center(child: Text('Ошибка загрузки: $error')),
            ),
          );
}

/// Централизованная система роутинга приложения
class AppRouter {
  static const String home = '/';
  static const String search = '/search';
  static const String myEvents = '/my-events';
  static const String profile = '/profile';
  static const String myBookings = '/my-bookings';
  static const String bookingRequests = '/booking-requests';
  static const String auth = '/auth';
  static const String register = '/register';
  static const String debug = '/debug';
  static const String recommendations = '/recommendations';
  static const String chats = '/chats';
  static const String adminPanel = '/admin-panel';
  static const String eventDetail = '/event/:id';
  static const String specialistProfile = '/specialist/:id';
  static const String createEvent = '/create-event';
  static const String bookingForm = '/booking-form/:specialistId';
  static const String createReview = '/create-review/:targetId';
  static const String chat = '/chat/:chatId';
  static const String settings = '/settings';
  static const String analytics = '/analytics';
  static const String payments = '/payments';
  static const String notifications = '/notifications';
  static const String help = '/help';
  static const String about = '/about';
  static const String monitoring = '/monitoring';

  /// Создание GoRouter конфигурации
  static GoRouter createRouter() => GoRouter(
        initialLocation: home,
        routes: [
          // Главная страница
          GoRoute(
            path: home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Поиск
          GoRoute(
            path: search,
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),

          // Мои события
          GoRoute(
            path: myEvents,
            name: 'myEvents',
            builder: (context, state) => const MyEventsScreen(),
          ),

          // Профиль
          GoRoute(
            path: profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),

          // Мои бронирования
          GoRoute(
            path: myBookings,
            name: 'myBookings',
            builder: (context, state) => const MyBookingsScreen(),
          ),

          // Заявки на бронирование
          GoRoute(
            path: bookingRequests,
            name: 'bookingRequests',
            builder: (context, state) => const BookingRequestsScreen(),
          ),

          // Аутентификация
          GoRoute(
            path: auth,
            name: 'auth',
            builder: (context, state) => const AuthScreen(),
          ),

          // Регистрация
          GoRoute(
            path: register,
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),

          // Отладка (только в debug режиме)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            GoRoute(
              path: debug,
              name: 'debug',
              builder: (context, state) => const DebugScreen(),
            ),

          // Рекомендации
          GoRoute(
            path: recommendations,
            name: 'recommendations',
            builder: (context, state) => const RecommendationsScreen(),
          ),

          // Чаты
          GoRoute(
            path: chats,
            name: 'chats',
            builder: (context, state) => const ChatsDemoScreen(),
          ),

          // Админ-панель (только в debug режиме)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            GoRoute(
              path: adminPanel,
              name: 'adminPanel',
              builder: (context, state) => const AdminPanelScreen(),
            ),

          // Детали события
          GoRoute(
            path: eventDetail,
            name: 'eventDetail',
            builder: (context, state) {
              final eventId = state.pathParameters['id'];
              return EventDetailScreenWrapper(eventId: eventId ?? '');
            },
          ),

          // Профиль специалиста
          GoRoute(
            path: specialistProfile,
            name: 'specialistProfile',
            builder: (context, state) {
              final specialistId = state.pathParameters['id'];
              return SpecialistProfileScreen(specialistId: specialistId ?? '');
            },
          ),

          // Создание события
          GoRoute(
            path: createEvent,
            name: 'createEvent',
            builder: (context, state) => const CreateEventScreen(),
          ),

          // Форма бронирования
          GoRoute(
            path: bookingForm,
            name: 'bookingForm',
            builder: (context, state) {
              final specialistId = state.pathParameters['specialistId'];
              return BookingFormScreen(specialistId: specialistId ?? '');
            },
          ),

          // Создание отзыва
          GoRoute(
            path: createReview,
            name: 'createReview',
            builder: (context, state) {
              final targetId = state.pathParameters['targetId'];
              return CreateReviewScreen(targetId: targetId ?? '');
            },
          ),

          // Чат
          GoRoute(
            path: chat,
            name: 'chat',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId'];
              return ChatScreen(chatId: chatId ?? '');
            },
          ),

          // Настройки
          GoRoute(
            path: settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),

          // Аналитика
          GoRoute(
            path: analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),

          // Платежи
          GoRoute(
            path: payments,
            name: 'payments',
            builder: (context, state) => const PaymentsScreen(),
          ),

          // Уведомления
          GoRoute(
            path: notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),

          // Помощь
          GoRoute(
            path: help,
            name: 'help',
            builder: (context, state) => const HelpScreen(),
          ),

          // О приложении
          GoRoute(
            path: about,
            name: 'about',
            builder: (context, state) => const AboutScreen(),
          ),

          // Мониторинг
          GoRoute(
            path: monitoring,
            name: 'monitoring',
            builder: (context, state) => const MonitoringScreen(),
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Ошибка навигации'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Страница не найдена: ${state.uri}',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(home),
                  child: const Text('На главную'),
                ),
              ],
            ),
          ),
        ),
      );

  /// Навигация к деталям события
  static void goToEventDetail(BuildContext context, String eventId) {
    context.go('/event/$eventId');
  }

  /// Навигация к профилю специалиста
  static void goToSpecialistProfile(BuildContext context, String specialistId) {
    context.go('/specialist/$specialistId');
  }

  /// Навигация к форме бронирования
  static void goToBookingForm(BuildContext context, String specialistId) {
    context.go('/booking-form/$specialistId');
  }

  /// Навигация к созданию отзыва
  static void goToCreateReview(BuildContext context, String targetId) {
    context.go('/create-review/$targetId');
  }

  /// Навигация к чату
  static void goToChat(BuildContext context, String chatId) {
    context.go('/chat/$chatId');
  }

  /// Навигация назад
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(home);
    }
  }

  /// Получение текущего маршрута
  static String getCurrentRoute(BuildContext context) =>
      GoRouterState.of(context).uri.toString();

  /// Проверка, является ли текущий маршрут активным
  static bool isCurrentRoute(BuildContext context, String route) =>
      getCurrentRoute(context) == route;
}
