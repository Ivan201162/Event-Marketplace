import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'oauth_profile_service.dart';

/// Полноценный сервис аутентификации с Firebase
class FirebaseAuthService {
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OAuthProfileService _oauthService = OAuthProfileService();
  StreamSubscription<User?>? _authStateSubscription;

  /// Поток изменений состояния аутентификации
  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().asyncMap(
      (user) async => user != null ? await _convertFirebaseUser(user) : null);

  /// Получить текущего пользователя
  Future<AppUser?> get currentUser async {
    final user = _auth.currentUser;
    return user != null ? await _convertFirebaseUser(user) : null;
  }

  /// Вход по email и паролю
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('Попытка входа с email: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final appUser = await _convertFirebaseUser(credential.user!);
        debugPrint('Успешный вход с email: ${appUser.displayName}');
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка входа: ${e.message}');
      throw _handleAuthException(e);
    } on Exception catch (e) {
      debugPrint('Неожиданная ошибка: $e');
      throw Exception('Произошла ошибка при входе');
    }
  }

  /// Регистрация по email и паролю
  Future<AppUser?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      debugPrint('Попытка регистрации с email: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Обновляем отображаемое имя
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }

        final appUser = await _convertFirebaseUser(credential.user!);
        debugPrint('Успешная регистрация с email: ${appUser.displayName}');
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка регистрации: ${e.message}');
      throw _handleAuthException(e);
    } on Exception catch (e) {
      debugPrint('Неожиданная ошибка: $e');
      throw Exception('Произошла ошибка при регистрации');
    }
  }

  /// Отправка SMS для входа по телефону
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      debugPrint('Отправка SMS на номер: $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          debugPrint('Автоматическая верификация завершена');
        },
        verificationFailed: (e) {
          debugPrint('Ошибка верификации: ${e.message}');
          throw _handleAuthException(e);
        },
        codeSent: (verificationId, resendToken) {
          debugPrint('SMS код отправлен');
          // Сохраняем verificationId для последующего использования
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (verificationId) {
          debugPrint('Таймаут автополучения кода');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка отправки SMS: $e');
      throw Exception('Не удалось отправить SMS код');
    }
  }

  String? _verificationId;

  /// Подтверждение SMS кода для входа по телефону
  Future<AppUser?> confirmPhoneCode(String smsCode) async {
    try {
      debugPrint('Подтверждение SMS кода: $smsCode');

      if (_verificationId == null) {
        throw Exception(
          'Код верификации не найден. Попробуйте отправить SMS заново',
        );
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final appUser = await _convertFirebaseUser(userCredential.user!);
        debugPrint('Успешный вход по телефону');
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка подтверждения кода: ${e.message}');
      throw _handleAuthException(e);
    } on Exception catch (e) {
      debugPrint('Неожиданная ошибка: $e');
      throw Exception('Неверный код подтверждения');
    }
  }

  /// Получить сохраненный verification ID
  String? get verificationId => _verificationId;

  /// Вход как гость (анонимная авторизация)
  Future<AppUser?> signInAsGuest() async {
    try {
      debugPrint('Попытка входа как гость');

      final credential = await _auth.signInAnonymously();

      if (credential.user != null) {
        final appUser = await _convertFirebaseUser(credential.user!);
        debugPrint('Успешный вход как гость');
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка входа как гость: ${e.message}');
      throw _handleAuthException(e);
    } on Exception catch (e) {
      debugPrint('Неожиданная ошибка: $e');
      throw Exception('Произошла ошибка при входе как гость');
    }
  }

  /// Выход
  Future<void> signOut() async {
    try {
      debugPrint('Выход выполнен');
      await _auth.signOut();
    } on Exception catch (e) {
      debugPrint('Ошибка выхода: $e');
      throw Exception('Произошла ошибка при выходе');
    }
  }

  /// Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('Сброс пароля для email: $email');
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка сброса пароля: ${e.message}');
      throw _handleAuthException(e);
    } on Exception catch (e) {
      debugPrint('Неожиданная ошибка: $e');
      throw Exception('Произошла ошибка при сбросе пароля');
    }
  }

  /// Конвертация Firebase User в AppUser
  Future<AppUser> _convertFirebaseUser(User user) async {
    try {
      // Сначала пытаемся получить профиль из OAuth сервиса
      final oauthUser = await _oauthService.handleOAuthUser(user);
      if (oauthUser != null) {
        return oauthUser;
      }

      // Если OAuth не сработал, создаем базовый профиль
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName:
            user.displayName ?? user.email?.split('@')[0] ?? 'Пользователь',
        role: UserRole.customer, // По умолчанию все пользователи - клиенты
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        additionalData: {
          'isAnonymous': user.isAnonymous,
          'phoneNumber': user.phoneNumber,
          'emailVerified': user.emailVerified,
        },
      );
    } catch (e) {
      debugPrint('Ошибка конвертации Firebase пользователя: $e');
      // Возвращаем базовый профиль в случае ошибки
      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName:
            user.displayName ?? user.email?.split('@')[0] ?? 'Пользователь',
        role: UserRole.customer,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        additionalData: {
          'isAnonymous': user.isAnonymous,
          'phoneNumber': user.phoneNumber,
          'emailVerified': user.emailVerified,
        },
      );
    }
  }

  /// Обработка ошибок Firebase Auth
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Пользователь с таким email не найден');
      case 'wrong-password':
        return Exception('Неверный пароль');
      case 'email-already-in-use':
        return Exception('Пользователь с таким email уже зарегистрирован');
      case 'weak-password':
        return Exception('Пароль слишком слабый');
      case 'invalid-email':
        return Exception('Неверный формат email');
      case 'user-disabled':
        return Exception('Аккаунт заблокирован');
      case 'too-many-requests':
        return Exception('Слишком много попыток. Попробуйте позже');
      case 'operation-not-allowed':
        return Exception('Операция не разрешена');
      case 'invalid-verification-code':
        return Exception('Неверный код подтверждения');
      case 'invalid-verification-id':
        return Exception('Неверный ID верификации');
      case 'credential-already-in-use':
        return Exception('Учетные данные уже используются');
      case 'invalid-credential':
        return Exception('Неверные учетные данные');
      default:
        return Exception(e.message ?? 'Произошла неизвестная ошибка');
    }
  }

  void dispose() {
    _authStateSubscription?.cancel();
  }
}
