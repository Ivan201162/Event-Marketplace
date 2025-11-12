/// SmartSyncService - V7.6
/// Объединяет Motion Depth, Dynamic Canvas и Ambient Engine

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:event_marketplace_app/services/motion_depth/motion_depth_service.dart';
import 'package:event_marketplace_app/services/dynamic_canvas/dynamic_canvas_service.dart';
import 'package:event_marketplace_app/services/ambient_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartSyncService extends ChangeNotifier {
  static final SmartSyncService _instance = SmartSyncService._internal();
  factory SmartSyncService() => _instance;
  SmartSyncService._internal();
  
  Offset _syncedOffset = Offset.zero;
  double _canvasIntensity = 0.0;
  double _ambientTemp = 0.0;
  bool _enabled = true;
  bool _isInitialized = false;
  
  /// Инициализация
  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('ambient_sync') ?? true;
    
    if (_enabled) {
      _startSyncing();
    }
    
    _isInitialized = true;
    log('SMART_SYNC_INIT: enabled=$_enabled');
  }
  
  /// Начать синхронизацию
  void _startSyncing() {
    // Слушаем Motion Depth
    MotionDepthService.tiltOffset.addListener(_onMotionChange);
    
    // Слушаем Dynamic Canvas
    DynamicCanvasService.intensity.addListener(_onCanvasChange);
    
    // Слушаем Ambient Engine
    AmbientEngine().colorTemperature.addListener(_onAmbientChange);
    
    log('SMART_SYNC_START');
  }
  
  void _onMotionChange() {
    _updateSyncedOffset();
  }
  
  void _onCanvasChange() {
    _updateSyncedOffset();
    _updateCanvasIntensity();
  }
  
  void _onAmbientChange() {
    _updateAmbientTemp();
  }
  
  /// Обновить синхронизированный offset
  void _updateSyncedOffset() {
    final tilt = MotionDepthService.tiltOffset.value;
    final intensity = DynamicCanvasService.intensity.value;
    
    _syncedOffset = MotionDepthService.syncWithCanvas(intensity);
    notifyListeners();
  }
  
  /// Обновить интенсивность canvas
  void _updateCanvasIntensity() {
    _canvasIntensity = DynamicCanvasService.intensity.value;
    notifyListeners();
  }
  
  /// Обновить температуру ambient
  void _updateAmbientTemp() {
    _ambientTemp = AmbientEngine().colorTemperature.value;
    notifyListeners();
  }
  
  /// Остановить синхронизацию
  void _stopSyncing() {
    MotionDepthService.tiltOffset.removeListener(_onMotionChange);
    DynamicCanvasService.intensity.removeListener(_onCanvasChange);
    AmbientEngine().colorTemperature.removeListener(_onAmbientChange);
    log('SMART_SYNC_STOP');
  }
  
  /// Переключение включено/выключено
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ambient_sync', enabled);
    
    if (enabled) {
      _startSyncing();
    } else {
      _stopSyncing();
    }
    
    log('SMART_SYNC_ENABLED:$enabled');
  }
  
  /// Адаптация на основе времени суток
  void adaptToTimeOfDay() {
    final hour = DateTime.now().hour;
    final isDay = hour >= 6 && hour < 20;
    
    if (isDay) {
      // День → яркий визуальный отклик
      log('SMART_SYNC_ADAPT:day');
    } else {
      // Ночь → мягкие тёплые пульсации
      log('SMART_SYNC_ADAPT:night');
    }
  }
  
  /// Очистка ресурсов
  void dispose() {
    _stopSyncing();
    super.dispose();
    _isInitialized = false;
  }
  
  // Getters
  Offset get syncedOffset => _syncedOffset;
  double get canvasIntensity => _canvasIntensity;
  double get ambientTemp => _ambientTemp;
  bool get enabled => _enabled;
  bool get isInitialized => _isInitialized;
}
