import 'package:cloud_functions/cloud_functions.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WipeService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Вызвать Cloud Function для удаления данных тестового пользователя
  static Future<bool> wipeTestUser({required String uid, bool hard = true}) async {
    try {
      debugLog('WIPE_CALL:$uid:hard=$hard');
      
      final callable = _functions.httpsCallable('wipeTestUser');
      final result = await callable.call({
        'uid': uid,
        'hard': hard,
      });

      if (result.data['ok'] == true) {
        debugLog('WIPE_DONE:$uid');
        // Принудительный выход из аккаунта после wipe
        try {
          await FirebaseAuth.instance.signOut();
          debugLog('WIPE_LOGOUT_COMPLETE');
        } catch (e) {
          debugLog('WIPE_LOGOUT_ERR:$e');
        }
        return true;
      } else {
        debugLog('WIPE_ERR:unknown_response');
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      debugLog('WIPE_ERR:${e.code}:${e.message}');
      return false;
    } catch (e) {
      debugLog('WIPE_ERR:unknown:$e');
      return false;
    }
  }
}

