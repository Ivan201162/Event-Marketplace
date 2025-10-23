import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Улучшенный сервис авторизации с исправленными ошибками
class AuthServiceEnhanced {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Поток текущего пользователя
  Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _getOrCreateUser(credential.user!);
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in with email: $e');
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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Обновляем отображаемое имя
        if (name != null) {
          await credential.user!.updateDisplayName(name);
        }

        return await _createUserDocument(credential.user!,
            name: name, city: city);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating user with email: $e');
      rethrow;
    }
  }

  /// Вход через Google
  Future<AppUser?> signInWithGoogle() async {
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

      if (userCredential.user != null) {
        return await _getOrCreateUser(userCredential.user!);
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
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
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _getOrCreateUser(userCredential.user!);
            }
          } catch (e) {
            onError('Ошибка автоматической верификации: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError('Ошибка верификации: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
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
