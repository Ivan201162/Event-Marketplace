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
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // тот же Splash
        }

        final user = snap.data;

        if (user == null) {
          return const LoginScreen(); // экран входа
        }

        return FutureBuilder<bool>(
          future: _ensureProfileAndRoute(), // см. ниже
          builder: (c, s) {
            if (!s.hasData) return const SplashScreen();

            // true → профиль ок, идём в main
            if (s.data!) {
              // Используем GoRouter для навигации
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) {
                  ctx.go('/main');
                }
              });
              return const SplashScreen();
            } else {
              // Используем GoRouter для навигации
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) {
                  ctx.go('/onboarding');
                }
              });
              return const SplashScreen();
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
      // ⚠️ Активно только в release-сборке
      if (!kDebugMode) {
        final isFirstRun = await FirstRunHelper.isFirstRun();
        if (!isFirstRun) {
          debugLog("WIPE_BEFORE_INIT_DONE:not_first_run");
        }
        if (isFirstRun) {
          debugLog("FRESH_INSTALL_DETECTED:uid=${widget.user.uid}");
          debugLog("FRESH_WIPE_START:uid=${widget.user.uid}");
          
          final uid = widget.user.uid;
          
          // 1) Удалить пользователя из Firebase Auth
          try {
            await widget.user.delete();
            debugLog("FRESH_WIPE:AUTH_USER_DELETED");
          } catch (e) {
            debugLog("FRESH_WIPE:AUTH_DELETE_ERR:$e");
            // Если не удалось удалить auth user, выходим
            await FirebaseAuth.instance.signOut();
          }
          
          // 2) Удалить user doc и связанные коллекции из Firestore
          try {
            // /users/{uid}
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .delete();
            debugLog("FRESH_WIPE:FIRESTORE_USER_DELETED");
            
            // /specialist_pricing/{uid}
            try {
              await FirebaseFirestore.instance
                  .collection('specialist_pricing')
                  .doc(uid)
                  .delete();
              debugLog("FRESH_WIPE:SPECIALIST_PRICING_DELETED");
            } catch (e) {
              debugLog("FRESH_WIPE:SPECIALIST_PRICING_ERR:$e");
            }
            
            // /bookings (где clientId или specialistId = uid)
            try {
              final bookingsSnapshot = await FirebaseFirestore.instance
                  .collection('bookings')
                  .where('clientId', isEqualTo: uid)
                  .get();
              for (var doc in bookingsSnapshot.docs) {
                await doc.reference.delete();
              }
              final bookingsSnapshot2 = await FirebaseFirestore.instance
                  .collection('bookings')
                  .where('specialistId', isEqualTo: uid)
                  .get();
              for (var doc in bookingsSnapshot2.docs) {
                await doc.reference.delete();
              }
              debugLog("FRESH_WIPE:BOOKINGS_DELETED");
            } catch (e) {
              debugLog("FRESH_WIPE:BOOKINGS_ERR:$e");
            }
            
            // /notifications (где userId = uid)
            try {
              final notificationsSnapshot = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .get();
              for (var doc in notificationsSnapshot.docs) {
                await doc.reference.delete();
              }
              debugLog("FRESH_WIPE:NOTIFICATIONS_DELETED");
            } catch (e) {
              debugLog("FRESH_WIPE:NOTIFICATIONS_ERR:$e");
            }
            
            // Очистить FCM токены
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({
                'fcmTokens': FieldValue.delete(),
              });
              debugLog("FCM_TOKENS_CLEARED");
            } catch (e) {
              debugLog("FCM_TOKENS_CLEAR_ERR:$e");
            }
            
            debugLog("USER_WIPE_DONE");
          } catch (e) {
            debugLog("FRESH_WIPE:FIRESTORE_DELETE_ERR:$e");
          }
          
          // 3) Удалить Storage uploads (если есть)
          try {
            final storageRef = FirebaseStorage.instance.ref('uploads/$uid');
            final listResult = await storageRef.listAll();
            for (var item in listResult.items) {
              try {
                await item.delete();
              } catch (e) {
                debugLog("FRESH_WIPE:STORAGE_DELETE_ITEM_ERR:$e");
              }
            }
            // Также удаляем все подпапки
            for (var prefix in listResult.prefixes) {
              try {
                final prefixList = await prefix.listAll();
                for (var item in prefixList.items) {
                  try {
                    await item.delete();
                  } catch (e) {
                    debugLog("FRESH_WIPE:STORAGE_DELETE_PREFIX_ITEM_ERR:$e");
                  }
                }
              } catch (e) {
                debugLog("FRESH_WIPE:STORAGE_PREFIX_ERR:$e");
              }
            }
            debugLog("STORAGE_CLEANUP_DONE");
          } catch (e) {
            debugLog("FRESH_WIPE:STORAGE_DELETE_ERR:$e");
          }
          
          // 4) Вызываем Cloud Function wipe для полной очистки
          try {
            final wipeResult = await WipeService.wipeTestUser(uid: uid, hard: true);
            if (wipeResult) {
              debugLog("FRESH_WIPE_DONE:$uid");
            } else {
              debugLog("FRESH_WIPE_ERR:cloud_function_failed");
            }
          } catch (e) {
            debugLog("FRESH_WIPE_ERR:cloud_function:$e");
          }
          
          // Выходим из аккаунта
          try {
            await FirebaseAuth.instance.signOut();
            debugLog("LOGOUT_OK");
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

      debugLog("AUTH_GATE:PROFILE_CHECK:uid=${widget.user.uid}");

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
        // Жёсткий редирект на онбординг - вход блокируется (без двойного срабатывания)
        Future.microtask(() {
          if (mounted) {
            context.go('/onboarding/role-name-city');
          }
        });
        return;
      }
      
      // Всё готово → /main (без двойного срабатывания)
      debugLog("AUTH_GATE:PROFILE_CHECK:ok");
      debugLog("AUTH_GATE_OK");
      debugLog("HOME_LOADED");
      Future.microtask(() {
        if (mounted) {
          context.go('/main');
        }
      });
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
