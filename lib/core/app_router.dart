import 'package:event_marketplace_app/screens/about_screen.dart';
import 'package:event_marketplace_app/screens/auth/auth_check_screen.dart';
import 'package:event_marketplace_app/screens/auth/forgot_password_screen.dart';
import 'package:event_marketplace_app/screens/auth/login_screen.dart';
import 'package:event_marketplace_app/screens/auth/onboarding_screen.dart';
import 'package:event_marketplace_app/screens/auth/phone_auth_screen.dart';
import 'package:event_marketplace_app/screens/auth/phone_verification_screen.dart';
import 'package:event_marketplace_app/screens/chat/chat_list_screen.dart';
import 'package:event_marketplace_app/screens/chat/chat_screen.dart';
import 'package:event_marketplace_app/screens/feed/feed_screen.dart';
import 'package:event_marketplace_app/screens/ideas/add_idea_screen.dart';
import 'package:event_marketplace_app/screens/ideas/create_idea_screen.dart';
import 'package:event_marketplace_app/screens/ideas/ideas_screen.dart';
import 'package:event_marketplace_app/screens/main_navigation_screen.dart';
import 'package:event_marketplace_app/screens/notifications/notifications_screen.dart';
import 'package:event_marketplace_app/screens/posts/create_post_screen.dart';
import 'package:event_marketplace_app/screens/profile/edit_profile_screen.dart';
import 'package:event_marketplace_app/screens/profile/profile_screen.dart';
import 'package:event_marketplace_app/screens/requests/requests_screen.dart';
import 'package:event_marketplace_app/screens/search/search_screen.dart';
import 'package:event_marketplace_app/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          builder: (context, state) => const AuthCheckScreen(),),

      // Auth routes
      GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Phone auth routes
      GoRoute(
        path: '/phone-auth',
        name: 'phone-auth',
        builder: (context, state) => const PhoneAuthScreen(),
      ),

      GoRoute(
        path: '/phone-verification',
        name: 'phone-verification',
        builder: (context, state) {
          final phoneNumber = state.extra as String?;
          if (phoneNumber == null) {
            return const Scaffold(
                body: Center(child: Text('Ошибка: номер телефона не найден')),);
          }
          return PhoneVerificationScreen(phoneNumber: phoneNumber);
        },
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
          builder: (context, state) => const SearchScreen(),),

      // Profile routes
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Ideas routes
      GoRoute(
        path: '/ideas/add',
        name: 'add-idea',
        builder: (context, state) => const AddIdeaScreen(),
      ),

      GoRoute(
        path: '/ideas/create',
        name: 'create-idea',
        builder: (context, state) => const CreateIdeaScreen(),
      ),

      // Posts routes
      GoRoute(
        path: '/posts/create',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),

      // Notifications route
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Chat routes
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            chatId: chatId,
            otherUserId: extra?['otherUserId'],
            otherUserName: extra?['otherUserName'],
            otherUserAvatar: extra?['otherUserAvatar'],
          );
        },
      ),

      // Feed routes
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
      ),

      // Requests routes
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const RequestsScreen(),
      ),

      // Ideas routes
      GoRoute(
        path: '/ideas',
        name: 'ideas',
        builder: (context, state) => const IdeasScreen(),
      ),

      // Profile routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Settings routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // About route
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
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
