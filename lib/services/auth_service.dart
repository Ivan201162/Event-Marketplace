import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import '../models/user.dart';
import 'storage_service.dart';

/// Сервис для управления аутентификацией пользователей
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final StorageService _storageService = StorageService();

  /// Текущий пользователь Firebase
  User? get currentFirebaseUser => _auth.currentUser;

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
    } catch (e) {
      print('Ошибка получения пользователя: $e');
      return null;
    }
  }

  /// Поток текущего пользователя
  Stream<AppUser?> get currentUserStream {
    return authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return AppUser.fromDocument(doc);
        }
        return null;
      } catch (e) {
        print('Ошибка получения пользователя: $e');
        return null;
      }
    });
  }

  /// Регистрация с email и паролем
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      // Создаем пользователя в Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) return null;

      // Обновляем профиль Firebase
      await firebaseUser.updateDisplayName(displayName);

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
      // Создаем анонимного пользователя
      final credential = await _auth.signInAnonymously();
      final firebaseUser = credential.user;

      if (firebaseUser == null) return null;

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

      return guestUser;
    } catch (e) {
      throw Exception('Ошибка входа как гость: $e');
    }
  }

  /// Войти через Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // Пользователь отменил вход
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      // Проверяем, существует ли пользователь в Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // Создаем нового пользователя
        final appUser = AppUser.fromFirebaseUser(
          firebaseUser.uid,
          firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
          role: UserRole.customer,
          socialProvider: 'google',
          socialId: googleUser.id,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(appUser.toMap());
        return appUser;
      } else {
        // Обновляем время последнего входа
        await _updateLastLogin(firebaseUser.uid);
        return AppUser.fromDocument(userDoc);
      }
    } catch (e) {
      throw Exception('Ошибка входа через Google: $e');
    }
  }

  /// Войти через VK
  Future<AppUser?> signInWithVK({UserRole role = UserRole.customer}) async {
    try {
      // TODO: Реализовать VK OAuth
      // Это требует дополнительной настройки VK SDK
      // Пока возвращаем заглушку
      throw Exception(
          'VK Sign-In пока не реализован. Требуется настройка VK SDK.');
    } catch (e) {
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

  /// Вход через Google
  Future<AppUser?> signInWithGoogle({required UserRole role}) async {
    try {
      // Запускаем процесс входа через Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Получаем данные аутентификации
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Создаем новый credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Входим в Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // Проверяем, существует ли пользователь в Firestore
      final existingUser = await getCurrentUser();
      if (existingUser != null) {
        await _updateLastLogin(firebaseUser.uid);
        return existingUser;
      }

      // Создаем нового пользователя
      final appUser = AppUser.fromFirebaseUser(
        firebaseUser.uid,
        firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Пользователь',
        photoURL: firebaseUser.photoURL,
        role: role,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toMap());
      return appUser;
    } catch (e) {
      throw Exception('Ошибка входа через Google: $e');
    }
  }

  /// Вход через ВКонтакте (временно отключен)
  Future<AppUser?> signInWithVK({required UserRole role}) async {
    throw Exception('Вход через ВКонтакте временно недоступен');
  }

  /// Выход из всех социальных сетей
  Future<void> signOutFromAll() async {
    try {
      await _googleSignIn.signOut();
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
