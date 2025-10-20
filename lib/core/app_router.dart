import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/auth_check_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/search/search_screen.dart';

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // No redirect logic here - handled by AuthCheckScreen
      return null;
    },
    routes: [
      // Auth check route
      GoRoute(
        path: '/',
        name: 'auth-check',
        builder: (context, state) => const AuthCheckScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Search route
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      // Fallback error route
      GoRoute(
        path: '/error',
        name: 'error',
        builder: (context, state) => const _RouterErrorScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      debugPrint('🚨 Router error for path: ${state.uri.path}');
      debugPrint('Error: ${state.error}');
      
      // Fallback to main navigation screen
      return const MainNavigationScreen();
    },
  );
});

/// Simple fallback error screen
class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибка маршрута')),
      body: const Center(child: Text('Неверный путь.')),
    );
  }
}