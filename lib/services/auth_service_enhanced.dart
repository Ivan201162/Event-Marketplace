import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Улучшенный сервис авторизации с исправленными ошибками
class AuthServiceEnhanced {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  /// Поток текущего пользователя
  Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          return AppUser.fromFirestore(userDoc);
        } else {
          // Создаем документ пользователя если его нет
          return await _createUserDocument(firebaseUser);
        }
      } catch (e) {
        debugPrint('Error getting user: $e');
        return null;
      }
    });
  }

  /// Получить текущего пользователя
  Future<AppUser?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc);
      } else {
        return await _createUserDocument(firebaseUser);
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Вход с email и паролем
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugLog('EMAIL_LOGIN_START:$email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        debugLog('EMAIL_LOGIN_OK:$uid');
        return await _getOrCreateUser(credential.user!);
      }
      debugLog('EMAIL_LOGIN_ERR:no_user');
      return null;
    } on FirebaseAuthException catch (e) {
      debugLog('EMAIL_LOGIN_ERR:${e.code}:${e.message}');
      rethrow;
    } catch (e) {
      debugLog('EMAIL_LOGIN_ERR:unknown:$e');
      rethrow;
    }
  }

  /// Регистрация с email и паролем
  Future<AppUser?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
    String? city,
  }) async {
    try {
      debugLog('EMAIL_SIGNUP_START:$email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        // Обновляем отображаемое имя
        if (name != null) {
          await credential.user!.updateDisplayName(name);
        }

        final user = await _createUserDocument(credential.user!,
            name: name, city: city,);
        debugLog('EMAIL_SIGNUP_OK:$uid');
        return user;
      }
      debugLog('EMAIL_SIGNUP_ERR:no_user');
      return null;
    } on FirebaseAuthException catch (e) {
      debugLog('EMAIL_SIGNUP_ERR:${e.code}:${e.message}');
      rethrow;
    } catch (e) {
      debugLog('EMAIL_SIGNUP_ERR:unknown:$e');
      rethrow;
    }
  }

  /// Вход через Google (release-ready with detailed logging + auto-retry)
  Future<UserCredential> signInWithGoogleRelease({int retryCount = 0}) async {
    debugLog('GOOGLE_SIGNIN_START:attempt=${retryCount + 1}');
    try {
      // Проверка инициализации Firebase
      try {
        Firebase.app();
        debugLog('GOOGLE_INIT:[DEFAULT]');
      } catch (_) {
        debugLog('GOOGLE_INIT:REINIT');
        await Firebase.initializeApp();
        debugLog('GOOGLE_INIT:[DEFAULT]');
      }

      debugLog('GOOGLE_SIGNIN_STEP:signIn');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugLog('GOOGLE_SIGNIN_ERROR:canceled:User canceled');
        throw FirebaseAuthException(code: 'canceled', message: 'Пользователь отменил вход');
      }

      debugLog('GOOGLE_SIGNIN_STEP:getTokens');
      final googleAuth = await googleUser.authentication;
      debugLog('GOOGLE_SIGNIN_STEP:TOKENS:${googleAuth.idToken != null}:${googleAuth.accessToken != null}');

      if (googleAuth.idToken == null) {
        debugLog('GOOGLE_SIGNIN_ERROR:no-id-token:Missing ID token');
        throw FirebaseAuthException(code: 'no-id-token', message: 'ID token отсутствует');
      }

      debugLog('GOOGLE_FIREBASE_AUTH_START');
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      debugLog('GOOGLE_FIREBASE_AUTH_STEP:signInWithCredential');
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (cred.user != null) {
        debugLog('GOOGLE_SIGNIN_SUCCESS:${cred.user!.uid}');
        debugLog('GOOGLE_FIREBASE_AUTH_SUCCESS:${cred.user!.uid}');
      } else {
        debugLog('GOOGLE_SIGNIN_ERROR:no-user:User is null after sign in');
        debugLog('GOOGLE_FIREBASE_AUTH_ERROR:no-user:User is null after sign in');
        throw FirebaseAuthException(code: 'no-user', message: 'Пользователь не создан');
      }
      
      return cred;
    } on FirebaseAuthException catch (e, st) {
      String readableCode = _mapAuthErrorCode(e.code);
      debugLog('GOOGLE_SIGNIN_ERROR:${e.code}:${e.message}');
      debugLog('GOOGLE_FIREBASE_AUTH_ERROR:${e.code}:${e.message}');
      debugLog('GOOGLE_SIGNIN_STACK:$st');
      
      // Авто-ретрай для определенных ошибок (1 раз)
      if (retryCount < 1 && (e.code == 'unknown' || e.code == 'internal-error' || e.code == 'network-request-failed')) {
        final delay = Duration(milliseconds: 500 * (1 << retryCount)); // Экспоненциальная задержка
        debugLog('GOOGLE_SIGNIN_RETRY:${retryCount + 1}:delay=${delay.inMilliseconds}ms');
        await Future.delayed(delay);
        
        // Повторная инициализация Firebase перед ретраем
        try {
          await Firebase.initializeApp();
          debugLog('GOOGLE_INIT:RETRY:[DEFAULT]');
        } catch (_) {
          // Уже инициализирован
        }
        
        return signInWithGoogleRelease(retryCount: retryCount + 1);
      }
      
      rethrow;
    } on PlatformException catch (e, st) {
      String readableCode = _mapPlatformErrorCode(e.code);
      debugLog('GOOGLE_SIGNIN_ERROR:PLATFORM:${e.code}:${e.message}');
      debugLog('GOOGLE_FIREBASE_AUTH_ERROR:PLATFORM:${e.code}:${e.message}');
      debugLog('GOOGLE_SIGNIN_STACK:$st');
      
      // Авто-ретрай для платформенных ошибок (1 раз)
      if (retryCount < 1 && (e.code == 'sign_in_failed' || e.code == 'network_error')) {
        final delay = Duration(milliseconds: 500 * (1 << retryCount));
        debugLog('GOOGLE_SIGNIN_RETRY:${retryCount + 1}:delay=${delay.inMilliseconds}ms');
        await Future.delayed(delay);
        
        try {
          await Firebase.initializeApp();
          debugLog('GOOGLE_INIT:RETRY:[DEFAULT]');
        } catch (_) {}
        
        return signInWithGoogleRelease(retryCount: retryCount + 1);
      }
      
      rethrow;
    } catch (e, st) {
      debugLog('GOOGLE_SIGNIN_ERROR:unknown:$e');
      debugLog('GOOGLE_FIREBASE_AUTH_ERROR:unknown:$e');
      debugLog('GOOGLE_SIGNIN_STACK:$st');
      
      // Авто-ретрай для неизвестных ошибок (1 раз)
      if (retryCount < 1) {
        final delay = Duration(milliseconds: 500 * (1 << retryCount));
        debugLog('GOOGLE_SIGNIN_RETRY:${retryCount + 1}:delay=${delay.inMilliseconds}ms');
        await Future.delayed(delay);
        
        try {
          await Firebase.initializeApp();
          debugLog('GOOGLE_INIT:RETRY:[DEFAULT]');
        } catch (_) {}
        
        return signInWithGoogleRelease(retryCount: retryCount + 1);
      }
      
      rethrow;
    }
  }

  String _mapAuthErrorCode(String code) {
    switch (code) {
      case '12500':
        return 'SIGN_IN_CANCELLED';
      case '12501':
        return 'SIGN_IN_CURRENTLY_IN_PROGRESS';
      case '10':
        return 'DEVELOPER_ERROR';
      case 'unknown':
        return 'UNKNOWN_ERROR_CHECK_SHA_OAUTH';
      default:
        return code;
    }
  }

  String _mapPlatformErrorCode(String code) {
    switch (code) {
      case 'sign_in_failed':
        return 'SIGN_IN_FAILED_CHECK_SHA';
      case 'network_error':
        return 'NETWORK_ERROR';
      default:
        return code;
    }
  }

  /// Вход через Google (legacy method, calls release version)
  Future<AppUser?> signInWithGoogle() async {
    try {
      final cred = await signInWithGoogleRelease();
      if (cred.user != null) {
        return await _getOrCreateUser(cred.user!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Вход через телефон
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _getOrCreateUser(userCredential.user!);
            }
          } catch (e) {
            onError('Ошибка автоматической верификации: $e');
          }
        },
        verificationFailed: (e) {
          onError('Ошибка верификации: ${e.message}');
        },
        codeSent: (verificationId, resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Таймаут автоматического получения кода
        },
      );
    } catch (e) {
      onError('Ошибка отправки SMS: $e');
    }
  }

  /// Подтверждение кода SMS
  Future<AppUser?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        return await _getOrCreateUser(userCredential.user!);
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying phone code: $e');
      rethrow;
    }
  }

  /// Выход из аккаунта
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  /// Обновление профиля
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? city,
    String? avatarUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Обновляем данные в Firebase Auth
      if (name != null) {
        await user.updateDisplayName(name);
      }

      // Обновляем данные в Firestore
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updateData['name'] = name;
      if (bio != null) updateData['bio'] = bio;
      if (city != null) updateData['city'] = city;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Получить или создать пользователя
  Future<AppUser?> _getOrCreateUser(User firebaseUser) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc);
      } else {
        return await _createUserDocument(firebaseUser);
      }
    } catch (e) {
      debugPrint('Error getting or creating user: $e');
      return null;
    }
  }

  /// Создать документ пользователя
  Future<AppUser> _createUserDocument(
    User firebaseUser, {
    String? name,
    String? city,
  }) async {
    try {
      // Получаем FCM токен
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final userData = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'name': name ?? firebaseUser.displayName ?? 'Пользователь',
        'avatarUrl': firebaseUser.photoURL,
        'city': city,
        'bio': '',
        'isOnline': true,
        'lastSeen': Timestamp.now(),
        'fcmToken': fcmToken,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'ideasCount': 0,
        'requestsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
      };

      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      return AppUser.fromMap(userData);
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  /// Обновить FCM токен
  Future<void> updateFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': fcmToken,
          'updatedAt': Timestamp.now(),
        });
        debugPrint('📱 Обновление FCM токена для пользователя: ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Установить статус онлайн
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error setting online status: $e');
    }
  }

  /// Получить дружелюбное сообщение об ошибке
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'weak-password':
        return 'Пароль должен содержать минимум 6 символов';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'invalid-credential':
        return 'Неверные учетные данные';
      case 'account-exists-with-different-credential':
        return 'Аккаунт уже существует с другими учетными данными';
      case 'credential-already-in-use':
        return 'Учетные данные уже используются';
      case 'invalid-verification-code':
        return 'Неверный код подтверждения';
      case 'invalid-verification-id':
        return 'Неверный ID подтверждения';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету';
      default:
        return 'Произошла ошибка: $errorCode';
    }
  }
}
