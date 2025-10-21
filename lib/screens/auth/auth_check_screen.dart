import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';

/// Screen for checking authentication status
class AuthCheckScreen extends ConsumerStatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  ConsumerState<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<AuthCheckScreen> {
  Timer? _timeoutTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startAuthCheck();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startAuthCheck() {
    // Set timeout for auth check
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!_hasNavigated) {
        _navigateToLogin();
      }
    });

    // Listen to auth state changes using listenManual
    ref.listenManual<AsyncValue<AppUser?>>(authStateProvider, (previous, next) {
      if (_hasNavigated) return;

      next.when(
        data: (user) {
          if (user != null) {
            _navigateToMain();
          } else {
            _navigateToLogin();
          }
        },
        loading: () {
          // Keep showing loading
        },
        error: (error, stack) {
          debugPrint('Auth check error: $error');
          _navigateToLogin();
        },
      );
    });
  }

  void _navigateToMain() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _timeoutTimer?.cancel();

    if (mounted) {
      context.go('/main');
    }
  }

  void _navigateToLogin() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _timeoutTimer?.cancel();

    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C5CE7),
              Color(0xFFA29BFE),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Icon(
                Icons.event,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),

              // App name
              Text(
                'Event Marketplace',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),

              Text(
                'Проверка авторизации...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),

              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
