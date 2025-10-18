/// Утилиты для работы с типами и преобразованиями
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Безопасное преобразование Map<dynamic, dynamic> в Map<String, dynamic>
Map<String, dynamic> safeMapFromDynamic(Map<dynamic, dynamic>? data) {
  if (data == null) {
    return {};
  }
  return data.map((key, value) => MapEntry(key.toString(), value));
}

/// Безопасное преобразование List<dynamic> в List<T>
List<T> safeListFromDynamic<T>(
  List<dynamic>? data,
  T Function(dynamic) converter,
) {
  if (data == null) return <T>[];
  return data.map<T>(converter).toList();
}

/// Безопасное преобразование String из dynamic
String safeStringFromDynamic(dynamic data, [String defaultValue = '']) {
  if (data == null) return defaultValue;
  if (data is String) return data;
  return data.toString();
}

/// Безопасное преобразование bool из dynamic
bool safeBoolFromDynamic(dynamic data, [bool defaultValue = false]) {
  if (data == null) return defaultValue;
  if (data is bool) return data;
  if (data is String) {
    return data.toLowerCase() == 'true';
  }
  return defaultValue;
}

/// Безопасное преобразование int из dynamic
int safeIntFromDynamic(dynamic data, [int defaultValue = 0]) {
  if (data == null) return defaultValue;
  if (data is int) return data;
  if (data is double) return data.toInt();
  if (data is String) {
    return int.tryParse(data) ?? defaultValue;
  }
  return defaultValue;
}

/// Безопасное преобразование double из dynamic
double safeDoubleFromDynamic(dynamic data, [double defaultValue = 0.0]) {
  if (data == null) return defaultValue;
  if (data is double) return data;
  if (data is int) return data.toDouble();
  if (data is String) {
    return double.tryParse(data) ?? defaultValue;
  }
  return defaultValue;
}

/// Безопасное преобразование DateTime из Timestamp
DateTime safeDateTimeFromTimestamp(dynamic data) {
  if (data == null) return DateTime.now();
  if (data is Timestamp) return data.toDate();
  if (data is DateTime) return data;
  if (data is String) {
    return DateTime.tryParse(data) ?? DateTime.now();
  }
  return DateTime.now();
}

/// Безопасное преобразование enum из String
T safeEnumFromString<T extends Enum>(
  List<T> values,
  dynamic data,
  T defaultValue,
) {
  if (data == null) return defaultValue;
  final stringValue = data.toString();
  return values.firstWhere(
    (e) => e.toString().split('.').last == stringValue,
    orElse: () => defaultValue,
  );
}
