import 'dart:async';

import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _startAuthCheck() async {
    // Set timeout for auth check
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!_hasNavigated) {
        _navigateToLogin();
      }
    });

    // Сначала проверяем сохраненную сессию
    try {
      final authService = ref.read(authServiceProvider);
      final hasStoredSession = await authService.hasStoredSession();

      if (hasStoredSession) {
        debugPrint('✅ Found stored session, checking Firebase auth...');
        // Если есть сохраненная сессия, проверяем Firebase
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          // Check user role
          final user = await authService.currentUser;
          if (user != null && user.role == null) {
            _navigateToRoleSelection();
          } else {
            _navigateToMain();
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking stored session: $e');
    }

    // Listen to auth state changes using listenManual
    ref.listenManual<AsyncValue<AppUser?>>(authStateProvider, (previous, next) {
      if (_hasNavigated) return;

      next.when(
        data: (user) {
          if (user != null) {
            // Check if role is set, if not show role selection
            if (user.role == null) {
              _navigateToRoleSelection();
            } else {
              _navigateToMain();
            }
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

  void _navigateToRoleSelection() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _timeoutTimer?.cancel();

    if (mounted) {
      context.go('/role-selection');
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
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Icon(Icons.event, size: 80, color: Colors.white),
              SizedBox(height: 24),

              // App name
              Text(
                'Event',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,),
              ),
              SizedBox(height: 8),

              Text(
                'Проверка авторизации...',
                style: TextStyle(fontSize: 16, color: Colors.white70),
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
