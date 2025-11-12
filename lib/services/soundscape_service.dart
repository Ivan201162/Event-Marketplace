/// SoundscapeService - Dynamic Soundscape System
/// V7.4: Атмосферные фоны день/ночь с реакциями на действия

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundscapeTheme { day, night }

class SoundscapeService {
  static final SoundscapeService _instance = SoundscapeService._internal();
  factory SoundscapeService() => _instance;
  SoundscapeService._internal();
  
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _reactionPlayer = AudioPlayer();
  SoundscapeTheme _currentTheme = SoundscapeTheme.day;
  bool _enabled = true;
  double _volume = 0.3; // 30% по умолчанию
  Timer? _themeCheckTimer;
  
  /// Инициализация
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('soundscape_enabled') ?? true;
    _volume = prefs.getDouble('soundscape_volume') ?? 0.3;
    
    // Автоопределение темы по времени суток
    _updateThemeByTime();
    
    // Проверка темы каждые 5 минут
    _themeCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateThemeByTime();
    });
    
    log('SOUNDSCAPE_INIT: theme=${_currentTheme.name}, enabled=$_enabled, volume=$_volume');
  }
  
  /// Обновление темы по времени суток
  void _updateThemeByTime() {
    final hour = DateTime.now().hour;
    final newTheme = (hour >= 6 && hour < 20) 
        ? SoundscapeTheme.day 
        : SoundscapeTheme.night;
    
    if (newTheme != _currentTheme) {
      _changeTheme(newTheme);
    }
  }
  
  /// Запуск звукового ландшафта
  Future<void> start() async {
    if (!_enabled) return;
    
    try {
      final assetPath = _currentTheme == SoundscapeTheme.day
          ? 'assets/soundscape/day_ambient.mp3'
          : 'assets/soundscape/night_lofi.mp3';
      
      await _ambientPlayer.setAsset(assetPath);
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.setVolume(_volume);
      await _ambientPlayer.play();
      
      log('SOUNDSCAPE_START:${_currentTheme.name}');
    } catch (e) {
      log('SOUNDSCAPE_START_ERR: $e');
    }
  }
  
  /// Остановка
  Future<void> stop() async {
    try {
      await _ambientPlayer.stop();
      log('SOUNDSCAPE_STOP');
    } catch (e) {
      log('SOUNDSCAPE_STOP_ERR: $e');
    }
  }
  
  /// Смена темы
  Future<void> _changeTheme(SoundscapeTheme theme) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    
    if (_enabled && _ambientPlayer.playing) {
      // Плавный переход (fade)
      await _ambientPlayer.setVolume(0.0);
      await Future.delayed(const Duration(milliseconds: 400));
      
      final assetPath = theme == SoundscapeTheme.day
          ? 'assets/soundscape/day_ambient.mp3'
          : 'assets/soundscape/night_lofi.mp3';
      
      await _ambientPlayer.setAsset(assetPath);
      await _ambientPlayer.setVolume(_volume);
      await _ambientPlayer.play();
      
      log('SOUNDSCAPE_CHANGE:${theme.name}');
    }
  }
  
  /// Реакция на скролл
  Future<void> onScroll() async {
    if (!_enabled) return;
    try {
      await _reactionPlayer.setAsset('assets/soundscape/swipe.mp3');
      await _reactionPlayer.setVolume(_volume * 0.3); // Тише для реакций
      await _reactionPlayer.play();
    } catch (e) {
      // Игнорируем ошибки реакций
    }
  }
  
  /// Реакция на переход вкладок
  Future<void> onTabSwitch() async {
    if (!_enabled) return;
    try {
      await _reactionPlayer.setAsset('assets/soundscape/fade.mp3');
      await _reactionPlayer.setVolume(_volume * 0.3);
      await _reactionPlayer.play();
    } catch (e) {
      // Игнорируем
    }
  }
  
  /// Реакция на открытие профиля
  Future<void> onProfileOpen() async {
    if (!_enabled) return;
    try {
      await _reactionPlayer.setAsset('assets/soundscape/swell.mp3');
      await _reactionPlayer.setVolume(_volume * 0.4);
      await _reactionPlayer.play();
    } catch (e) {
      // Игнорируем
    }
  }
  
  /// Установка громкости
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _ambientPlayer.setVolume(_volume);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('soundscape_volume', _volume);
    
    log('SOUNDSCAPE_VOLUME:$volume');
  }
  
  /// Переключение включено/выключено
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundscape_enabled', enabled);
    
    if (enabled) {
      await start();
    } else {
      await stop();
    }
    
    log('SOUNDSCAPE_ENABLED:$enabled');
  }
  
  /// Очистка ресурсов
  Future<void> dispose() async {
    _themeCheckTimer?.cancel();
    await _ambientPlayer.dispose();
    await _reactionPlayer.dispose();
  }
  
  SoundscapeTheme get currentTheme => _currentTheme;
  bool get enabled => _enabled;
  double get volume => _volume;
}

