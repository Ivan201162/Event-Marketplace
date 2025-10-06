import 'dart:async';

import '../core/logger.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Сервис для управления таймаутом сессии
class SessionTimeoutService {
  factory SessionTimeoutService() => _instance;
  SessionTimeoutService._internal();
  static final SessionTimeoutService _instance =
      SessionTimeoutService._internal();

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  Timer? _timeoutTimer;
  Timer? _activityTimer;
  DateTime? _lastActivity;

  // Таймаут сессии (30 минут)
  static const Duration _sessionTimeout = Duration(minutes: 30);

  // Интервал проверки активности (1 минута)
  static const Duration _activityCheckInterval = Duration(minutes: 1);

  // Таймаут неактивности (15 минут)
  static const Duration _inactivityTimeout = Duration(minutes: 15);

  /// Инициализировать отслеживание сессии
  void initialize() {
    AppLogger.logI(
      'Инициализация отслеживания сессии',
      'session_timeout_service',
    );

    // Запускаем таймер проверки активности
    _startActivityTimer();

    // Запускаем таймер таймаута сессии
    _startSessionTimer();
  }

  /// Остановить отслеживание сессии
  void dispose() {
    AppLogger.logI('Остановка отслеживания сессии', 'session_timeout_service');
    _timeoutTimer?.cancel();
    _activityTimer?.cancel();
    _timeoutTimer = null;
    _activityTimer = null;
  }

  /// Отметить активность пользователя
  void markActivity() {
    _lastActivity = DateTime.now();
    AppLogger.logD(
      'Активность пользователя отмечена',
      'session_timeout_service',
    );
  }

  /// Запустить таймер проверки активности
  void _startActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(_activityCheckInterval, (timer) {
      _checkInactivity();
    });
  }

  /// Запустить таймер таймаута сессии
  void _startSessionTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_sessionTimeout, _handleSessionTimeout);
  }

  /// Проверить неактивность пользователя
  void _checkInactivity() {
    if (_lastActivity == null) {
      _lastActivity = DateTime.now();
      return;
    }

    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivity!);

    if (timeSinceLastActivity > _inactivityTimeout) {
      AppLogger.logI(
        'Пользователь неактивен более ${_inactivityTimeout.inMinutes} минут',
        'session_timeout_service',
      );
      _handleInactivity();
    }
  }

  /// Обработать неактивность пользователя
  Future<void> _handleInactivity() async {
    try {
      AppLogger.logI(
        'Обработка неактивности пользователя',
        'session_timeout_service',
      );

      // Сохраняем информацию о неактивности
      await _storageService.setString(
        'last_inactivity',
        DateTime.now().toIso8601String(),
      );

      // Выходим из системы
      await _authService.signOut();

      AppLogger.logI(
        'Пользователь вышел из-за неактивности',
        'session_timeout_service',
      );
    } catch (e) {
      AppLogger.logE(
        'Ошибка обработки неактивности',
        'session_timeout_service',
        e,
      );
    }
  }

  /// Обработать таймаут сессии
  Future<void> _handleSessionTimeout() async {
    try {
      AppLogger.logI('Обработка таймаута сессии', 'session_timeout_service');

      // Сохраняем информацию о таймауте
      await _storageService.setString(
        'session_timeout',
        DateTime.now().toIso8601String(),
      );

      // Выходим из системы
      await _authService.signOut();

      AppLogger.logI(
        'Пользователь вышел из-за таймаута сессии',
        'session_timeout_service',
      );
    } catch (e) {
      AppLogger.logE(
        'Ошибка обработки таймаута сессии',
        'session_timeout_service',
        e,
      );
    }
  }

  /// Сбросить таймеры (при новой активности)
  void resetTimers() {
    AppLogger.logD('Сброс таймеров сессии', 'session_timeout_service');
    _startSessionTimer();
    markActivity();
  }

  /// Получить время последней активности
  DateTime? get lastActivity => _lastActivity;

  /// Получить оставшееся время сессии
  Duration? get remainingSessionTime {
    if (_timeoutTimer == null || !_timeoutTimer!.isActive) {
      return null;
    }

    final now = DateTime.now();
    final sessionStart = now.subtract(_sessionTimeout);
    final elapsed = now.difference(sessionStart);

    return _sessionTimeout - elapsed;
  }

  /// Получить оставшееся время до неактивности
  Duration? get remainingInactivityTime {
    if (_lastActivity == null) {
      return _inactivityTimeout;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastActivity!);

    if (elapsed > _inactivityTimeout) {
      return Duration.zero;
    }

    return _inactivityTimeout - elapsed;
  }

  /// Проверить, активна ли сессия
  bool get isSessionActive {
    final remaining = remainingSessionTime;
    return remaining != null && remaining > Duration.zero;
  }

  /// Проверить, активен ли пользователь
  bool get isUserActive {
    final remaining = remainingInactivityTime;
    return remaining != null && remaining > Duration.zero;
  }

  /// Получить статистику сессии
  Map<String, dynamic> getSessionStats() => {
        'lastActivity': _lastActivity?.toIso8601String(),
        'remainingSessionTime': remainingSessionTime?.inSeconds,
        'remainingInactivityTime': remainingInactivityTime?.inSeconds,
        'isSessionActive': isSessionActive,
        'isUserActive': isUserActive,
        'sessionTimeoutMinutes': _sessionTimeout.inMinutes,
        'inactivityTimeoutMinutes': _inactivityTimeout.inMinutes,
      };
}
