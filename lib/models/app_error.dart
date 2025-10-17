import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель ошибки приложения
@immutable
class AppError {
  const AppError({
    required this.id,
    this.userId,
    required this.device,
    required this.screen,
    required this.errorMessage,
    this.stackTrace,
    required this.errorType,
    this.resolved = false,
    required this.timestamp,
    this.metadata,
  });

  /// Создать из документа Firestore
  factory AppError.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return AppError(
        id: doc.id,
        device: '',
        screen: '',
        errorMessage: '',
        errorType: 'unknown',
        timestamp: DateTime.now(),
      );
    }

    // Безопасное преобразование данных
    Map<String, dynamic> safeData;
    if (data is Map<String, dynamic>) {
      safeData = data;
    } else if (data is Map<dynamic, dynamic>) {
      safeData = data.map((key, value) => MapEntry(key.toString(), value));
    } else {
      throw Exception('Document data is not a Map: ${data.runtimeType}');
    }

    return AppError(
      id: doc.id,
      userId: safeData['userId'] as String?,
      device: safeData['device'] as String? ?? '',
      screen: safeData['screen'] as String? ?? '',
      errorMessage: safeData['errorMessage'] as String? ?? '',
      stackTrace: safeData['stackTrace'] as String?,
      errorType: safeData['errorType'] as String? ?? 'unknown',
      resolved: safeData['resolved'] as bool? ?? false,
      timestamp: safeData['timestamp'] != null
          ? (safeData['timestamp'] is Timestamp
              ? (safeData['timestamp'] as Timestamp).toDate()
              : DateTime.parse(safeData['timestamp'].toString()))
          : DateTime.now(),
      metadata: safeData['metadata'] != null
          ? Map<String, dynamic>.from(safeData['metadata'] as Map)
          : null,
    );
  }

  /// Создать из Map
  factory AppError.fromMap(Map<String, dynamic> data) => AppError(
        id: data['id'] as String? ?? '',
        userId: data['userId'] as String?,
        device: data['device'] as String? ?? '',
        screen: data['screen'] as String? ?? '',
        errorMessage: data['errorMessage'] as String? ?? '',
        stackTrace: data['stackTrace'] as String?,
        errorType: data['errorType'] as String? ?? 'unknown',
        resolved: data['resolved'] as bool? ?? false,
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata:
            data['metadata'] != null ? Map<String, dynamic>.from(data['metadata'] as Map) : null,
      );
  final String id;
  final String? userId;
  final String device;
  final String screen;
  final String errorMessage;
  final String? stackTrace;
  final String errorType;
  final bool resolved;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'device': device,
        'screen': screen,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'errorType': errorType,
        'resolved': resolved,
        'timestamp': Timestamp.fromDate(timestamp),
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  AppError copyWith({
    String? id,
    String? userId,
    String? device,
    String? screen,
    String? errorMessage,
    String? stackTrace,
    String? errorType,
    bool? resolved,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      AppError(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        device: device ?? this.device,
        screen: screen ?? this.screen,
        errorMessage: errorMessage ?? this.errorMessage,
        stackTrace: stackTrace ?? this.stackTrace,
        errorType: errorType ?? this.errorType,
        resolved: resolved ?? this.resolved,
        timestamp: timestamp ?? this.timestamp,
        metadata: metadata ?? this.metadata,
      );

  /// Получить краткое описание ошибки
  String get shortDescription {
    if (errorMessage.length > 100) {
      return '${errorMessage.substring(0, 100)}...';
    }
    return errorMessage;
  }

  /// Получить уровень критичности ошибки
  ErrorSeverity get severity {
    switch (errorType) {
      case 'crash':
        return ErrorSeverity.critical;
      case 'network':
        return ErrorSeverity.high;
      case 'validation':
        return ErrorSeverity.medium;
      case 'ui':
        return ErrorSeverity.low;
      default:
        return ErrorSeverity.medium;
    }
  }

  /// Проверить, является ли ошибка критической
  bool get isCritical => severity == ErrorSeverity.critical;

  /// Проверить, является ли ошибка недавней (менее 24 часов)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours < 24;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppError &&
        other.id == id &&
        other.userId == userId &&
        other.device == device &&
        other.screen == screen &&
        other.errorMessage == errorMessage &&
        other.stackTrace == stackTrace &&
        other.errorType == errorType &&
        other.resolved == resolved &&
        other.timestamp == timestamp &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        device,
        screen,
        errorMessage,
        stackTrace,
        errorType,
        resolved,
        timestamp,
        metadata,
      );

  @override
  String toString() => 'AppError(id: $id, errorType: $errorType, resolved: $resolved)';
}

/// Уровень критичности ошибки
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Расширение для уровня критичности ошибки
extension ErrorSeverityExtension on ErrorSeverity {
  String get displayName {
    switch (this) {
      case ErrorSeverity.low:
        return 'Низкий';
      case ErrorSeverity.medium:
        return 'Средний';
      case ErrorSeverity.high:
        return 'Высокий';
      case ErrorSeverity.critical:
        return 'Критический';
    }
  }

  String get description {
    switch (this) {
      case ErrorSeverity.low:
        return 'Незначительная ошибка, не влияющая на функциональность';
      case ErrorSeverity.medium:
        return 'Ошибка, которая может повлиять на пользовательский опыт';
      case ErrorSeverity.high:
        return 'Серьезная ошибка, влияющая на функциональность';
      case ErrorSeverity.critical:
        return 'Критическая ошибка, приводящая к сбою приложения';
    }
  }

  Color get color {
    switch (this) {
      case ErrorSeverity.low:
        return Colors.green;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.purple;
    }
  }
}

/// Статистика ошибок
class ErrorStatistics {
  const ErrorStatistics({
    required this.totalErrors,
    required this.resolvedErrors,
    required this.unresolvedErrors,
    required this.criticalErrors,
    required this.recentErrors,
    required this.errorsByType,
    required this.errorsByScreen,
    required this.errorsByDevice,
  });
  final int totalErrors;
  final int resolvedErrors;
  final int unresolvedErrors;
  final int criticalErrors;
  final int recentErrors;
  final Map<String, int> errorsByType;
  final Map<String, int> errorsByScreen;
  final Map<String, int> errorsByDevice;

  /// Процент решенных ошибок
  double get resolutionRate {
    if (totalErrors == 0) {
      return 0;
    }
    return (resolvedErrors / totalErrors) * 100;
  }

  /// Процент критических ошибок
  double get criticalErrorRate {
    if (totalErrors == 0) {
      return 0;
    }
    return (criticalErrors / totalErrors) * 100;
  }

  /// Процент недавних ошибок
  double get recentErrorRate {
    if (totalErrors == 0) {
      return 0;
    }
    return (recentErrors / totalErrors) * 100;
  }

  /// Получить самый проблемный экран
  String? get mostProblematicScreen {
    if (errorsByScreen.isEmpty) {
      return null;
    }
    return errorsByScreen.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Получить самый проблемный тип ошибки
  String? get mostCommonErrorType {
    if (errorsByType.isEmpty) {
      return null;
    }
    return errorsByType.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  String toString() =>
      'ErrorStatistics(totalErrors: $totalErrors, resolvedErrors: $resolvedErrors, criticalErrors: $criticalErrors)';
}
