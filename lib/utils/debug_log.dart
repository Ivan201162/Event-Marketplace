import 'dart:developer' as dev;

/// Утилита для логирования, работает в release и debug
void debugLog(String msg) {
  // печатаем всегда, даже в release
  // чтобы автосмок ловил маркеры в logcat
  dev.log(msg, name: 'APP');
  // дублируем в print на всякий случай
  print('APP: $msg');
}

