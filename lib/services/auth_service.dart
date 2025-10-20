import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
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
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email registration: $e');
      return false;
    }
  }

  /// Get sign-in methods for email (to detect Google/Phone conflicts)
  Future<List<String>> getSignInMethodsForEmail(String email) async {
    try {
      return await _auth.fetchSignInMethodsForEmail(email);
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
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Неверный формат email',
        );
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

  /// Sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
      );
    } catch (e) {
      debugPrint('Phone sign in error: $e');
      onError(e.toString());
    }
  }

  /// Verify phone code
  Future<AppUser?> verifyPhoneCode({
    required String verificationId,
    required String code,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        return await currentUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Phone verification error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected phone verification error: $e');
      rethrow;
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
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(code: 'canceled', message: 'Google sign-in canceled');
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
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
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updateData['name'] = name;
      if (city != null) updateData['city'] = city;
      if (status != null) updateData['status'] = status;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;
      if (type != null) updateData['type'] = type.name;

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
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Неверный формат email',
        );
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

      return user;
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }
}
