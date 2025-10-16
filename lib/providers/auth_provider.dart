import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  String? _currentUserId;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  // Геттеры
  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Для совместимости с существующим кодом
  Map<String, dynamic>? get currentUser =>
      _currentUserId != null ? {'id': _currentUserId} : null;

  // Методы
  Future<void> signIn(String userId) async {
    _isLoading = true;
    notifyListeners();

    // Симуляция входа
    await Future.delayed(const Duration(seconds: 1));

    _currentUserId = userId;
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    // Симуляция выхода
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUserId = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  // Для тестирования - установить пользователя
  void setTestUser(String userId) {
    _currentUserId = userId;
    _isAuthenticated = true;
    notifyListeners();
  }
}
