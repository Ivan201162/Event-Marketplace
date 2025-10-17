// Условный импорт для мобильных платформ
import 'package:firebase_auth/firebase_auth.dart' as firebase;

/// Мобильная версия сервиса аутентификации
class MobileAuthService {
  static firebase.FirebaseAuth get firebaseAuth => firebase.FirebaseAuth.instance;
}
