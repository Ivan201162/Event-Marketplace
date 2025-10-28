import 'package:event_marketplace_app/utils/back_utils.dart';
import 'package:flutter/material.dart';

/// Виджет для обработки кнопки "Назад"
class BackButtonHandler extends StatelessWidget {
  const BackButtonHandler({
    required this.child, super.key,
    this.showExitConfirmation = false,
    this.showBackConfirmation = false,
    this.backConfirmationMessage,
  });
  final Widget child;
  final bool showExitConfirmation;
  final bool showBackConfirmation;
  final String? backConfirmationMessage;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (showBackConfirmation) {
            final dialogResult =
                await BackUtils.showBackConfirmationDialog(context);
            if (dialogResult ?? false) {
              BackUtils.handleBackButton(context);
            }
          } else if (showExitConfirmation) {
            final dialogResult =
                await BackUtils.showExitConfirmationDialog(context);
            if (dialogResult ?? false) {
              BackUtils.handleSystemBackButton(context);
            }
          } else {
            BackUtils.handleSystemBackButton(context);
          }
        },
        child: child,
      );
}
