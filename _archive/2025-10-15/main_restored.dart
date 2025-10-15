import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/restored_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EventMarketplaceApp()));
}

class EventMarketplaceApp extends ConsumerStatefulWidget {
  const EventMarketplaceApp({super.key});

  @override
  ConsumerState<EventMarketplaceApp> createState() =>
      _EventMarketplaceAppState();
}

class _EventMarketplaceAppState extends ConsumerState<EventMarketplaceApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString('themeMode') ?? 'system';
      setState(() {
        _themeMode = _getThemeModeFromString(themeString);
      });
    } catch (e) {
      setState(() {
        _themeMode = ThemeMode.system;
      });
    }
  }

  ThemeMode _getThemeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    _saveTheme(mode);
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', mode.toString().split('.').last);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Event Marketplace',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: _themeMode,
        home: RestoredHomeScreen(
          onThemeChange: _changeTheme,
        ),
        debugShowCheckedModeBanner: false,
      );
}
