import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/auth_screen.dart';
import '../screens/auth/phone_verification_screen.dart';
import '../screens/calendar_reminders_screen.dart';
import '../screens/chats_screen.dart';
import '../screens/enhanced_chat_screen.dart';
import '../screens/enhanced_feed_screen.dart';
import '../screens/enhanced_ideas_screen.dart';
import '../screens/enhanced_order_screen.dart';
import '../screens/enhanced_profile_screen.dart';
import '../screens/event_organizer_screen.dart';
import '../screens/home_screen.dart';
import '../screens/optimized_main_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/promotions_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/test_data_management_screen.dart';
import '../screens/testing_monitoring_screen.dart';

/// Улучшенный роутер с поддержкой свайпов и анимаций
class EnhancedRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const SplashScreen(),
          state,
          transitionType: TransitionType.fade,
        ),
      ),

      // Authentication
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const AuthScreen(),
          state,
          transitionType: TransitionType.slideLeft,
        ),
      ),

      // Phone Verification
      GoRoute(
        path: '/phone-verification',
        name: 'phone-verification',
        pageBuilder: (context, state) => _buildPageWithTransition(
          PhoneVerificationScreen(
            phoneNumber: state.extra as String? ?? '',
          ),
          state,
          transitionType: TransitionType.slideLeft,
        ),
      ),

      // Main App
      GoRoute(
        path: '/main',
        name: 'main',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const OptimizedMainScreen(),
          state,
          transitionType: TransitionType.fade,
        ),
      ),

      // Home
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const HomeScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Feed
      GoRoute(
        path: '/feed',
        name: 'feed',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const EnhancedFeedScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Requests
      GoRoute(
        path: '/requests',
        name: 'requests',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const RequestsScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Chats
      GoRoute(
        path: '/chats',
        name: 'chats',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const ChatsScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Ideas
      GoRoute(
        path: '/ideas',
        name: 'ideas',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const EnhancedIdeasScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const ProfileScreen(),
          state,
          transitionType: TransitionType.slideRight,
        ),
      ),

      // Promotions
      GoRoute(
        path: '/promos',
        name: 'promos',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const PromotionsScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const SettingsScreen(),
          state,
          transitionType: TransitionType.slideRight,
        ),
      ),

      // Specialist Profile
      GoRoute(
        path: '/specialist/:id',
        name: 'specialist-profile',
        pageBuilder: (context, state) => _buildPageWithTransition(
          EnhancedProfileScreen(
            specialistId: state.pathParameters['id'],
          ),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Order Details
      GoRoute(
        path: '/order/:id',
        name: 'order-details',
        pageBuilder: (context, state) => _buildPageWithTransition(
          EnhancedOrderScreen(
            orderId: state.pathParameters['id']!,
          ),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Chat Details
      GoRoute(
        path: '/chat/:id',
        name: 'chat-details',
        pageBuilder: (context, state) => _buildPageWithTransition(
          EnhancedChatScreen(
            chatId: state.pathParameters['id']!,
          ),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Testing and Monitoring
      GoRoute(
        path: '/testing',
        name: 'testing',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const TestingMonitoringScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Test Data Management
      GoRoute(
        path: '/test-data',
        name: 'test-data',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const TestDataManagementScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Event Organizers
      GoRoute(
        path: '/organizers',
        name: 'organizers',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const EventOrganizerScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),

      // Calendar and Reminders
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        pageBuilder: (context, state) => _buildPageWithTransition(
          const CalendarRemindersScreen(),
          state,
          transitionType: TransitionType.slideUp,
        ),
      ),
    ],
    errorPageBuilder: (context, state) => _buildPageWithTransition(
      Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: ${state.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
      state,
      transitionType: TransitionType.fade,
    ),
  );

  static GoRouter get router => _router;

  /// Создать страницу с переходом
  static Page<void> _buildPageWithTransition(
    Widget child,
    GoRouterState state, {
    required TransitionType transitionType,
  }) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            _buildTransition(
          animation,
          secondaryAnimation,
          child,
          transitionType,
        ),
      );

  /// Создать переход
  static Widget _buildTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    TransitionType transitionType,
  ) {
    switch (transitionType) {
      case TransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case TransitionType.slideLeft:
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: child,
        );
      case TransitionType.slideRight:
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case TransitionType.slideUp:
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case TransitionType.scale:
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(
              begin: 0,
              end: 1,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: child,
        );
      case TransitionType.rotation:
        return RotationTransition(
          turns: animation.drive(
            Tween<double>(
              begin: 0,
              end: 1,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: child,
        );
    }
  }
}

/// Типы переходов
enum TransitionType {
  fade,
  slideLeft,
  slideRight,
  slideUp,
  scale,
  rotation,
}

/// Экран ошибки
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    required this.error,
  });

  final String error;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
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
              const Text(
                'Произошла ошибка',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/main');
                },
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      );
}
