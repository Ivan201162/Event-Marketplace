/// Premium Motion Design System
/// V7.4: Motion transitions and animations

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AppMotion - центральный класс для всех анимаций
class AppMotion {
  // Длительности
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Кривые
  static const Curve standard = Curves.easeInOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeOutCubic;
}

/// Fade transition
class FadeTransition extends PageRouteBuilder {
  final Widget page;
  
  FadeTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: AppMotion.normal,
        );
}

/// Slide transition
class SlideTransition extends PageRouteBuilder {
  final Widget page;
  final Offset begin;
  final Offset end;
  
  SlideTransition({
    required this.page,
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: begin,
              end: end,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppMotion.standard,
            ));
            
            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
          transitionDuration: AppMotion.normal,
        );
}

/// Scale transition
class ScaleTransition extends PageRouteBuilder {
  final Widget page;
  final double begin;
  final double end;
  
  ScaleTransition({
    required this.page,
    this.begin = 0.8,
    this.end = 1.0,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(
              begin: begin,
              end: end,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppMotion.smooth,
            ));
            
            return ScaleTransition(
              scale: scaleAnimation,
              child: child,
            );
          },
          transitionDuration: AppMotion.normal,
        );
}

/// Depth transition (3D effect)
class DepthTransition extends PageRouteBuilder {
  final Widget page;
  
  DepthTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          },
          transitionDuration: AppMotion.normal,
        );
}

/// Composed transition (fade + scale + slide)
class ComposedTransition extends PageRouteBuilder {
  final Widget page;
  
  ComposedTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(parent: animation, curve: AppMotion.standard));
            
            final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
                .animate(CurvedAnimation(parent: animation, curve: AppMotion.smooth));
            
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.02),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: AppMotion.standard));
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: AppMotion.normal,
        );
}

/// MotionPageTransition - адаптивный переход в зависимости от платформы
class MotionPageTransition extends PageRouteBuilder {
  final Widget page;
  final TargetPlatform platform;
  
  MotionPageTransition({
    required this.page,
    this.platform = TargetPlatform.android,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (platform) {
              case TargetPlatform.iOS:
                // iOS: cupertino slide + parallax
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
                // Android: fade + scale
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
                // Web: fadeDown
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

