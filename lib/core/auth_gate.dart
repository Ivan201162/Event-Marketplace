import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/wipe_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/utils/first_run.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
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
  bool _firebaseReady = false;
  bool _authStateReady = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Проверяем, инициализирован ли Firebase
      try {
        Firebase.app();
        debugLog("AUTH_GATE:FIREBASE_ALREADY_INIT");
        _firebaseReady = true;
      } catch (_) {
        // Инициализируем Firebase
        await Firebase.initializeApp();
        debugLog("AUTH_GATE:FIREBASE_INIT_OK");
        _firebaseReady = true;
      }
      
      // Ждём первое событие authStateChanges
      await FirebaseAuth.instance.authStateChanges().first;
      debugLog("AUTH_GATE_READY");
      _authStateReady = true;
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugLog("AUTH_GATE:INIT_ERROR:$e");
      _firebaseReady = true;
      _authStateReady = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ждём Firebase init и первое authStateChanges
    if (!_firebaseReady || !_authStateReady) {
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
      // Полный fresh install wipe после успешной авторизации
      if (!kDebugMode) {
        final isFirstRun = await FirstRunHelper.isFirstRun();
        if (isFirstRun) {
          debugLog("FRESH_INSTALL_DETECTED:uid=${widget.user.uid}");
          debugLog("FRESH_WIPE_START:uid=${widget.user.uid}");
          
          // 1) Удалить пользователя из Firebase Auth
          try {
            await widget.user.delete();
            debugLog("FRESH_WIPE:AUTH_USER_DELETED");
          } catch (e) {
            debugLog("FRESH_WIPE:AUTH_DELETE_ERR:$e");
            // Если не удалось удалить auth user, выходим
            await FirebaseAuth.instance.signOut();
          }
          
          // 2) Удалить user doc из Firestore
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.user.uid)
                .delete();
            debugLog("FRESH_WIPE:FIRESTORE_USER_DELETED");
          } catch (e) {
            debugLog("FRESH_WIPE:FIRESTORE_DELETE_ERR:$e");
          }
          
          // 3) Удалить Storage uploads (если есть)
          try {
            final storageRef = FirebaseStorage.instance.ref('uploads/${widget.user.uid}');
            final listResult = await storageRef.listAll();
            for (var item in listResult.items) {
              try {
                await item.delete();
              } catch (e) {
                debugLog("FRESH_WIPE:STORAGE_DELETE_ITEM_ERR:$e");
              }
            }
            debugLog("FRESH_WIPE:STORAGE_DELETED");
          } catch (e) {
            debugLog("FRESH_WIPE:STORAGE_DELETE_ERR:$e");
          }
          
          // 4) Вызываем Cloud Function wipe для полной очистки
          try {
            final wipeResult = await WipeService.wipeTestUser(uid: widget.user.uid, hard: true);
            if (wipeResult) {
              debugLog("FRESH_WIPE_DONE:${widget.user.uid}");
            } else {
              debugLog("FRESH_WIPE_ERR:cloud_function_failed");
            }
          } catch (e) {
            debugLog("FRESH_WIPE_ERR:cloud_function:$e");
          }
          
          // Выходим из аккаунта
          try {
            await FirebaseAuth.instance.signOut();
            debugLog("LOGOUT:OK");
            debugLog("FRESH_INSTALL_WIPE_COMPLETE:logged_out");
          } catch (e) {
            debugLog("LOGOUT:ERR:$e");
          }
          
          // Отмечаем первую установку как выполненную
          await FirstRunHelper.markFirstRunDone();
          
          // После wipe редирект на логин
          if (mounted) {
            context.go('/login');
          }
          return;
        }
      }
      
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
        debugLog("ONBOARDING_REQUIRED:uid=${widget.user.uid}");
        debugLog("ONBOARDING_OPENED");
        // Жёсткий редирект на онбординг - вход блокируется
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
