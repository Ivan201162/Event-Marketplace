import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Onboarding state notifier
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false);
  
  void setOnboardingComplete(bool value) {
    state = value;
  }
}

/// Auth loading state notifier
class AuthLoadingNotifier extends StateNotifier<bool> {
  AuthLoadingNotifier() : super(false);
  
  void setLoading(bool value) {
    state = value;
  }
}

/// Phone verification ID notifier
class PhoneVerificationIdNotifier extends StateNotifier<String?> {
  PhoneVerificationIdNotifier() : super(null);
  
  void setVerificationId(String? value) {
    state = value;
  }
}

/// Phone auth state notifier
class PhoneAuthStateNotifier extends StateNotifier<PhoneAuthState> {
  PhoneAuthStateNotifier() : super(PhoneAuthState.idle);
  
  void setState(PhoneAuthState value) {
    state = value;
  }
}

/// Phone number notifier
class PhoneNumberNotifier extends StateNotifier<String?> {
  PhoneNumberNotifier() : super(null);
  
  void setPhoneNumber(String? value) {
    state = value;
  }
}

/// Phone auth timer notifier
class PhoneAuthTimerNotifier extends StateNotifier<int> {
  PhoneAuthTimerNotifier() : super(0);
  
  void setTimer(int value) {
    state = value;
  }
}

/// Can resend code notifier
class CanResendCodeNotifier extends StateNotifier<bool> {
  CanResendCodeNotifier() : super(false);
  
  void setCanResend(bool value) {
    state = value;
  }
}

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
final onboardingStateProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) => OnboardingNotifier());

/// Auth loading state provider
final authLoadingProvider = StateNotifierProvider<AuthLoadingNotifier, bool>((ref) => AuthLoadingNotifier());

/// Phone verification ID provider
final phoneVerificationIdProvider = StateNotifierProvider<PhoneVerificationIdNotifier, String?>((ref) => PhoneVerificationIdNotifier());

/// Phone auth state provider
final phoneAuthStateProvider = StateNotifierProvider<PhoneAuthStateNotifier, PhoneAuthState>((ref) => PhoneAuthStateNotifier());

/// Phone number provider
final phoneNumberProvider = StateNotifierProvider<PhoneNumberNotifier, String?>((ref) => PhoneNumberNotifier());

/// Phone auth timer provider
final phoneAuthTimerProvider = StateNotifierProvider<PhoneAuthTimerNotifier, int>((ref) => PhoneAuthTimerNotifier());

/// Can resend code provider
final canResendCodeProvider = StateNotifierProvider<CanResendCodeNotifier, bool>((ref) => CanResendCodeNotifier());

/// Phone auth states
enum PhoneAuthState {
  idle, // Начальное состояние
  sending, // Отправка SMS
  codeSent, // SMS отправлен
  verifying, // Проверка кода
  verified, // Код подтвержден
  error, // Ошибка
}
