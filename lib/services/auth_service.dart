import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/safe_log.dart';
import '../core/logger.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'vk_auth_service.dart';

/// Сервис для управления аутентификацией пользователей
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // GoogleSignIn не поддерживается для web в текущей версии
  // final GoogleSignIn _googleSignIn = GoogleSignIn(
  //   scopes: ['email', 'profile'],
  // );
  final StorageService _storageService = StorageService();
  final VKAuthService _vkAuthService = VKAuthService();

  /// Текущий пользователь Firebase
  User? get currentFirebaseUser => _auth.currentUser;

  /// Текущий пользователь (алиас для совместимости)
  User? get currentUser => _auth.currentUser;

  /// Поток изменений состояния аутентификации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Получить текущего пользователя из Firestore
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;

    try {
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return AppUser.fromDocument(doc);
      }
      return null;
    } catch (e, stackTrace) {
      SafeLog.error('Ошибка получения пользователя', e, stackTrace);
      return null;
    }
  }

  /// Восстановить сессию пользователя
  Future<AppUser?> restoreSession() async {
    try {
      SafeLog.info('Попытка восстановления сессии...');

      // Проверяем, есть ли активная сессия Firebase
      final firebaseUser = currentFirebaseUser;
      if (firebaseUser == null) {
        SafeLog.info('Нет активной сессии Firebase');
        return null;
      }

      // Проверяем, не истекла ли сессия
      await firebaseUser.reload();
      if (firebaseUser.uid.isEmpty) {
        SafeLog.warning('Сессия Firebase истекла');
        return null;
      }

      // Получаем данные пользователя из Firestore
      final appUser = await getCurrentUser();
      if (appUser != null) {
        SafeLog.info(
          'Сессия успешно восстановлена для пользователя: ${appUser.displayName}',
        );
        return appUser;
      } else {
        SafeLog.warning('Пользователь не найден в Firestore');
        return null;
      }
    } catch (e, stackTrace) {
      SafeLog.error('Ошибка восстановления сессии', e, stackTrace);
      return null;
    }
  }

  /// Проверить, валидна ли текущая сессия
  Future<bool> isSessionValid() async {
    try {
      final firebaseUser = currentFirebaseUser;
      if (firebaseUser == null) return false;

      // Проверяем, не истекла ли сессия
      await firebaseUser.reload();
      return firebaseUser.uid.isNotEmpty;
    } catch (e, stackTrace) {
      SafeLog.error('Ошибка проверки валидности сессии', e, stackTrace);
      return false;
    }
  }

  /// Поток текущего пользователя
  Stream<AppUser?> get currentUserStream =>
      authStateChanges.asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;

        try {
          final doc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (doc.exists) {
            return AppUser.fromDocument(doc);
          }
          return null;
        } catch (e) {
          AppLogger.logE('Ошибка получения пользователя', 'auth_service', e);
          return null;
        }
      });

  /// Регистрация с email и паролем (новый метод)
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      AppLogger.logI('Начинаем регистрацию пользователя: $email', 'auth_service');
      
      // Создаем пользователя в Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        AppLogger.logE('Firebase user is null after registration', 'auth_service');
        throw Exception('Ошибка создания пользователя');
      }

      AppLogger.logI('Firebase user создан: ${firebaseUser.uid}', 'auth_service');

      // Обновляем профиль Firebase
      await firebaseUser.updateDisplayName(name);
      AppLogger.logI('Display name обновлен: $name', 'auth_service');

      // Создаем пользователя в Firestore
      final appUser = AppUser.fromFirebaseUser(
        firebaseUser.uid,
        email,
        displayName: name,
        role: role,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toMap());
      
      AppLogger.logI('Пользователь создан в Firestore: ${appUser.id}', 'auth_service');

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.logE('Ошибка регистрации', 'auth_service', e);
      throw Exception('Ошибка регистрации: $e');
    }
  }

  /// Регистрация с email и паролем (старый метод для совместимости)
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      AppLogger.logI('Начинаем регистрацию пользователя: $email', 'auth_service');
      
      // Создаем пользователя в Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        AppLogger.logE('Firebase user is null after registration', 'auth_service');
        return null;
      }

      AppLogger.logI('Firebase user создан: ${firebaseUser.uid}', 'auth_service');

      // Обновляем профиль Firebase
      await firebaseUser.updateDisplayName(displayName);
      AppLogger.logI('Display name обновлен: $displayName', 'auth_service');

      // Создаем пользователя в Firestore
      final appUser = AppUser.fromFirebaseUser(
        firebaseUser.uid,
        email,
        displayName: displayName,
        role: role,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toMap());
      
      AppLogger.logI('Пользователь создан в Firestore: ${appUser.id}', 'auth_service');

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка регистрации: $e');
    }
  }

  /// Вход с email и паролем
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) return null;

      // Обновляем время последнего входа
      await _updateLastLogin(firebaseUser.uid);

      // Получаем пользователя из Firestore
      return await getCurrentUser();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }

  /// Вход как гость
  Future<AppUser?> signInAsGuest() async {
    try {
      AppLogger.logI('Начало входа как гость...', 'auth_service');
      
      // Создаем анонимного пользователя
      final credential = await _auth.signInAnonymously();
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        AppLogger.logE('Firebase пользователь не создан для гостя', 'auth_service');
        return null;
      }

      AppLogger.logI('Гость вошел: ${firebaseUser.uid}', 'auth_service');

      // Создаем гостевого пользователя в Firestore
      final guestUser = AppUser.fromFirebaseUser(
        firebaseUser.uid,
        'guest@example.com',
        displayName: 'Гость',
        role: UserRole.guest,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(guestUser.toMap());

      AppLogger.logI('Гость создан: ${guestUser.displayName}', 'auth_service');
      return guestUser;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка входа как гость', 'auth_service', e, stackTrace);
      throw Exception('Ошибка входа как гость: $e');
    }
  }

  /// Войти через Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      AppLogger.logI('Начало входа через Google...', 'auth_service');
      
      // Для web-версии используем Firebase Auth с Google провайдером
      final googleProvider = GoogleAuthProvider();
      
      // Попробуем войти через popup
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithPopup(googleProvider);
      } catch (e) {
        AppLogger.logI('Popup заблокирован, пробуем redirect...', 'auth_service');
        // Если popup заблокирован, используем redirect
        await _auth.signInWithRedirect(googleProvider);
        return null; // Redirect не возвращает результат сразу
      }
      
      final firebaseUser = userCredential?.user;
      if (firebaseUser == null) {
        AppLogger.logE('Firebase пользователь не создан для Google', 'auth_service');
        return null;
      }
      
      AppLogger.logI('Google аутентификация успешна: ${firebaseUser.email}', 'auth_service');
      
      // Проверяем, существует ли пользователь в Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (!userDoc.exists) {
        // Создаем нового пользователя
        AppLogger.logI('Создание нового Google пользователя в Firestore...', 'auth_service');
        final appUser = AppUser.fromFirebaseUser(
          firebaseUser.uid,
          firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Google Пользователь',
          photoURL: firebaseUser.photoURL,
          role: UserRole.customer,
          socialProvider: 'google',
          socialId: firebaseUser.uid,
        );
        
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(appUser.toMap());
        
        AppLogger.logI('Google пользователь создан: ${appUser.displayName}', 'auth_service');
        return appUser;
      } else {
        // Обновляем время последнего входа
        AppLogger.logI('Обновление времени последнего входа...', 'auth_service');
        await _updateLastLogin(firebaseUser.uid);
        final appUser = AppUser.fromDocument(userDoc);
        AppLogger.logI('Google пользователь вошел: ${appUser.displayName}', 'auth_service');
        return appUser;
      }
      
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка входа через Google', 'auth_service', e, stackTrace);
      throw Exception('Ошибка входа через Google: $e');
    }
  }

  /// Войти через VK
  Future<AppUser?> signInWithVK({UserRole role = UserRole.customer}) async {
    try {
      AppLogger.logI('Начало входа через VK...', 'auth_service');
      
      // Для тестирования используем заглушку
      // В production здесь должен быть реальный VK OAuth
      return await _vkAuthService.createVkUserForTesting();
      
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка входа через VK', 'auth_service', e, stackTrace);
      throw Exception('Ошибка входа через VK: $e');
    }
  }

  /// Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Ошибка сброса пароля: $e');
    }
  }

  /// Обновить профиль пользователя
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    UserRole? role,
  }) async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) throw Exception('Пользователь не авторизован');

    try {
      // Обновляем Firebase Auth профиль
      if (displayName != null) {
        await firebaseUser.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await firebaseUser.updatePhotoURL(photoURL);
      }

      // Обновляем данные в Firestore
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (role != null) updateData['role'] = role.name;

      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .update(updateData);
      }
    } catch (e) {
      throw Exception('Ошибка обновления профиля: $e');
    }
  }

  /// Обновить профиль с загрузкой изображения
  Future<void> updateUserProfileWithImage({
    String? displayName,
    File? imageFile,
    UserRole? role,
  }) async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) throw Exception('Пользователь не авторизован');

    try {
      String? photoURL;

      // Загружаем изображение, если оно выбрано
      if (imageFile != null) {
        photoURL = await _storageService.uploadProfileImage(imageFile);
      }

      // Обновляем профиль
      await updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
        role: role,
      );
    } catch (e) {
      throw Exception('Ошибка обновления профиля с изображением: $e');
    }
  }

  /// Удалить аккаунт
  Future<void> deleteAccount() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) throw Exception('Пользователь не авторизован');

    try {
      // Удаляем данные из Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).delete();

      // Удаляем аккаунт Firebase Auth
      await firebaseUser.delete();
    } catch (e) {
      throw Exception('Ошибка удаления аккаунта: $e');
    }
  }

  /// Обновить время последнего входа
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка обновления времени входа: $e');
    }
  }

  /// Выход из всех социальных сетей
  Future<void> signOutFromAll() async {
    try {
      // await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Ошибка выхода: $e');
    }
  }

  /// Выход из системы (обновленный метод)
  Future<void> signOut() async {
    try {
      await signOutFromAll();
    } catch (e) {
      throw Exception('Ошибка выхода: $e');
    }
  }

  /// Обработка исключений Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Пароль слишком слабый';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      default:
        return 'Ошибка аутентификации: ${e.message}';
    }
  }
}
