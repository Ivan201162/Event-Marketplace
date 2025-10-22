import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/animated_splash_screen.dart';
import '../screens/auth/auth_check_screen.dart';
import '../screens/auth/login_screen_improved.dart';
import '../screens/auth/phone_auth_improved.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/profile/edit_profile_improved.dart';
import '../screens/profile/profile_screen_improved.dart';
import '../screens/chat/chat_list_screen_improved.dart';
import '../screens/chat/chat_screen_improved.dart';

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
        builder: (context, state) => const EditProfileImproved(),
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
          return ProfileScreenImproved(userId: userId);
        },
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
