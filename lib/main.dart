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
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
            ],
          ),
        ),
      ),
    ),
  );
  
  print("🚀 runApp() выполнен - ШАГ 6");
}
