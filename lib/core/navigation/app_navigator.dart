import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Универсальный навигационный сервис для обработки кнопки "Назад"
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static DateTime? _lastExitAttempt;

  /// Обработка кнопки "Назад" с правильной логикой
  static Future<bool> handleBackPress(BuildContext context) async {
    // Сначала пробуем go_router
    try {
      if (context.canPop()) {
        context.pop();
        return false; // Предотвращаем системное действие
      }
    } catch (e) {
      // Если go_router недоступен, используем обычный Navigator
    }

    // Пробуем обычный Navigator
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return false; // Предотвращаем системное действие
    }

    // Проверяем, находимся ли мы на главном экране
    final currentLocation = GoRouterState.of(context).uri.path;
    if (currentLocation == '/home') {
      // На главном экране - используем "двойное нажатие для выхода"
      return _handleExitOrHome(context);
    }

    // Если не на главном экране, но не можем вернуться - переходим на главный
    context.go('/home');
    return false;
  }

  /// Обработка выхода из приложения с "двойным нажатием"
  static Future<bool> _handleExitOrHome(BuildContext context) async {
    final now = DateTime.now();

    // Если прошло больше 2 секунд с последней попытки или это первая попытка
    if (_lastExitAttempt == null ||
        now.difference(_lastExitAttempt!) > const Duration(seconds: 2)) {
      _lastExitAttempt = now;

      // Показываем SnackBar с подсказкой
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нажмите «Назад» ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false; // Предотвращаем выход
    }

    // Второе нажатие - выходим из приложения
    await SystemNavigator.pop();
    return true;
  }

  /// Создание правильной стрелки "Назад" для AppBar
  static Widget? buildBackButton(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => handleBackPress(context),);

  /// Создание AppBar с правильной навигацией
  static AppBar buildAppBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
  }) =>
      AppBar(
        title: Text(title),
        leading: automaticallyImplyLeading ? buildBackButton(context) : null,
        actions: actions,
        backgroundColor: backgroundColor ?? Colors.transparent,
        foregroundColor: foregroundColor,
        elevation: elevation ?? 0,
      );

  /// Создание PopScope с правильной обработкой
  static Widget buildPopScope(
          {required Widget child, required BuildContext context,}) =>
      PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            await handleBackPress(context);
          }
        },
        child: child,
      );

  /// Безопасная навигация назад
  static Future<void> safeBack(BuildContext context) async {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        // Если не можем вернуться, переходим на главную
        context.go('/home');
      }
    } catch (e) {
      // Fallback на обычный Navigator
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        context.go('/home');
      }
    }
  }

  /// Проверка возможности возврата назад
  static bool canGoBack(BuildContext context) {
    try {
      return context.canPop();
    } catch (e) {
      return Navigator.of(context).canPop();
    }
  }
}
