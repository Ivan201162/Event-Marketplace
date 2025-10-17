import 'dart:ui';

import 'package:flutter/material.dart';

void main() async {
  print("🚀 main() запущен успешно - ШАГ 1");
  
  WidgetsFlutterBinding.ensureInitialized();
  print("🚀 WidgetsFlutterBinding.ensureInitialized() - ШАГ 2");

  // Настройка обработки ошибок
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print("🔥 Flutter error: ${details.exception}");
    print("Stack: ${details.stack}");
  };
  print("🚀 FlutterError.onError настроен - ШАГ 3");

  PlatformDispatcher.instance.onError = (error, stack) {
    print("🔥 Uncaught error: $error");
    print(stack);
    return true;
  };
  print("🚀 PlatformDispatcher.onError настроен - ШАГ 4");

  print("🚀 Запуск runApp() - ШАГ 5");
  
  runApp(const MyApp());
  
  print("🚀 runApp() выполнен - ШАГ 6");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("🚀 MyApp.build() вызван - ШАГ 7");
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DiagnosticScreen(),
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  @override
  void initState() {
    super.initState();
    print("🚀 DiagnosticScreen.initState() - ШАГ 8");
    
    // Автоматический переход к основному UI через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      print("🚀 Переход к основному UI - ШАГ 9");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainApp()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🚀 DiagnosticScreen.build() - ШАГ 10");
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rocket_launch,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '🚀 Приложение запущено',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Время: ${DateTime.now().toString()}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            const Text(
              'Переход к основному UI...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("🚀 MainApp.build() - ШАГ 11");
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '🏠 Основной экран',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Навигация работает!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
