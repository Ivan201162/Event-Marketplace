import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';

class FirstRunHelper {
  static const String _keyInstallId = 'install_id';
  static const String _keyFirstRunDone = 'first_run_done';

  /// Получить или создать installId
  static Future<String> getInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    String? installId = prefs.getString(_keyInstallId);
    if (installId == null || installId.isEmpty) {
      installId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_keyInstallId, installId);
      debugLog('FRESH_INSTALL_DETECTED:installId=$installId');
    }
    return installId;
  }

  /// Проверить, была ли уже выполнена первая установка
  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyFirstRunDone) ?? false);
  }

  /// Отметить первую установку как выполненную
  static Future<void> markFirstRunDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstRunDone, true);
  }

  /// Сбросить флаг первой установки (для тестирования)
  static Future<void> resetFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstRunDone);
    await prefs.remove(_keyInstallId);
  }
}

