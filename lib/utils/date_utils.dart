import 'package:flutter/material.dart';

class DateUtils {
  static String formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  static String formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static String formatDateTime(DateTime dateTime) =>
      '${formatDate(dateTime)} ${formatTime(TimeOfDay.fromDateTime(dateTime))}';

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  static String getRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Сегодня';
    } else if (isTomorrow(date)) {
      return 'Завтра';
    } else {
      return formatDate(date);
    }
  }
}

