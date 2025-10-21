import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current Firebase user provider
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current app user provider
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserStream;
});

/// Auth state provider (loading, authenticated, unauthenticated)
final authStateProvider = Provider<AsyncValue<AppUser?>>((ref) {
  return ref.watch(currentUserProvider);
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if user profile is complete
final isProfileCompleteProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.isProfileComplete ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// User onboarding state provider
final onboardingStateProvider = StateProvider<bool>((ref) => false);

/// Auth loading state provider
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Phone verification ID provider
final phoneVerificationIdProvider = StateProvider<String?>((ref) => null);

/// Phone auth state provider
final phoneAuthStateProvider = StateProvider<PhoneAuthState>((ref) => PhoneAuthState.idle);

/// Phone number provider
final phoneNumberProvider = StateProvider<String?>((ref) => null);

/// Phone auth timer provider
final phoneAuthTimerProvider = StateProvider<int>((ref) => 0);

/// Can resend code provider
final canResendCodeProvider = StateProvider<bool>((ref) => false);

/// Phone auth states
enum PhoneAuthState {
  idle, // Начальное состояние
  sending, // Отправка SMS
  codeSent, // SMS отправлен
  verifying, // Проверка кода
  verified, // Код подтвержден
  error, // Ошибка
}
