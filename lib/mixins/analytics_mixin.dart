import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/firebase_analytics_providers.dart';
import '../services/firebase_analytics_service.dart';

/// Миксин для автоматического отслеживания экранов и событий
mixin AnalyticsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  FirebaseAnalyticsService? _analyticsService;
  String? _currentScreenName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAnalytics();
    });
  }

  @override
  void dispose() {
    _analyticsService = null;
    super.dispose();
  }

  /// Инициализация аналитики
  void _initializeAnalytics() {
    _analyticsService = ref.read(firebaseAnalyticsServiceProvider);
    _trackScreenView();
  }

  /// Отслеживание просмотра экрана
  void _trackScreenView() {
    if (_analyticsService != null) {
      _currentScreenName = widget.runtimeType.toString();
      _analyticsService!.logScreenView(
        screenName: _currentScreenName!,
        screenClass: widget.runtimeType.toString(),
      );
    }
  }

  /// Отслеживание события
  Future<void> trackEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (_analyticsService != null) {
      await _analyticsService!.logEvent(
        name: name,
        parameters: parameters,
      );
    }
  }

  /// Отслеживание пользовательского действия
  Future<void> trackUserAction({
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    final eventParameters = <String, dynamic>{
      'screen': _currentScreenName ?? 'unknown',
      'action': action,
      if (parameters != null) ...parameters,
    };

    await trackEvent(
      name: 'user_action',
      parameters: eventParameters,
    );
  }

  /// Отслеживание ошибки
  Future<void> trackError({
    required String error,
    String? action,
    Map<String, dynamic>? parameters,
  }) async {
    final errorParameters = <String, dynamic>{
      'error': error,
      'screen': _currentScreenName ?? 'unknown',
      if (action != null) 'action': action,
      if (parameters != null) ...parameters,
    };

    await trackEvent(
      name: 'app_error',
      parameters: errorParameters,
    );
  }

  /// Отслеживание времени загрузки
  Future<void> trackLoadTime({
    required int loadTimeMs,
    String? component,
  }) async {
    await trackEvent(
      name: 'load_time',
      parameters: {
        'load_time_ms': loadTimeMs,
        'screen': _currentScreenName ?? 'unknown',
        if (component != null) 'component': component,
      },
    );
  }

  /// Отслеживание клика по элементу
  Future<void> trackClick({
    required String element,
    Map<String, dynamic>? parameters,
  }) async {
    await trackUserAction(
      action: 'click',
      parameters: {
        'element': element,
        if (parameters != null) ...parameters,
      },
    );
  }

  /// Отслеживание навигации
  Future<void> trackNavigation({
    required String destination,
    String? source,
  }) async {
    await trackEvent(
      name: 'navigation',
      parameters: {
        'destination': destination,
        'source': source ?? _currentScreenName ?? 'unknown',
      },
    );
  }

  /// Отслеживание поиска
  Future<void> trackSearch({
    required String query,
    String? category,
    int? resultsCount,
  }) async {
    await trackEvent(
      name: 'search',
      parameters: {
        'query': query,
        if (category != null) 'category': category,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  /// Отслеживание фильтрации
  Future<void> trackFilter({
    required Map<String, dynamic> filters,
    int? resultsCount,
  }) async {
    await trackEvent(
      name: 'filter',
      parameters: {
        ...filters,
        if (resultsCount != null) 'results_count': resultsCount,
      },
    );
  }

  /// Отслеживание формы
  Future<void> trackForm({
    required String formName,
    required String action,
    bool isSuccess = true,
    String? error,
  }) async {
    await trackEvent(
      name: 'form_submission',
      parameters: {
        'form_name': formName,
        'action': action,
        'is_success': isSuccess,
        if (error != null) 'error': error,
      },
    );
  }

  /// Отслеживание покупки/платежа
  Future<void> trackPurchase({
    required String itemId,
    required String itemName,
    required double value,
    String? currency,
    String? category,
  }) async {
    await trackEvent(
      name: 'purchase',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'value': value,
        if (currency != null) 'currency': currency,
        if (category != null) 'category': category,
      },
    );
  }

  /// Отслеживание просмотра контента
  Future<void> trackContentView({
    required String contentType,
    required String contentId,
    String? contentName,
    Map<String, dynamic>? parameters,
  }) async {
    await trackEvent(
      name: 'content_view',
      parameters: {
        'content_type': contentType,
        'content_id': contentId,
        if (contentName != null) 'content_name': contentName,
        if (parameters != null) ...parameters,
      },
    );
  }

  /// Отслеживание социального взаимодействия
  Future<void> trackSocialInteraction({
    required String network,
    required String action,
    String? target,
  }) async {
    await trackEvent(
      name: 'social_interaction',
      parameters: {
        'network': network,
        'action': action,
        if (target != null) 'target': target,
      },
    );
  }

  /// Отслеживание времени на экране
  Future<void> trackTimeOnScreen({
    required int timeInSeconds,
  }) async {
    await trackEvent(
      name: 'time_on_screen',
      parameters: {
        'time_seconds': timeInSeconds,
        'screen': _currentScreenName ?? 'unknown',
      },
    );
  }

  /// Получить сервис аналитики
  FirebaseAnalyticsService? get analyticsService => _analyticsService;

  /// Получить текущее имя экрана
  String? get currentScreenName => _currentScreenName;
}
