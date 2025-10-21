import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Authentication service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of current user
  Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((User? firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          return AppUser.fromFirestore(userDoc);
        } else {
          // Create user document if it doesn't exist
          return await _createUserDocument(firebaseUser);
        }
      } catch (e) {
        debugPrint('Error getting user: $e');
        return null;
      }
    });
  }

  /// Get current user
  Future<AppUser?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

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

  /// Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        // Обновляем FCM токен после успешного входа
        await updateFCMToken();
        return await currentUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      rethrow;
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Try to sign in with a dummy password to check if email exists
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: 'dummy_password');
        return true;
      } catch (e) {
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            return false;
          } else if (e.code == 'wrong-password') {
            return true; // Email exists but wrong password
          }
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error checking email registration: $e');
      return false;
    }
  }

  /// Get sign-in methods for email (to detect Google/Phone conflicts)
  Future<List<String>> getSignInMethodsForEmail(String email) async {
    try {
      // This method is deprecated, return empty list for now
      // In production, you might want to implement a different approach
      return [];
    } catch (e) {
      debugPrint('Error getting sign-in methods: $e');
      return [];
    }
  }

  /// Sign up with email and password
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Предварительная проверка существования email
      final signInMethods = await getSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        // Email уже зарегистрирован
        if (signInMethods.contains('google.com')) {
          throw FirebaseAuthException(
            code: 'email-already-in-use-google',
            message: 'Этот email уже используется с Google. Войти через Google?',
          );
        } else if (signInMethods.contains('phone')) {
          throw FirebaseAuthException(
            code: 'email-already-in-use-phone',
            message:
                'Этот email уже используется с номером телефона. Попробуйте войти или восстановить пароль.',
          );
        } else {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Этот email уже используется. Попробуйте войти или восстановить пароль.',
          );
        }
      }

      // Дополнительная проверка валидности email
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw FirebaseAuthException(code: 'invalid-email', message: 'Неверный формат email');
      }

      // Проверка силы пароля
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Пароль должен содержать минимум 6 символов',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user document
        return await _createUserDocument(credential.user!, name: name);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign up error: $e');
      rethrow;
    }
  }

  /// Send phone verification code
  Future<void> sendPhoneVerificationCode(String phoneNumber) async {
    try {
      debugPrint('📱 Отправка SMS кода на номер: $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Автоматическая верификация завершена');
          // Auto-verification completed
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Ошибка верификации: ${e.code} - ${e.message}');

          // Обработка специфических ошибок Phone Auth
          if (e.code == 'unknown' && e.message?.contains('BILLING_NOT_ENABLED') == true) {
            throw FirebaseAuthException(
              code: 'billing-not-enabled',
              message:
                  'Phone Authentication не настроена в Firebase Console. Обратитесь к администратору.',
            );
          }

          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📨 SMS код отправлен, verificationId: $verificationId');
          // Сохраняем verificationId для последующей проверки
          _currentVerificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Таймаут автоматического получения кода');
          _currentVerificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('❌ Ошибка отправки SMS: $e');
      rethrow;
    }
  }

  /// Verify phone code
  Future<AppUser?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      debugPrint('🔐 Проверка SMS кода: $smsCode');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found after phone verification',
        );
      }

      debugPrint('✅ SMS код подтвержден для пользователя: ${user.uid}');

      // Ensure profile exists
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        // Create new user profile
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'name': user.displayName ?? 'Пользователь',
          'avatarUrl': user.photoURL,
          'provider': 'phone',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        debugPrint('👤 Создан новый профиль пользователя');
      } else {
        // Update existing profile with phone number
        await docRef.update({'phone': user.phoneNumber ?? '', 'updatedAt': Timestamp.now()});
        debugPrint('👤 Обновлен профиль пользователя с номером телефона');
      }

      // Обновляем FCM токен после успешной авторизации
      await updateFCMToken();

      return await currentUser;
    } catch (e) {
      debugPrint('❌ Ошибка проверки SMS кода: $e');
      rethrow;
    }
  }

  // Private fields for phone auth
  String? _currentVerificationId;
  int? _resendToken;

  /// Get current verification ID
  String? get currentVerificationId => _currentVerificationId;

  /// Get resend token
  int? get resendToken => _resendToken;

  /// Update FCM token for current user
  Future<void> updateFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      debugPrint('📱 Обновление FCM токена для пользователя: ${user.uid}');

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': Timestamp.now(),
      });

      debugPrint('✅ FCM токен обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка обновления FCM токена: $e');
    }
  }

  /// Clear FCM token on logout
  Future<void> clearFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('📱 Очистка FCM токена для пользователя: ${user.uid}');

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenClearedAt': Timestamp.now(),
      });

      debugPrint('✅ FCM токен очищен');
    } catch (e) {
      debugPrint('❌ Ошибка очистки FCM токена: $e');
    }
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Configure Google Sign-In with proper client ID
        final GoogleSignIn googleSignIn = GoogleSignIn();

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(code: 'canceled', message: 'Google sign-in canceled');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null) {
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Failed to get Google authentication tokens',
          );
        }

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) return null;

      // Ensure profile exists
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'phone': user.phoneNumber ?? '',
          'name': user.displayName ?? 'Пользователь',
          'avatarUrl': user.photoURL,
          'provider': 'google',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      } else {
        await docRef.update({'updatedAt': Timestamp.now()});
      }

      // Обновляем FCM токен после успешной авторизации
      await updateFCMToken();

      return await currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected Google sign-in error: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? city,
    String? status,
    String? avatarUrl,
    UserType? type,
    String? bio,
    double? hourlyRate,
    String? specialistType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final updateData = <String, dynamic>{'updatedAt': Timestamp.now()};

      if (name != null) updateData['name'] = name;
      if (city != null) updateData['city'] = city;
      if (status != null) updateData['status'] = status;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
      if (type != null) updateData['type'] = type.name;
      if (bio != null) updateData['bio'] = bio;
      if (hourlyRate != null) updateData['hourlyRate'] = hourlyRate;
      if (specialistType != null) updateData['specialistType'] = specialistType;

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Update Firebase Auth display name if name changed
      if (name != null && user.displayName != name) {
        await user.updateDisplayName(name);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Set user online status
  Future<void> setUserOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error setting online status: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      // Проверяем валидность email
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw FirebaseAuthException(code: 'invalid-email', message: 'Неверный формат email');
      }

      // Проверяем, существует ли email
      final signInMethods = await getSignInMethodsForEmail(email);

      if (signInMethods.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message:
              'Пользователь с таким email не найден. Проверьте правильность email или зарегистрируйтесь.',
        );
      }

      // Проверяем, не зарегистрирован ли через Google
      if (signInMethods.contains('google.com')) {
        throw FirebaseAuthException(
          code: 'google-account',
          message:
              'Этот email зарегистрирован через Google. Войдите через Google или используйте другой email.',
        );
      }

      // Проверяем, не зарегистрирован ли через телефон
      if (signInMethods.contains('phone')) {
        throw FirebaseAuthException(
          code: 'phone-account',
          message:
              'Этот email зарегистрирован через номер телефона. Войдите через телефон или используйте другой email.',
        );
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Error sending password reset: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error sending password reset: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await setUserOnlineStatus(false);

      // Очищаем FCM токен перед выходом
      await clearFCMToken();

      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Create user document in Firestore
  Future<AppUser> _createUserDocument(
    User firebaseUser, {
    String? name,
    bool isGuest = false,
  }) async {
    final now = DateTime.now();
    final user = AppUser(
      uid: firebaseUser.uid,
      name: name ?? firebaseUser.displayName ?? 'Пользователь',
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      createdAt: now,
      updatedAt: now,
      type: isGuest ? UserType.physical : UserType.physical,
    );

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toFirestore());

      // Обновляем FCM токен после создания профиля
      await updateFCMToken();

      return user;
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }
}
