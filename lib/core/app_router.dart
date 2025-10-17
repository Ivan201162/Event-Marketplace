import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/feed/ui/create_post_screen.dart';
import '../features/profile/presentation/edit_customer_profile_screen.dart';
import '../providers/auth_providers.dart';
import '../screens/add_idea_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/create_booking_screen.dart';
import '../screens/create_chat_screen.dart';
import '../screens/dev_seed_screen.dart';
import '../screens/enhanced_notifications_screen.dart';
import '../screens/feed_screen.dart' as new_feed;
import '../screens/fixed_profile_screen.dart';
import '../screens/ideas_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/modern_auth_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/recommendations_screen.dart';
import '../screens/search_screen.dart' as screens;
import '../screens/settings_page.dart';
import '../screens/specialist_profile_edit_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/test_profile_screen.dart';
import '../screens/video_reels_viewer.dart';

/// Провайдер роутера приложения
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final currentPath = state.uri.path;

      // Если это начальный маршрут, всегда показываем splash screen
      if (currentPath == '/') {
        return null; // Показываем splash screen
      }

      final isAuthenticated = authState.when(
        data: (auth) => auth,
        loading: () => null, // Возвращаем null для состояния загрузки
        error: (_, __) => false,
      );

      // Если состояние аутентификации еще загружается, не перенаправляем
      if (isAuthenticated == null) {
        return null;
      }

      final isAuthRoute = currentPath == '/auth';
      final isMainRoute = currentPath == '/main';

      // Если пользователь аутентифицирован и находится на странице входа
      if (isAuthenticated && isAuthRoute) {
        return '/main';
      }

      // Если пользователь не аутентифицирован и не на странице входа
      if (!isAuthenticated && !isAuthRoute && !isMainRoute) {
        return '/auth';
      }

      return null; // Не перенаправляем
    },
    routes: [
      // Начальная страница (Splash Screen)
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Авторизация
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const ModernAuthScreen(),
      ),

      // Главный экран с навигацией
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      // Старый главный экран (для совместимости)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      // Лента активности
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const new_feed.FeedScreen(),
      ),

      // Создание поста
      GoRoute(
        path: '/create-post',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),

      // Поиск специалистов
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const screens.SearchScreen(),
      ),

      // Профиль специалиста
      GoRoute(
        path: '/specialist/:specialistId',
        name: 'specialist',
        builder: (context, state) {
          final specialistId = state.pathParameters['specialistId']!;
          return SpecialistProfileEditScreen(specialistId: specialistId);
        },
      ),

      // Бронирование
      GoRoute(
        path: '/booking/:specialistId',
        name: 'booking',
        builder: (context, state) {
          final specialistId = state.pathParameters['specialistId']!;
          return BookingScreen(specialistId: specialistId);
        },
      ),

      // Чат
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.uri.queryParameters['chatId'] ?? '';
          final otherParticipantId = state.uri.queryParameters['otherParticipantId'] ?? '';
          final otherParticipantName =
              state.uri.queryParameters['otherParticipantName'] ?? 'Пользователь';
          final otherParticipantAvatar = state.uri.queryParameters['otherParticipantAvatar'];
          return ChatScreen(
            chatId: chatId,
          );
        },
      ),

      // Профиль
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'] ?? 'current_user_id';
          final isOwnProfile = userId == 'current_user_id';
          return FixedProfileScreen(
            userId: userId,
            isOwnProfile: isOwnProfile,
          );
        },
      ),

      // Настройки
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Редактирование профиля
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditCustomerProfileScreen(
          customerId: 'current_user',
        ),
      ),

      // Календарь
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),

      // Мои заявки
      GoRoute(
        path: '/my-bookings',
        name: 'my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),

      // Создание заявки
      GoRoute(
        path: '/create_booking',
        name: 'create_booking',
        builder: (context, state) => const CreateBookingScreen(),
      ),

      // Создание чата
      GoRoute(
        path: '/create_chat',
        name: 'create_chat',
        builder: (context, state) => const CreateChatScreen(),
      ),

      // Рекомендации
      GoRoute(
        path: '/recommendations',
        name: 'recommendations',
        builder: (context, state) => const RecommendationsScreen(),
      ),

      // Идеи
      GoRoute(
        path: '/ideas',
        name: 'ideas',
        builder: (context, state) => const IdeasScreen(),
      ),

      // Добавление идеи
      GoRoute(
        path: '/add-idea',
        name: 'add-idea',
        builder: (context, state) => const AddIdeaScreen(),
      ),

      // Детали идеи
      GoRoute(
        path: '/idea/:ideaId',
        name: 'idea-detail',
        builder: (context, state) {
          // TODO(developer): Загрузить идею по ID
          return const IdeasScreen(); // Временная заглушка
        },
      ),

      // Просмотр видео
      GoRoute(
        path: '/video-reels',
        name: 'video-reels',
        builder: (context, state) => const VideoReelsViewer(),
      ),

      // Поделиться идеей
      GoRoute(
        path: '/share-idea/:ideaId',
        name: 'share-idea',
        builder: (context, state) {
          // TODO(developer): Загрузить идею по ID
          return const IdeasScreen(); // Временная заглушка
        },
      ),

      // Уведомления
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const EnhancedNotificationsScreen(),
      ),

      // Аналитика
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),

      // Редактирование профиля специалиста
      GoRoute(
        path: '/specialist/:specialistId/edit',
        name: 'specialist-edit',
        builder: (context, state) {
          final specialistId = state.pathParameters['specialistId']!;
          return SpecialistProfileEditScreen(specialistId: specialistId);
        },
      ),

      // Тестирование профиля
      GoRoute(
        path: '/test-profile',
        name: 'test-profile',
        builder: (context, state) => const TestProfileScreen(),
      ),

      // Управление тестовыми данными (только в debug режиме)
      GoRoute(
        path: '/dev-seed',
        name: 'dev-seed',
        builder: (context, state) => const DevSeedScreen(),
      ),
    ],
  );
});
