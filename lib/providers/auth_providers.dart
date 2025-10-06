import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Провайдер сервиса аутентификации
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Провайдер текущего пользователя приложения
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Провайдер состояния авторизации
final authStateProvider = StreamProvider<bool>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);

  return currentUserAsync.when(
    data: (user) => Stream.value(user != null),
    loading: () => Stream.value(false),
    error: (_, __) => Stream.value(false),
  );
});

/// Провайдер для формы входа
final loginFormNotifierProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>(
  (ref) => LoginFormNotifier(ref.read(authServiceProvider)),
);

/// Состояние формы входа
class LoginFormState {
  const LoginFormState({
    this.isLoading = false,
    this.error,
    this.isEmailMode = true,
    this.isPhoneMode = false,
    this.isGuestMode = false,
    this.phoneVerificationId,
  });
  final bool isLoading;
  final String? error;
  final bool isEmailMode;
  final bool isPhoneMode;
  final bool isGuestMode;
  final String? phoneVerificationId;

  LoginFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isEmailMode,
    bool? isPhoneMode,
    bool? isGuestMode,
    String? phoneVerificationId,
  }) =>
      LoginFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isEmailMode: isEmailMode ?? this.isEmailMode,
        isPhoneMode: isPhoneMode ?? this.isPhoneMode,
        isGuestMode: isGuestMode ?? this.isGuestMode,
        phoneVerificationId: phoneVerificationId ?? this.phoneVerificationId,
      );
}

/// Нотификатор формы входа
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier(this._authService) : super(const LoginFormState());
  final AuthService _authService;

  /// Вход по email и паролю
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signInWithEmail(email, password);
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Регистрация по email и паролю
  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signUpWithEmail(
        email,
        password,
        displayName: displayName,
      );
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Отправка SMS кода
  Future<void> sendPhoneCode(String phoneNumber) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signInWithPhone(phoneNumber);
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Подтверждение SMS кода
  Future<void> confirmPhoneCode(String smsCode) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.confirmPhoneCode(smsCode);
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Вход как гость
  Future<void> signInAsGuest() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signInAsGuest();
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Переключение режима входа
  void setEmailMode() {
    state = state.copyWith(
      isEmailMode: true,
      isPhoneMode: false,
      isGuestMode: false,
    );
  }

  void setPhoneMode() {
    state = state.copyWith(
      isEmailMode: false,
      isPhoneMode: true,
      isGuestMode: false,
    );
  }

  void setGuestMode() {
    state = state.copyWith(
      isEmailMode: false,
      isPhoneMode: false,
      isGuestMode: true,
    );
  }

  /// Вход с тестовым email
  Future<void> signInWithTestEmail() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signInWithTestEmail();
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Регистрация с тестовым email
  Future<void> signUpWithTestEmail() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signUpWithTestEmail();
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Вход с тестовым телефоном
  Future<void> signInWithTestPhone() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signInWithTestPhone();
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith();
  }
}
