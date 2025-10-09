import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

/// Сервис для работы с сессией пользователя
class SessionService {
  static const _storage = FlutterSecureStorage();
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Сохранение пользователя в локальном хранилище
  static Future<void> saveUser(AppUser user) async {
    try {
      final userJson = jsonEncode(user.toMap());
      await _storage.write(key: _userKey, value: userJson);
      await _storage.write(key: _isLoggedInKey, value: 'true');
      debugPrint('Пользователь сохранен в локальном хранилище');
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения пользователя: $e');
    }
  }

  /// Получение пользователя из локального хранилища
  static Future<AppUser?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return AppUser.fromMap(userMap);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения пользователя: $e');
    }
    return null;
  }

  /// Проверка, авторизован ли пользователь
  static Future<bool> isLoggedIn() async {
    try {
      final isLoggedIn = await _storage.read(key: _isLoggedInKey);
      return isLoggedIn == 'true';
    } on Exception catch (e) {
      debugPrint('Ошибка проверки авторизации: $e');
      return false;
    }
  }

  /// Очистка данных сессии
  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _isLoggedInKey);
      debugPrint('Сессия очищена');
    } on Exception catch (e) {
      debugPrint('Ошибка очистки сессии: $e');
    }
  }

  /// Сохранение UID пользователя
  static Future<void> saveUserId(String uid) async {
    try {
      await _storage.write(key: 'user_uid', value: uid);
      debugPrint('UID пользователя сохранен: $uid');
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения UID: $e');
    }
  }

  /// Получение UID пользователя
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: 'user_uid');
    } on Exception catch (e) {
      debugPrint('Ошибка получения UID: $e');
      return null;
    }
  }
}
