import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/main_navigation_screen_enhanced.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/profile/profile_screen_enhanced.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/feed/feed_screen_improved.dart';
import '../screens/ideas/ideas_screen.dart';
import '../screens/ideas/create_idea_screen.dart';
import '../screens/requests/create_request_screen.dart';
import '../screens/posts/create_post_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/help/help_screen.dart';
import '../screens/search/search_screen_enhanced.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/monetization/monetization_screen.dart';
import '../screens/loading/loading_screen.dart';
import '../services/navigation_service.dart';
import '../services/session_service.dart';

/// Улучшенный роутер с анимациями и унифицированной навигацией
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Главная навигация
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainNavigationScreenEnhanced(),
      ),
      
      // Аутентификация
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const LoginScreen(),
          state,
          transitionType: PageTransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const RegisterScreen(),
          state,
          transitionType: PageTransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const OnboardingScreen(),
          state,
          transitionType: PageTransitionType.fade,
        ),
      ),
      
      // Профиль
      GoRoute(
        path: '/profile/:userId',
        name: 'profile',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return _buildPageWithAnimation(
            ProfileScreenEnhanced(userId: userId),
            state,
            transitionType: PageTransitionType.slideUp,
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const EditProfileScreen(),
          state,
          transitionType: PageTransitionType.slideLeft,
        ),
      ),
      
      // Лента и идеи
      GoRoute(
        path: '/feed',
        name: 'feed',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const FeedScreenImproved(),
          state,
          transitionType: PageTransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: '/ideas',
        name: 'ideas',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const IdeasScreen(),
          state,
          transitionType: PageTransitionType.slideRight,
        ),
      ),
      GoRoute(
        path: '/ideas/create',
        name: 'create-idea',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const CreateIdeaScreen(),
          state,
          transitionType: PageTransitionType.slideUp,
        ),
      ),
      GoRoute(
        path: '/posts/create',
        name: 'create-post',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const CreatePostScreen(),
          state,
          transitionType: PageTransitionType.slideUp,
        ),
      ),
      
      // Заявки
      GoRoute(
        path: '/create-request',
        name: 'create-request',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const CreateRequestScreen(),
          state,
          transitionType: PageTransitionType.slideUp,
        ),
      ),
      
      // Настройки и помощь
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const SettingsScreen(),
          state,
          transitionType: PageTransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const HelpScreen(),
          state,
          transitionType: PageTransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const SearchScreenEnhanced(),
          state,
          transitionType: PageTransitionType.slideUp,
        ),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const NotificationsScreen(),
          state,
          transitionType: PageTransitionType.slideLeft,
        ),
      ),
      GoRoute(
        path: '/monetization',
        name: 'monetization',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const MonetizationScreen(),
          state,
          transitionType: PageTransitionType.slideLeft,
        ),
      ),
      
      // Загрузка
      GoRoute(
        path: '/loading',
        name: 'loading',
        pageBuilder: (context, state) => _buildPageWithAnimation(
          const LoadingScreen(),
          state,
          transitionType: PageTransitionType.fade,
        ),
      ),
    ],
    errorBuilder: (context, state) => _buildErrorPage(context, state),
    redirect: (context, state) => _handleRedirect(context, state),
  );
});

/// Типы анимаций переходов
enum PageTransitionType {
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
  fade,
  scale,
  rotation,
}

/// Создать страницу с анимацией
Page<void> _buildPageWithAnimation(
  Widget child,
  GoRouterState state, {
  required PageTransitionType transitionType,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _buildTransition(animation, secondaryAnimation, child, transitionType);
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

/// Создать анимацию перехода
Widget _buildTransition(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
  PageTransitionType transitionType,
) {
  switch (transitionType) {
    case PageTransitionType.slideLeft:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    case PageTransitionType.slideRight:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    case PageTransitionType.slideUp:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    case PageTransitionType.slideDown:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    case PageTransitionType.fade:
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    case PageTransitionType.scale:
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        )),
        child: child,
      );
    case PageTransitionType.rotation:
      return RotationTransition(
        turns: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
  }
}

/// Обработать редирект
Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
  try {
    // Проверяем, есть ли активная сессия
    final hasSession = await SessionService.hasActiveSession();
    final currentPath = state.uri.path;
    
    // Если пользователь не авторизован и не на экранах входа
    if (!hasSession && !_isAuthPath(currentPath)) {
      NavigationService.logNavigation(currentPath, '/login', data: {'reason': 'no_session'});
      return '/login';
    }
    
    // Если пользователь авторизован и на экране входа, перенаправляем на главную
    if (hasSession && _isAuthPath(currentPath)) {
      NavigationService.logNavigation(currentPath, '/main', data: {'reason': 'already_authenticated'});
      return '/main';
    }
    
    return null; // Нет редиректа
  } catch (e) {
    debugPrint('❌ Error in redirect handler: $e');
    return '/main'; // Fallback к главной странице
  }
}

/// Проверить, является ли путь экраном аутентификации
bool _isAuthPath(String path) {
  return path == '/login' || path == '/register' || path == '/onboarding';
}

/// Создать страницу ошибки
Widget _buildErrorPage(BuildContext context, GoRouterState state) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Ошибка'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => NavigationService.safePop(context),
      ),
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
            'Страница не найдена',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Путь: ${state.uri.path}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => NavigationService.safeGo(context, '/main'),
            child: const Text('На главную'),
          ),
        ],
      ),
    ),
  );
}
