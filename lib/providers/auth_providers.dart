import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

/// Провайдер сервиса аутентификации
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Провайдер текущего пользователя Firebase
final currentFirebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Провайдер текущего пользователя приложения
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserStream;
});

/// Провайдер состояния аутентификации
final authStateProvider = Provider<AuthState>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) =>
        user != null ? AuthState.authenticated : AuthState.unauthenticated,
    loading: () => AuthState.loading,
    error: (_, __) => AuthState.error,
  );
});

/// Провайдер роли текущего пользователя
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.whenOrNull(
    data: (user) => user?.role,
  );
});

/// Провайдер для проверки, является ли пользователь специалистом
final isSpecialistProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.specialist;
});

/// Провайдер для проверки, является ли пользователь заказчиком
final isCustomerProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.customer;
});

/// Провайдер для восстановления сессии
final sessionRestoreProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.restoreSession();
});

/// Провайдер для проверки валидности сессии
final sessionValidProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isSessionValid();
});

/// Провайдер для проверки, является ли пользователь гостем
final isGuestProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.guest;
});

/// Провайдер для проверки, авторизован ли пользователь
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState == AuthState.authenticated;
});

/// Провайдер для проверки, загружается ли аутентификация
final isLoadingAuthProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState == AuthState.loading;
});

/// Провайдер для проверки, есть ли ошибка аутентификации
final hasAuthErrorProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState == AuthState.error;
});

/// Состояния аутентификации
enum AuthState {
  loading, // Загрузка
  authenticated, // Авторизован
  unauthenticated, // Не авторизован
  error, // Ошибка
}

/// Провайдер для управления состоянием формы входа
final loginFormProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier(ref.read(authServiceProvider));
});

/// Состояние формы входа
class LoginFormState {
  final String email;
  final String password;
  final String? errorMessage;
  final bool isLoading;
  final bool isSignUpMode;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.errorMessage,
    this.isLoading = false,
    this.isSignUpMode = false,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    String? errorMessage,
    bool? isLoading,
    bool? isSignUpMode,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isSignUpMode: isSignUpMode ?? this.isSignUpMode,
    );
  }
}

/// Нотификатор для управления формой входа
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  final AuthService _authService;

  LoginFormNotifier(this._authService) : super(const LoginFormState());

  /// Обновить email
  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  /// Обновить пароль
  void updatePassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  /// Переключить режим регистрации/входа
  void toggleSignUpMode() {
    state = state.copyWith(
      isSignUpMode: !state.isSignUpMode,
      errorMessage: null,
    );
  }

  /// Войти
  Future<void> signIn() async {
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(errorMessage: 'Заполните все поля');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.signInWithEmailAndPassword(
        email: state.email,
        password: state.password,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Зарегистрироваться
  Future<void> signUp({
    required String displayName,
    required UserRole role,
  }) async {
    if (state.email.isEmpty || state.password.isEmpty || displayName.isEmpty) {
      state = state.copyWith(errorMessage: 'Заполните все поля');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.signUpWithEmailAndPassword(
        email: state.email,
        password: state.password,
        displayName: displayName,
        role: role,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Войти как гость
  Future<void> signInAsGuest() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.signInAsGuest();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Сбросить пароль
  Future<void> resetPassword() async {
    if (state.email.isEmpty) {
      state = state.copyWith(errorMessage: 'Введите email для сброса пароля');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.resetPassword(state.email);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Письмо для сброса пароля отправлено на ${state.email}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
