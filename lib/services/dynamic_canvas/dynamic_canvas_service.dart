/// DynamicCanvasService - V7.6
/// Анализ громкости микрофона для визуальной реакции интерфейса
/// Упрощённая версия без реального микрофона (симуляция для демонстрации)

import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicCanvasService {
  static final DynamicCanvasService _instance = DynamicCanvasService._internal();
  factory DynamicCanvasService() => _instance;
  DynamicCanvasService._internal();
  
  static final ValueNotifier<double> intensity = ValueNotifier(0.0);
  Timer? _simulationTimer;
  bool _enabled = true;
  bool _isInitialized = false;
  final math.Random _random = math.Random();
  
  /// Инициализация
  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('audio_reactive_canvas') ?? true;
    
    if (_enabled) {
      _startSimulation();
    }
    
    _isInitialized = true;
    log('DYNAMIC_CANVAS_INIT: enabled=$_enabled (simulation mode)');
  }
  
  /// Начать симуляцию (вместо реального микрофона)
  void _startSimulation() {
    _simulationTimer?.cancel();
    
    // Симуляция аудио-реакции с плавными изменениями
    double currentIntensity = 0.0;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_enabled) return;
      
      // Генерируем плавные изменения интенсивности (0.0-1.0)
      currentIntensity += (_random.nextDouble() - 0.5) * 0.1;
      currentIntensity = currentIntensity.clamp(0.0, 1.0);
      
      intensity.value = currentIntensity;
    });
    
    log('DYNAMIC_CANVAS_START (simulation)');
  }
  
  /// Остановить симуляцию
  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    intensity.value = 0.0;
    log('DYNAMIC_CANVAS_STOP');
  }
  
  /// Переключение включено/выключено
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_reactive_canvas', enabled);
    
    if (enabled) {
      _startSimulation();
    } else {
      _stopSimulation();
    }
    
    log('DYNAMIC_CANVAS_ENABLED:$enabled');
  }
  
  /// Очистка ресурсов
  void dispose() {
    _stopSimulation();
    intensity.dispose();
    _isInitialized = false;
  }
  
  bool get enabled => _enabled;
  bool get isInitialized => _isInitialized;
}
