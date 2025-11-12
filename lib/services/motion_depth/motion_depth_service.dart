/// MotionDepthService - V7.5
/// Использует motion_sensors для создания эффекта глубины при наклоне устройства

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MotionDepthService {
  static final MotionDepthService _instance = MotionDepthService._internal();
  factory MotionDepthService() => _instance;
  MotionDepthService._internal();
  
  static final ValueNotifier<Offset> tiltOffset = ValueNotifier(Offset.zero);
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _enabled = true;
  bool _isInitialized = false;
  
  /// Инициализация
  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('motion_depth_enabled') ?? true;
    
    if (_enabled) {
      _startListening();
    }
    
    _isInitialized = true;
    log('MOTION_DEPTH_INIT: enabled=$_enabled');
  }
  
  /// Начать прослушивание акселерометра
  void _startListening() {
    _accelerometerSubscription?.cancel();
    
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!_enabled) return;
      
      // Ограничиваем значения и применяем множитель
      final x = event.x.clamp(-5.0, 5.0);
      final y = event.y.clamp(-5.0, 5.0);
      
      // Для iOS — лёгкий tilt, для Android — уменьшенная амплитуда
      final multiplier = Platform.isIOS ? 2.0 : 1.5;
      
      tiltOffset.value = Offset(
        x * multiplier,
        y * multiplier,
      );
    });
    
    log('MOTION_DEPTH_START');
  }
  
  /// Остановить прослушивание
  void _stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    tiltOffset.value = Offset.zero;
    log('MOTION_DEPTH_STOP');
  }
  
  /// Переключение включено/выключено
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motion_depth_enabled', enabled);
    
    if (enabled) {
      _startListening();
    } else {
      _stopListening();
    }
    
    log('MOTION_DEPTH_ENABLED:$enabled');
  }
  
  /// Очистка ресурсов
  void dispose() {
    _stopListening();
    tiltOffset.dispose();
    _isInitialized = false;
  }
  
  /// Синхронизация с Dynamic Canvas
  static Offset get syncedOffset {
    try {
      final tilt = tiltOffset.value;
      // Импортируем DynamicCanvasService только при использовании
      // final dynamicFactor = DynamicCanvasService.intensity.value;
      // Временно используем статический множитель
      final dynamicFactor = 0.0; // Будет обновлено через SmartSyncService
      return Offset(
        tilt.dx * (1 + dynamicFactor),
        tilt.dy * (1 + dynamicFactor),
      );
    } catch (e) {
      return tiltOffset.value;
    }
  }
  
  /// Синхронизация с Canvas (вызывается из SmartSyncService)
  static Offset syncWithCanvas(double canvasIntensity) {
    final tilt = tiltOffset.value;
    return Offset(
      tilt.dx * (1 + canvasIntensity * 0.3),
      tilt.dy * (1 + canvasIntensity * 0.3),
    );
  }
  
  bool get enabled => _enabled;
  bool get isInitialized => _isInitialized;
}

