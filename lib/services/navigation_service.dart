import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Сервис для управления навигацией с логированием
class NavigationService {
  static final List<String> _navigationHistory = [];
  static final int _maxHistorySize = 50;

  /// Логировать переход
  static void logNavigation(String from, String to,
      {Map<String, dynamic>? data}) {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = {
        'timestamp': timestamp,
        'from': from,
        'to': to,
        'data': data,
      };

      debugPrint('🧭 Navigation: $from → $to');

      // Добавляем в историю
      _navigationHistory.add('$timestamp: $from → $to');
      if (_navigationHistory.length > _maxHistorySize) {
        _navigationHistory.removeAt(0);
      }

      // Отправляем в Crashlytics для аналитики
      FirebaseCrashlytics.instance.log('Navigation: $from → $to');

      if (data != null) {
        FirebaseCrashlytics.instance
            .setCustomKey('last_navigation_data', data.toString());
      }
    } catch (e) {
      debugPrint('❌ Error logging navigation: $e');
    }
  }

  /// Безопасный переход с обработкой ошибок
  static Future<void> safeGo(BuildContext context, String path,
      {Object? extra}) async {
    try {
      final currentPath = GoRouterState.of(context).uri.path;
      logNavigation(currentPath, path,
          data: extra != null ? {'extra': extra.toString()} : null);

      context.go(path, extra: extra);
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);

      // Fallback к главной странице
      try {
        context.go('/main');
      } catch (fallbackError) {
        debugPrint('❌ Fallback navigation failed: $fallbackError');
      }
    }
  }

  /// Безопасный push с обработкой ошибок
  static Future<void> safePush(BuildContext context, String path,
      {Object? extra}) async {
    try {
      final currentPath = GoRouterState.of(context).uri.path;
      logNavigation(currentPath, path,
          data: {'action': 'push', 'extra': extra?.toString()});

      context.push(path, extra: extra);
    } catch (e) {
      debugPrint('❌ Push navigation error: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  /// Безопасный возврат назад
  static void safePop(BuildContext context, {dynamic result}) {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
        logNavigation('current', 'previous', data: {'action': 'pop'});
      } else {
        // Если нельзя вернуться назад, идем на главную
        safeGo(context, '/main');
      }
    } catch (e) {
      debugPrint('❌ Pop navigation error: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  /// Проверить, можно ли вернуться назад
  static bool canPop(BuildContext context) {
    try {
      return Navigator.of(context).canPop();
    } catch (e) {
      debugPrint('❌ Error checking canPop: $e');
      return false;
    }
  }

  /// Получить текущий путь
  static String getCurrentPath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (e) {
      debugPrint('❌ Error getting current path: $e');
      return '/unknown';
    }
  }

  /// Получить историю навигации
  static List<String> getNavigationHistory() {
    return List.from(_navigationHistory);
  }

  /// Очистить историю навигации
  static void clearHistory() {
    _navigationHistory.clear();
    debugPrint('🧹 Navigation history cleared');
  }

  /// Проверить, есть ли циклы в навигации
  static bool hasNavigationCycles() {
    try {
      if (_navigationHistory.length < 3) return false;

      final recent = _navigationHistory.length > 10
          ? _navigationHistory.sublist(_navigationHistory.length - 10)
          : _navigationHistory;
      final uniquePaths =
          recent.map((entry) => entry.split(' → ').last).toSet();

      // Если в последних 10 переходах много повторений, возможен цикл
      return uniquePaths.length < 3;
    } catch (e) {
      debugPrint('❌ Error checking navigation cycles: $e');
      return false;
    }
  }

  /// Обработать системную кнопку "Назад"
  static Future<bool> handleSystemBack(BuildContext context) async {
    try {
      final currentPath = getCurrentPath(context);

      // Если мы на главной странице, показываем диалог выхода
      if (currentPath == '/main' || currentPath == '/') {
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          return true; // Разрешаем выход из приложения
        }
        return false; // Отменяем выход
      }

      // Иначе просто возвращаемся назад
      safePop(context);
      return false;
    } catch (e) {
      debugPrint('❌ Error handling system back: $e');
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      return false;
    }
  }

  /// Показать диалог выхода из приложения
  static Future<bool?> _showExitDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из приложения'),
        content: const Text('Вы действительно хотите выйти из приложения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  /// Проверить валидность маршрута
  static bool isValidRoute(String route) {
    const validRoutes = [
      '/',
      '/splash',
      '/auth-check',
      '/login',
      '/phone-auth',
      '/main',
      '/profile/edit',
      '/profile/:userId',
      '/chats',
      '/chat/:chatId',
      '/monetization',
      '/create-request',
      '/create-idea',
      '/notifications',
    ];

    // Проверяем точное совпадение или параметризованные маршруты
    if (validRoutes.contains(route)) return true;

    // Проверяем параметризованные маршруты
    for (final validRoute in validRoutes) {
      if (validRoute.contains(':')) {
        final pattern = validRoute.replaceAll(RegExp(r':\w+'), r'[^/]+');
        if (RegExp('^$pattern\$').hasMatch(route)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Получить статистику навигации
  static Map<String, dynamic> getNavigationStats() {
    try {
      final totalNavigations = _navigationHistory.length;
      final uniquePaths = _navigationHistory
          .map((entry) => entry.split(' → ').last)
          .toSet()
          .length;

      return {
        'totalNavigations': totalNavigations,
        'uniquePaths': uniquePaths,
        'hasCycles': hasNavigationCycles(),
        'lastNavigation':
            _navigationHistory.isNotEmpty ? _navigationHistory.last : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting navigation stats: $e');
      return {
        'totalNavigations': 0,
        'uniquePaths': 0,
        'hasCycles': false,
        'lastNavigation': null,
      };
    }
  }
}
