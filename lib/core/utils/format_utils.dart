/// Утилиты для форматирования данных
library;

import 'package:intl/intl.dart';

/// Форматирование валюты
String formatCurrency(double amount, [String currency = '₽']) {
  final formatter = NumberFormat('#,##0.00', 'ru_RU');
  return '${formatter.format(amount)} $currency';
}

/// Форматирование даты
String formatDate(DateTime date, [String pattern = 'dd.MM.yyyy']) {
  final formatter = DateFormat(pattern, 'ru_RU');
  return formatter.format(date);
}

/// Форматирование времени
String formatTime(DateTime time, [String pattern = 'HH:mm']) {
  final formatter = DateFormat(pattern, 'ru_RU');
  return formatter.format(time);
}

/// Форматирование даты и времени
String formatDateTime(
  DateTime dateTime, [
  String pattern = 'dd.MM.yyyy HH:mm',
]) {
  final formatter = DateFormat(pattern, 'ru_RU');
  return formatter.format(dateTime);
}

/// Форматирование размера файла
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Форматирование номера телефона
String formatPhoneNumber(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (cleaned.length == 11 && cleaned.startsWith('7')) {
    return '+7 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7, 9)}-${cleaned.substring(9)}';
  }
  return phone;
}

/// Форматирование имени (первая буква заглавная)
String formatName(String name) {
  if (name.isEmpty) return name;
  return name.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

/// Форматирование рейтинга
String formatRating(double rating) => rating.toStringAsFixed(1);

/// Форматирование процентов
String formatPercentage(double value) => '${(value * 100).toStringAsFixed(1)}%';
