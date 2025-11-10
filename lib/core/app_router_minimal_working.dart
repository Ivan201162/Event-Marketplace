import 'package:event_marketplace_app/core/auth_gate.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/screens/animated_splash_screen.dart';
import 'package:event_marketplace_app/screens/splash/splash_event_screen.dart';
import 'package:event_marketplace_app/screens/auth/auth_check_screen.dart';
import 'package:event_marketplace_app/screens/auth/login_screen_improved.dart';
import 'package:event_marketplace_app/screens/auth/phone_auth_improved.dart';
import 'package:event_marketplace_app/screens/auth/role_selection_screen.dart';
import 'package:event_marketplace_app/screens/auth/register_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/auth/onboarding_complete_profile_screen.dart';
import 'package:event_marketplace_app/screens/auth/post_google_onboarding.dart';
import 'package:event_marketplace_app/screens/auth/role_name_city_onboarding.dart';
import 'package:event_marketplace_app/screens/chat/chat_list_screen_improved.dart';
import 'package:event_marketplace_app/screens/chat/chat_screen_improved.dart';
import 'package:event_marketplace_app/screens/ideas/create_idea_screen.dart';
import 'package:event_marketplace_app/screens/feed/feed_screen_full.dart';
import 'package:event_marketplace_app/screens/posts/create_post_screen.dart';
import 'package:event_marketplace_app/screens/reels/create_reel_screen.dart';
import 'package:event_marketplace_app/screens/create_story_screen.dart';
import 'package:event_marketplace_app/screens/legal/privacy_policy_screen.dart';
import 'package:event_marketplace_app/screens/legal/terms_of_use_screen.dart';
import 'package:event_marketplace_app/screens/main_navigation_screen.dart';
import 'package:event_marketplace_app/screens/monetization/monetization_screen.dart';
import 'package:event_marketplace_app/screens/notifications/notifications_screen.dart';
import 'package:event_marketplace_app/screens/notifications/notifications_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/profile/edit_profile_advanced.dart';
import 'package:event_marketplace_app/screens/profile/profile_edit_screen.dart';
import 'package:event_marketplace_app/screens/profile/profile_screen_advanced.dart';
import 'package:event_marketplace_app/screens/profile/profile_full_screen.dart';
import 'package:event_marketplace_app/screens/profile/specialist_price_editor.dart';
import 'package:event_marketplace_app/screens/profile/profile_booking_settings.dart';
import 'package:event_marketplace_app/screens/booking/specialist_calendar_screen.dart';
import 'package:event_marketplace_app/screens/requests/create_request_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/search/search_screen_enhanced.dart';
import 'package:event_marketplace_app/screens/settings/settings_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Минимальный рабочий роутер без проблемных компонентов
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash-event', // Start with splash screen
    debugLogDiagnostics: true,
    observers: [
      _AnalyticsRouteObserver(),
    ],
    routes: [
      // Splash экран (новый с EVENT)
      GoRoute(
        path: '/splash-event',
        name: 'splash-event',
        builder: (context, state) => const SplashEventScreen(),
      ),
      // Старый splash (для совместимости)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const AnimatedSplashScreen(),
      ),

      // Проверка авторизации
      GoRoute(
        path: '/auth-gate',
        name: 'auth-gate',
        builder: (context, state) => const AuthGate(),
      ),
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

      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreenEnhanced(),
      ),

      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Onboarding: после Google Sign-In
      GoRoute(
        path: '/onboarding/post-google',
        name: 'post-google-onboarding',
        builder: (context, state) => const PostGoogleOnboardingScreen(),
      ),
      
      // Onboarding: роль + ФИО + город
      GoRoute(
        path: '/onboarding/role-name-city',
        name: 'role-name-city-onboarding',
        builder: (context, state) => const RoleNameCityOnboardingScreen(),
      ),
      
      // Onboarding: дозаполнение профиля
      GoRoute(
        path: '/onboarding/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const OnboardingCompleteProfileScreen(),
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
        builder: (context, state) => const ProfileEditScreen(),
      ),
      
      // Редактор прайсов специалиста
      GoRoute(
        path: '/profile/prices',
        name: 'specialist-prices',
        builder: (context, state) => const SpecialistPriceEditor(),
      ),
      GoRoute(
        path: '/profile/booking-settings',
        name: 'booking-settings',
        builder: (context, state) => const ProfileBookingSettingsScreen(),
      ),
      
      // Календарь бронирования специалиста
      GoRoute(
        path: '/booking/calendar/:specialistId',
        name: 'specialist-calendar',
        builder: (context, state) {
          final specialistId = state.pathParameters['specialistId']!;
          final name = state.uri.queryParameters['name'] ?? 'Специалист';
          return SpecialistCalendarScreen(
            specialistId: specialistId,
            specialistName: name,
          );
        },
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
          // Если userId == 'me', используем текущего пользователя
          if (userId == 'me') {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const LoginScreenImproved();
            }
            return ProfileFullScreen(userId: currentUser.uid);
          }
          return ProfileFullScreen(userId: userId);
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
        path: '/requests/create',
        name: 'create-request',
        builder: (context, state) => const CreateRequestScreenEnhanced(),
      ),
      GoRoute(
        path: '/create-request',
        name: 'create-request-legacy',
        builder: (context, state) => const CreateRequestScreenEnhanced(),
      ),

      // Поиск специалистов
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreenEnhanced(),
      ),

      // Настройки
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Создание идеи
      GoRoute(
        path: '/create-idea',
        name: 'create-idea',
        builder: (context, state) => const CreateIdeaScreen(),
      ),

      // Лента
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreenFull(),
      ),

      // Создание контента
      GoRoute(
        path: '/create/post',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/create/reel',
        name: 'create-reel',
        builder: (context, state) => const CreateReelScreen(),
      ),
      GoRoute(
        path: '/create/story',
        name: 'create-story',
        builder: (context, state) => const CreateStoryScreen(),
      ),

      // Уведомления
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreenEnhanced(),
      ),

      // Юридические документы
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-use',
        name: 'terms-of-use',
        builder: (context, state) => const TermsOfUseScreen(),
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

/// Наблюдатель для логирования навигации в Firebase Analytics
class _AnalyticsRouteObserver extends NavigatorObserver {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRouteChange(route.settings.name ?? 'unknown', 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRouteChange(route.settings.name ?? 'unknown', 'pop');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logRouteChange(newRoute.settings.name ?? 'unknown', 'replace');
    }
  }

  void _logRouteChange(String routeName, String action) {
    _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': routeName,
        'action': action,
      },
    );
  }
}
