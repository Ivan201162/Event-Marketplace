import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../core/logger.dart';
import '../models/user.dart';

/// Сервис для аутентификации через ВКонтакте
class VKAuthService {
  static const String _vkClientId = 'YOUR_VK_APP_ID'; // Заменить на реальный ID
  static const String _vkRedirectUri = 'http://localhost:8080/vk-callback';
  static const String _vkScope = 'friends,photos,wall,email';
  static const String _vkVersion = '5.199';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Начать процесс входа через VK для web
  Future<void> startVkLoginWeb() async {
    try {
      AppLogger.logI('Начало VK OAuth для web...', 'vk_auth_service');

      final vkAuthUrl = _buildVkAuthUrl();
      AppLogger.logI('VK Auth URL: $vkAuthUrl', 'vk_auth_service');

      // Открываем VK OAuth в новом окне (только для web)
      if (kIsWeb) {
        // Для web используем условный импорт
        await _openVkAuthWindow(vkAuthUrl);
      } else {
        throw UnsupportedError('VK OAuth доступен только для web платформы');
      }
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка начала VK OAuth', 'vk_auth_service', e, stackTrace);
      throw Exception('Ошибка начала входа через VK: $e');
    }
  }

  /// Обработать VK callback и войти в систему
  Future<AppUser?> handleVkCallbackAndSignIn(String code) async {
    try {
      AppLogger.logI('Обработка VK callback и вход в систему...', 'vk_auth_service');
      
      // Получаем custom token через Cloud Function
      final customToken = await _exchangeCodeForCustomToken(code);
      
      if (customToken == null) {
        AppLogger.logE('Не удалось получить custom token', 'vk_auth_service');
        return null;
      }
      
      // Входим в Firebase с custom token
      final credential = await _auth.signInWithCustomToken(customToken);
      final firebaseUser = credential.user;
      
      if (firebaseUser == null) {
        AppLogger.logE('Firebase пользователь не создан', 'vk_auth_service');
        return null;
      }
      
      // Получаем данные пользователя из Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (userDoc.exists) {
        final appUser = AppUser.fromDocument(userDoc);
        AppLogger.logI('VK пользователь вошел: ${appUser.displayName}', 'vk_auth_service');
        return appUser;
      } else {
        AppLogger.logE('Пользователь не найден в Firestore', 'vk_auth_service');
        return null;
      }
      
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка обработки VK callback и входа', 'vk_auth_service', e, stackTrace);
      throw Exception('Ошибка обработки VK callback и входа: $e');
    }
  }

  /// Построить URL для VK OAuth
  String _buildVkAuthUrl() {
    final params = {
      'client_id': _vkClientId,
      'display': 'page',
      'redirect_uri': _vkRedirectUri,
      'scope': _vkScope,
      'response_type': 'code',
      'v': _vkVersion,
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://oauth.vk.com/authorize?$queryString';
  }

  /// Обработать callback от VK OAuth
  Future<AppUser?> handleVkCallback(String code) async {
    try {
      AppLogger.logI('Обработка VK callback с кодом: $code', 'vk_auth_service');

      // Отправляем код на Cloud Function для получения custom token
      final customToken = await _exchangeCodeForCustomToken(code);

      if (customToken == null) {
        AppLogger.logE('Не удалось получить custom token', 'vk_auth_service');
        return null;
      }

      // Входим в Firebase с custom token
      final credential = await _auth.signInWithCustomToken(customToken);
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        AppLogger.logE('Firebase пользователь не создан', 'vk_auth_service');
        return null;
      }

      // Получаем данные пользователя из Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        final appUser = AppUser.fromDocument(userDoc);
        AppLogger.logI(
            'VK пользователь вошел: ${appUser.displayName}', 'vk_auth_service');
        return appUser;
      } else {
        AppLogger.logE('Пользователь не найден в Firestore', 'vk_auth_service');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка обработки VK callback', 'vk_auth_service', e, stackTrace);
      throw Exception('Ошибка обработки VK callback: $e');
    }
  }

  /// Обменять код на custom token через Cloud Function
  Future<String?> _exchangeCodeForCustomToken(String code) async {
    try {
      AppLogger.logI(
          'Обмен кода на custom token через Cloud Function', 'vk_auth_service');

      // Вызываем Cloud Function для получения custom token
      final callable =
          FirebaseFunctions.instance.httpsCallable('vkCustomToken');
      final result = await callable.call({'code': code});

      if (result.data != null && result.data['firebaseCustomToken'] != null) {
        AppLogger.logI('Custom token получен успешно', 'vk_auth_service');
        return result.data['firebaseCustomToken'] as String;
      } else {
        AppLogger.logE('Custom token не получен', 'vk_auth_service');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка обмена кода на token', 'vk_auth_service', e, stackTrace);
      return null;
    }
  }

  /// Создать VK пользователя (заглушка для тестирования)
  Future<AppUser?> createVkUserForTesting() async {
    try {
      AppLogger.logI(
          'Создание VK пользователя для тестирования...', 'vk_auth_service');

      // Для веб-платформы возвращаем демо-пользователя без Firebase
      if (kIsWeb) {
        final demoUser = AppUser(
          id: 'demo_vk_user_${DateTime.now().millisecondsSinceEpoch}',
          email: 'demo@vk.com',
          displayName: 'Демо VK Пользователь',
          photoURL: 'https://via.placeholder.com/200',
          role: UserRole.customer,
          createdAt: DateTime.now(),
          socialProvider: 'vk',
          socialId: '123456789',
        );

        AppLogger.logI('VK демо-пользователь создан: ${demoUser.displayName}',
            'vk_auth_service');
        return demoUser;
      }

      // Создаем тестового пользователя
      final vkUserId = 'vk_${DateTime.now().millisecondsSinceEpoch}';
      final vkEmail = 'vk_user_${DateTime.now().millisecondsSinceEpoch}@vk.com';
      final vkDisplayName = 'VK Пользователь';

      // Создаем пользователя в Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: vkEmail,
        password: 'vk_temp_password_${DateTime.now().millisecondsSinceEpoch}',
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        AppLogger.logE(
            'Firebase пользователь не создан для VK', 'vk_auth_service');
        return null;
      }

      // Обновляем профиль
      await firebaseUser.updateDisplayName(vkDisplayName);

      // Создаем пользователя в Firestore
      final appUser = AppUser.fromFirebaseUser(
        firebaseUser.uid,
        vkEmail,
        displayName: vkDisplayName,
        role: UserRole.customer,
        socialProvider: 'vk',
        socialId: vkUserId,
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toMap());

      AppLogger.logI(
          'VK пользователь создан: ${appUser.displayName}', 'vk_auth_service');
      return appUser;
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка создания VK пользователя', 'vk_auth_service', e, stackTrace);
      throw Exception('Ошибка создания VK пользователя: $e');
    }
  }

  /// Открыть окно VK OAuth (только для web)
  Future<void> _openVkAuthWindow(String url) async {
    if (kIsWeb) {
      // Используем условный импорт для web
      await _openWindowWeb(url);
    }
  }

  /// Открыть окно для web платформы
  Future<void> _openWindowWeb(String url) async {
    // Этот метод будет реализован через условный импорт
    throw UnsupportedError('VK OAuth не реализован для данной платформы');
  }
}
