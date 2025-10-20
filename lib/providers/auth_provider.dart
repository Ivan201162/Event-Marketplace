import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Модель состояния аутентификации
class AuthState {
  const AuthState({
    this.currentUserId,
    this.isAuthenticated = false,
    this.isLoading = false,
  });

  final String? currentUserId;
  final bool isAuthenticated;
  final bool isLoading;

  /// Для совместимости с существующим кодом
  Map<String, dynamic>? get currentUser => currentUserId != null ? {'id': currentUserId} : null;

  AuthState copyWith({
    String? currentUserId,
    bool? isAuthenticated,
    bool? isLoading,
  }) {
    return AuthState(
      currentUserId: currentUserId ?? this.currentUserId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier для управления аутентификацией (мигрирован с ChangeNotifier)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  /// Войти в систему
  Future<void> signIn(String userId) async {
    state = state.copyWith(isLoading: true);

    // Симуляция входа
    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(
      currentUserId: userId,
      isAuthenticated: true,
      isLoading: false,
    );
  }

  /// Выйти из системы
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    // Симуляция выхода
    await Future.delayed(const Duration(milliseconds: 500));

    state = state.copyWith(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  /// Для тестирования - установить пользователя
  void setTestUser(String userId) {
    state = state.copyWith(
      currentUserId: userId,
      isAuthenticated: true,
    );
  }
}

/// Провайдер для управления аутентификацией
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Провайдер для получения текущего пользователя
final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.currentUser;
});

/// Провайдер для проверки аутентификации
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

/// Провайдер для проверки загрузки
final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isLoading;
});
