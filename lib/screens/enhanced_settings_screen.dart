import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class EnhancedSettingsScreen extends ConsumerWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Тема'),
            subtitle: Text(themeMode.name),
            onTap: () {
              // Переключение темы
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('О приложении'),
            subtitle: Text('Версия 1.0.0'),
          ),
        ],
      ),
    );
  }
}