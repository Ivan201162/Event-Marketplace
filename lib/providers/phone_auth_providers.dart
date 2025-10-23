import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для хранения verification ID
final phoneVerificationIdProvider = StateProvider<String?>((ref) => null);

/// Провайдер для состояния phone auth
final phoneAuthStateProvider =
    StateProvider<PhoneAuthState>((ref) => PhoneAuthState.idle);

/// Провайдер для номера телефона
final phoneNumberProvider = StateProvider<String?>((ref) => null);

/// Провайдер для таймера обратного отсчета
final phoneAuthTimerProvider = StateProvider<int>((ref) => 0);

/// Провайдер для возможности повторной отправки
final canResendCodeProvider = StateProvider<bool>((ref) => false);

/// Состояния phone auth
enum PhoneAuthState {
  idle, // Начальное состояние
  sending, // Отправка SMS
  codeSent, // SMS отправлен
  verifying, // Проверка кода
  verified, // Код подтвержден
  error, // Ошибка
}

/// Провайдер для получения текущего состояния
final currentPhoneAuthStateProvider = Provider<PhoneAuthState>((ref) {
  return ref.watch(phoneAuthStateProvider);
});

/// Провайдер для проверки, можно ли отправить код повторно
final canResendCodeProvider = Provider<bool>((ref) {
  return ref.watch(canResendCodeProvider);
});

/// Провайдер для получения оставшегося времени таймера
final remainingTimeProvider = Provider<int>((ref) {
  return ref.watch(phoneAuthTimerProvider);
});
