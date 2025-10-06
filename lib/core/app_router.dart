import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/feed/ui/create_post_screen.dart';
import '../features/feed/ui/feed_screen.dart';
import '../features/profile/presentation/edit_customer_profile_screen.dart';
import '../providers/auth_providers.dart';
import '../screens/analytics_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/dev_seed_screen.dart';
import '../screens/ideas_screen.dart';
import '../screens/main_navigation_screen.dart' as main_nav;
import '../screens/modern_auth_screen.dart';
import '../screens/my_bookings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart' as screens;
import '../screens/recommendations_screen.dart';
import '../screens/search_screen.dart' as screens;
import '../screens/specialist_profile_edit_screen.dart';
import '../screens/specialist_profile_screen.dart';
import '../screens/test_profile_screen.dart';

/// Провайдер роутера приложения
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.when(
        data: (auth) => auth,
        loading: () => false,
        error: (_, __) => false,
      );

      final currentPath = state.uri.path;
      final isAuthRoute = currentPath == '/auth';
      final isInitialRoute = currentPath == '/';

      // Если пользователь авторизован и на начальной странице или на странице авторизации
      if (isAuthenticated && (isInitialRoute || isAuthRoute)) {
        return '/home';
      }

      // Если пользователь не авторизован и не на странице авторизации
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      return null;
    },
    routes: [
      // Начальная страница (заглушка для редиректа)
      GoRoute(
        path: '/',
        name: 'initial',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),

      // Авторизация
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const ModernAuthScreen(),
      ),

      // Главный экран с навигацией
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const main_nav.MainNavigationScreen(),
      ),

      // Лента активности
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
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
          return SpecialistProfileScreen(specialistId: specialistId);
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
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final otherParticipantId =
              state.uri.queryParameters['otherParticipantId'] ?? '';
          final otherParticipantName =
              state.uri.queryParameters['otherParticipantName'] ??
                  'Пользователь';
          final otherParticipantAvatar =
              state.uri.queryParameters['otherParticipantAvatar'];
          return ChatScreen(
            chatId: chatId,
            otherParticipantId: otherParticipantId,
            otherParticipantName: otherParticipantName,
            otherParticipantAvatar: otherParticipantAvatar,
          );
        },
      ),

      // Профиль
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          final userId =
              state.uri.queryParameters['userId'] ?? 'current_user_id';
          final isOwnProfile = userId == 'current_user_id';
          return screens.ProfileScreen(
            userId: userId,
            isOwnProfile: isOwnProfile,
          );
        },
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

      // Уведомления
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
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
