import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/services/auth_service_enhanced.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер сервиса авторизации
final authServiceProvider = Provider<AuthServiceEnhanced>((ref) {
  return AuthServiceEnhanced();
});

/// Провайдер текущего пользователя Firebase Auth
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Провайдер текущего пользователя приложения
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserStream;
});

/// Провайдер текущего пользователя (Future)
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

/// Провайдер состояния загрузки авторизации
final authLoadingProvider =
    StateNotifierProvider<AuthLoadingNotifier, bool>((ref) {
  return AuthLoadingNotifier();
});

/// Провайдер ошибок авторизации
final authErrorProvider =
    StateNotifierProvider<AuthErrorNotifier, String?>((ref) {
  return AuthErrorNotifier();
});

/// Провайдер состояния онлайн
final onlineStatusProvider =
    StateNotifierProvider<OnlineStatusNotifier, bool>((ref) {
  return OnlineStatusNotifier();
});

/// Нотификатор состояния загрузки
class AuthLoadingNotifier extends StateNotifier<bool> {
  AuthLoadingNotifier() : super(false);

  void setLoading(bool loading) {
    state = loading;
  }
}

/// Нотификатор ошибок авторизации
class AuthErrorNotifier extends StateNotifier<String?> {
  AuthErrorNotifier() : super(null);

  void setError(String? error) {
    state = error;
  }

  void clearError() {
    state = null;
  }
}

/// Нотификатор статуса онлайн
class OnlineStatusNotifier extends StateNotifier<bool> {
  OnlineStatusNotifier() : super(false);

  void setOnline(bool online) {
    state = online;
  }
}
