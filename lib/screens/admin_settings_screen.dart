import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран настроек в админ-панели
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Настройки системы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Функция будет реализована в следующих версиях',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}
