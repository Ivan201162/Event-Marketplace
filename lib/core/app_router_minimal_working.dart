import 'package:event_marketplace_app/screens/animated_splash_screen.dart';
import 'package:event_marketplace_app/screens/auth/auth_check_screen.dart';
import 'package:event_marketplace_app/screens/auth/login_screen_improved.dart';
import 'package:event_marketplace_app/screens/auth/phone_auth_improved.dart';
import 'package:event_marketplace_app/screens/chat/chat_list_screen_improved.dart';
import 'package:event_marketplace_app/screens/chat/chat_screen_improved.dart';
import 'package:event_marketplace_app/screens/ideas/create_idea_screen.dart';
import 'package:event_marketplace_app/screens/main_navigation_screen.dart';
import 'package:event_marketplace_app/screens/monetization/monetization_screen.dart';
import 'package:event_marketplace_app/screens/notifications/notifications_screen.dart';
import 'package:event_marketplace_app/screens/profile/edit_profile_advanced.dart';
import 'package:event_marketplace_app/screens/profile/profile_screen_advanced.dart';
import 'package:event_marketplace_app/screens/requests/create_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Минимальный рабочий роутер без проблемных компонентов
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash экран
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const AnimatedSplashScreen(),
      ),

      // Проверка авторизации
      GoRoute(
        path: '/auth-check',
        name: 'auth-check',
        builder: (context, state) => const AuthCheckScreen(),
      ),

      // Аутентификация
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreenImproved(),
      ),

      // Аутентификация по телефону
      GoRoute(
        path: '/phone-auth',
        name: 'phone-auth',
        builder: (context, state) => const PhoneAuthImproved(),
      ),

      // Главное приложение
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
      ),

      // Редактирование профиля
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileAdvanced(),
      ),

      // Чаты
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatListScreenImproved(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatScreenImproved(chatId: chatId);
        },
      ),

      // Профиль пользователя
      GoRoute(
        path: '/profile/:userId',
        name: 'profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreenAdvanced(userId: userId);
        },
      ),

      // Монетизация
      GoRoute(
        path: '/monetization',
        name: 'monetization',
        builder: (context, state) => const MonetizationScreen(),
      ),

      // Создание заявки
      GoRoute(
        path: '/create-request',
        name: 'create-request',
        builder: (context, state) => const CreateRequestScreen(),
      ),

      // Создание идеи
      GoRoute(
        path: '/create-idea',
        name: 'create-idea',
        builder: (context, state) => const CreateIdeaScreen(),
      ),

      // Уведомления
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      debugPrint('🚨 Router error for path: ${state.uri.path}');
      debugPrint('Error: ${state.error}');

      // Fallback к главному экрану
      return const MainNavigationScreen();
    },
  );
});
