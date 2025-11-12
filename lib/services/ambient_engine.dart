/// AmbientEngine - Smart Ambient Engine
/// V7.4: Реактивная адаптация интерфейса на основе действий пользователя

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:event_marketplace_app/services/soundscape_service.dart';
import 'package:event_marketplace_app/services/feedback_service.dart';
import 'package:event_marketplace_app/services/dynamic_canvas/dynamic_canvas_service.dart';

enum AmbientContext {
  calendar,
  chat,
  profile,
  feed,
  search,
  booking,
  publish,
  default_,
}

class AmbientEngine {
  static final AmbientEngine _instance = AmbientEngine._internal();
  factory AmbientEngine() => _instance;
  AmbientEngine._internal();
  
  final ValueNotifier<Color> _backgroundColor = ValueNotifier<Color>(Colors.transparent);
  final ValueNotifier<double> _colorTemperature = ValueNotifier<double>(0.0); // -1.0 (cold) to 1.0 (warm)
  final ValueNotifier<bool> _pulseActive = ValueNotifier<bool>(false);
  
  AmbientContext? _currentContext;
  Timer? _pulseTimer;
  bool _enabled = true;
  bool _audioReactive = true;
  
  /// Инициализация
  Future<void> init() async {
    // Слушаем изменения интенсивности звука для audio-reactive режима
    if (_audioReactive) {
      DynamicCanvasService.intensity.addListener(_onAudioIntensityChange);
    }
    log('AMBIENT_ENGINE_INIT: audioReactive=$_audioReactive');
  }
  
  /// Обработчик изменения интенсивности звука
  void _onAudioIntensityChange() {
    if (!_audioReactive || !_enabled) return;
    
    final intensity = DynamicCanvasService.intensity.value;
    
    // Если громкость высокая (>0.6) → тёплый оттенок
    if (intensity > 0.6) {
      _ambientColorShift(Colors.orangeAccent, null);
    } else {
      // Низкая громкость → холодный оттенок
      _ambientColorShift(Colors.blueAccent, null);
    }
    
    // Лёгкий пульс света в фоне под музыку
    if (intensity > 0.3) {
      _triggerPulse(
        Colors.white.withOpacity(intensity * 0.1),
        duration: (100 + intensity * 200).round(),
      );
    }
  }
  
  /// Сдвиг цвета ambient (внутренний метод)
  void _ambientColorShift(Color color, BuildContext? uiContext) {
    _colorTemperature.value = color == Colors.orangeAccent ? 0.5 : -0.5;
    
    if (uiContext != null) {
      final theme = Theme.of(uiContext);
      final baseColor = theme.scaffoldBackgroundColor;
      
      _backgroundColor.value = Color.lerp(
        baseColor,
        color.withOpacity(0.1),
        0.5,
      ) ?? baseColor;
      
      log('AMBIENT_COLOR_SHIFT_AUDIO:$color');
    } else {
      _backgroundColor.value = color.withOpacity(0.1);
    }
  }
  
  /// Установка audioReactive режима
  void setAudioReactive(bool enabled) {
    _audioReactive = enabled;
    log('AMBIENT_AUDIO_REACTIVE:$enabled');
  }
  
  /// Триггер контекста
  void triggerContext(AmbientContext context, BuildContext? uiContext) {
    if (!_enabled) return;
    
    _currentContext = context;
    
    switch (context) {
      case AmbientContext.calendar:
        // Календарь → тёплый оттенок
        _setColorTemperature(0.3, uiContext);
        _playAmbientTone('warm');
        log('AMBIENT_TRIGGER:calendar');
        break;
      
      case AmbientContext.chat:
        // Чат → холодный акцент
        _setColorTemperature(-0.2, uiContext);
        _playAmbientTone('focus');
        log('AMBIENT_TRIGGER:chat');
        break;
      
      case AmbientContext.profile:
        // Профиль → нейтральный с лёгким тёплым
        _setColorTemperature(0.1, uiContext);
        _playAmbientTone('swell');
        log('AMBIENT_TRIGGER:profile');
        break;
      
      case AmbientContext.publish:
        // Публикация → warm flash
        _triggerPulse(Colors.orange.withOpacity(0.2), duration: 500);
        _playAmbientTone('swell');
        log('AMBIENT_TRIGGER:publish');
        break;
      
      default:
        _setColorTemperature(0.0, uiContext);
        break;
    }
  }
  
  /// Установка цветовой температуры
  void _setColorTemperature(double temperature, BuildContext? uiContext) {
    _colorTemperature.value = temperature.clamp(-1.0, 1.0);
    
    if (uiContext != null) {
      final theme = Theme.of(uiContext);
      final baseColor = theme.scaffoldBackgroundColor;
      
      // Применяем температурный сдвиг
      if (temperature > 0) {
        // Тёплый (оранжевый/жёлтый оттенок)
        _backgroundColor.value = Color.lerp(
          baseColor,
          Colors.orange.withOpacity(0.05),
          temperature,
        ) ?? baseColor;
      } else if (temperature < 0) {
        // Холодный (синий/голубой оттенок)
        _backgroundColor.value = Color.lerp(
          baseColor,
          Colors.blue.withOpacity(0.05),
          -temperature,
        ) ?? baseColor;
      } else {
        _backgroundColor.value = baseColor;
      }
      
      log('AMBIENT_COLOR_SHIFT:$temperature');
    }
  }
  
  /// Триггер пульсации
  void _triggerPulse(Color color, {int duration = 300}) {
    _pulseActive.value = true;
    _backgroundColor.value = color;
    
    _pulseTimer?.cancel();
    _pulseTimer = Timer(Duration(milliseconds: duration), () {
      _pulseActive.value = false;
      _backgroundColor.value = Colors.transparent;
    });
  }
  
  /// Воспроизведение ambient tone
  void _playAmbientTone(String track) {
    final soundscape = SoundscapeService();
    
    switch (track) {
      case 'warm':
        // Тёплый тон (синхронизация со звуком)
        soundscape.onProfileOpen(); // Используем существующий swell
        log('AMBIENT_SOUND_SYNC:warm');
        break;
      
      case 'focus':
        // Фокусный тон
        soundscape.onTabSwitch();
        log('AMBIENT_SOUND_SYNC:focus');
        break;
      
      case 'swell':
        // Swell для успешных действий
        soundscape.onProfileOpen();
        log('AMBIENT_SOUND_SYNC:swell');
        break;
    }
  }
  
  /// Адаптация на основе времени суток
  void adaptToTimeOfDay() {
    final hour = DateTime.now().hour;
    final isDay = hour >= 6 && hour < 20;
    
    if (isDay) {
      // День → активные тона
      _colorTemperature.value = 0.1;
    } else {
      // Ночь → мягкий контраст
      _colorTemperature.value = -0.1;
    }
    
    log('AMBIENT_TIME_ADAPT:${isDay ? "day" : "night"}');
  }
  
  /// Переключение включено/выключено
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _backgroundColor.value = Colors.transparent;
      _colorTemperature.value = 0.0;
      _pulseActive.value = false;
    }
    log('AMBIENT_ENABLED:$enabled');
  }
  
  /// Очистка ресурсов
  void dispose() {
    _pulseTimer?.cancel();
    _backgroundColor.dispose();
    _colorTemperature.dispose();
    _pulseActive.dispose();
  }
  
  // Getters для ValueNotifiers
  ValueNotifier<Color> get backgroundColor => _backgroundColor;
  ValueNotifier<double> get colorTemperature => _colorTemperature;
  ValueNotifier<bool> get pulseActive => _pulseActive;
  bool get enabled => _enabled;
}

