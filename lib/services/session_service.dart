import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ СЃРµСЃСЃРёРµР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
class SessionService {
  static const _storage = FlutterSecureStorage();
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РІ Р»РѕРєР°Р»СЊРЅРѕРј С…СЂР°РЅРёР»РёС‰Рµ
  static Future<void> saveUser(AppUser user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _userKey, value: userJson);
      await _storage.write(key: _isLoggedInKey, value: 'true');
      debugPrint('РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ СЃРѕС…СЂР°РЅРµРЅ РІ Р»РѕРєР°Р»СЊРЅРѕРј С…СЂР°РЅРёР»РёС‰Рµ');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РёР· Р»РѕРєР°Р»СЊРЅРѕРіРѕ С…СЂР°РЅРёР»РёС‰Р°
  static Future<AppUser?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return AppUser.fromJson(userMap);
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e');
    }
    return null;
  }

  /// РџСЂРѕРІРµСЂРєР°, Р°РІС‚РѕСЂРёР·РѕРІР°РЅ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ
  static Future<bool> isLoggedIn() async {
    try {
      final isLoggedIn = await _storage.read(key: _isLoggedInKey);
      return isLoggedIn == 'true';
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё Р°РІС‚РѕСЂРёР·Р°С†РёРё: $e');
      return false;
    }
  }

  /// РћС‡РёСЃС‚РєР° РґР°РЅРЅС‹С… СЃРµСЃСЃРёРё
  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: _userKey);
      await _storage.delete(key: _isLoggedInKey);
      debugPrint('РЎРµСЃСЃРёСЏ РѕС‡РёС‰РµРЅР°');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё СЃРµСЃСЃРёРё: $e');
    }
  }

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ UID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Future<void> saveUserId(String uid) async {
    try {
      await _storage.write(key: 'user_uid', value: uid);
      debugPrint('UID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ СЃРѕС…СЂР°РЅРµРЅ: $uid');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ UID: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ UID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: 'user_uid');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ UID: $e');
      return null;
    }
  }
}

