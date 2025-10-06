import 'dart:async';
import '../models/user.dart';
import 'firebase_auth_service.dart';

/// Сервис аутентификации
class AuthService {
  factory AuthService() => _instance;
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();

  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  /// Поток изменений состояния аутентификации
  Stream<AppUser?> get authStateChanges => _firebaseAuth.authStateChanges;

  /// Получить текущего пользователя
  AppUser? get currentUser => _firebaseAuth.currentUser;

  /// Вход по email и паролю
  Future<AppUser?> signInWithEmail(String email, String password) async =>
      _firebaseAuth.signInWithEmail(email, password);

  /// Регистрация по email и паролю
  Future<AppUser?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async =>
      _firebaseAuth.signUpWithEmail(email, password, displayName: displayName);

  /// Отправка SMS для входа по телефону
  Future<void> signInWithPhone(String phoneNumber) async =>
      _firebaseAuth.signInWithPhone(phoneNumber);

  /// Подтверждение SMS кода для входа по телефону
  Future<AppUser?> confirmPhoneCode(String smsCode) async =>
      _firebaseAuth.confirmPhoneCode(smsCode);

  /// Вход как гость
  Future<AppUser?> signInAsGuest() async => _firebaseAuth.signInAsGuest();

  /// Выход
  Future<void> signOut() async => _firebaseAuth.signOut();

  /// Сброс пароля
  Future<void> resetPassword(String email) async =>
      _firebaseAuth.resetPassword(email);

  /// Вход с тестовым email
  Future<AppUser?> signInWithTestEmail() async =>
      signInWithEmail('test@example.com', 'Test1234');

  /// Регистрация с тестовым email (если не существует)
  Future<AppUser?> signUpWithTestEmail() async {
    try {
      return await signUpWithEmail(
        'test@example.com',
        'Test1234',
        displayName: 'Тестовый пользователь',
      );
    } catch (e) {
      // Если пользователь уже существует, пробуем войти
      if (e.toString().contains('email-already-in-use')) {
        return signInWithTestEmail();
      }
      rethrow;
    }
  }

  /// Вход с тестовым телефоном
  Future<AppUser?> signInWithTestPhone() async {
    try {
      // Сначала отправляем код
      await signInWithPhone('+79998887766');
      // Затем подтверждаем с тестовым кодом
      return await confirmPhoneCode('123456');
    } catch (e) {
      // Если это ошибка верификации, пробуем войти напрямую
      if (e.toString().contains('verification')) {
        return confirmPhoneCode('123456');
      }
      rethrow;
    }
  }

  void dispose() {
    _firebaseAuth.dispose();
  }
}
