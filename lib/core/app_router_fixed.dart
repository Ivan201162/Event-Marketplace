import 'package:event_marketplace_app/screens/animated_splash_screen.dart';
import 'package:event_marketplace_app/screens/auth/auth_check_screen.dart';
import 'package:event_marketplace_app/screens/auth/login_screen.dart';
import 'package:event_marketplace_app/screens/auth/onboarding_screen.dart';
import 'package:event_marketplace_app/screens/auth/register_screen.dart';
import 'package:event_marketplace_app/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Исправленный роутер приложения
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
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Главное приложение
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
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
