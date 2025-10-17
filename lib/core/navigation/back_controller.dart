import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackController {
  static DateTime? _lastBackPressTime;

  static Future<bool> handleBackPress(BuildContext context) async {
    final nav = Navigator.of(context);

    if (nav.canPop()) {
      nav.pop();
      return false;
    }

    final currentTime = DateTime.now();
    if (_lastBackPressTime == null ||
        currentTime.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = currentTime;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нажмите «Назад» ещё раз, чтобы выйти')),
      );
      return false;
    }

    await SystemNavigator.pop();
    return true;
  }
}
