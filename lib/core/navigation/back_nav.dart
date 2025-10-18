import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Унифицированная утилита для безопасной обработки навигации "Назад"
class BackNav {
  static DateTime? _lastExitAttempt;

  /// Мягкий "назад": если можно — pop, иначе вернуться на корень/закрыть
  static Future<void> safeBack(BuildContext context) async {
    // Сначала пробуем go_router
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
    } catch (e) {
      // Если go_router недоступен, используем обычный Navigator
    }

    // Пробуем обычный Navigator
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // Если не можем вернуться назад, используем exitOrHome
    await exitOrHome(context);
  }

  /// На корне: "двойное нажатие для выхода" — чтобы не закрывать случайно
  static Future<void> exitOrHome(BuildContext context) async {
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
        ),
      );
      return;
    }

    // Второе нажатие - выходим из приложения
    await SystemNavigator.pop();
  }

  /// Создание правильной стрелки "Назад" для AppBar
  static Widget? buildBackButton(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => safeBack(context),
      );

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

  /// Проверка, можем ли мы вернуться назад
  static bool canPop(BuildContext context) {
    try {
      return context.canPop();
    } catch (e) {
      return Navigator.of(context).canPop();
    }
  }

  /// Принудительный возврат назад (если возможно)
  static void pop(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
    } catch (e) {
      // Если go_router недоступен, используем обычный Navigator
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Принудительный возврат назад с результатом
  static void popWithResult(BuildContext context, [Object? result]) {
    try {
      if (context.canPop()) {
        context.pop(result);
        return;
      }
    } catch (e) {
      // Если go_router недоступен, используем обычный Navigator
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result);
    }
  }
}

/// Виджет для правильной обработки системной кнопки "Назад"
class BackButtonHandler extends StatelessWidget {
  const BackButtonHandler({
    super.key,
    required this.child,
    this.canPop = true,
    this.onBackPressed,
  });
  final Widget child;
  final bool canPop;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && canPop) {
            if (onBackPressed != null) {
              onBackPressed!();
            } else {
              BackNav.safeBack(context);
            }
          }
        },
        child: child,
      );
}

/// Виджет для экранов, которые должны закрывать приложение при нажатии "Назад"
class ExitAppHandler extends StatelessWidget {
  const ExitAppHandler({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            BackNav.exitOrHome(context);
          }
        },
        child: child,
      );
}

/// Виджет для экранов с кастомной логикой обработки "Назад"
class CustomBackHandler extends StatelessWidget {
  const CustomBackHandler({
    super.key,
    required this.child,
    this.onWillPop,
  });
  final Widget child;
  final Future<bool> Function()? onWillPop;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            if (onWillPop != null) {
              final shouldPop = await onWillPop!();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            } else {
              await BackNav.safeBack(context);
            }
          }
        },
        child: child,
      );
}
