import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/debug_log.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashEventScreen extends StatefulWidget {
  const SplashEventScreen({super.key});

  @override
  State<SplashEventScreen> createState() => _SplashEventScreenState();
}

class _SplashEventScreenState extends State<SplashEventScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _firebaseReady = false;
  bool _authStateReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    debugLog("SPLASH: Firebase init start");
    try {
      try {
        Firebase.app();
        debugLog("SPLASH: Firebase init ok");
        setState(() {
          _firebaseReady = true;
        });
        _checkAuthState();
      } catch (_) {
        await Firebase.initializeApp();
        debugLog("SPLASH: Firebase init ok");
        setState(() {
          _firebaseReady = true;
        });
        _checkAuthState();
      }
    } catch (e) {
      debugLog("SPLASH: Firebase init error: $e");
      setState(() {
        _firebaseReady = true;
        _authStateReady = true;
      });
      _navigateToAuthGate();
    }
  }

  void _checkAuthState() {
    StreamSubscription<User?>? subscription;
    subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      subscription?.cancel();
      debugLog("SPLASH: Auth state resolved");
      setState(() {
        _authStateReady = true;
      });
      _navigateToAuthGate();
    });
  }

  void _navigateToAuthGate() {
    if (_firebaseReady && _authStateReady && mounted) {
      // Запускаем анимацию, если ещё не запущена
      if (!_controller.isAnimating && !_controller.isCompleted) {
        _controller.forward().then((_) {
          debugLog("SPLASH_COMPLETE");
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              context.go('/auth-gate');
            }
          });
        });
      } else if (_controller.isCompleted) {
        debugLog("SPLASH_COMPLETE");
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            context.go('/auth-gate');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // EVENT крупно
                Text(
                  'EVENT',
                  style: AppTypography.displayLg.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                // Тонкая черта
                Container(
                  width: 140,
                  height: 1,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                // Слоган
                Text(
                  'Найдите своего идеального специалиста для мероприятий',
                  style: AppTypography.bodyMd.copyWith(
                    color: mutedColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!_firebaseReady || !_authStateReady) ...[
                  const SizedBox(height: 32),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
