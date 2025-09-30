import 'package:mockito/mockito.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/services/auth_service.dart';

/// Мок для AuthService
class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return super.noSuchMethod(
      Invocation.method(
        #registerWithEmail,
        [],
        {
          #name: name,
          #email: email,
          #password: password,
          #role: role,
        },
      ),
      returnValue: null,
    );
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return super.noSuchMethod(
      Invocation.method(
        #signInWithEmail,
        [],
        {
          #email: email,
          #password: password,
        },
      ),
      returnValue: AppUser(
        id: 'test-123',
        email: email,
        displayName: 'Test User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    return super.noSuchMethod(
      Invocation.method(#signInWithGoogle, []),
      returnValue: AppUser(
        id: 'google-123',
        email: 'test@gmail.com',
        displayName: 'Google User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        socialProvider: 'google',
        socialId: 'google-123',
      ),
    );
  }

  @override
  Future<AppUser?> handleGoogleRedirectResult() async {
    return super.noSuchMethod(
      Invocation.method(#handleGoogleRedirectResult, []),
      returnValue: AppUser(
        id: 'google-123',
        email: 'test@gmail.com',
        displayName: 'Google User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        socialProvider: 'google',
        socialId: 'google-123',
      ),
    );
  }

  @override
  Future<AppUser?> signInAsGuest() async {
    return super.noSuchMethod(
      Invocation.method(#signInAsGuest, []),
      returnValue: AppUser(
        id: 'guest-123',
        email: 'guest@example.com',
        displayName: 'Guest User',
        role: UserRole.guest,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<AppUser?> signInWithVK({UserRole role = UserRole.customer}) async {
    return super.noSuchMethod(
      Invocation.method(
        #signInWithVK,
        [],
        {#role: role},
      ),
      returnValue: AppUser(
        id: 'vk-123',
        email: 'test@vk.com',
        displayName: 'VK User',
        role: role,
        createdAt: DateTime.now(),
        socialProvider: 'vk',
        socialId: 'vk-123',
      ),
    );
  }
}
