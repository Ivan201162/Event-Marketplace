import 'package:flutter/material.dart';

/// Миксин для поддержки свайпа назад
mixin SwipeBackMixin<T extends StatefulWidget> on State<T> {
  /// Обернуть виджет с поддержкой свайпа назад
  Widget wrapWithSwipeBack(Widget child) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Проверяем, был ли свайп влево с достаточной скоростью
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

