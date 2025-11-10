import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Репозиторий для работы с аутентификацией
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // serverClientId НЕ указывать на Android (используется из google-services.json)
  );

  /// Вход через Google с жёстким reset
  Future<UserCredential> signInWithGoogle() async {
    // Полный сброс состояния — лечит stuck-сессию Google
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final connectivity = Connectivity();
    final hasNet = await connectivity.checkConnectivity();
    if (hasNet == ConnectivityResult.none) {
      throw FirebaseAuthException(
        code: 'network_request_failed',
        message: 'No internet',
      );
    }

    debugPrint('GOOGLE_SIGNIN_START');
    final account = await _googleSignIn.signIn();

    if (account == null) {
      throw FirebaseAuthException(
        code: 'canceled',
        message: 'User canceled',
      );
    }

    final auth = await account.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    debugPrint('GOOGLE_FIREBASE_AUTH_START');
    final userCred = await _auth.signInWithCredential(cred);
    debugPrint('GOOGLE_SIGNIN_SUCCESS:${userCred.user?.uid}');
    debugPrint('GOOGLE_FIREBASE_AUTH_SUCCESS');
    return userCred;
  }

  /// Вход через email/пароль
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Регистрация через email/пароль
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final c = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return c;
  }

  /// Отправка письма для сброса пароля
  Future<void> sendReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Выход из аккаунта
  Future<void> logout() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

