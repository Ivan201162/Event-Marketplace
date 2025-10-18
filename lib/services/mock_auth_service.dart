import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';

/// РњРѕРє-СЃРµСЂРІРёСЃ Р°СѓС‚РµРЅС‚РёС„РёРєР°С†РёРё РґР»СЏ С‚РµСЃС‚РёСЂРѕРІР°РЅРёСЏ Р±РµР· Firebase
class MockAuthService {
  factory MockAuthService() => _instance;
  MockAuthService._internal();
  static final MockAuthService _instance = MockAuthService._internal();

  AppUser? _currentUser;
  final List<AppUser> _users = [
    // РўРµСЃС‚РѕРІС‹Р№ email Р°РєРєР°СѓРЅС‚
    AppUser(
      id: 'test-email-user',
      email: 'testuser@example.com',
      displayName: 'РўРµСЃС‚РѕРІС‹Р№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    ),
    // РўРµСЃС‚РѕРІС‹Р№ С‚РµР»РµС„РѕРЅ Р°РєРєР°СѓРЅС‚
    AppUser(
      id: 'test-phone-user',
      email: 'phone@example.com',
      displayName: 'РўРµР»РµС„РѕРЅРЅС‹Р№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    ),
  ];

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РµРєСѓС‰РµРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  AppUser? get currentUser => _currentUser;

  /// РџРѕС‚РѕРє РёР·РјРµРЅРµРЅРёР№ СЃРѕСЃС‚РѕСЏРЅРёСЏ Р°СѓС‚РµРЅС‚РёС„РёРєР°С†РёРё
  Stream<AppUser?> get authStateChanges => Stream.value(_currentUser);

  /// Р’С…РѕРґ РїРѕ email Рё РїР°СЂРѕР»СЋ
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('INFO: [mock_auth_service] РџРѕРїС‹С‚РєР° РІС…РѕРґР° СЃ email: $email');

      // РРјРёС‚РёСЂСѓРµРј Р·Р°РґРµСЂР¶РєСѓ СЃРµС‚Рё
      await Future.delayed(const Duration(seconds: 1));

      // РџСЂРѕРІРµСЂСЏРµРј С‚РµСЃС‚РѕРІС‹Р№ Р°РєРєР°СѓРЅС‚
      if (email == 'testuser@example.com' && password == 'Test1234') {
        _currentUser = _users.firstWhere((user) => user.email == email);
        debugPrint('INFO: [mock_auth_service] РЈСЃРїРµС€РЅС‹Р№ РІС…РѕРґ СЃ email');
        return _currentUser;
      }

      // РџСЂРѕРІРµСЂСЏРµРј СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёС… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
      final user = _users.firstWhere(
        (user) => user.email == email,
        orElse: () => throw Exception('user-not-found'),
      );

      // Р”Р»СЏ РґРµРјРѕРЅСЃС‚СЂР°С†РёРё РїСЂРёРЅРёРјР°РµРј Р»СЋР±РѕР№ РїР°СЂРѕР»СЊ
      _currentUser = user;
      debugPrint('INFO: [mock_auth_service] РЈСЃРїРµС€РЅС‹Р№ РІС…РѕРґ СЃ email');
      return _currentUser;
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] РћС€РёР±РєР° РІС…РѕРґР° СЃ email: $e');
      throw _handleAuthException(e.toString());
    }
  }

  /// Р РµРіРёСЃС‚СЂР°С†РёСЏ РїРѕ email Рё РїР°СЂРѕР»СЋ
  Future<AppUser?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      debugPrint(
        'INFO: [mock_auth_service] РџРѕРїС‹С‚РєР° СЂРµРіРёСЃС‚СЂР°С†РёРё СЃ email: $email',
      );

      // РРјРёС‚РёСЂСѓРµРј Р·Р°РґРµСЂР¶РєСѓ СЃРµС‚Рё
      await Future.delayed(const Duration(seconds: 1));

      // РџСЂРѕРІРµСЂСЏРµРј, РЅРµ Р·Р°РЅСЏС‚ Р»Рё email
      if (_users.any((user) => user.email == email)) {
        throw Exception('email-already-in-use');
      }

      // РЎРѕР·РґР°РµРј РЅРѕРІРѕРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final newUser = AppUser(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      _users.add(newUser);
      _currentUser = newUser;

      debugPrint('INFO: [mock_auth_service] РЈСЃРїРµС€РЅР°СЏ СЂРµРіРёСЃС‚СЂР°С†РёСЏ СЃ email');
      return _currentUser;
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] РћС€РёР±РєР° СЂРµРіРёСЃС‚СЂР°С†РёРё СЃ email: $e');
      throw _handleAuthException(e.toString());
    }
  }

  /// Р’С…РѕРґ РїРѕ С‚РµР»РµС„РѕРЅСѓ
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      debugPrint(
        'INFO: [mock_auth_service] РћС‚РїСЂР°РІРєР° SMS РЅР° РЅРѕРјРµСЂ: $phoneNumber',
      );

      // РРјРёС‚РёСЂСѓРµРј Р·Р°РґРµСЂР¶РєСѓ РѕС‚РїСЂР°РІРєРё SMS
      await Future.delayed(const Duration(seconds: 1));

      // Р”Р»СЏ С‚РµСЃС‚РѕРІРѕРіРѕ РЅРѕРјРµСЂР° СЃСЂР°Р·Сѓ "РѕС‚РїСЂР°РІР»СЏРµРј" SMS
      if (phoneNumber == '+79998887766') {
        debugPrint(
          'INFO: [mock_auth_service] SMS РєРѕРґ РѕС‚РїСЂР°РІР»РµРЅ (С‚РµСЃС‚РѕРІС‹Р№ СЂРµР¶РёРј)',
        );
        return;
      }

      throw Exception('invalid-phone-number');
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё SMS: $e');
      rethrow;
    }
  }

  /// РџРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ SMS РєРѕРґР°
  Future<AppUser?> confirmPhoneCode(String smsCode) async {
    try {
      debugPrint('INFO: [mock_auth_service] РџРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ SMS РєРѕРґР°');

      // РРјРёС‚РёСЂСѓРµРј Р·Р°РґРµСЂР¶РєСѓ РїСЂРѕРІРµСЂРєРё РєРѕРґР°
      await Future.delayed(const Duration(seconds: 1));

      // РџСЂРѕРІРµСЂСЏРµРј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРґ
      if (smsCode == '123456') {
        _currentUser = _users.firstWhere((user) => user.id == 'test-phone-user');
        debugPrint('INFO: [mock_auth_service] РЈСЃРїРµС€РЅС‹Р№ РІС…РѕРґ РїРѕ С‚РµР»РµС„РѕРЅСѓ');
        return _currentUser;
      }

      throw Exception('invalid-verification-code');
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] РћС€РёР±РєР° РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ SMS: $e');
      rethrow;
    }
  }

  /// Р’С…РѕРґ РєР°Рє РіРѕСЃС‚СЊ
  Future<AppUser?> signInAsGuest() async {
    try {
      debugPrint('INFO: [mock_auth_service] РџРѕРїС‹С‚РєР° РІС…РѕРґР° РєР°Рє РіРѕСЃС‚СЊ');

      // РРјРёС‚РёСЂСѓРµРј Р·Р°РґРµСЂР¶РєСѓ
      await Future.delayed(const Duration(milliseconds: 500));

      // РЎРѕР·РґР°РµРј РіРѕСЃС‚РµРІРѕРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final guestUser = AppUser(
        id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@example.com',
        displayName: 'Р“РѕСЃС‚СЊ',
        role: UserRole.guest,
        createdAt: DateTime.now(),
      );

      _currentUser = guestUser;
      debugPrint('INFO: [mock_auth_service] РЈСЃРїРµС€РЅС‹Р№ РІС…РѕРґ РєР°Рє РіРѕСЃС‚СЊ');
      return _currentUser;
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] РћС€РёР±РєР° РІС…РѕРґР° РєР°Рє РіРѕСЃС‚СЊ: $e');
      rethrow;
    }
  }

  /// Р’С‹С…РѕРґ
  Future<void> signOut() async {
    try {
      _currentUser = null;
      debugPrint('INFO: [mock_auth_service] Р’С‹С…РѕРґ РІС‹РїРѕР»РЅРµРЅ');
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] РћС€РёР±РєР° РІС‹С…РѕРґР°: $e');
      rethrow;
    }
  }

  /// РћР±СЂР°Р±РѕС‚РєР° РѕС€РёР±РѕРє
  String _handleAuthException(String error) {
    if (error.contains('user-not-found')) {
      return 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ СЃ С‚Р°РєРёРј email РЅРµ РЅР°Р№РґРµРЅ';
    } else if (error.contains('wrong-password')) {
      return 'РќРµРІРµСЂРЅС‹Р№ РїР°СЂРѕР»СЊ';
    } else if (error.contains('email-already-in-use')) {
      return 'РўР°РєРѕР№ email СѓР¶Рµ Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°РЅ';
    } else if (error.contains('weak-password')) {
      return 'РџР°СЂРѕР»СЊ СЃР»РёС€РєРѕРј СЃР»Р°Р±С‹Р№';
    } else if (error.contains('invalid-email')) {
      return 'РќРµРІРµСЂРЅС‹Р№ С„РѕСЂРјР°С‚ email';
    } else if (error.contains('invalid-verification-code')) {
      return 'РќРµРІРµСЂРЅС‹Р№ РєРѕРґ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ';
    } else if (error.contains('invalid-phone-number')) {
      return 'РќРµРІРµСЂРЅС‹Р№ РЅРѕРјРµСЂ С‚РµР»РµС„РѕРЅР°';
    } else {
      return 'РџСЂРѕРёР·РѕС€Р»Р° РѕС€РёР±РєР°: $error';
    }
  }
}


