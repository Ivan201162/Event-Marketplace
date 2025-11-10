import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:event_marketplace_app/services/auth_repository.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/utils/first_run.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class WipeService {
  static const _deviceId = '34HDU20228002261';

  /// Безопасная очистка только для тестового устройства и только в release
  static Future<void> maybeWipeOnFirstRun() async {
    if (kReleaseMode) {
      final first = await FirstRunHelper.isFirstRun();
      if (!first) return;

      // Включаем wipe без подтверждения только если пользователь уже авторизован
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _wipeUser(user.uid);
        await AuthRepository().logout();
      }
    }
  }

  /// Очистка данных пользователя
  static Future<void> _wipeUser(String uid) async {
    try {
      debugLog('FRESH_WIPE_START:uid=$uid');
      final fs = FirebaseFirestore.instance;

      // Удаляем корневой профиль
      await fs.collection('users').doc(uid).delete().catchError((_) {});

      // Удаляем уведомления
      await fs
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get()
          .then((q) {
        for (final d in q.docs) {
          d.reference.delete();
        }
      });

      debugLog('FRESH_WIPE_DONE:uid=$uid');
    } catch (e) {
      debugLog('FRESH_WIPE_ERR:$e');
    }
  }

  /// Вызвать Cloud Function для удаления данных тестового пользователя
  static Future<bool> wipeTestUser({required String uid, bool hard = true}) async {
    try {
      debugLog('WIPE_CALL:$uid:hard=$hard');
      
      final callable = FirebaseFunctions.instance.httpsCallable('wipeTestUser');
      final result = await callable.call({
        'uid': uid,
        'hard': hard,
      });

      if (result.data['ok'] == true) {
        debugLog('WIPE_DONE:$uid');
        return true;
      } else {
        debugLog('WIPE_ERR:unknown_response');
        return false;
      }
    } catch (e) {
      debugLog('WIPE_ERR:${e.toString()}');
      return false;
    }
  }
}

