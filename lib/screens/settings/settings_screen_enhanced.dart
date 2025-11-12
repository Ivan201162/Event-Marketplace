/// Settings Screen Enhanced - V7.6 Premium UI
/// Экран настроек с секциями и сохранением

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_marketplace_app/ui/components/gradient_appbar.dart';
import 'package:event_marketplace_app/theme/backgrounds.dart';
import 'package:event_marketplace_app/services/feedback_service.dart';
import 'package:event_marketplace_app/services/soundscape_service.dart';
import 'package:event_marketplace_app/services/motion_depth/motion_depth_service.dart';
import 'package:event_marketplace_app/services/dynamic_canvas/dynamic_canvas_service.dart';
import 'package:event_marketplace_app/services/sync/smart_sync_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';

class SettingsScreenEnhanced extends StatefulWidget {
  const SettingsScreenEnhanced({super.key});

  @override
  State<SettingsScreenEnhanced> createState() => _SettingsScreenEnhancedState();
}

class _SettingsScreenEnhancedState extends State<SettingsScreenEnhanced> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _soundEnabled = true;
  bool _soundscapeEnabled = true;
  bool _hapticEnabled = true;
  bool _motionDepthEnabled = true;
  bool _audioReactiveEnabled = true;
  bool _ambientSyncEnabled = true;
  double _soundscapeVolume = 0.15;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    debugLog('SETTINGS_OPENED');
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _soundscapeEnabled = prefs.getBool('soundscape_enabled') ?? true;
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      _motionDepthEnabled = prefs.getBool('motion_depth_enabled') ?? true;
      _audioReactiveEnabled = prefs.getBool('audio_reactive_canvas') ?? true;
      _ambientSyncEnabled = prefs.getBool('ambient_sync') ?? true;
      _soundscapeVolume = prefs.getDouble('soundscape_volume') ?? 0.15;
    });
  }
  
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() => _themeMode = mode);
    debugLog('SETTINGS_THEME:${mode.name}');
  }
  
  Future<void> _saveSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
    await FeedbackService().setSoundEnabled(enabled);
    setState(() => _soundEnabled = enabled);
    debugLog('SETTINGS_SOUND:${enabled ? "on" : "off"}');
  }
  
  Future<void> _saveSoundscapeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundscape_enabled', enabled);
    await SoundscapeService().setEnabled(enabled);
    setState(() => _soundscapeEnabled = enabled);
    debugLog('SETTINGS_SOUNDSCAPE:${enabled ? "on" : "off"}');
  }
  
  Future<void> _saveHapticEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', enabled);
    await FeedbackService().setHapticEnabled(enabled);
    setState(() => _hapticEnabled = enabled);
    debugLog('SETTINGS_HAPTIC:${enabled ? "on" : "off"}');
  }
  
  Future<void> _saveMotionDepthEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motion_depth_enabled', enabled);
    await MotionDepthService().setEnabled(enabled);
    setState(() => _motionDepthEnabled = enabled);
    debugLog('SETTINGS_MOTION_DEPTH:${enabled ? "on" : "off"}');
  }
  
  Future<void> _saveAudioReactiveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_reactive_canvas', enabled);
    await DynamicCanvasService().setEnabled(enabled);
    setState(() => _audioReactiveEnabled = enabled);
    debugLog('SETTINGS_AUDIO_REACTIVE:${enabled ? "on" : "off"}');
  }
  
  Future<void> _saveAmbientSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ambient_sync', enabled);
    await SmartSyncService().setEnabled(enabled);
    setState(() => _ambientSyncEnabled = enabled);
    debugLog('SETTINGS_AMBIENT_SYNC:${enabled ? "on" : "off"}');
  }
  
  Future<void> _saveSoundscapeVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('soundscape_volume', volume);
    await SoundscapeService().setVolume(volume);
    setState(() => _soundscapeVolume = volume);
    debugLog('SETTINGS_SOUNDSCAPE_VOLUME:$volume');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: "Настройки", showSettings: false),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientColors(context),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Профиль
            GlassContainer(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Профиль'),
                subtitle: const Text('Редактировать профиль'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Переход в редактирование профиля
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Тема
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('🌞 Тема', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Системная'),
                    value: ThemeMode.system,
                    groupValue: _themeMode,
                    onChanged: (value) => value != null ? _saveThemeMode(value) : null,
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Светлая'),
                    value: ThemeMode.light,
                    groupValue: _themeMode,
                    onChanged: (value) => value != null ? _saveThemeMode(value) : null,
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Тёмная'),
                    value: ThemeMode.dark,
                    groupValue: _themeMode,
                    onChanged: (value) => value != null ? _saveThemeMode(value) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Звук
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('🔊 Звук', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SwitchListTile(
                    title: const Text('🎵 Звуки интерфейса'),
                    value: _soundEnabled,
                    onChanged: _saveSoundEnabled,
                  ),
                  SwitchListTile(
                    title: const Text('🎚️ Soundscape (атмосферные фоны)'),
                    value: _soundscapeEnabled,
                    onChanged: _saveSoundscapeEnabled,
                  ),
                  if (_soundscapeEnabled) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Громкость: ${(_soundscapeVolume * 100).round()}%'),
                          Slider(
                            value: _soundscapeVolume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: _saveSoundscapeVolume,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Хаптик
            GlassContainer(
              child: SwitchListTile(
                title: const Text('💫 Вибрация'),
                value: _hapticEnabled,
                onChanged: _saveHapticEnabled,
              ),
            ),
            const SizedBox(height: 16),
            
            // Motion & Ambient
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('🌀 Motion & Ambient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SwitchListTile(
                    title: const Text('🎚️ Motion Depth'),
                    value: _motionDepthEnabled,
                    onChanged: _saveMotionDepthEnabled,
                  ),
                  SwitchListTile(
                    title: const Text('🎵 Audio Reactive Canvas'),
                    value: _audioReactiveEnabled,
                    onChanged: _saveAudioReactiveEnabled,
                  ),
                  SwitchListTile(
                    title: const Text('💫 Ambient Sync'),
                    value: _ambientSyncEnabled,
                    onChanged: _saveAmbientSyncEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Выход
            GlassContainer(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Выйти', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  debugLog('SETTINGS_LOGOUT:OK');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

