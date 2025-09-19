import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Утилиты для приложения
class AppUtils {
  /// Форматирование даты
  static String formatDate(DateTime date) =>
      DateFormat('dd.MM.yyyy').format(date);

  /// Форматирование времени
  static String formatTime(DateTime time) => DateFormat('HH:mm').format(time);

  /// Форматирование даты и времени
  static String formatDateTime(DateTime dateTime) =>
      DateFormat('dd.MM.yyyy HH:mm').format(dateTime);

  /// Форматирование валюты
  static String formatCurrency(double amount, {String currency = '₽'}) =>
      NumberFormat.currency(
        locale: 'ru_RU',
        symbol: currency,
        decimalDigits: 0,
      ).format(amount);

  /// Форматирование расстояния
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} м';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} км';
    }
  }

  /// Форматирование размера файла
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Проверка валидности email
  static bool isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  /// Проверка валидности телефона
  static bool isValidPhone(String phone) =>
      RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone.replaceAll(' ', ''));

  /// Получение инициалов
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Получение цвета по строке
  static Color getColorFromString(String str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return Color(hash & 0x00FFFFFF).withOpacity(1);
  }

  /// Проверка платформы
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => !isAndroid && !isIOS;

  /// Получение размера экрана
  static Size getScreenSize(BuildContext context) =>
      MediaQuery.of(context).size;

  /// Проверка мобильного устройства
  static bool isMobile(BuildContext context) =>
      getScreenSize(context).width < 600;

  /// Проверка планшета
  static bool isTablet(BuildContext context) {
    final size = getScreenSize(context);
    return size.width >= 600 && size.width < 1200;
  }

  /// Проверка десктопа
  static bool isDesktop(BuildContext context) =>
      getScreenSize(context).width >= 1200;

  /// Получение безопасной области
  static EdgeInsets getSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding;

  /// Скрытие клавиатуры
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Показать снэкбар
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  /// Показать диалог подтверждения
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Да',
    String cancelText = 'Отмена',
  }) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      );

  /// Дебаунс функция
  static void debounce(
    String key,
    Duration delay,
    VoidCallback callback,
  ) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  static final Map<String, Timer> _debounceTimers = {};

  /// Очистка дебаунс таймеров
  static void clearDebounceTimers() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}

/// Расширения для строк
extension StringExtensions on String {
  /// Капитализация первой буквы
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Удаление лишних пробелов
  String trimAll() => replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Проверка на пустоту или null
  bool get isNullOrEmpty => isEmpty;

  /// Получение инициалов
  String get initials => AppUtils.getInitials(this);
}

/// Расширения для DateTime
extension DateTimeExtensions on DateTime {
  /// Проверка на сегодня
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Проверка на вчера
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Проверка на завтра
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Получение относительного времени
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} г. назад';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} мес. назад';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}
