import 'package:flutter/material.dart';

/// Расширение для ThemeMode
extension ThemeModeExtension on ThemeMode {
  String get icon {
    switch (this) {
      case ThemeMode.system:
        return '🌓';
      case ThemeMode.light:
        return '☀️';
      case ThemeMode.dark:
        return '🌙';
    }
  }

  String get description {
    switch (this) {
      case ThemeMode.system:
        return 'Системная тема';
      case ThemeMode.light:
        return 'Светлая тема';
      case ThemeMode.dark:
        return 'Тёмная тема';
    }
  }
}
