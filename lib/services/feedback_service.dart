/// FeedbackService - Haptic & Sound Feedback System
/// V7.4: Вибрация и звуки интерфейса

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hapticEnabled = true;
  bool _soundEnabled = true;
  
  /// Инициализация
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    log('FEEDBACK_INIT: haptic=$_hapticEnabled, sound=$_soundEnabled');
  }
  
  /// Вибрация: light
  Future<void> hapticLight() async {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.lightImpact();
      log('HAPTIC:light');
    } catch (e) {
      log('HAPTIC_ERR: $e');
    }
  }
  
  /// Вибрация: medium
  Future<void> hapticMedium() async {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      log('HAPTIC:medium');
    } catch (e) {
      log('HAPTIC_ERR: $e');
    }
  }
  
  /// Вибрация: heavy
  Future<void> hapticHeavy() async {
    if (!_hapticEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      log('HAPTIC:heavy');
    } catch (e) {
      log('HAPTIC_ERR: $e');
    }
  }
  
  /// Звук: tap
  Future<void> soundTap() async {
    if (!_soundEnabled) return;
    try {
      // Используем системный звук или встроенный
      await _audioPlayer.play(AssetSource('sounds/tap.mp3'));
      log('SOUND:tap');
    } catch (e) {
      // Если файл не найден, просто логируем
      log('SOUND:tap (silent)');
    }
  }
  
  /// Звук: send
  Future<void> soundSend() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/send.mp3'));
      log('SOUND:send');
    } catch (e) {
      log('SOUND:send (silent)');
    }
  }
  
  /// Звук: success
  Future<void> soundSuccess() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      log('SOUND:success');
    } catch (e) {
      log('SOUND:success (silent)');
    }
  }
  
  /// Звук: error
  Future<void> soundError() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
      log('SOUND:error');
    } catch (e) {
      log('SOUND:error (silent)');
    }
  }
  
  /// Переключение haptic
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', enabled);
    log('HAPTIC_SET:$enabled');
  }
  
  /// Переключение sound
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
    log('SOUND_SET:$enabled');
  }
  
  bool get hapticEnabled => _hapticEnabled;
  bool get soundEnabled => _soundEnabled;
}
