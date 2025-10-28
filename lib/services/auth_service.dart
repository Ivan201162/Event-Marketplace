import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Stream of current user
  Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          try {
            return AppUser.fromFirestore(userDoc);
          } catch (e) {
            debugPrint('Error parsing user data from Firestore: $e');
            // If parsing fails, create a new user document
            return await _createUserDocument(firebaseUser);
          }
        } else {
          // Create user document if it doesn't exist
          return await _createUserDocument(firebaseUser);
        }
      } catch (e) {
        debugPrint('Error getting user: $e');
        // Return a basic user object if Firestore fails
        return AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Пользователь',
          email: firebaseUser.email,
          phone: firebaseUser.phoneNumber,
          avatarUrl: firebaseUser.photoURL,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          type: UserType.physical,
          favoriteSpecialists: const [],
          socialLinks: const [],
          ctaButtons: const {},
        );
      }
    });
  }

  /// Get current user
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
      // Return a basic user object if Firestore fails
      return AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Пользователь',
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber,
        avatarUrl: firebaseUser.photoURL,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: UserType.physical,
        favoriteSpecialists: const [],
        socialLinks: const [],
        ctaButtons: const {},
      );
    }
  }

  /// Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password,);

      if (credential.user != null) {
        // Обновляем FCM токен после успешного входа
        await updateFCMToken();

        // Сохраняем сессию
        await _saveUserSession(credential.user!);

        // Логируем успешную авторизацию
        await _analytics.logLogin(loginMethod: 'email');

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

  /// Create user with email and password
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user document
        await _createUserDocument(credential.user!);
      }

      // Логируем успешную регистрацию
      await _analytics.logSignUp(signUpMethod: 'email');

      debugPrint('✅ User created with email successfully');
    } catch (e) {
      debugPrint('❌ Error creating user with email: $e');
      rethrow;
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      // Try to sign in with a dummy password to check if email exists
      try {
        await _auth.signInWithEmailAndPassword(
            email: email, password: 'dummy_password',);
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
      // Проверяем существование email через попытку входа
      try {
        await _auth.signInWithEmailAndPassword(
            email: email, password: 'dummy_password',);
        return ['email']; // Email существует
      } catch (e) {
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            return []; // Email не найден
          } else if (e.code == 'wrong-password') {
            return ['email']; // Email существует, но пароль неверный
          }
        }
        return [];
      }
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
            message:
                'Этот email уже используется с Google. Войти через Google?',
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
            message:
                'Этот email уже используется. Попробуйте войти или восстановить пароль.',
          );
        }
      }

      // Дополнительная проверка валидности email
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw FirebaseAuthException(
            code: 'invalid-email', message: 'Неверный формат email',);
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
        final user = await _createUserDocument(credential.user!, name: name);

        // Логируем успешную регистрацию
        await _analytics.logSignUp(signUpMethod: 'email');

        return user;
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
  Future<String> sendPhoneVerificationCode(String phoneNumber) async {
    try {
      debugPrint('📱 Отправка SMS кода на номер: $phoneNumber');

      final completer = Completer<String>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          debugPrint('✅ Автоматическая верификация завершена');
          // Auto-verification completed
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          debugPrint('❌ Ошибка верификации: ${e.code} - ${e.message}');

          // Обработка специфических ошибок Phone Auth
          if (e.code == 'unknown' &&
              (e.message?.contains('BILLING_NOT_ENABLED') ?? false)) {
            throw FirebaseAuthException(
              code: 'billing-not-enabled',
              message:
                  'Phone Authentication не настроена в Firebase Console. Обратитесь к администратору.',
            );
          }

          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (verificationId, resendToken) {
          debugPrint('📨 SMS код отправлен, verificationId: $verificationId');
          // Сохраняем verificationId для последующей проверки
          _currentVerificationId = verificationId;
          _resendToken = resendToken;

          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          debugPrint('⏰ Таймаут автоматического получения кода');
          _currentVerificationId = verificationId;

          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return await completer.future;
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
        await docRef.update(
            {'phone': user.phoneNumber ?? '', 'updatedAt': Timestamp.now()},);
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
        // Use Firebase Auth with Google provider directly
        final googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithProvider(googleProvider);
      }

      final user = userCredential.user;
      if (user == null) return null;

      // Ensure profile exists and update with Google data
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();

      // Parse display name into first and last name
      var firstName = '';
      var lastName = '';
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final nameParts = user.displayName!.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }

      if (!snapshot.exists) {
        // Create new user profile with Google data
        await docRef.set({
          'uid': user.uid,
          'name': user.displayName ?? 'Пользователь',
          'firstName': firstName,
          'lastName': lastName,
          'email': user.email,
          'phone': user.phoneNumber ?? '',
          'avatarUrl': user.photoURL,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'provider': 'google',
          'isProAccount': false,
          'isVerified': false,
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
          'socialLinks': [],
          'ctaButtons': {},
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Update existing profile with Google data (only if fields are empty)
        final existingData = snapshot.data()!;
        final updateData = <String, dynamic>{
          'updatedAt': Timestamp.now(),
        };

        // Update name if empty or if Google has better data
        if (existingData['name'] == null ||
            existingData['name'] == 'Пользователь') {
          updateData['name'] = user.displayName ?? 'Пользователь';
        }
        if (existingData['firstName'] == null ||
            existingData['firstName'] == '') {
          updateData['firstName'] = firstName;
        }
        if (existingData['lastName'] == null ||
            existingData['lastName'] == '') {
          updateData['lastName'] = lastName;
        }
        if (existingData['avatarUrl'] == null ||
            existingData['avatarUrl'] == '') {
          updateData['avatarUrl'] = user.photoURL;
        }
        if (existingData['displayName'] == null ||
            existingData['displayName'] == '') {
          updateData['displayName'] = user.displayName;
        }
        if (existingData['photoURL'] == null ||
            existingData['photoURL'] == '') {
          updateData['photoURL'] = user.photoURL;
        }

        await docRef.update(updateData);
      }

      // Обновляем FCM токен после успешной авторизации
      await updateFCMToken();

      // Сохраняем сессию
      await _saveUserSession(user);

      // Логируем успешную авторизацию
      await _analytics.logLogin(loginMethod: 'google');

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

  /// Update user profile (simplified version)
  Future<void> updateUserProfileSimple({
    required String name,
    String? city,
    String? description,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final updateData = <String, dynamic>{
        'name': name,
        'updatedAt': Timestamp.now(),
      };

      if (city != null) updateData['city'] = city;
      if (description != null) updateData['description'] = description;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Update Firebase Auth display name if name changed
      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      debugPrint('✅ User profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
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
        throw FirebaseAuthException(
            code: 'invalid-email', message: 'Неверный формат email',);
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

      // Очищаем локальную сессию
      await _clearUserSession();

      if (!kIsWeb) {
        try {
          // Google sign out is handled by Firebase Auth
        } catch (_) {}
      }

      // Логируем выход
      await _analytics.logEvent(name: 'user_sign_out');

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
    
    // Parse display name into first and last name
    var firstName = '';
    var lastName = '';
    if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
      final nameParts = firebaseUser.displayName!.split(' ');
      firstName = nameParts.first;
      if (nameParts.length > 1) {
        lastName = nameParts.sublist(1).join(' ');
      }
    }
    
    final user = AppUser(
      uid: firebaseUser.uid,
      name: name ?? firebaseUser.displayName ?? 'Пользователь',
      firstName: firstName,
      lastName: lastName,
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      createdAt: now,
      updatedAt: now,
      type: isGuest ? UserType.physical : UserType.physical,
      favoriteSpecialists: const [],
      socialLinks: const [],
      ctaButtons: const {},
    );

    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toFirestore());

      // Обновляем FCM токен после создания профиля
      await updateFCMToken();

      return user;
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  /// Сохранить сессию пользователя локально
  Future<void> _saveUserSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session_id', user.uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_display_name', user.displayName ?? '');
      await prefs.setString('user_photo_url', user.photoURL ?? '');
      await prefs.setInt(
          'session_timestamp', DateTime.now().millisecondsSinceEpoch,);

      debugPrint('✅ User session saved locally');
    } catch (e) {
      debugPrint('❌ Error saving user session: $e');
    }
  }

  /// Очистить локальную сессию пользователя
  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session_id');
      await prefs.remove('user_email');
      await prefs.remove('user_display_name');
      await prefs.remove('user_photo_url');
      await prefs.remove('session_timestamp');

      debugPrint('✅ User session cleared locally');
    } catch (e) {
      debugPrint('❌ Error clearing user session: $e');
    }
  }

  /// Проверить, есть ли сохраненная сессия
  Future<bool> hasStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('user_session_id');
      final timestamp = prefs.getInt('session_timestamp');

      if (sessionId == null || timestamp == null) return false;

      // Проверяем, не истекла ли сессия (30 дней)
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(sessionDate);

      if (difference.inDays > 30) {
        await _clearUserSession();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error checking stored session: $e');
      return false;
    }
  }

  /// Получить сохраненные данные пользователя
  Future<Map<String, String>?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('user_session_id');
      final email = prefs.getString('user_email');
      final displayName = prefs.getString('user_display_name');
      final photoUrl = prefs.getString('user_photo_url');

      if (sessionId == null) return null;

      return {
        'uid': sessionId,
        'email': email ?? '',
        'displayName': displayName ?? '',
        'photoURL': photoUrl ?? '',
      };
    } catch (e) {
      debugPrint('❌ Error getting stored user data: $e');
      return null;
    }
  }
}
