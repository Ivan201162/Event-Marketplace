import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Демо-сервис аутентификации для веб-версии
/// Используется когда Firebase не настроен или недоступен
class DemoAuthService {
  static final DemoAuthService _instance = DemoAuthService._internal();
  factory DemoAuthService() => _instance;
  DemoAuthService._internal();

  User? _currentUser;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  /// Текущий пользователь
  User? get currentUser => _currentUser;

  /// Поток изменений состояния аутентификации
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// Вход с email и паролем (демо)
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (kIsWeb) {
      // Создаем демо-пользователя
      final demoUser = _createDemoUser(email);
      _currentUser = demoUser;
      _authStateController.add(demoUser);
      
      return UserCredential._(
        user: demoUser,
        credential: null,
        additionalUserInfo: null,
      );
    }
    
    throw UnsupportedError('Demo auth only available on web');
  }

  /// Регистрация с email и паролем (демо)
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (kIsWeb) {
      // Создаем демо-пользователя
      final demoUser = _createDemoUser(email);
      _currentUser = demoUser;
      _authStateController.add(demoUser);
      
      return UserCredential._(
        user: demoUser,
        credential: null,
        additionalUserInfo: null,
      );
    }
    
    throw UnsupportedError('Demo auth only available on web');
  }

  /// Вход через Google (демо)
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Создаем демо-пользователя Google
      final demoUser = _createDemoUser('demo@gmail.com', displayName: 'Demo User');
      _currentUser = demoUser;
      _authStateController.add(demoUser);
      
      return UserCredential._(
        user: demoUser,
        credential: null,
        additionalUserInfo: null,
      );
    }
    
    throw UnsupportedError('Demo auth only available on web');
  }

  /// Анонимный вход (демо)
  Future<UserCredential> signInAnonymously() async {
    if (kIsWeb) {
      // Создаем демо-анонимного пользователя
      final demoUser = _createDemoUser('anonymous@demo.com', displayName: 'Гость');
      _currentUser = demoUser;
      _authStateController.add(demoUser);
      
      return UserCredential._(
        user: demoUser,
        credential: null,
        additionalUserInfo: null,
      );
    }
    
    throw UnsupportedError('Demo auth only available on web');
  }

  /// Выход
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  /// Создание демо-пользователя
  User _createDemoUser(String email, {String? displayName}) {
    return User._(
      uid: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName ?? 'Demo User',
      photoURL: null,
      isAnonymous: email == 'anonymous@demo.com',
    );
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Демо-класс User для веб-аутентификации
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;

  User._({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
  });

  /// Обновление профиля (демо)
  Future<void> updateDisplayName(String displayName) async {
    // В демо-режиме просто логируем
    if (kDebugMode) {
      print('Demo: Updating display name to $displayName');
    }
  }

  /// Обновление email (демо)
  Future<void> updateEmail(String email) async {
    // В демо-режиме просто логируем
    if (kDebugMode) {
      print('Demo: Updating email to $email');
    }
  }

  /// Отправка email для верификации (демо)
  Future<void> sendEmailVerification() async {
    // В демо-режиме просто логируем
    if (kDebugMode) {
      print('Demo: Sending email verification');
    }
  }

  /// Проверка верификации email (демо)
  bool get emailVerified => true; // В демо-режиме всегда true
}

/// Демо-класс UserCredential
class UserCredential {
  final User? user;
  final dynamic credential;
  final dynamic additionalUserInfo;

  UserCredential._({
    this.user,
    this.credential,
    this.additionalUserInfo,
  });
}
