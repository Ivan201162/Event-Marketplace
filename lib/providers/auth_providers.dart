import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Onboarding state notifier
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setOnboardingComplete(bool value) {
    state = value;
  }
}

/// Auth loading state notifier
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setLoading(bool value) {
    state = value;
  }
}

/// Phone verification ID notifier
class PhoneVerificationIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setVerificationId(String? value) {
    state = value;
  }
}

/// Phone auth state notifier
class PhoneAuthStateNotifier extends Notifier<PhoneAuthState> {
  @override
  PhoneAuthState build() => PhoneAuthState.idle;
  
  void setState(PhoneAuthState value) {
    state = value;
  }
}

/// Phone number notifier
class PhoneNumberNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setPhoneNumber(String? value) {
    state = value;
  }
}

/// Phone auth timer notifier
class PhoneAuthTimerNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void setTimer(int value) {
    state = value;
  }
}

/// Can resend code notifier
class CanResendCodeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setCanResend(bool value) {
    state = value;
  }
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
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
final onboardingStateProvider = NotifierProvider<OnboardingNotifier, bool>(() => OnboardingNotifier());

/// Auth loading state provider
final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(() => AuthLoadingNotifier());

/// Phone verification ID provider
final phoneVerificationIdProvider = NotifierProvider<PhoneVerificationIdNotifier, String?>(() => PhoneVerificationIdNotifier());

/// Phone auth state provider
final phoneAuthStateProvider = NotifierProvider<PhoneAuthStateNotifier, PhoneAuthState>(() => PhoneAuthStateNotifier());

/// Phone number provider
final phoneNumberProvider = NotifierProvider<PhoneNumberNotifier, String?>(() => PhoneNumberNotifier());

/// Phone auth timer provider
final phoneAuthTimerProvider = NotifierProvider<PhoneAuthTimerNotifier, int>(() => PhoneAuthTimerNotifier());

/// Can resend code provider
final canResendCodeProvider = NotifierProvider<CanResendCodeNotifier, bool>(() => CanResendCodeNotifier());

/// Phone auth states
enum PhoneAuthState {
  idle, // Начальное состояние
  sending, // Отправка SMS
  codeSent, // SMS отправлен
  verifying, // Проверка кода
  verified, // Код подтвержден
  error, // Ошибка
}
