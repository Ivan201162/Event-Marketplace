import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/wipe_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/utils/first_run.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    // Проверка fresh-install в release режиме
    if (!kDebugMode) {
      final isFirstRun = await FirstRunHelper.isFirstRun();
      if (isFirstRun) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugLog("FRESH_INSTALL_DETECTED:uid=${currentUser.uid}");
          debugLog("WIPE_CALL:${currentUser.uid}");
          // Вызываем wipe для очистки данных
          final wipeResult = await WipeService.wipeTestUser(uid: currentUser.uid, hard: true);
          if (wipeResult) {
            debugLog("FRESH_WIPE_DONE:${currentUser.uid}");
            debugLog("WIPE_DONE:${currentUser.uid}");
          } else {
            debugLog("FRESH_WIPE_ERR:failed");
            debugLog("WIPE_ERR:failed");
          }
          // Выходим из аккаунта (wipe уже делает signOut, но на всякий случай)
          try {
          await FirebaseAuth.instance.signOut();
          debugLog("LOGOUT:OK");
          debugLog("FRESH_INSTALL_WIPE_COMPLETE:logged_out");
          } catch (e) {
            debugLog("LOGOUT:ERR:$e");
            debugLog("FRESH_INSTALL_LOGOUT_ERR:$e");
          }
          // Отмечаем первую установку как выполненную
          await FirstRunHelper.markFirstRunDone();
        } else {
          await FirstRunHelper.markFirstRunDone();
        }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Пока загружается состояние авторизации
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // IF user == null → show LoginScreen
        if (user == null) {
          debugLog("AUTH_GATE:USER:null");
          debugLog("AUTH_SCREEN_SHOWN");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/login');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // IF user != null → check profile
        debugLog("AUTH_GATE:USER:uid=${user.uid}");
        return _ProfileCheckWidget(user: user);
      },
    );
  }
}

class _ProfileCheckWidget extends StatefulWidget {
  final User user;

  const _ProfileCheckWidget({required this.user});

  @override
  State<_ProfileCheckWidget> createState() => _ProfileCheckWidgetState();
}

class _ProfileCheckWidgetState extends State<_ProfileCheckWidget> {
  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (!userDoc.exists) {
        debugLog("AUTH_GATE:PROFILE_CHECK:missing_fields=[doc_not_exists]");
        debugLog("ONBOARDING_OPENED");
        if (mounted) {
          context.go('/onboarding/role-name-city');
        }
        return;
      }

      final userData = userDoc.data()!;
      final roles = userData['roles'] as List?;
      final rolesLower = userData['rolesLower'] as List?;
      final firstName = userData['firstName'] as String?;
      final lastName = userData['lastName'] as String?;
      final city = userData['city'] as String?;
      
      // Проверка обязательных полей для онбординга (жёсткая проверка)
      final missingFields = <String>[];
      
      final hasValidRoles = roles != null &&
          roles is List &&
          roles.isNotEmpty &&
          roles.length >= 1 &&
          roles.length <= 3;
      if (!hasValidRoles) missingFields.add('roles');
      
      final hasValidRolesLower = rolesLower != null &&
          rolesLower is List &&
          rolesLower.isNotEmpty &&
          rolesLower.length >= 1 &&
          rolesLower.length <= 3;
      if (!hasValidRolesLower) missingFields.add('rolesLower');
      
      if (firstName == null || firstName.trim().isEmpty) missingFields.add('firstName');
      if (lastName == null || lastName.trim().isEmpty) missingFields.add('lastName');
      if (city == null || city.trim().isEmpty) missingFields.add('city');
      
      if (missingFields.isNotEmpty) {
        debugLog("AUTH_GATE:PROFILE_CHECK:missing_fields=[${missingFields.join(',')}]");
        debugLog("ONBOARDING_OPENED");
        if (mounted) {
          context.go('/onboarding/role-name-city');
        }
        return;
      }
      
      // Всё готово → /main
      debugLog("AUTH_GATE:PROFILE_CHECK:ok");
      debugLog("HOME_LOADED");
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      debugLog("ERROR:AUTH_GATE_CHECK:$e");
      debugLog("AUTH_GATE: user=null → show login");
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
