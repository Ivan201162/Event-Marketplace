import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/safe_log.dart';
import '../core/logger.dart';
import '../models/user.dart';
import '../features/auth/utils/auth_error_mapper.dart';
import 'demo_auth_service.dart' as demo;
import 'storage_service.dart';

// Условные импорты для веб и мобильных платформ
import 'auth_service_web.dart' if (dart.library.io) 'auth_service_mobile.dart';

/// Сервис для управления аутентификацией пользователей
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  
  // Демо-сервис для веб-платформы
  dynamic get _demoAuth {
    if (kIsWeb) {
      try {
        return demo.DemoAuthService();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Проверка, используется ли демо-режим
  bool get _isDemoMode => false; // Отключаем демо-режим

  /// Текущий пользователь Firebase
  User? get currentFirebaseUser =>
      _isDemoMode ? _demoAuth?.currentUser : _auth.currentUser;

  /// Текущий пользователь (алиас для совместимости)
  User? get currentUser =>
      _isDemoMode ? _demoAuth?.currentUser : _auth.currentUser;

  /// Поток изменений состояния аутентификации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Поток изменений ID токена
  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  /// Поток изменений пользователя
  Stream<User?> get userChanges => _auth.userChanges();

  /// Проверка, авторизован ли пользователь
  bool get isSignedIn => currentUser != null;

  /// Получить текущего пользователя приложения
  Future<AppUser?> getCurrentAppUser() async {
    try {
      final firebaseUser = currentUser;
      if (firebaseUser == null) {
        AppLogger.logI('Пользователь не авторизован', 'auth_service');
        return null;
      }

      AppLogger.logI('Получение данных пользователя: ${firebaseUser.uid}', 'auth_service');

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        AppLogger.logW('Документ пользователя не найден в Firestore', 'auth_service');
        return null;
      }

      final appUser = AppUser.fromDocument(userDoc);
      AppLogger.logI('Пользователь получен: ${appUser.displayNameOrEmail}', 'auth_service');
      return appUser;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения пользователя', 'auth_service', e, stackTrace);
      return null;
    }
  }

  /// Регистрация с email и паролем
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      AppLogger.logI(
          'Начинаем регистрацию пользователя: $email', 'auth_service');

      // Создаем пользователя в Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Не удалось создать пользователя в Firebase Auth');
      }

      AppLogger.logI('Пользователь создан в Firebase Auth: ${firebaseUser.uid}', 'auth_service');

      // Обновляем отображаемое имя
      await firebaseUser.updateDisplayName(name);
      await firebaseUser.reload();

      // Создаем запись в Firestore
      final appUser = AppUser(
        id: firebaseUser.uid,
        email: email,
        displayName: name,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toMap());

      AppLogger.logI('Пользователь создан в Firestore: ${appUser.displayName}', 'auth_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка регистрации', 'auth_service', e, stackTrace);
      if (e is FirebaseAuthException) {
        throw Exception(_handleAuthException(e));
      }
      throw Exception('Ошибка регистрации: $e');
    }
  }

  /// Вход с email и паролем
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.logI('Начинаем вход пользователя: $email', 'auth_service');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Не удалось войти в систему');
      }

      AppLogger.logI('Пользователь вошел: ${firebaseUser.uid}', 'auth_service');

      // Обновляем время последнего входа
      await _updateLastLogin(firebaseUser.uid);

      // Получаем данные пользователя из Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        AppLogger.logW('Документ пользователя не найден в Firestore', 'auth_service');
        return null;
      }

      final appUser = AppUser.fromDocument(userDoc);
      AppLogger.logI('Пользователь получен: ${appUser.displayNameOrEmail}', 'auth_service');
      return appUser;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка входа', 'auth_service', e, stackTrace);
      if (e is FirebaseAuthException) {
        throw Exception(_handleAuthException(e));
      }
      throw Exception('Ошибка входа: $e');
    }
  }

  /// Вход с номером телефона (отправка SMS)
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      AppLogger.logI('Начинаем вход по телефону: $phoneNumber', 'auth_service');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );

      AppLogger.logI('SMS отправлена на номер: $phoneNumber', 'auth_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка отправки SMS', 'auth_service', e, stackTrace);
      if (e is FirebaseAuthException) {
        throw Exception(_handleAuthException(e));
      }
      throw Exception('Ошибка отправки SMS: $e');
    }
  }

  /// Подтверждение SMS кода
  Future<AppUser?> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      AppLogger.logI('Подтверждение SMS кода', 'auth_service');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Не удалось войти с SMS кодом');
      }

      AppLogger.logI('Пользователь вошел по SMS: ${firebaseUser.uid}', 'auth_service');

      // Проверяем, существует ли пользователь в Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Создаем нового пользователя
        AppLogger.logI('Создание нового пользователя по SMS...', 'auth_service');
        final appUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Пользователь',
          phoneNumber: firebaseUser.phoneNumber,
          role: UserRole.customer,
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(appUser.toMap());

        AppLogger.logI('Пользователь создан: ${appUser.displayName}', 'auth_service');
        return appUser;
      } else {
        // Обновляем время последнего входа
        await _updateLastLogin(firebaseUser.uid);
        final appUser = AppUser.fromDocument(userDoc);
        AppLogger.logI('Пользователь вошел: ${appUser.displayNameOrEmail}', 'auth_service');
        return appUser;
      }
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка подтверждения SMS', 'auth_service', e, stackTrace);
      if (e is FirebaseAuthException) {
        throw Exception(_handleAuthException(e));
      }
      throw Exception('Ошибка подтверждения SMS: $e');
    }
  }

  /// Вход как гость (анонимно)
  Future<AppUser?> signInAsGuest() async {
    try {
      AppLogger.logI('Начинаем анонимный вход...', 'auth_service');

      final credential = await _auth.signInAnonymously();
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Не удалось войти анонимно');
      }

      AppLogger.logI('Анонимный пользователь создан: ${firebaseUser.uid}', 'auth_service');

      // Создаем запись в Firestore
      final appUser = AppUser(
        id: firebaseUser.uid,
        email: 'guest@example.com',
        displayName: 'Гость',
        role: UserRole.guest,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toMap());

      AppLogger.logI('Гость создан: ${appUser.displayName}', 'auth_service');
      return appUser;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка анонимного входа', 'auth_service', e, stackTrace);
      if (e is FirebaseAuthException) {
        throw Exception(_handleAuthException(e));
      }
      throw Exception('Ошибка анонимного входа: $e');
    }
  }

  /// Выход из системы
  Future<void> signOut() async {
    try {
      AppLogger.logI('Выход из системы...', 'auth_service');
      await _auth.signOut();
      AppLogger.logI('Выход выполнен успешно', 'auth_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка выхода', 'auth_service', e, stackTrace);
      throw Exception('Ошибка выхода: $e');
    }
  }

  /// Отправка письма для сброса пароля
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.logI('Отправка письма для сброса пароля: $email', 'auth_service');
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.logI('Письмо для сброса пароля отправлено', 'auth_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка отправки письма для сброса пароля', 'auth_service', e, stackTrace);
      if (e is FirebaseAuthException) {
        throw Exception(_handleAuthException(e));
      }
      throw Exception('Ошибка отправки письма: $e');
    }
  }

  /// Обновление времени последнего входа
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.logE('Ошибка обновления времени входа', 'auth_service', e);
    }
  }

  /// Обработка ошибок аутентификации
  String _handleAuthException(FirebaseAuthException e) {
    AppLogger.logE('Firebase Auth Error: ${e.code} - ${e.message}', 'auth_service');
    return AuthErrorMapper.mapFirebaseAuthException(e);
  }

  /// Проверка, поддерживается ли аутентификация по телефону
  bool get isPhoneAuthSupported {
    // Для веб-платформы проверяем поддержку
    if (kIsWeb) {
      return true; // Firebase Auth поддерживает телефон для веб
    }
    return true; // Для мобильных платформ всегда поддерживается
  }

  /// Получить маскированный номер телефона
  String getMaskedPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) return phoneNumber;
    final lastFour = phoneNumber.substring(phoneNumber.length - 4);
    return '***-***-$lastFour';
  }

  /// Проверить формат номера телефона
  bool isValidPhoneNumber(String phoneNumber) {
    // Простая проверка формата российского номера
    final phoneRegex = RegExp(r'^\+7\d{10}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  /// Форматировать номер телефона
  String formatPhoneNumber(String phoneNumber) {
    // Убираем все символы кроме цифр
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 8, заменяем на +7
    if (digits.startsWith('8') && digits.length == 11) {
      return '+7${digits.substring(1)}';
    }
    
    // Если номер начинается с 7, добавляем +
    if (digits.startsWith('7') && digits.length == 11) {
      return '+$digits';
    }
    
    // Если номер уже в формате +7
    if (phoneNumber.startsWith('+7') && digits.length == 11) {
      return phoneNumber;
    }
    
    return phoneNumber;
  }
}