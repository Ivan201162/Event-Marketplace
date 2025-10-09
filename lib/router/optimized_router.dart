import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_test_data_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/phone_verification_screen.dart';
import '../screens/optimized_main_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/promotions_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/animated_page_transitions.dart';

/// Оптимизированный роутер с анимированными переходами
class OptimizedRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Сплэш-экран
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Главный экран
      GoRoute(
        path: '/main',
        name: 'main',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OptimizedMainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              AnimatedPageTransitions.fadeScaleTransition(
            child: child,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
          ),
        ),
      ),

      // Экран авторизации
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              AnimatedPageTransitions.slideFromRight(
            child: child,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
          ),
        ),
      ),

      // Экран подтверждения SMS кода
      GoRoute(
        path: '/phone-verification',
        name: 'phone-verification',
        pageBuilder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PhoneVerificationScreen(phoneNumber: phoneNumber),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    AnimatedPageTransitions.slideFromRight(
              child: child,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
            ),
          );
        },
      ),

      // Экран промоакций
      GoRoute(
        path: '/promos',
        name: 'promos',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PromotionsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              AnimatedPageTransitions.slideFromRight(
            child: child,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
          ),
        ),
      ),

      // Экран профиля
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              AnimatedPageTransitions.slideFromRight(
            child: child,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
          ),
        ),
      ),

      // Экран добавления тестовых данных
      GoRoute(
        path: '/add-test-data',
        name: 'add-test-data',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddTestDataScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              AnimatedPageTransitions.slideFromRight(
            child: child,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
          ),
        ),
      ),

      // GoRoute(
      //   path: '/register',
      //   name: 'register',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const RegisterScreen(),
      //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //       return AnimatedPageTransitions.slideFromRight(
      //         child: child,
      //         animation: animation,
      //         secondaryAnimation: secondaryAnimation,
      //       );
      //     },
      //   ),
      // ),
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
  );

  static GoRouter get router => _router;
}

/// Экран ошибки
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Страница не найдена',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Попробуйте вернуться на главную страницу',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/main'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      );
}

/// Утилиты для навигации
class NavigationUtils {
  /// Переход с анимацией
  static Future<T?> pushWithAnimation<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      Navigator.of(context).push(
        AnimatedPageRoute<T>(
          page: page,
          transitionType: transitionType,
          duration: duration,
        ),
      );

  /// Замена с анимацией
  static Future<T?> pushReplacementWithAnimation<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      Navigator.of(context).pushReplacement(
        AnimatedPageRoute<T>(
          page: page,
          transitionType: transitionType,
          duration: duration,
        ),
      );

  /// Переход к корню с анимацией
  static Future<T?> pushAndRemoveUntilWithAnimation<T>(
    BuildContext context,
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.fadeScale,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      Navigator.of(context).pushAndRemoveUntil(
        AnimatedPageRoute<T>(
          page: page,
          transitionType: transitionType,
          duration: duration,
        ),
        (route) => false,
      );

  /// Показать диалог с анимацией
  static Future<T?> showAnimatedDialog<T>(
    BuildContext context,
    Widget dialog, {
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      showGeneralDialog<T>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        transitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) => dialog,
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            AnimatedPageTransitions.fadeScaleTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        ),
      );

  /// Показать bottom sheet с анимацией
  static Future<T?> showAnimatedBottomSheet<T>(
    BuildContext context,
    Widget bottomSheet, {
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        transitionAnimationController: AnimationController(
          duration: duration,
          vsync: Navigator.of(context),
        ),
        builder: (context) => AnimatedPageTransitions.slideFromBottom(
          child: bottomSheet,
          animation: ModalRoute.of(context)!.animation!,
          secondaryAnimation: ModalRoute.of(context)!.secondaryAnimation!,
        ),
      );
}

/// Расширения для GoRouter
extension GoRouterExtensions on GoRouter {
  /// Переход с анимацией
  void goWithAnimation(
    String location, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
  }) {
    go(location);
  }

  /// Push с анимацией
  Future<T?> pushWithAnimation<T>(
    String location, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
  }) =>
      push<T>(location);

  /// Push replacement с анимацией
  Future<T?> pushReplacementWithAnimation<T>(
    String location, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
  }) =>
      pushReplacement<T>(location);
}

/// Провайдер для роутера
final routerProvider = Provider<GoRouter>((ref) => OptimizedRouter.router);
