import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Сервис для управления сессией пользователя
class SessionService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String _sessionKey = 'user_session';
  static const String _lastLoginKey = 'last_login';
  static const String _userDataKey = 'user_data';
  static const String _authMethodKey = 'auth_method';

  /// Проверить, есть ли активная сессия
  static Future<bool> hasActiveSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Проверяем, не истекла ли сессия (например, больше 30 дней)
      final prefs = await SharedPreferences.getInstance();
      final lastLogin = prefs.getInt(_lastLoginKey);

      if (lastLogin != null) {
        final lastLoginDate = DateTime.fromMillisecondsSinceEpoch(lastLogin);
        final now = DateTime.now();
        final difference = now.difference(lastLoginDate);

        // Сессия действительна 30 дней
        if (difference.inDays > 30) {
          await clearSession();
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking session: $e');
      return false;
    }
  }

  /// Сохранить сессию пользователя
  static Future<void> saveSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, user.uid);
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);

      // Сохраняем основные данные пользователя для быстрого доступа
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };

      await prefs.setString(_userDataKey, userData.toString());

      debugPrint('✅ Session saved for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
    }
  }

  /// Очистить сессию
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_lastLoginKey);
      await prefs.remove(_userDataKey);

      debugPrint('🧹 Session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  /// Получить сохраненные данные пользователя
  static Future<Map<String, String>?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);

      if (userDataString != null) {
        // Простой парсинг для демонстрации
        // В реальном приложении лучше использовать JSON
        final userData = <String, String>{};
        final pairs = userDataString.split(', ');
        for (final pair in pairs) {
          final keyValue = pair.split(': ');
          if (keyValue.length == 2) {
            userData[keyValue[0]] = keyValue[1];
          }
        }
        return userData;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting cached user data: $e');
      return null;
    }
  }

  /// Обновить время последнего входа
  static Future<void> updateLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Error updating last login: $e');
    }
  }

  /// Проверить, нужно ли показать онбординг
  static Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.getBool('onboarding_completed') ?? true;
    } catch (e) {
      debugPrint('❌ Error checking onboarding status: $e');
      return true;
    }
  }

  /// Отметить онбординг как завершенный
  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
    }
  }

  /// Получить настройки приложения
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'darkMode': prefs.getBool('dark_mode') ?? false,
        'notificationsEnabled': prefs.getBool('notifications_enabled') ?? true,
        'autoLogin': prefs.getBool('auto_login') ?? true,
        'language': prefs.getString('language') ?? 'ru',
      };
    } catch (e) {
      debugPrint('❌ Error getting app settings: $e');
      return {
        'darkMode': false,
        'notificationsEnabled': true,
        'autoLogin': true,
        'language': 'ru',
      };
    }
  }

  /// Сохранить настройки приложения
  static Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (settings.containsKey('darkMode')) {
        await prefs.setBool('dark_mode', settings['darkMode'] as bool);
      }
      if (settings.containsKey('notificationsEnabled')) {
        await prefs.setBool(
            'notifications_enabled', settings['notificationsEnabled'] as bool);
      }
      if (settings.containsKey('autoLogin')) {
        await prefs.setBool('auto_login', settings['autoLogin'] as bool);
      }
      if (settings.containsKey('language')) {
        await prefs.setString('language', settings['language'] as String);
      }

      debugPrint('✅ App settings saved');
    } catch (e) {
      debugPrint('❌ Error saving app settings: $e');
    }
  }

  /// Войти через Google
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await saveSession();
        await _saveAuthMethod('google');
        debugPrint('✅ Google sign-in successful: ${user.uid}');
      }

      return user;
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');
      return null;
    }
  }

  /// Войти через email и пароль
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        await saveSession();
        await _saveAuthMethod('email');
        debugPrint('✅ Email sign-in successful: ${user.uid}');
      }

      return user;
    } catch (e) {
      debugPrint('❌ Email sign-in error: $e');
      return null;
    }
  }

  /// Войти через телефон
  static Future<User?> signInWithPhone(String phoneNumber) async {
    try {
      // Здесь должна быть реализация входа через телефон
      // Для демонстрации возвращаем null
      debugPrint('📱 Phone sign-in not implemented yet');
      return null;
    } catch (e) {
      debugPrint('❌ Phone sign-in error: $e');
      return null;
    }
  }

  /// Регистрация через email
  static Future<User?> registerWithEmail(
      String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(displayName);
        await saveSession();
        await _saveAuthMethod('email');
        debugPrint('✅ Email registration successful: ${user.uid}');
      }

      return user;
    } catch (e) {
      debugPrint('❌ Email registration error: $e');
      return null;
    }
  }

  /// Выйти из аккаунта
  static Future<void> signOut() async {
    try {
      // Выход из Firebase
      await _auth.signOut();

      // Выход из Google
      await _googleSignIn.signOut();

      // Очистка сессии
      await clearSession();

      debugPrint('✅ Sign-out successful');
    } catch (e) {
      debugPrint('❌ Sign-out error: $e');
    }
  }

  /// Сохранить метод аутентификации
  static Future<void> _saveAuthMethod(String method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authMethodKey, method);
    } catch (e) {
      debugPrint('❌ Error saving auth method: $e');
    }
  }

  /// Получить метод аутентификации
  static Future<String?> getAuthMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authMethodKey);
    } catch (e) {
      debugPrint('❌ Error getting auth method: $e');
      return null;
    }
  }

  /// Проверить, нужно ли показать онбординг для нового пользователя
  static Future<bool> shouldShowOnboardingForNewUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.getBool('onboarding_completed') ?? true;
    } catch (e) {
      debugPrint('❌ Error checking onboarding status: $e');
      return true;
    }
  }

  /// Обновить профиль пользователя
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      if (phoneNumber != null) {
        await user.updatePhoneNumber(phoneNumber as PhoneAuthCredential);
      }

      await saveSession();
      debugPrint('✅ User profile updated');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
    }
  }

  /// Получить информацию о текущем пользователе
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Проверить, авторизован ли пользователь
  static bool isUserSignedIn() {
    return _auth.currentUser != null;
  }

  /// Получить токен доступа
  static Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      debugPrint('❌ Error getting ID token: $e');
      return null;
    }
  }

  /// Обновить токен доступа
  static Future<String?> refreshIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(true);
    } catch (e) {
      debugPrint('❌ Error refreshing ID token: $e');
      return null;
    }
  }

  /// Проверить, нужно ли обновить токен
  static Future<bool> shouldRefreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final tokenResult = await user.getIdTokenResult();
      final expirationTime = tokenResult.expirationTime;
      if (expirationTime == null) return false;

      final now = DateTime.now();
      final timeUntilExpiry = expirationTime.difference(now);

      // Обновляем токен, если до истечения осталось меньше 5 минут
      return timeUntilExpiry.inMinutes < 5;
    } catch (e) {
      debugPrint('❌ Error checking token expiry: $e');
      return false;
    }
  }

  /// Автоматически обновить токен при необходимости
  static Future<void> autoRefreshToken() async {
    try {
      if (await shouldRefreshToken()) {
        await refreshIdToken();
        debugPrint('✅ Token refreshed automatically');
      }
    } catch (e) {
      debugPrint('❌ Error auto-refreshing token: $e');
    }
  }
}
