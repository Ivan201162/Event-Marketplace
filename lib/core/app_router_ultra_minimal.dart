import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/main_navigation_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/ideas/ideas_screen.dart';
import '../screens/ideas/create_idea_screen.dart';
import '../screens/posts/create_post_screen.dart';
import '../screens/search/search_screen.dart';

/// Ультра-минимальный роутер для сборки без ошибок
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Главная навигация
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
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

      // Лента и идеи
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/ideas',
        name: 'ideas',
        builder: (context, state) => const IdeasScreen(),
      ),
      GoRoute(
        path: '/ideas/create',
        name: 'create-idea',
        builder: (context, state) => const CreateIdeaScreen(),
      ),
      GoRoute(
        path: '/posts/create',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),

      // Поиск
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
});
