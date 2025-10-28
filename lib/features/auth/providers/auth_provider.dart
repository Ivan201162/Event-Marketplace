import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для получения текущего пользователя
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Провайдер для получения текущего пользователя (синхронный)
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

/// Провайдер для управления аутентификацией
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Сервис аутентификации
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Получить текущего пользователя
  User? get currentUser => _auth.currentUser;

  /// Войти с email и паролем
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password,) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password,);
      return credential;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return null;
    }
  }

  /// Зарегистрироваться с email и паролем
  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password,) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return null;
    }
  }

  /// Выйти из системы
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Сбросить пароль
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
    }
  }

  /// Обновить профиль пользователя
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  /// Удалить аккаунт
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
    }
  }
}
