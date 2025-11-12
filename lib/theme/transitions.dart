/// MotionPageTransition для GoRouter
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:event_marketplace_app/theme/animations.dart';

/// Адаптивный переход для GoRouter
CustomTransitionPage motionPageBuilder<T extends Object?>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final platform = Theme.of(context).platform;
      
      switch (platform) {
        case TargetPlatform.iOS:
          final slideAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          
          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        
        case TargetPlatform.android:
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: AppMotion.standard));
          
          final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: AppMotion.smooth));
          
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        
        default:
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: AppMotion.standard));
          
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: AppMotion.standard));
          
          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
      }
    },
    transitionDuration: AppMotion.normal,
  );
}

