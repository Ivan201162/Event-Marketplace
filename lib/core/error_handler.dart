import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'feature_flags.dart';

/// Глобальный обработчик ошибок для приложения
class GlobalErrorHandler {
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();

  /// Инициализация обработчика ошибок
  static void initialize() {
    // Обработка ошибок Flutter
    FlutterError.onError = (details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        _logError(details.exception, details.stack);
      }
    };

    // Обработка асинхронных ошибок
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack);
      return true;
    };

    // Обработка ошибок в зонах
    runZonedGuarded(
      () {
        // Здесь будет запуск приложения
      },
      _logError,
    );
  }

  /// Логирование ошибки
  static void _logError(error, StackTrace? stack) {
    if (FeatureFlags.debugMode) {
      developer.log(
        'Error: $error',
        name: 'GlobalErrorHandler',
        error: error,
        stackTrace: stack,
      );
    }

    // Отправка в Crashlytics (если включена аналитика)
    if (FeatureFlags.analyticsEnabled) {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
  }

  /// Обработка ошибки с показом пользователю
  static void handleError(
    BuildContext context,
    error, {
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    if (FeatureFlags.debugMode) {
      developer.log(
        'Handling error: $error',
        name: 'GlobalErrorHandler',
        error: error,
      );
    }

    // Показ диалога с ошибкой
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Ошибка'),
        content: Text(message ?? _getErrorMessage(error)),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Повторить'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Получение понятного сообщения об ошибке
  static String _getErrorMessage(error) {
    if (error is String) {
      return error;
    }

    // Обработка специфичных типов ошибок
    if (error.toString().contains('network')) {
      return 'Проблема с подключением к интернету';
    }
    if (error.toString().contains('timeout')) {
      return 'Превышено время ожидания';
    }
    if (error.toString().contains('permission')) {
      return 'Недостаточно прав доступа';
    }

    return 'Произошла неизвестная ошибка';
  }

  /// Обработка ошибки без показа диалога
  static void logError(error, [StackTrace? stack]) {
    _logError(error, stack);
  }

  /// Обработка ошибки с контекстом
  static void logErrorWithContext(
    String context,
    error, [
    StackTrace? stack,
  ]) {
    if (FeatureFlags.debugMode) {
      developer.log(
        'Error in $context: $error',
        name: 'GlobalErrorHandler',
        error: error,
        stackTrace: stack,
      );
    }

    if (FeatureFlags.analyticsEnabled) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        information: ['Context: $context'],
      );
    }
  }
}

/// Виджет для отлова ошибок в UI
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });
  final Widget child;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!);
      }
      return _DefaultErrorWidget(error: _error!);
    }
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      setState(() {
        _error = details.exception;
      });
      GlobalErrorHandler.logError(details.exception, details.stack);
    };
  }
}

/// Виджет по умолчанию для отображения ошибок
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Что-то пошло не так',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (FeatureFlags.debugMode)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error.toString(),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Перезапуск приложения
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                child: const Text('Перезапустить'),
              ),
            ],
          ),
        ),
      );
}
