import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/screens/splash/splash_screen.dart';
import 'package:event_marketplace_app/screens/auth/login_screen.dart';
import 'package:event_marketplace_app/screens/onboarding/onboarding_screen.dart';
import 'package:event_marketplace_app/screens/main/main_screen.dart';
import 'package:event_marketplace_app/services/wipe_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/utils/first_run.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Экран-ворота для проверки авторизации
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _wipeChecked = false;

  @override
  void initState() {
    super.initState();
    _checkFreshInstall();
  }

  Future<void> _checkFreshInstall() async {
    // Fresh-install wipe только в release режиме
    if (kReleaseMode) {
      final isFirstRun = await FirstRunHelper.isFirstRun();
      if (isFirstRun) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugLog('FRESH_INSTALL_DETECTED:uid=${currentUser.uid}');
          debugLog('WIPE_CALL:uid=${currentUser.uid}');
          
          final wipeResult = await WipeService.wipeTestUser(
            uid: currentUser.uid,
            hard: true,
          );
          
          if (wipeResult) {
            debugLog('WIPE_DONE:uid=${currentUser.uid}');
          } else {
            debugLog('WIPE_ERR:failed');
          }
          
          // Выходим из аккаунта после wipe
          try {
            await FirebaseAuth.instance.signOut();
            debugLog('LOGOUT:OK');
          } catch (e) {
            debugLog('LOGOUT:ERR:$e');
          }
        }
        await FirstRunHelper.markFirstRunDone();
      }
    }
    
    if (mounted) {
      setState(() {
        _wipeChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_wipeChecked) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snap.data;

        if (user == null) {
          debugLog('AUTH_GATE:STATE:null -> LOGIN');
          return const LoginScreen();
        }

        debugLog('AUTH_GATE:STATE:user -> PROFILE_CHECK');
        return FutureBuilder<bool>(
          future: _checkProfile(user.uid),
          builder: (c, s) {
            if (!s.hasData) {
              return const SplashScreen();
            }

            if (s.data!) {
              debugLog('AUTH_GATE:ROUTE_MAIN');
              return const MainScreen();
            } else {
              debugLog('AUTH_GATE:PROFILE_INCOMPLETE -> ONBOARDING');
              return const OnboardingScreen();
            }
          },
        );
      },
    );
  }

  Future<bool> _checkProfile(String uid) async {
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
      final firstName = d['firstName']?.toString() ?? '';
      final lastName = d['lastName']?.toString() ?? '';
      final city = d['city']?.toString() ?? '';
      final roles = d['roles'] as List?;

      final ok = firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          city.isNotEmpty &&
          (roles != null && roles.isNotEmpty);

      debugLog('AUTH_GATE:PROFILE_CHECK:ok=$ok');
      return ok;
    } catch (e) {
      debugLog('AUTH_GATE:PROFILE_CHECK:error=$e');
      return false;
    }
  }
}
