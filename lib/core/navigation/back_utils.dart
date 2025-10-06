import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Утилиты для правильной обработки навигации "Назад"
class BackUtils {
  /// Обработка кнопки "Назад" с правильной логикой
  static Future<void> handleBackNavigation(BuildContext context) async {
    // Проверяем, можем ли мы вернуться назад в GoRouter
    if (context.canPop()) {
      context.pop();
    } else {
      // Если не можем вернуться назад, закрываем приложение
      await exitOrHome(context);
    }
  }

  /// Выход из приложения или возврат на главный экран
  static Future<void> exitOrHome(BuildContext context) async {
    // Если есть главный экран (home), переходим туда
    if (context.canPop()) {
      context.pop();
    } else {
      // Иначе закрываем приложение
      await SystemNavigator.pop();
    }
  }

  /// Создание правильной стрелки "Назад" для AppBar
  static Widget? buildBackButton(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => handleBackNavigation(context),
      );

  /// Создание AppBar с правильной навигацией
  static AppBar buildAppBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) =>
      AppBar(
        title: Text(title),
        leading: automaticallyImplyLeading ? buildBackButton(context) : null,
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: 0,
      );
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
              BackUtils.handleBackNavigation(context);
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
            BackUtils.exitOrHome(context);
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
        onPopInvoked: (didPop) async {
          if (!didPop) {
            if (onWillPop != null) {
              final shouldPop = await onWillPop!();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            } else {
              await BackUtils.handleBackNavigation(context);
            }
          }
        },
        child: child,
      );
}
