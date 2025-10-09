import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../models/user.dart';

/// Провайдер сервиса аутентификации
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Провайдер текущего пользователя Firebase
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Провайдер текущего пользователя приложения
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Провайдер состояния авторизации
final authStateProvider = StreamProvider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => Stream.value(user != null),
    loading: () => Stream.value(false),
    error: (_, __) => Stream.value(false),
  );
});

/// Провайдер для проверки, авторизован ли пользователь
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Провайдер для получения ID текущего пользователя
final currentUserIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.id,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Провайдер для состояния загрузки аутентификации
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Провайдер для ошибок аутентификации
final authErrorProvider = StateProvider<String?>((ref) => null);