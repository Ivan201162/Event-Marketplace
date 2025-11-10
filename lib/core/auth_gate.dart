import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/screens/splash/splash_event_screen.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран-ворота для проверки авторизации
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SplashEventScreen(); // тот же Splash
        }

        final user = snap.data;

        if (user == null) {
          // Используем GoRouter для навигации
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ctx.mounted) {
              ctx.go('/login');
            }
          });
          return SplashEventScreen();
        }

        return FutureBuilder<bool>(
          future: _ensureProfileAndRoute(), // см. ниже
          builder: (c, s) {
            if (!s.hasData) return SplashEventScreen();

            // true → профиль ок, идём в main
            if (s.data!) {
              // Используем GoRouter для навигации
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) {
                  ctx.go('/main');
                }
              });
              return SplashEventScreen();
            } else {
              // Используем GoRouter для навигации
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) {
                  ctx.go('/onboarding');
                }
              });
              return SplashEventScreen();
            }
          },
        );
      },
    );
  }

  Future<bool> _ensureProfileAndRoute() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    debugLog('AUTH_GATE:PROFILE_CHECK:uid=$uid');
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (!doc.exists) {
        debugLog('AUTH_GATE:PROFILE_CHECK:not_exists');
        return false;
      }

      final d = doc.data()!;
      final ok = (d['firstName']?.toString().isNotEmpty ?? false) &&
          (d['lastName']?.toString().isNotEmpty ?? false) &&
          (d['city']?.toString().isNotEmpty ?? false) &&
          ((d['roles'] is List) && (d['roles'] as List).isNotEmpty);

      debugLog('AUTH_GATE:PROFILE_CHECK:ok=$ok');
      return ok;
    } catch (e) {
      debugLog('AUTH_GATE:PROFILE_CHECK:error=$e');
      return false;
    }
  }
}
